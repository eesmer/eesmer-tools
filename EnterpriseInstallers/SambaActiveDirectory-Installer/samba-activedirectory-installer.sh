#!/bin/bash

#-------------------------------------------------------------------
# Samba Active Directory Installer
# This script has been tested in Debian environment.
# It is compatible with Debian.
# - It installs the Samba package and its requirements
# - It installs and configures bind9 for DNS
# - It installs and configures the chrony service for the NTP service
# Then, it performs the Domain Name Provisioning process according to the information it receives and configures the smb.conf file.
# The machine on which it is run takes the PDC role and starts working as a DC for the established domain.
# ------------------------------------------------------------------
# It should be run in a Debian 13(trixie) environment.
# You might also be able to use it on a distribution derived from Debian 13, but this has not been tested.
# ------------------------------------------------------------------
# USAGE:
# wget https://raw.githubusercontent.com/eesmer/MyNotes/refs/heads/main/HelperScripts/SambaAD/samba-activedirectory-installer.sh
# bash samba-activedirectory-installer.sh
#-------------------------------------------------------------------

# Color Codes
MAGENTA="tput setaf 1"
GREEN="tput setaf 2"
YELLOW="tput setaf 3"
DGREEN="tput setaf 4"
CYAN="tput setaf 6"
WHITE="tput setaf 7"
GRAY="tput setaf 8"
RED="tput setaf 9"
BLUE="tput setaf 12"
NOCOL="tput sgr0"
BOLD="tput bold"

whiptail --msgbox \
        ".:: Samba Active Directory Domain Controller Installer ::. \
        \n---------------------------------------------------------------- \
        \nThis program is distributed for the purpose of being useful. \
        \nThis program installs Samba Active Directory. \
        \nIt will ask you questions about the domain and it will install and will install it according to the information it receives. \
        \n\nWhen the installation is completed;\na Domain is created and this machine is configured as a Domain Controller. \
        \n---------------------------------------------------------------- \
        \n\nhttps://github.com/eesmer/SambaAD-HelperScripts \
        \nhttps://github.com/eesmer/sambadtui \
        \nhttps://github.com/eesmer/DebianDC" 20 90 45

UPDATE_CONTROL() {
    $GREEN
    echo "Internet and repository access is controlled"
    $NOCOL
    UPDATE_OUTPUT=$(apt update 2>&1)
    if echo "$UPDATE_OUTPUT" | grep -qE "(Failed to fetch|Temporary failure resolving|Could not resolve|Some index files failed to download)"; then
        $RED
        echo "Some errors occurred during apt update. Please check internet or repository access."
        echo "$UPDATE_OUTPUT" #> $LOGFILE
        $NOCOL
        exit 1
    fi
}

CHECKRUN_ROOT() {
if ! [[ $EUID -eq 0 ]]; then
	$RED
	echo "This script must be run with root user"
	$NOCOL
	exit 1
fi
}

