#!/bin/bash

# Handle signal ignoring
trap '' TERM HUP INT

# Function to log changes
log_change() {
    logger "$1"
}

# Function to apply hostname changes
apply_hostname() {
    local desired_name=$1
    local current_name=$(hostname)
    if [ "$current_name" != "$desired_name" ]; then
        echo "$desired_name" > /etc/hostname
        hostnamectl set-hostname "$desired_name"
        sed -i "s/$current_name/$desired_name/g" /etc/hosts
        log_change "Hostname changed from $current_name to $desired_name"
        [ "$verbose" = true ] && echo "Hostname changed from $current_name to $desired_name"
    else
        [ "$verbose" = true ] && echo "Hostname is already $desired_name"
    fi
}

# Function to apply IP changes
apply_ip() {
    local desired_ip=$1
    local interface=$(ip -o -4 route show to default | awk '{print $5}')
    local current_ip=$(ip -o -4 addr show dev $interface | awk '{print $4}' | cut -d/ -f1)

    if [ "$current_ip" != "$desired_ip" ]; then
        local netplan_file=$(ls /etc/netplan/*.yaml)
        sed -i "s/$current_ip/$desired_ip/g" $netplan_file
        netplan apply
        log_change "IP address changed from $current_ip to $desired_ip"
        [ "$verbose" = true ] && echo "IP address changed from $current_ip to $desired_ip"
    else
        [ "$verbose" = true ] && echo "IP address is already $desired_ip"
    fi
}

# Function to update /etc/hosts
update_hosts() {
    local desired_name=$1
    local desired_ip=$2

    if ! grep -q "$desired_name" /etc/hosts; then
        echo "$desired_ip $desired_name" >> /etc/hosts
        log_change "/etc/hosts updated with $desired_ip $desired_name"
        [ "$verbose" = true ] && echo "/etc/hosts updated with $desired_ip $desired_name"
    else
        [ "$verbose" = true ] && echo "/etc/hosts already contains $desired_ip $desired_name"
    fi
}

# Parse command line arguments
verbose=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) verbose=true ;;
        -name) shift; apply_hostname "$1" ;;
        -ip) shift; apply_ip "$1" ;;
        -hostentry) shift; update_hosts "$1" "$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
