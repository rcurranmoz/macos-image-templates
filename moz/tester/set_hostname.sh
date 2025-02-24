#!/bin/bash
# This script sets the hostname based on the Mac's serial number

SERIAL_NUMBER=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $NF}')
HOSTNAME="mac-${SERIAL_NUMBER}"

echo "Setting system hostname to $HOSTNAME"

# Apply hostname settings
scutil --set ComputerName "$HOSTNAME"
scutil --set LocalHostName "$HOSTNAME"
scutil --set HostName "$HOSTNAME"

# Confirm the change
echo "New Hostname: $(scutil --get HostName)"