CHECK_DISTRO() {
cat /etc/*-release /etc/issue > "/tmp/distrocheck"
grep "debian" "/tmp/distrocheck" >/dev/null
if [[ $? = 0 ]]; then
	DIST=DEB
fi
rm /tmp/distrocheck
# Not support message
if [[ $DIST = DEB ]]; then
	VER=$(cat /etc/debian_version | cut -d "." -f1)
	if [[ $VER -lt 13 ]]; then
		$RED
		echo -e
		echo "-------------------------------------------------------------------------------------"
		echo -e "This script has been tested with Debian 13 \nIt is recommended to use it with Debian 13"
		echo "-------------------------------------------------------------------------------------"
		echo -e
		$NOCOL
		exit 1
	fi
else
	$RED
	echo -e
	echo "-------------------------------------------------------------------------------------"
	echo -e "This script has been tested in Debian environment.\nIt is compatible with Debian 13."
	echo -e "You might also be able to use it on a distribution derived from Debian 13, but this has not been tested."
	echo "-------------------------------------------------------------------------------------"
	$NOCOL
fi
}

SAMBAAD_INSTALL() {
	HNAME=$(whiptail --inputbox "Enter DC Machine Hostname (e.g.,DC01)" 10 50 --title "DC Hostname" --backtitle "DC Hostname" 3>&1 1>&2 2>&3)
        ANSWER=$?
        if [ ! $ANSWER = 0 ]; then
                echo "User canceled"
		exit 1
        fi
	REALM=$(whiptail --inputbox "Enter Domain Name (e.g., EXAMPLE.LOC)" 10 50 --title "DomainName" --backtitle "Domain Name" 3>&1 1>&2 2>&3)
	ANSWER=$?
	if [ ! $ANSWER = 0 ]; then
		echo "User canceled"
		exit 1
	fi
        PASSWORD=$(whiptail --passwordbox "Enter Administrator Password" 10 50 --title "Administrator Password" --backtitle "Administrator Password" 3>&1 1>&2 2>&3)
	ANSWER=$?
	if [ ! $ANSWER = 0 ]; then
		echo "User canceled"
		exit 1
	fi
	if [ -z "$HNAME" ] || [ -z "$REALM" ] || [ -z "$PASSWORD" ]; then
		whiptail --msgbox "Please fill in all fields.." --title "SambaAD Install" --backtitle "Samba Active Directory Installation" 0 0 0
		SAMBAAD_INSTALL
	fi

	whiptail --yesno "Domain Name: $REALM\n Start Installation?" 0 0 0
	ANSWER=$?
	if [ ! $ANSWER = 0 ]; then
		echo "User canceled"
		exit 1
	fi

	SERVER_IP=$(ip r | grep link | grep src | cut -d '/' -f2 | cut -d'c' -f3 | cut -d ' ' -f2)
	DOMAIN=$(echo $REALM | cut -d "." -f1)
	#sed -i "/127.0.1.1/ c 127.0.1.1 $HOSTNAME.$REALM $HOSTNAME" /etc/hosts
	sed -i "/127.0.1.1/ c 127.0.1.1 $HNAME.$REALM $HNAME $REALM" /etc/hosts
	hostnamectl set-hostname $HNAME.$REALM
	
	apt-get update || exit 1
	DEBIAN_FRONTEND=noninteractive \
		apt-get install -y --no-install-recommends \
		samba-ad-dc samba-ad-provision samba-common-bin winbind krb5-user bind9 bind9-utils bind9-dnsutils \
		chrony smbclient \
		ldb-tools tdb-tools \
		acl attr rsync openssh-server \
		|| exit 1

	#export DEBIAN_FRONTEND=noninteractive
	#apt-get -y update && apt-get -y upgrade && apt-get -y autoremove
	#apt-get -y install bind9 bind9utils dnsutils
	#apt-get -y install samba --install-recommends
	#apt-get -y install winbind
	#apt-get -y install krb5-config krb5-user
	
	systemctl stop smbd nmbd winbind
	systemctl disable smbd nmbd winbind
	systemctl mask smbd nmbd winbind

	#apt-get -y install chrony ntpdate
	#apt-get -y install dnsutils net-tools
	#apt-get -y install openssh-server 
	#apt-get -y install ack expect krb5-user krb5-config
	#apt-get -y install curl wget
	
	#Domain Provision
	rm /etc/samba/smb.conf
	samba-tool domain provision --server-role=dc --use-rfc2307 --realm="$REALM" --domain="$DOMAIN" --adminpass="$PASSWORD"
	
	##Log Config
	#sed -i '/server services =/a log level = 4' /etc/samba/smb.conf
	#sed -i '/log level =/a log file = /var/log/samba/$REALM.log' /etc/samba/smb.conf
	#sed -i '/log file =/a debug timestamp = yes' /etc/samba/smb.conf
	
	#Time/Sync Config
	ntpdate -bu pool.ntp.org
	echo "allow 0.0.0.0/0" >> /etc/chrony/chrony.conf
	echo "ntpsigndsocket  /var/lib/samba/ntp_signd" >> /etc/chrony/chrony.conf
	chown root:_chrony /var/lib/samba/ntp_signd/
	chmod 750 /var/lib/samba/ntp_signd/
	systemctl restart chrony
	systemctl enable chrony
	#sed -i "s/\$IP/$SERVER_IP/" /var/lib/samba/private/dns_update_list
	
	rm /etc/krb5.conf
	cp /var/lib/samba/private/krb5.conf /etc/
	echo "search $REALM" > /etc/resolv.conf
	echo "nameserver 127.0.0.1" >> /etc/resolv.conf



# DC IP and SUBNET
# Varsayılan çıkış yolunda kullanılan kaynak IPv4 adresi.
# Bu komut hedefe paket göndermez; yerel routing tablosunu sorgular.
DC_IP=$(
    ip -4 route get 1.1.1.1 |
        awk '{
            for (i = 1; i <= NF; i++)
                if ($i == "src") {
                    print $(i + 1)
                    exit
                }
        }'
)
if [[ -z "$DC_IP" ]]; then
    echo "[HATA] DC IPv4 adresi belirlenemedi." >&2
    exit 1
fi
# Seçilen adresin prefix bilgisini al: ör. 10.12.12.14/24
DC_CIDR=$(
    ip -o -4 address show scope global |
        awk -v ip="$DC_IP" '{
            split($4, addr, "/")
            if (addr[1] == ip) {
                print $4
                exit
            }
        }'
)
if [[ -z "$DC_CIDR" ]]; then
    echo "[HATA] DC adresinin prefix bilgisi bulunamadı." >&2
    exit 1
fi
# Prefix'i gerçek ağ adresine dönüştür.
# /24 dışında /23, /22 vb. ağlarda da doğru hesaplar.
if ! CLIENT_NETWORK=$(
    python3 - "$DC_CIDR" <<'PY'
import ipaddress
import sys
print(ipaddress.IPv4Interface(sys.argv[1]).network)
PY
); then
    echo "[HATA] Ağ adresi hesaplanamadı." >&2
    exit 1
fi
printf 'DC IP adresi : %s\n' "$DC_IP"
printf 'İstemci ağı  : %s\n' "$CLIENT_NETWORK"

# named.conf.options
cat > /etc/bind/named.conf.options << EOF
acl "ad_clients" {
127.0.0.1;
$CLIENT_NETWORK;
};
options {
directory "/var/cache/bind";
recursion yes;
allow-query { ad_clients; };
allow-recursion { ad_clients; };
allow-query-cache { ad_clients; };
allow-transfer { none; };
listen-on {
127.0.0.1;
$DC_IP;
};
listen-on-v6 { none; };
forwarders {
8.8.8.8;
8.8.4.4;
};
forward only;
dnssec-validation auto;
tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";
};
EOF

# named.conf.local
#cat > /etc/bind/named.conf.local << EOF
#dlz "$REALM" {
#    database "dlopen /usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9_18.so";
#};
#EOF
#echo 'include "/var/lib/samba/bind-dns/named.conf";' >> /etc/bind/named.conf.local

# named.conf.local
DLZ_INCLUDE='include "/var/lib/samba/bind-dns/named.conf";'
if ! grep -Fqx "$DLZ_INCLUDE" /etc/bind/named.conf.local; then
	printf '\n%s\n' "$DLZ_INCLUDE" >> /etc/bind/named.conf.local
fi

cat > /etc/default/named << EOF
RESOLVCONF=no
OPTIONS="-4 -u bind"
EOF
chmod 644 /etc/default/named

sed -i 's/dns forwarder = .*/server services = -dns/' /etc/samba/smb.conf
mkdir -p /var/lib/samba/bind-dns
mkdir -p /var/lib/samba/bind-dns/dns

##Log Config
sed -i "/server services =/a log level = 2" /etc/samba/smb.conf
sed -i "/log level =/a log file = /var/log/samba/$REALM.log" /etc/samba/smb.conf
sed -i "/log file =/a debug timestamp = yes" /etc/samba/smb.conf

samba_upgradedns --dns-backend=BIND9_DLZ

if named-checkconf; then
    systemctl restart named
else
    echo "ERROR: BIND configuration is invalid; Service could not be restarted" >&2
    exit 1
fi

systemctl unmask samba-ad-dc.service
systemctl enable samba-ad-dc.service
systemctl restart samba-ad-dc
systemctl restart bind9
}

CHECKRUN_ROOT
CHECK_DISTRO
UPDATE_CONTROL
SAMBAAD_INSTALL
