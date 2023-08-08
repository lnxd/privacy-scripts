#!/bin/bash
# This script automates some of the privacy changes I usually make on fresh Debian installs when I'm working under an NDA

# Update & upgrade packages to avoid repetition
sudo apt-get update
sudo apt-get upgrade -y

# Ensure popularity-contest (package survey) not in use
echo "- Disabling package survey"
sudo apt-get remove -y popularity-contest
echo "- Finished disabling package survey"

# Install & enable UFW
echo "- Setting up ufw"
sudo apt-get install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw --force enable
echo "- Finished setting up ufw"

# Set Cloudflare as default DNS provider on all interfaces
echo "- Setting DNS provider to Cloudflare on all interfaces"
interfaces=$(ls /sys/class/net)
for iface in $interfaces; do
  if [[ "$iface" != "lo" ]]; then
    echo "Setting DNS servers for $iface..."
    sudo resolvectl dns "$iface" 1.1.1.1 1.0.0.1
  fi
done
echo "- Done setting DNS provider to Cloudflare on all interfaces"
