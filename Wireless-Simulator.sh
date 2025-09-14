#!/bin/bash

# 🔹 Color variables
RED=$'\e[0;31m'
NC=$'\e[0m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[0;33m'
BLUE=$'\e[0;34m'
CYAN=$'\e[0;36m'

# 🔹 User acknowledgment
echo -e "${YELLOW}⚠️  Please ensure no Ethernet cable is connected to this device.${NC}"
while true; do
    read -p "$(echo -e "${GREEN}Type 'yes' to confirm and continue: ${NC}")" ack
    if [[ "$ack" == "yes" ]]; then
        echo -e "${GREEN}✅ Acknowledged. Continuing...${NC}"
        break
    else
        echo -e "${RED}❌ Invalid input. Please type 'yes' to continue.${NC}"
    fi
done

# 🔹 Ask user number of iterations
while true; do
    echo -e "${YELLOW}⚠️  Each Wi-Fi test may take up to 10-15 mins${NC}"
    read -p "$(echo -e "${BLUE}Enter the number of Wi-Fi Tests: ${NC}")" iterations
    if [[ "$iterations" =~ ^[1-9][0-9]*$ ]]; then break; fi
    echo -e "${RED}❌ Please enter a valid positive integer.${NC}"
done

# 🔹 Wi-Fi interface & Mac serial
wifi_device=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')
SERIAL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# 🔹 CSV file
NOW=$(date "+%Y-%m-%d_%H-%M-%S")
RESULTS="$HOME/Desktop/WiFiTestResults_${SERIAL}_${NOW}.csv"

# 🔹 CSV header
header="Timestamp,IP Address,Default Gateway,Primary DNS,Secondary DNS,Google_Status,Google_RTT,PrimaryDNS_Status,PrimaryDNS_RTT,SecondaryDNS_Status,SecondaryDNS_RTT,Apple_Status,Apple_RTT,Cloudflare_Status,Cloudflare_RTT"
echo "$header" > "$RESULTS"

# 🔹 Run iterations
for ((iter=1; iter<=iterations; iter++)); do
    echo -e "${RED}🔴 Disconnecting Wi-Fi (Iteration $iter)...${NC}"
    networksetup -setairportpower "$wifi_device" off
    sleep 2

    echo -e "${GREEN}🟢 Reconnecting Wi-Fi (Iteration $iter)...${NC}"
    networksetup -setairportpower "$wifi_device" on
    sleep 5

    echo -e "${BLUE}🔵 Gathering network info for iteration $iter...${NC}"

    # 🔹 IP, Gateway, DNS
    ip_address=$(ipconfig getifaddr "$wifi_device")
    default_gateway=$(netstat -rn | awk '/default/ && /'"$wifi_device"'/{print $2}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
    dns_list=($(scutil --dns | awk -v iface="$wifi_device" '
        $0 ~ "nameserver" && $0 ~ iface {
            while(getline){ if ($0 ~ /nameserver/ && $3 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/) print $3 }
        }'))
    primary_dns="${dns_list[0]}"
    secondary_dns="${dns_list[1]}"
    [[ -z "$primary_dns" ]] && primary_dns="DNS empty"
    [[ -z "$secondary_dns" ]] && secondary_dns="DNS empty"

    # 🔹 Destinations
    destinations=("8.8.8.8" "$primary_dns" "$secondary_dns" "apple.com" "cloudflare.com")

    ping_count=10
    ping_statuses=()
    ping_rtts=()

    for dest in "${destinations[@]}"; do
        if [[ -z "$dest" || "$dest" == "DNS empty" ]]; then
            ping_statuses+=("Skipped")
            ping_rtts+=("Skipped")
            continue
        fi

        success=0
        total_rtt=0

        for j in $(seq 1 $ping_count); do
            result=$(ping -c 1 -W 1000 "$dest" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                ((success++))
                rtt=$(echo "$result" | awk -F'=' '/time=/{print $4}' | awk '{print $1}')
                total_rtt=$(echo "$total_rtt + $rtt" | bc)
            fi
        done

        if [[ $success -eq $ping_count ]]; then
            status="All ($ping_count) pings successful"
        elif [[ $success -eq 0 ]]; then
            status="All pings failed"
        else
            status="Partially Successful ($success/$ping_count)"
        fi

        avg_rtt=$([[ $success -gt 0 ]] && echo "scale=2; $total_rtt / $success" | bc || echo "Failed")

        # Add ms and emoji
        if [[ "$avg_rtt" != "Failed" ]]; then
            if (( $(echo "$avg_rtt < 100" | bc -l) )); then
                avg_rtt="${avg_rtt}ms ✅"
            else
                avg_rtt="${avg_rtt}ms ⚠️"
            fi
        else
            avg_rtt="Failed ⚠️"
        fi

        ping_statuses+=("$status")
        ping_rtts+=("$avg_rtt")
    done

    # 🔹 Write CSV line
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    line="$TIMESTAMP,$ip_address,$default_gateway,$primary_dns,$secondary_dns"
    for idx in "${!ping_statuses[@]}"; do
        line+=","${ping_statuses[$idx]}","${ping_rtts[$idx]}
    done

    echo "$line" >> "$RESULTS"
    echo -e "${BLUE}🔵 Iteration $iter completed${NC}"
done

echo -e "${GREEN}✅ Results saved to CSV:${NC} ${CYAN}$RESULTS${NC}"
