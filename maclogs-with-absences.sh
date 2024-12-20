#!/bin/bash

# Path to store the unique MAC addresses log
MAC_LOG_FILE="/tmp/mac_addresses.log"
# Path to temporarily store the current list of MAC addresses
CURRENT_MACS_FILE="/tmp/current_macs.txt"
# Path to temporarily store the last seen list of MAC addresses
LAST_SEEN_MACS_FILE="/tmp/last_seen_macs.txt"

# Network interface to scan (change to your network interface, e.g., eth0, wlan0)
INTERFACE="eth0"  # Change this to your local network interface (e.g., eth0, wlan0)

# Function to get the current MAC addresses from the network
get_current_mac_addresses() {
    # Use arp-scan to scan the local network for devices
    # Use grep to capture only the MAC addresses
    sudo arp-scan --interface=$INTERFACE --localnet | \
        grep -oE "([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}" | sort | uniq
}

# Function to log new unique MAC addresses (Presence)
log_presence() {
    current_macs=$(get_current_mac_addresses)

    # If the MAC log file doesn't exist, create it
    if [ ! -f "$MAC_LOG_FILE" ]; then
        touch "$MAC_LOG_FILE"
    fi

    # Loop through the current MACs and log them if they're not already in the log file
    for mac in $current_macs; do
        if ! grep -q "$mac" "$MAC_LOG_FILE"; then
            # Log the new MAC address with the date and time
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $mac - Presence" >> "$MAC_LOG_FILE"
            echo "Logged new MAC address (Presence): $mac"
        fi
    done
}

# Function to log absences of MAC addresses
log_absence() {
    current_macs=$(get_current_mac_addresses)

    # If the last seen MACs file doesn't exist, create it
    if [ ! -f "$LAST_SEEN_MACS_FILE" ]; then
        touch "$LAST_SEEN_MACS_FILE"
    fi

    # Read the last seen MAC addresses
    last_seen_macs=$(cat "$LAST_SEEN_MACS_FILE")

    # Loop through the previously seen MACs and check if they are still present
    for logged_mac in $last_seen_macs; do
        if ! echo "$current_macs" | grep -q "$logged_mac"; then
            # Log the MAC address as absent
            echo "$(date '+%Y-%m-%d %H:%M:%S') - $logged_mac - Absence" >> "$MAC_LOG_FILE"
            echo "Logged MAC address (Absence): $logged_mac"
        fi
    done

    # Update the last seen MACs file with the current list
    echo "$current_macs" > "$LAST_SEEN_MACS_FILE"
}

# Main loop: Log new MAC addresses (Presence) and check for absences every minute
while true; do
    log_presence
    log_absence
    echo "Waiting 60 seconds before the next scan..."
    sleep 60  # Sleep for 60 seconds (1 minute)
done
