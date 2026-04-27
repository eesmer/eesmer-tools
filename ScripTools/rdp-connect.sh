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
# --------------------------------------------------------------------------------------------------------------
# +auto-reconnect               (If the connection is lost, it will attempt to reconnect automatically)
# /auto-reconnect-max-retries:5 (Limits the number of automatic reconnection attempts to 5)
# /network:auto                 (It automatically optimizes performance settings by detecting network speed and quality)
# /log-level:WARN               (Displays only warning and error-level logs)
# /w:1620 /h:1000               (instead of /dynamic-resolution)
# /fonts                        ( Set ClearType - It is available by default in FreeRDP 3.x)
# /printer                      (Redirects the local Linux printer to the RDP session.)
