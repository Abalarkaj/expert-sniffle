#!/bin/bash

# macos-run.sh MAC_USER_PASSWORD VNC_PASSWORD ZEROTIER_NETWORK_ID MAC_REALNAME

# Disable spotlight indexing
sudo mdutil -i off -a

# Create new account
sudo dscl . -create /Users/koolisw
sudo dscl . -create /Users/koolisw UserShell /bin/bash
sudo dscl . -create /Users/koolisw RealName "$4"
sudo dscl . -create /Users/koolisw UniqueID 1001
sudo dscl . -create /Users/koolisw PrimaryGroupID 80
sudo dscl . -create /Users/koolisw NFSHomeDirectory /Users/koolisw
sudo dscl . -passwd /Users/koolisw "$1"
sudo createhomedir -c -u koolisw > /dev/null
sudo dscl . -append /Groups/admin GroupMembership koolisw

# Enable VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 

# Configure VNC password (encrypted)
echo "$2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Start VNC/reset changes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Install ZeroTier (if not installed)
if ! command -v zerotier-cli &> /dev/null
then
    echo "ZeroTier not found, installing..."
    brew install zerotier-one
else
    echo "ZeroTier is already installed."
fi

# Join ZeroTier network
sudo zerotier-cli join "$3"
sleep 10  # Give it a little time to join the network

# Get ZeroTier IP address (assumes 10.x.x.x range)
ZERO_TIER_IP=$(sudo zerotier-cli listnetworks | grep "10." | awk '{print $3}')
if [ -z "$ZERO_TIER_IP" ]; then
  echo "ZeroTier IP address not found, retrying..."
  sleep 10
  ZERO_TIER_IP=$(sudo zerotier-cli listnetworks | grep "10." | awk '{print $3}')
fi

if [ -z "$ZERO_TIER_IP" ]; then
  echo "Failed to get ZeroTier IP address, exiting..."
  exit 1
else
  echo "ZeroTier IP address is: $ZERO_TIER_IP"
fi

# Output the ZeroTier IP for VNC
echo "Use the following IP for VNC access: $ZERO_TIER_IP"

# Keep the system alive (if needed for long tasks, e.g., debugging)
while true; do sleep 1d; done
