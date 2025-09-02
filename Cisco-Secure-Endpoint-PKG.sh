#!/bin/bash


# Download the MAC Installer for MAC OS (Group:Protect)
# Console URL in EU in this case 
# https://console.eu.amp.cisco.com/download_connector

# Check if we have move than one Cisco AMP DMG Installer in our Downloads folder 


# Colors for output
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${RED}${BOLD}ℹ️ Read the instruction below carefully and follow the steps${NC}"
echo -e "⬇️ Download the latest Cisco Secure Endpoint client installer from the Cisco Secure Endpoint Portal"
echo -e "🌐 URL: https://console.eu.amp.cisco.com/download_connector (for EU). " 
echo -e "📁 Add the Cisco Secure Endpoint installer (amp_Protect.dmg under the folder /Cisco-Secure-Endpoint-App-DB folder/Version "
echo -e "For example the full DMG path must be: ${RED}${BOLD}~/Cisco-Secure-Endpoint-App-DB/1.27.0.1046/amp_Protect.dmg${NC}"

while true; do
  echo -e "Type '${RED}${BOLD}continue${NC}' and press ${RED}${BOLD}Enter${NC} to proceed: "
  read input
  
  if [ "$input" = "continue" ]; then
    echo "✅ Proceeding with the installation..."
    break
  else
    echo "❌ You typed: '$input'. Please type 'continue' to proceed."
    echo " Try again or press Ctrl+C to exit the script."
  fi
done


# Get version from user and check if DMG exists
while true; do
  read -p "📋 Enter the Cisco Secure Endpoint version number (e.g., 1.27.0.1046): " version
  
  if [ -z "$version" ]; then
    echo "❌ Version cannot be empty. Please try again."
    continue
  fi
  
  # Construct the full path
  dmg_path="$HOME/Cisco-Secure-Endpoint-App-DB/$version/amp_Protect.dmg"
  folder_path="$HOME/Cisco-Secure-Endpoint-App-DB/$version"
  
  echo -e "🔍 Checking if DMG exists at: ${RED}$dmg_path${NC}"
  
  if [ -f "$dmg_path" ]; then
    echo -e "✅ DMG file found! Path exists"
    break
  else
    echo "❌ DMG file not found at: $dmg_path"
    echo "📁 Please make sure the folder structure exists and contains amp_Protect.dmg"
    echo -e "For example the full DMG path must be: ${RED}~/Cisco-Secure-Endpoint-App-DB/1.27.0.1046/amp_Protect.dmg${NC}"

    read -p "🔄 Try again? (y/n): " retry
    if [[ ! "$retry" =~ ^[Yy]$ ]]; then
      echo "👋 Exiting script. Goodbye!"
      exit 1
    fi
  fi
done

# Remove the trailing slash from folder_path
folder_path="$HOME/Cisco-Secure-Endpoint-App-DB/$version"
pkg_folder="$folder_path/PKG-$version"


# Check if PKG folder exists and delete it with all contents
if [ -d "$pkg_folder" ]; then
  echo -e "🧹 Removing existing PKG folder: ${RED}$pkg_folder${NC}"
  rm -rf "$pkg_folder"
fi

# Now create the directory where the PKG file will be added.
mkdir -p "$pkg_folder"

# Mount the DMG File and extract the pkg file - Supressing output
hdiutil attach $dmg_path >> /dev/null

# Move the pkg file to our PKG folder - Supressing output
# There is also a hidden XML file that needs to be copied over
cp /Volumes/ampmac*/ciscoampmac*.pkg $pkg_folder >> /dev/null
cp /Volumes/ampmac*/.policy.xml $pkg_folder >> /dev/null

# Unmount the DMG - Suppressing output
hdiutil detach /Volumes/ampmac* >> /dev/null

# ZIP all files (excluding folders) from the PKG folder
echo -e "📦 Creating ZIP file with all files from: ${RED}$pkg_folder${NC}"
cd "$pkg_folder"

# Create ZIP with all files in current directory (excluding folders)
zip -j "PKG-$version.zip" ./* >> /dev/null

echo -e "✅ ZIP file created: ${RED}PKG-$version.zip${NC}"

echo -e "✅ Process completed! ZIP file is ready at: ${RED}$pkg_folder/PKG-$version.zip${NC}"


