#!/bin/bash

#------------------------------------------------------------------------------------------
# The host machine must be Debian. Tested with Debian13
# --------------------------------------------
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

# Virtualization Feature Check (CPU,BIOS,KVM Module)
if egrep -q 'vmx|svm' /proc/cpuinfo; then
	if dmesg | grep -qi "kvm: disabled by bios"; then
		echo "Error: CPU Virtualization support OK - BIOS Feature Disable!!"
		exit 1
	fi
	if lsmod | grep -q kvm; then
		echo "Virtualization: Active (KVM Module Loaded)."
	else
		echo "Warning: CPU VT-x/AMD-V supported. KVM Module Not Loaded"
		echo "BIOS/UEFI virtualization status: OFF"
		exit 1
	fi
else
	echo "Error: This Host CPU virtualization (VT-x/AMD-V) not supported"
	exit 1
fi

# PACKAGES
apt-get update || { echo -e "\nError: Repository update failed. Check your internet connection or repository list."; exit 1; }
apt-get -y install qemu-kvm libvirt-daemon-system libvirt-clients qemu-utils virtinst bridge-utils netfilter-persistent cpu-checker || { echo -e "\nError: Required packages could not be installed"; exit 1; }
apt-get -y install iputils-arping
apt-get -y install net-tools
if ! arping -V 2>/dev/null | grep -qi "iputils"; then
    echo "Error: Required tools could not be installed. Check internet access" >&2
    echo -e
    exit 1
fi

systemctl enable --now libvirtd

NETWORK_BR1="/tmp/network-br1.xml"
cat << EOF > "$NETWORK_BR1"
<network>
<name>br1-net</name>
<bridge name='br1'/>
<forward mode='nat'/>
<ip address='10.1.1.1' netmask='255.255.255.0'>
<dhcp start='10.1.1.100' end='10.1.1.200'/>
</ip>
</network>
EOF

virsh net-define "$NETWORK_BR1"
virsh net-start br1-net
virsh net-autostart br1-net

if ! ip link show "$IFACE" &>/dev/null; then
    echo "Error: '$IFACE' NW Adapter Not Found!" >&2
    echo -e
    exit 1
fi

sysctl -w net.ipv4.ip_forward=1
sh -c 'echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf'

if [[ -f /sys/class/net/$IFACE/carrier ]]; then
        if ! grep -q '^1' "/sys/class/net/$IFACE/carrier"; then
                echo "Error: There is no Link on $IFACE NW Adapter!"
                echo -e
                exit 1
        fi
else
        if [[ -f "/sys/class/$IFACE/operstate" ]]; then
                LINK_STATE=$(cat "/sys/class/$IFACE/operstate")
                if [[ "$LINK_STATE" != "up" ]]; then
                        echo "Error: $IFACE NW Adapter/Interface is not up (Link Status:$LINK_STATE)"
                        echo -e
                        exit 1
                fi
        else
                echo "Error: Could not check link status for $IFACE This cause installetion issues. Check network settings"
                echo -e
                exit 1
        fi
fi

valid_ipv4() {
    local ip=$1
    local IFS=.
    local -a octets=($ip)
    [[ ${#octets[@]} -eq 4 ]] || return 1
    for o in "${octets[@]}"; do
        [[ "$o" =~ ^[0-9]+$ ]] || return 1
        (( o >= 0 && o <= 255 )) || return 1
    done
    return 0
}

if ! valid_ipv4 "$IPADDR"; then
    echo "HATA: '$IPADDR' not valid for IPv4" >&2
    echo -e
    exit 1
fi

if arping -D -I "$IFACE" -c 3 "$IPADDR" >/dev/null 2>&1; then
    echo "IP ($IPADDR) is available. Static configuration will be starting.."
else
    echo "Error: $IPADDR IP Address is already in use on the network. Specify a different ip address" >&2
    echo -e
    exit 1
fi

mkdir -p /etc/network/interfaces.d
cat > /etc/network/interfaces.d/debianhostnw <<EOF
auto $IFACE
iface $IFACE inet static
address $IPADDR
netmask $NETMASK
gateway $GATEWAY
EOF
chmod 644 /etc/network/interfaces.d/debianhostnw
sed -i "/$IFACE/d" /etc/network/interfaces

echo -e
echo "libvirt-Host (DebianHost) Installation Completed"
echo "You can access from the IP address $IPADDR"
echo "----------------------------------------------------"
echo -e

sleep 2
reboot

