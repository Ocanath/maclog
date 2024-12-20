#!/bin/bash

# Path to store the unique MAC addresses
MAC_LOG_FILE="./mac_addresses.log"
CURRENT_MACS_FILE="./current_macs.txt"

# Network interface to scan (change to your network interface, e.g., eth0, wlan0)
INTERFACE="wlan0"  # Change this to your local network interface (e.g., eth0, wlan0)

# Function to get the current MAC addresses from the network
get_current_mac_addresses() {
    # Use arp-scan to scan the local network for devices
    # arp-scan sends ARP requests to all devices on the network and returns their MAC addresses
    #arp-scan --interface=$INTERFACE --localnet | awk '/[0-9a-f]{2}(:[0-9a-f]{2}){5}/ {print $2}' | sort | uniq
	sudo arp-scan --interface=$INTERFACE --localnet | grep -oE "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | sort | uniq
}

# Function to log new unique MAC addresses
log_unique_macs() {
    current_macs=$(get_current_mac_addresses)

    # If the MAC log file doesn't exist, create it
    if [ ! -f "$MAC_LOG_FILE" ]; then
        touch "$MAC_LOG_FILE"
    fi

    # Loop through the current MACs and log them if they're not already in the log file
    for mac in $current_macs; do
        if ! grep -q "$mac" "$MAC_LOG_FILE"; then
            # Log the new MAC address with the date and time
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $mac" >> "$MAC_LOG_FILE"
            echo "Logged new MAC address: $mac"
        fi
    done
}

# Function to check for absences (optional, can be removed if only presence matters)
log_absences() {
    current_macs=$(get_current_mac_addresses)
    if [ -f "$MAC_LOG_FILE" ]; then
        # Loop through previously logged MACs and check if they're still present
        while read -r logged_mac; do
            # Extract the MAC address from the logged entry (assumes 'Logged at [date] MAC')
            logged_mac_address=$(echo "$logged_mac" | awk '{print $5}')
            
            if ! echo "$current_macs" | grep -q "$logged_mac_address"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - $logged_mac_address has left the network." >> "$MAC_LOG_FILE"
                echo "Device with MAC address $logged_mac_address has left the network."
            fi
        done < "$MAC_LOG_FILE"
    fi
}

# Main logic: Log new MAC addresses and check for absences
log_unique_macs
log_absences
