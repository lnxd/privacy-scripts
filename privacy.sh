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

echo "- Checking Apparmor status"
apparmor_status=$(cat /sys/module/apparmor/parameters/enabled)
if [ "$apparmor_status" = "Y" ]; then
    echo -e "\033[32m- Apparmor is enabled\033[0m"  # 32 for green, 0 to reset the color
else
    echo -e "\033[31m- Apparmor is disabled\033[0m"  # 31 for red, 0 to reset the color
fi

echo "- Checking if DNS provider is Cloudflare"
dns_provider=$(cat /etc/resolv.conf | grep "nameserver 1.1.1.1")
if [ -n "$dns_provider" ]; then
    echo -e "\033[32m- DNS configured correctly\033[0m"
else
    echo -e "\033[31m- DNS not configured correctly\033[0m"
fi

echo "- Checking if firewall is enabled"
ufw_status=$(sudo ufw status | grep "Status: active")
if [ -n "$ufw_status" ]; then
    echo -e "\033[32m- UFW is enabled\033[0m"
else
    echo -e "\033[31m- UFW is disabled\033[0m"
fi

echo "- Checking if package survey is disabled"
package_survey=$(dpkg -l | grep popularity-contest)
if [ -z "$package_survey" ]; then
    echo -e "\033[32m- Package survey is disabled\033[0m"
else
    echo -e "\033[31m- Package survey is enabled\033[0m"
fi

