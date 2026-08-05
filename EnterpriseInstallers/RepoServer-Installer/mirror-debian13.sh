#!/bin/bash
set -euo pipefail

BASE="/mnt/mirrors/pardus/"
ARCH="amd64"
SECTIONS="main,contrib,non-free,non-free-firmware"
SUITES="trixie,trixie-updates,trixie-backports"

debmirror "$BASE" \
  --host=deb.debian.org \
  --root=debian \
  --method=http \
  --dist="$SUITES" \
  --section="$SECTIONS" \
  --arch="$ARCH" \
  --nosource \
  --progress \
  --ignore-release-gpg

debmirror "$BASE-security" \
  --host=security.debian.org \
  --root=debian-security \
  --method=http \
  --dist=trixie-security \
  --section="$SECTIONS" \
  --arch="$ARCH" \
  --nosource \
  --progress \
  --ignore-release-gpg
