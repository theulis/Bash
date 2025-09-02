#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}${BOLD}ℹ️ Read the instruction below carefully and follow the steps${NC}"
echo -e "⬇️ Download the latest Cisco Secure Client installer from the Cisco Secure Endpoint Portal"
echo -e "Cisco Secure Client Pre-Deployment Package (Mac OS): cisco-secure-client-macos-<version>-predeploy-k9.dmg"
echo -e "🌐 URL: https://software.cisco.com/download/home/286330811/ " 
echo -e "📁 Add the Cisco Secure Client dmg installer under the folder Cisco-Secure-Client-App-DB/Cisco-Secure-Client-Version "
echo -e "For example the full DMG path must be: ${RED}${BOLD}~/Cisco-Secure-Client-App-DB/Cisco-Secure-Client-5.1.10.233/cisco-secure-client-macos-5.1.10.233-predeploy-k9.dmg${NC}"

## Function to check if the Cisco Secure Client Version format is valid
is_valid_version() {
    local version="$1"
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

read -p "Enter the Cisco Secure Client version (e.g., 5.1.10.233): " VERSION

if ! is_valid_version "$VERSION"; then
    echo "⚠️ Invalid version format. Use X.X.X or X.X.X.X (e.g., 5.1.10 or 5.1.10.233)"
    exit 1
fi

echo "✅ Version format looks good: $VERSION"

CONFIG_DIR="$HOME/Cisco-Secure-Client-App-DB/Configuration-Files"
CONFIG_MODULES=("VPN" "Umbrella" "ThousandEyes")
CONFIG_FILES=("anyconnectOGS.xml" "orgInfo.json" "ThousandEyes Endpoint Agent Configuration.json")

echo "🔍 Checking configuration files in: $CONFIG_DIR"
MISSING="false"

for i in "${!CONFIG_MODULES[@]}"; do
    MODULE="${CONFIG_MODULES[$i]}"
    FILE="${CONFIG_FILES[$i]}"
    FILE_PATH="$CONFIG_DIR/$FILE"

    if [[ ! -f "$FILE_PATH" ]]; then
        echo "❌ Missing config for $MODULE: $FILE"
        MISSING="true"
    else
        echo "✅ Found config for $MODULE: $FILE"
    fi
done

if [[ "$MISSING" == "true" ]]; then
    echo "⚠️ One or more required configuration files are missing. Aborting."
    exit 1
fi

# Optional certificate check
CERT_FILE="$CONFIG_DIR/Cisco_Secure_Access_Root_CA.cer"
if [[ -f "$CERT_FILE" ]]; then
    echo "✅ Found certificate file: $(basename "$CERT_FILE")"
else
    echo "ℹ️ Certificate file not found (optional): $(basename "$CERT_FILE")"
fi

CHOICES_XML="$CONFIG_DIR/install_choices.xml"
if [[ ! -f "$CHOICES_XML" ]]; then
    echo "❌ install_choices.xml file not found in $CONFIG_DIR"
    exit 1
fi
echo "✅ Found install_choices.xml"

# Check for DMG file
DMG_DIR="$HOME/Cisco-Secure-Client-App-DB/Cisco-Secure-Client-$VERSION"
DMG_FILE="cisco-secure-client-macos-$VERSION-predeploy-k9.dmg"
DMG_PATH="$DMG_DIR/$DMG_FILE"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "❌ Expected DMG file not found: $DMG_PATH"
    exit 1
fi
echo "✅ Found DMG file: $DMG_FILE"

# Prepare working directories
WORKDIR="/tmp/cisco_secure_client_custom_$VERSION"
MOUNTDIR="/Volumes/CiscoSecureClient"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Mount the DMG
echo "🚀 Mounting DMG..."
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNTDIR" > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to mount DMG: $DMG_PATH"
    exit 1
fi

# Find the .pkg inside mounted DMG
PKG_SOURCE=$(find "$MOUNTDIR" -name "*.pkg" | head -n 1)
if [[ -z "$PKG_SOURCE" ]]; then
    echo "❌ No .pkg found inside mounted DMG."
    hdiutil detach "$MOUNTDIR" > /dev/null 2>&1
    exit 1
fi
echo "✅ Found pkg: $PKG_SOURCE"

# Expand the installer package
echo "🚀 Expanding installer package..."
pkgutil --expand "$PKG_SOURCE" "$WORKDIR/expanded"

# Unmount the DMG
hdiutil detach "$MOUNTDIR" > /dev/null 2>&1

# Copy config files, cert, choices.xml into expanded pkg
cp "$CONFIG_DIR/anyconnectOGS.xml" "$WORKDIR/expanded/"
cp "$CONFIG_DIR/orgInfo.json" "$WORKDIR/expanded/"
cp "$CONFIG_DIR/ThousandEyes Endpoint Agent Configuration.json" "$WORKDIR/expanded/"
cp "$CHOICES_XML" "$WORKDIR/expanded/"
if [[ -f "$CERT_FILE" ]]; then
    cp "$CERT_FILE" "$WORKDIR/expanded/"
fi

# Rebuild the custom package
CUSTOM_PKG_NAME="CiscoSecureClient-Custom-$VERSION.pkg"
CUSTOM_PKG_PATH="$WORKDIR/$CUSTOM_PKG_NAME"

echo "🚀 Rebuilding custom package..."
pkgutil --flatten "$WORKDIR/expanded" "$CUSTOM_PKG_PATH"
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to rebuild the custom package."
    exit 1
fi
echo "✅ Custom installer created at: $CUSTOM_PKG_PATH"

# Prepare flat staging directory for zip
STAGING_DIR="$WORKDIR/staging"
mkdir -p "$STAGING_DIR"

# Move the custom pkg into staging
mv "$CUSTOM_PKG_PATH" "$STAGING_DIR/"

# Copy all config files and optional cert
cp "$CONFIG_DIR/anyconnectOGS.xml" "$STAGING_DIR/"
cp "$CONFIG_DIR/orgInfo.json" "$STAGING_DIR/"
cp "$CONFIG_DIR/ThousandEyes Endpoint Agent Configuration.json" "$STAGING_DIR/"
cp "$CHOICES_XML" "$STAGING_DIR/"
if [[ -f "$CERT_FILE" ]]; then
    cp "$CERT_FILE" "$STAGING_DIR/"
fi

# Create the zip archive with flat structure
cd "$STAGING_DIR" || exit 1
ZIP_NAME="CiscoSecureClient-Custom-$VERSION.zip"
zip -r "$DMG_DIR/$ZIP_NAME" . > /dev/null

# Clean up
echo "🧹 Cleaning up..."
rm -rf "$WORKDIR"

echo "✅ Custom installer zip created at: $DMG_DIR/$ZIP_NAME"
