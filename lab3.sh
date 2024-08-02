#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

server1_ip="192.168.16.3"
server2_ip="192.168.16.4"

# Check if verbose flag is set
verbose=0
if [ "$1" == "-verbose" ]; then
    verbose=1
    shift
fi

# Define the verbose option for remote scripts
verbose_option=""
if [ "$verbose" -eq 1 ]; then
    verbose_option="-verbose"
fi

# Copy and run configure-host.sh on server1
scp configure-host.sh remoteadmin@$server1_ip:/home/remoteadmin
ssh remoteadmin@$server1_ip "sudo /home/remoteadmin/configure-host.sh -name loghost -ip $server1_ip -hostentry webhost $server2_ip $verbose_option"

# Copy and run configure-host.sh on server2
scp configure-host.sh remoteadmin@$server2_ip:/home/remoteadmin
ssh remoteadmin@$server2_ip "sudo /home/remoteadmin/configure-host.sh -name webhost -ip $server2_ip -hostentry loghost $server1_ip $verbose_option"

# Update local /etc/hosts file
sudo ./configure-host.sh -hostentry loghost $server1_ip $verbose_option
sudo ./configure-host.sh -hostentry webhost $server2_ip $verbose_option
