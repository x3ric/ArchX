#!/bin/bash
while true; do
    list_networks() {
        iwlist wlan0 scanning | grep "ESSID:" | sed -E 's/.*ESSID:"?([^"]+)"?/\1/' | grep -v '^$' | sort -u
    }
    connect_to_network() {
        local network_ssid="$1"
        read -sp "Enter the Wi-Fi password for \"$network_ssid\": " password
        echo
        iwctl --passphrase "$password" station wlan0 connect "$network_ssid"
    }
    IFS=$'\n'
    iw_networks=($(list_networks))
    unset IFS
    echo "Available Wi-Fi networks:"
    echo "-------------------------"
    for i in "${!iw_networks[@]}"; do
        echo "$((i+1)). ${iw_networks[i]}"
    done
    read -p "Enter the number of the Wi-Fi network you want to connect to: " choice
    selected_network="${iw_networks[$((choice - 1))]}"
    connect_to_network "$selected_network"
    if ping -c 4 8.8.8.8; then
        echo "Ping successful! Exiting..."
        break
    else
        echo "Ping failed. Retrying..."
    fi
done