#!/bin/bash

#------------------------------------------------------------------------------------------
# Parameters that must be met for it to work:
# $1 = Ethernet Card (example: eth0, enp0s3)
# $2 = IP Address (example: 192.168.1.15)
# $3 = Netmask (example: 255.255.255.0)
# $4 = Gateway (example: 192.168.1.1)
# $5 = Hostname (example: host1)
#------------------------------------------------------------------------------------------
# Usage: bash debianhost_installer.sh enp0s3 192.168.1.15 255.255.255.0 192.168.1.1 host1
#------------------------------------------------------------------------------------------

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
        echo "The script must be run as root user" >&2
        echo -e
        exit 1
fi

if [[ $# -ne 5 ]]; then
    echo "Error: The required parameters for the script to run are missing" >&2
    echo "Usage: $0 <ethernet_card> <ip_address> <netmask> <gateway> <hostname>" >&2
    echo -e
    exit 1
fi

IFACE="$1"
IPADDR="$2"
NETMASK="$3"
GATEWAY="$4"
HOSTNAME="$5"

if [[ -z "$IFACE" || -z "$IPADDR" || -z "$NETMASK" || -z "$GATEWAY" || -z "$HOSTNAME" ]]; then
    echo "Error: Parameters cannot be empty" >&2
    echo "Usage: $0 <ethernet_card> <ip_address> <hostname>" >&2
    echo -e
    exit 1
fi

echo -e
echo "Parameters to be used in the libvirt-host-install (DebianHost Installation)"
echo "----------------------------------------------------"
echo "NW Adapter/Interface: $IFACE"
echo "IP Address          : $IPADDR"
echo "Netmask             : $NETMASK"
echo "Gateway             : $GATEWAY"
echo "Hostname            : $HOSTNAME"
echo "----------------------------------------------------"
echo -e

# PACKAGES
apt-get -y install iputils-arping
apt-get -y install net-tools
if ! arping -V 2>/dev/null | grep -qi "iputils"; then
    echo "Error: Required tools could not be installed. Check internet access" >&2
    echo -e
    exit 1
fi

