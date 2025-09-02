#!/bin/bash

# -----------------------------
# Colors
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# -----------------------------
# User instructions
# -----------------------------
echo -e "${RED}${BOLD}ℹ️ Read the instructions carefully${NC}"
echo -e "⬇️ Download the latest Cisco Secure Client installer (Mac OS) from the Cisco Portal"
echo -e "🌐 URL: https://software.cisco.com/download/home/286330811/"
echo -e "📁 Place the dmg installer under ${RED}${BOLD}~/Cisco-Secure-Client-App-DB/Cisco-Secure-Client-Version/${NC}"
echo -e "Config files must be under ${RED}${BOLD}~/Cisco-Secure-Client-App-DB/Cisco-Secure-Client-Version/Configuration-Files/${NC}"

# -----------------------------
# User acknowledges
# -----------------------------
while true; do
    echo -e "Type '${RED}${BOLD}continue${NC}' to proceed:"
    read input
    if [ "$input" = "continue" ]; then
        echo "✅ Proceeding..."
        break
    else
        echo "❌ Invalid input. Try again."
    fi
done

# -----------------------------
# Version input
# -----------------------------
is_valid_version() {
    local version="$1"
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

read -p "Enter Cisco Secure Client version (e.g., 5.1.10.233): " VERSION
if ! is_valid_version "$VERSION"; then
    echo "⚠️ Invalid version format"
    exit 1
fi
echo -e "✅ Version format looks good: $VERSION"

# -----------------------------
# Config folder
# -----------------------------
CONFIG_DIR="$HOME/Cisco-Secure-Client-App-DB/Configuration-Files"

# -----------------------------
# Module file arrays
# -----------------------------
VPN_FILES=("$CONFIG_DIR/anyconnectOGS.xml")
UMBRELLA_FILES=("$CONFIG_DIR/OrgInfo.json" "$CONFIG_DIR/Cisco_Secure_Access_Root_CA.cer")
THOUSANDEYES_FILES=("$CONFIG_DIR/ThousandEyes Endpoint Agent Configuration.json")
ZEROTRUST_FILES=()
DART_FILES=()
DUO_FILES=()

# -----------------------------
# Menu options
# -----------------------------
MENU_OPTIONS=("Umbrella" "ThousandEyes" "ZeroTrust" "DUO")

# -----------------------------
# Mandatory files check for VPN
# -----------------------------
echo "🔍 Checking mandatory configuration file(s) for VPN..."
MISSING="false"
for file in "${VPN_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "✅ Found VPN file: $file"
    else
        echo -e "❌ Missing VPN file: $file"
        MISSING="true"
    fi
done
if [[ "$MISSING" = "true" ]]; then
    exit 1
fi

# -----------------------------
# Interactive menu
# -----------------------------
FINAL_MODULES=("VPN" "DART")  # always included
while true; do
    clear
    echo -e "${CYAN}================ Module Selection ================${NC}"
    echo -e "${GREEN}VPN${NC} and ${GREEN}DART${NC} are always included."
    echo "Select optional modules by typing numbers (comma-separated):"
    for i in "${!MENU_OPTIONS[@]}"; do
        echo -e "${YELLOW}$((i+1)))${NC} ${MENU_OPTIONS[$i]}"
    done
    echo -e "${CYAN}==================================================${NC}"
    
    read -p "Enter selection: " selection
    IFS=',' read -ra choices <<< "$selection"
    
    TEMP_MODULES=("VPN" "DART")
    for choice in "${choices[@]}"; do
        choice=$(echo "$choice" | xargs)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#MENU_OPTIONS[@]} )); then
            module="${MENU_OPTIONS[$((choice-1))]}"
            TEMP_MODULES+=("$module")
        else
            echo -e "${RED}Invalid choice: $choice${NC}"
        fi
    done
    
    echo "You selected:"
    for m in "${TEMP_MODULES[@]}"; do
        echo " - $m"
    done
    read -p "Confirm? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        FINAL_MODULES=("${TEMP_MODULES[@]}")
        break
    fi
done

# -----------------------------
# Check config files for selected modules
# -----------------------------
echo "🔍 Checking configuration files..."
MISSING="false"
for module in "${FINAL_MODULES[@]}"; do
    case "$module" in
        VPN) files=("${VPN_FILES[@]}") ;;
        Umbrella) files=("${UMBRELLA_FILES[@]}") ;;
        ThousandEyes) files=("${THOUSANDEYES_FILES[@]}") ;;
        ZeroTrust) files=() ;;
        DART) files=() ;;
        DUO) files=() ;;
    esac
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "ℹ️ No config files required for $module, skipping."
        continue
    fi
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "✅ Found file for $module: $file"
        else
            echo -e "❌ Missing file for $module: $file"
            MISSING="true"
        fi
    done
done

if [[ "$MISSING" = "true" ]]; then
    echo "⚠️ One or more required files are missing. Aborting."
    exit 1
fi

