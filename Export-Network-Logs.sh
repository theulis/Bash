#!/bin/bash

# ⚡ Network Troubleshooting Log Collector
# This script collects macOS networking-related logs for post-incident troubleshooting.
# It may take 10-15 minutes to run depending on log size.
# DO NOT close the Terminal window during execution.
# Exported logs will be saved in ~/Downloads/SysLogs as individual files and a zipped archive.

RED='\033[31m'    # Red text
GREEN='\033[32m'  # Green text
YELLOW='\033[33m' # Yellow text
RESET='\033[0m'   # Reset color

echo -e "${GREEN}🟢 Starting network log collection...${RESET}"
echo -e "${YELLOW}⏳ This may take up to 10–15 minutes. Please do not close the Terminal window.${RESET}"

# --- Temp directory for log collection --- 
if [ -d "/Users/Shared/SysLogs" ]; then
    /bin/rm -rf /Users/Shared/SysLogs >> /dev/null
fi
/bin/mkdir /Users/Shared/SysLogs

# 1️⃣ DNS-related events (mDNSResponder)
/usr/bin/log show --last 8h --predicate 'process == "mDNSResponder"' > /Users/Shared/SysLogs/process-mDNSResponder.log
echo "✅ Collected DNS logs (mDNSResponder)."

# 2️⃣ Network configuration and interface events (configd)
/usr/bin/log show --last 8h --predicate 'process == "configd"' > /Users/Shared/SysLogs/process-configd.log
echo "✅ Collected configd logs."

# 3️⃣ Network interface, routing, and connectivity events (networkd)
/usr/bin/log show --last 8h --predicate 'process == "networkd"' > /Users/Shared/SysLogs/process-networkd.log
echo "✅ Collected networkd logs."

# 4️⃣ Wi-Fi daemon events (airportd)
/usr/bin/log show --last 8h --predicate 'process == "airportd"' > /Users/Shared/SysLogs/process-airportd.log
echo "✅ Collected airportd (Wi-Fi) logs."

# 5️⃣ VPN-related processes
/usr/bin/log show --last 8h --predicate 'process CONTAINS[cd] "vpn"' > /Users/Shared/SysLogs/process-vpn.log
echo "✅ Collected VPN-related logs."

# 6️⃣ DHCP-related events
/usr/bin/log show --last 8h --predicate 'process == "bootp" OR eventMessage CONTAINS[cd] "DHCP"' > /Users/Shared/SysLogs/process-dhcp.log
echo "✅ Collected DHCP logs."

# 7️⃣ DNS and Umbrella logs
/usr/bin/log show --last 8h --predicate 'eventMessage CONTAINS[cd] "dns"' > /Users/Shared/SysLogs/eventMessage-dns.log
echo "✅ Collected generic DNS logs."
/usr/bin/log show --last 8h --predicate 'eventMessage CONTAINS[cd] "umbrella"' > /Users/Shared/SysLogs/eventMessage-umbrella.log
echo "✅ Collected Umbrella logs."

# 8️⃣ Network Extension subsystem logs
/usr/bin/log show --last 8h --predicate 'subsystem == "com.apple.networkextension"' > /Users/Shared/SysLogs/subsystem_com.apple.networkextension.log
echo "✅ Collected network extension logs."

# 9️⃣ System-wide network configuration changes
/usr/bin/log show --last 8h --predicate 'subsystem == "com.apple.SystemConfiguration"' > /Users/Shared/SysLogs/subsystem_com.apple.SystemConfiguration.log
echo "✅ Collected SystemConfiguration logs."

# 🔟 Symptomsd network health monitoring
/usr/bin/log show --last 8h --predicate 'subsystem == "com.apple.symptomsd" AND category == "netepochs"' > /Users/Shared/SysLogs/subsystem_com.apple.symptomsd.log
echo "✅ Collected symptomsd logs (network health)."

# 1️⃣1️⃣ Network subsystem connection logs
/usr/bin/log show --last 8h --predicate 'subsystem == "com.apple.network" AND category == "connection"' > /Users/Shared/SysLogs/subsystem_com.apple.network.log
echo "✅ Collected com.apple.network connection logs."

# --- Create a zipped archive of all logs ---
echo "📦 Creating a zip archive of all logs..."
/usr/bin/zip -r ~/Desktop/SysLogs/verbose-logs-$USER-"$(date +%Y-%m-%d_%H-%M-%S)".zip /Users/Shared/SysLogs/ > /dev/null

# --- Cleanup temporary folder ---
/bin/rm -rf /Users/Shared/SysLogs

# --- Final user notification ---
echo -e "${GREEN}🎉 Network log collection complete!${RESET}"
echo -e "${YELLOW}📂 Your logs are now available in the ZIP file:${RESET}"
echo -e "${RED}   $ZIP_FILE${RESET}"