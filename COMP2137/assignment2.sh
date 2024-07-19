#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Updating package lists
echo "Updating package lists..."
apt-get update -y

# Installing necessary software
echo "Installing apache2..."
apt-get install -y apache2

echo "Installing squid..."
apt-get install -y squid

# Configure the network interface
echo "Configuring network interface..."
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses:
        - 192.168.16.21/24
EOF

netplan apply

# Update /etc/hosts
echo "Updating /etc/hosts..."
sed -i '/server1/d' /etc/hosts
echo "192.168.16.21 server1" >> /etc/hosts

# Configure UFW firewall
echo "Configuring UFW firewall..."
ufw allow from 192.168.16.0/24 to any port 22
ufw allow 80
ufw allow 3128
ufw --force enable

# Create user accounts and set up SSH keys
create_user() {
    local username=$1
    local ssh_key=$2

    if ! id "$username" &>/dev/null; then
        echo "Creating user $username..."
        useradd -m -s /bin/bash "$username"
    fi

    mkdir -p /home/"$username"/.ssh
    touch /home/"$username"/.ssh/authorized_keys
    chown -R "$username":"$username" /home/"$username"/.ssh
    chmod 700 /home/"$username"/.ssh
    chmod 600 /home/"$username"/.ssh/authorized_keys

    if [ -n "$ssh_key" ]; then
        echo "Adding SSH key for $username..."
        echo "$ssh_key" >> /home/"$username"/.ssh/authorized_keys
    fi
}

# Define users and their SSH keys
declare -A users
users=(
    ["dennis"]="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
    ["aubrey"]=""
    ["captain"]=""
    ["snibbles"]=""
    ["brownie"]=""
    ["scooter"]=""
    ["sandy"]=""
    ["perrier"]=""
    ["cindy"]=""
    ["tiger"]=""
    ["yoda"]=""
)

# Create the users
for user in "${!users[@]}"; do
    create_user "$user" "${users[$user]}"
done

# Add 'dennis' to sudo group
echo "Adding user dennis to sudo group..."
usermod -aG sudo dennis

echo "Assignment 2 configuration complete."
