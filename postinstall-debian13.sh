#!/bin/bash

#-------------------------------------------------------------------------
# Debian 13 PostInstall
# Debian13-postinstall.sh
# This script customizes my Debian installation for personal use.
# It includes the tools and configurations I use.
# Prepared for Debian 13 / Tested with Debian 13
#-------------------------------------------------------------------------

set -euo pipefail
set -o errtrace
trap 'ec=$?; echo "[!] Error ($ec): ${BASH_SOURCE[0]}:${BASH_LINENO[0]}: $(printf "%q" "$BASH_COMMAND")" >&2' ERR

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------
# Install Config
# --------------------------------------------
HOSTNAME="erkdebian"
TIMEZONE="Europe/Istanbul"
MYUSER="erkan"
# --------------------------------------------

# === HOSTNAME and TIMEDATE Settings ===
hostnamectl set-hostname "$HOSTNAME"
timedatectl set-timezone "$TIMEZONE"
timedatectl set-ntp true

# === MYUSER Settings ===
usermod -aG sudo "$MYUSER"

# === APT REPO / CUSTOM REPO ===
rm -f /etc/apt/sources.list
cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://ftp2.de.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
Enabled: yes

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
Enabled: yes

Types: deb
URIs: http://ftp2.de.debian.org/debian/
Suites: trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
Enabled: yes
EOF
chmod 644 /etc/apt/sources.list.d/debian.sources
apt-get update

# === TIME/SYNC ===
mkdir -p /etc/systemd/timesyncd.conf.d
tee /etc/systemd/timesyncd.conf.d/timesync_custom.conf > /dev/null <<'EOF'
[Time]
NTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org
FallbackNTP=2.debian.pool.ntp.org 3.debian.pool.ntp.org
EOF
systemctl restart systemd-timesyncd

apt-get install -y locales
sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^# *\(tr_TR.UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8 LC_TIME=tr_TR.UTF-8

# === PACKAGES ===
grep -qi 'GenuineIntel' /proc/cpuinfo && apt-get -y install intel-microcode || grep -qi 'AuthenticAMD' /proc/cpuinfo && apt-get -y install amd64-microcode || true
apt-get -y install isenkram-cli && isenkram-autoinstall-firmware || true
apt-get -y install xserver-xorg xserver-xorg-input-libinput xauth
apt-get -y install i3 i3status xtrlock suckless-tools
apt-get -y install xterm xinit lxpolkit x11-xserver-utils
apt-get -y install vim tmux htop openssh-server sudo xfce4-terminal whiptail fzf net-tools dnsutils
apt-get -y install feathernotes atril pavucontrol unzip freerdp3-x11 vlc feh xdg-utils desktop-file-utils
apt-get -y install ripgrep ack wget curl rsync traceroute nmap lsof
apt-get -y install mtr-tiny tcpdump iperf3 ncdu pv jq ca-certificates gpg pinentry-curses git git-delta
apt-get -y install thunar thunar-volman tumbler ffmpegthumbnailer gvfs-backends gvfs-fuse udisks2
apt-get -y install firefox-esr chromium
apt-get -y install vim-airline vim-airline-themes fonts-powerline
apt-get -y install network-manager network-manager-gnome wireless-regdb iw rfkill

apt-get update && apt-get -y full-upgrade && apt-get -y autoremove --purge && apt-get -y autoclean

if update-alternatives --list x-terminal-emulator >/dev/null 2>&1; then
  update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper 2>/dev/null || \
  update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal 2>/dev/null || true
fi

# === MIME Defaults for $MYUSER(erkan) ===
mkdir -p "/home/$MYUSER/.config"
chmod 0700 "/home/$MYUSER/.config"
chown $MYUSER:$MYUSER "/home/$MYUSER/.config"
mkdir -p "/home/$MYUSER/.local/share/applications"
chmod 0700 "/home/$MYUSER/.config"
chmod 0700 "/home/$MYUSER/.local" "/home/$MYUSER/.local/share" "/home/$MYUSER/.local/share/applications"
chown -R "$MYUSER:$MYUSER" "/home/$MYUSER/.config" "/home/$MYUSER/.local"

cat >"/home/$MYUSER/.config/mimeapps.list" <<'EOF'
[Default Applications]
image/jpeg=feh.desktop
image/png=feh.desktop
image/gif=feh.desktop
image/webp=feh.desktop
image/bmp=feh.desktop
image/tiff=feh.desktop
video/mp4=vlc.desktop
video/x-matroska=vlc.desktop
video/x-msvideo=vlc.desktop
video/webm=vlc.desktop
video/x-ms-wmv=vlc.desktop
video/mpeg=vlc.desktop
application/pdf=atril.desktop
inode/directory=Thunar.desktop
EOF
chmod 0644 "/home/$MYUSER/.config/mimeapps.list"

# === DAILY SCRIPTS ===
TMPDIR="$(mktemp -d daily-scripts.tmp.XXX)"
wget -r -np -nH --cut-dirs=2 -R "index.html*" -N -P /tmp/$TMPDIR https://esmerkan.com/fileserver/daily-scripts/
mv $TMPDIR/ /home/$MYUSER/daily-scripts
find "/home/$MYUSER" -type d -exec chmod 755 {} \;
find "/home/$MYUSER" -type f -exec chmod 644 {} \;
