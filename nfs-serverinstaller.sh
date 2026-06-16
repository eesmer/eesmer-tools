#!/bin/bash
set -euo pipefail

EXPORT_DIR="/exports/nfs_dir"

if [ "$#" -lt 1 ]; then
    echo "ERROR: At least one client address must be specified"
    echo
    echo "USAGE:"
    echo "  $0 CLIENT_IP [CLIENT_IP ...]"
    echo
    echo "  $0 192.168.1.11"
    echo "  $0 192.168.1.11 192.168.1.12 192.168.1.13"
    echo
    exit 1
fi

echo "IP Addresses to Be Authorized:"
for CLIENT in "$@"; do
    echo " - $CLIENT"
done
echo

echo "[1/7] Installing NFS Packages"
apt update
apt install -y nfs-kernel-server nfs-common rpcbind

echo "[2/7] Preparing Export Directory: $EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

chown nobody:nogroup "$EXPORT_DIR"
chmod 0777 "$EXPORT_DIR"

echo "[3/7] Backing up /etc/exports"
cp -a /etc/exports "/etc/exports.bak.$(date +%Y%m%d-%H%M%S)"

echo "[4/7] Duplicate lines are being deleted"
sed -i "\|^$EXPORT_DIR|d" /etc/exports

echo "[5/7] Export definitions are being created"
for CLIENT in "$@"; do
    echo "$EXPORT_DIR $CLIENT(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
done

echo "[6/7] NFS services are being enabled"
systemctl enable --now rpcbind
systemctl enable --now nfs-server

echo "[7/7] Export settings are being applied"
exportfs -ra

echo
echo "Active NFS Export List:"
exportfs -v

echo
echo "NFS setup is complete"
echo "Export dizini: $EXPORT_DIR"
echo

