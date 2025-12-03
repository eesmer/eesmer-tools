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

