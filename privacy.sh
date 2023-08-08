#!/bin/bash
# This script automates some of the privacy changes I usually make on fresh Debian installs when I'm working under an NDA

# Display script info
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

# Check if script is being run on Debian
if [ ! -f /etc/debian_version ]; then
    echo -e "\nError: This script is only supported on Debian\n"
    exit 1
fi

# Confirm user has reviewed the script
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

# Function to calculate padding
calculate_padding() {
    local message_length=$1
    local max_length=$2
    local padding=$((max_length - message_length))
    printf "%${padding}s"
}

# Print status of each check
print_status() {
    local status=$1
    local message=$2

    local max_length=15  # Adjust this value as needed for the maximum message length
    local status_padding=$(calculate_padding ${#status} $max_length)
    local message_padding=$(calculate_padding ${#message} $max_length)

    if [ "$status" = "Passed" ]; then
        echo -e "${message}:${message_padding}\033[32m${status}${status_padding}\033[0m"
    elif [ "$status" = "Failed" ]; then
        echo -e "${message}:${message_padding}\033[31m${status}${status_padding}\033[0m"
    else
        echo "${message}:${message_padding}${status}"
    fi
}

# Check Apparmor status
apparmor_status=$(cat /sys/module/apparmor/parameters/enabled)
if [ "$apparmor_status" = "Y" ]; then
    print_status "Passed" "Apparmor"
else
    print_status "Failed" "Apparmor"
fi

# Check DNS provider
dns_provider=$(cat /etc/resolv.conf | grep "nameserver 1.1.1.1")
if [ -n "$dns_provider" ]; then
    print_status "Passed" "DNS"
else
    print_status "Failed" "DNS"
fi

# Check UFW status
ufw_status=$(sudo ufw status | grep "Status: active")
if [ -n "$ufw_status" ]; then
    print_status "Passed" "Firewall"
else
    print_status "Failed" "Firewall"
fi

# Check package survey
package_survey=$(dpkg -l | grep popularity-contest)
if [ -z "$package_survey" ]; then
    print_status "Passed" "Telemetrics"
else
    print_status "Failed" "Telemetrics"
fi
