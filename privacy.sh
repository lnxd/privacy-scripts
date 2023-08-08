#!/bin/bash
# This script automates some of the privacy changes I usually make on fresh Debian installs when I'm working under an NDA

echo "This script will make the following changes to your system:"
echo "- Update & upgrade packages"
echo "- Disable package survey"
echo "- Enable UFW"
echo "- Set Cloudflare as default DNS provider on all interfaces"
echo "- Enable Apparmor"
# Check if script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\nError: This script must be run as root\n"
    exit 1
fi
echo -e "\nPlease visit this link and review the script before continuing: https://raw.githubusercontent.com/lnxd/debian-privacy-automations/main/privacy.sh"
echo "Enter 'y' to continue or 'n' to exit"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "- Continuing..."
else
    echo "- Exiting..."
    exit 1
fi

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

echo -e "\nPrivacy check complete. Results below:"

apparmor_status=$(cat /sys/module/apparmor/parameters/enabled)
if [ "$apparmor_status" = "Y" ]; then
    echo -e "\033[32m- Apparmor is enabled\033[0m"
else
    echo -e "\033[31m- Apparmor is disabled\033[0m"
fi

dns_provider=$(cat /etc/resolv.conf | grep "nameserver 1.1.1.1")
if [ -n "$dns_provider" ]; then
    echo -e "\033[32m- DNS configured correctly\033[0m"
else
    echo -e "\033[31m- DNS not configured correctly\033[0m"
fi

ufw_status=$(sudo ufw status | grep "Status: active")
if [ -n "$ufw_status" ]; then
    echo -e "\033[32m- UFW is enabled\033[0m"
else
    echo -e "\033[31m- UFW is disabled\033[0m"
fi

package_survey=$(dpkg -l | grep popularity-contest)
if [ -z "$package_survey" ]; then
    echo -e "\033[32m- Package survey is disabled\033[0m"
else
    echo -e "\033[31m- Package survey is enabled\033[0m"
fi

