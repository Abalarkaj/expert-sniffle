#!/bin/bash

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
sudo dscl . -passwd /Users/koolisw "$1"
sudo createhomedir -c -u koolisw > /dev/null
sudo dscl . -append /Groups/admin GroupMembership koolisw

# Enable VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes

# Set VNC password (optional customization)
echo "$2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Start/reset VNC server
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Install ZeroTier (if not installed already)
if ! command -v zerotier-cli &> /dev/null
then
    echo "ZeroTier not found. Installing..."
    brew install zerotier-one
fi

# Join ZeroTier network
echo "Joining ZeroTier network..."
zerotier-cli join "$3"

# Wait for ZeroTier to connect and get an IP address
echo "Waiting for ZeroTier to establish a connection..."
for i in {1..10}
do
    ZT_IP=$(zerotier-cli listnetworks | grep -oP "(?<=\s)(\d+\.\d+\.\d+\.\d+)(?=\s)" | head -n 1)
    if [[ -n "$ZT_IP" ]]; then
        echo "ZeroTier IP address is: $ZT_IP"
        break
    else
        echo "ZeroTier IP address not found, retrying... ($i/10)"
        sleep 10
    fi
done

if [[ -z "$ZT_IP" ]]; then
    echo "Failed to get ZeroTier IP address, exiting..."
    exit 1
fi

# Proceed with further setup (if any)
echo "ZeroTier setup complete, IP: $ZT_IP"

# You can continue with other steps here...