# -----------------------------
# Check DMG
# -----------------------------
DMG_DIR="$HOME/Cisco-Secure-Client-App-DB/Cisco-Secure-Client-$VERSION"
DMG_FILE="cisco-secure-client-macos-$VERSION-predeploy-k9.dmg"
DMG_PATH="$DMG_DIR/$DMG_FILE"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "❌ DMG not found: $DMG_PATH"
    exit 1
fi
echo "✅ Found DMG: $DMG_FILE"

# -----------------------------
# Prepare working directories
# -----------------------------
WORKDIR="/tmp/cisco_secure_client_custom_$VERSION"
MOUNTDIR="/Volumes/CiscoSecureClient"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# -----------------------------
# Mount DMG
# -----------------------------
echo "🚀 Mounting DMG..."
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNTDIR" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to mount DMG"
    exit 1
fi

# Find .pkg inside DMG
PKG_SOURCE=$(find "$MOUNTDIR" -name "*.pkg" | head -n 1)
if [[ -z "$PKG_SOURCE" ]]; then
    echo "❌ No .pkg found inside DMG"
    hdiutil detach "$MOUNTDIR" > /dev/null 2>&1
    exit 1
fi
echo "✅ Found pkg: $PKG_SOURCE"

# -----------------------------
# Expand package
# -----------------------------
echo "🚀 Expanding package..."
pkgutil --expand "$PKG_SOURCE" "$WORKDIR/expanded"
hdiutil detach "$MOUNTDIR" > /dev/null 2>&1

# -----------------------------
# Copy selected module files into expanded pkg
# -----------------------------
for module in "${FINAL_MODULES[@]}"; do
    pkgname="$(echo "$module" | tr '[:upper:]' '[:lower:]')_module_flat.pkg"
    case "$module" in
        VPN) files=("${VPN_FILES[@]}") ;;
        Umbrella) files=("${UMBRELLA_FILES[@]}") ;;
        ThousandEyes) files=("${THOUSANDEYES_FILES[@]}") ;;
        ZeroTrust) files=() ;;
        DART) files=() ;;
        DUO) files=() ;;
    esac
    
    # Copy config files (if any)
    for file in "${files[@]}"; do
        cp "$file" "$WORKDIR/expanded/"
        echo "✅ Copied $file"
    done
done


# -----------------------------
# ZIP final package (flattened)
# -----------------------------

STAGING="$WORKDIR/staging"
mkdir -p "$STAGING"


# Copy ALL configuration files to staging
for module in "${FINAL_MODULES[@]}"; do
    case "$module" in
        VPN) files=("${VPN_FILES[@]}") ;;
        Umbrella) files=("${UMBRELLA_FILES[@]}") ;;
        ThousandEyes) files=("${THOUSANDEYES_FILES[@]}") ;;
        ZeroTrust|DART|DUO) files=() ;;
    esac
    for file in "${files[@]}"; do
        cp "$file" "$STAGING/"
    done
done

# Copy and flatten module packages based on selection
cd "$WORKDIR/expanded" || exit 1

# Always include DART module
if [[ -d "dart_module.pkg" ]]; then
    echo "📦 Flattening dart_module.pkg..."
    pkgutil --flatten "dart_module.pkg" "$STAGING/dart_module_flat.pkg"
fi

# Copy selected module packages (only those selected from menu)
for module in "${FINAL_MODULES[@]}"; do
    case "$module" in
        VPN)
            if [[ -d "vpn_module.pkg" ]]; then
                echo "📦 Flattening vpn_module.pkg..."
                pkgutil --flatten "vpn_module.pkg" "$STAGING/vpn_module_flat.pkg"
            fi
            ;;
        Umbrella)
            if [[ -d "umbrella_module.pkg" ]]; then
                echo "📦 Flattening umbrella_module.pkg..."
                pkgutil --flatten "umbrella_module.pkg" "$STAGING/umbrella_module_flat.pkg"
            fi
            ;;
        ThousandEyes)
            if [[ -d "thousandeyes_module.pkg" ]]; then
                echo "📦 Flattening thousandeyes_module.pkg..."
                pkgutil --flatten "thousandeyes_module.pkg" "$STAGING/thousandeyes_module_flat.pkg"
            fi
            ;;
        ZeroTrust)
            if [[ -d "zta_module.pkg" ]]; then
                echo "📦 Flattening zta_module.pkg..."
                pkgutil --flatten "zta_module.pkg" "$STAGING/zta_module_flat.pkg"
            fi
            ;;
        DUO)
            if [[ -d "duo_module.pkg" ]]; then
                echo "📦 Flattening duo_module.pkg..."
                pkgutil --flatten "duo_module.pkg" "$STAGING/duo_module_flat.pkg"
            fi
            ;;
    esac
done

cd "$STAGING" || exit 1
ZIP_NAME="CiscoSecureClient-Custom-$VERSION.zip"

# Create flattened ZIP with all files
zip -j "$DMG_DIR/$ZIP_NAME" ./* > /dev/null

# Cleanup
rm -rf "$WORKDIR"
echo "✅ Custom installer zip created at: $DMG_DIR/$ZIP_NAME"