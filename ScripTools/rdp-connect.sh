#!/bin/bash

# ----------------------------------------
# Name   : rdp-connect.sh
# Usage  : bash rdp-connect.sh 192.168.2.11 administrator testdomain
# Extra  : man xfreerdp
# Package: xfreerdp - apt -y install xfreerdp
# ----------------------------------------

SERVER="$1"
USERNAME="$2"
DOMAIN="$3"

xfreerdp /v:$SERVER /u:$USERNAME /d:$DOMAIN \
	 /dynamic-resolution \
         +clipboard \
         /cert:tofu

# extras:
# ----------------------------------------
# +auto-reconnect
# /auto-reconnect-max-retries:5
# /network:auto
# /log-level:WARN
# /w:1620 /h:1000 (instead of /dynamic-resolution)
# /fonts (It is available by default in FreeRDP 3.x)
