#!/bin/bash

### 🔌 This script restarts Wi-Fi by turning it off, then on again.
### 🚀 Useful when the device struggles with roaming or staying connected.


### That warning is macOS telling you that the airport command is deprecated and may disappear in future versions. 
### Apple recommends using Wireless Diagnostics (wdutil) instead - but there is no equivalent for --disassociate
### 🔴 Unfortunately due to macOS command limitation, this is not a recommended script any more

RED=$'\e[0;31m'
NC=$'\e[0m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[0;33m'

wifi_device=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

echo "${BLUE}==============================${NC}"
echo "${RED}🔴 Disconnecting from Wi-Fi...${NC}"
echo "🔑 If prompted, please type your Local MAC Password and press Enter"
echo "${BLUE}==============================${NC}"


### Not sure if this command is working any more!!
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --disassociate &>/dev/null

# Turn off Wi-Fi
networksetup -setairportpower "$wifi_device" off

echo "${YELLOW}🟡 Waiting a moment...${NC}"
sleep 2

# Turn Wi-Fi back on
echo "${GREEN}🟢 Reconnecting to Wi-Fi...${NC}"
networksetup -setairportpower "$wifi_device" on

# Wait a few seconds for Wi-Fi to reinitialize
sleep 5

### This command is no longer supported - Show which WiFi you are connected
### sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I

echo "📶 ${GREEN}Connected Back to Wi-Fi"