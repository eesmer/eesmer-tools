#!/bin/bash

# ------------------------------------------------------------------------
# Mirror Server Installer on Debian13
#
# It sets up a RepoServer by mirroring the Debian 13 trixe and Pardus 23, Pardus 25, and Pardus-Backports repositories.
# The apt-mirror and debmirror tools were used, as appropriate for each repository.
# The debmirror tool is fully compatible with the Debian repository and is very flexible and effective when it comes to parameters such as filtering,
# excluding source packages, or specifying the backports repository. For this reason, debmirror was used as the Debian repository mirroring tool.
# The apt-mirror tool does not provide a full set of parameters for fetching the Debian repository.
# apt-mirror is a simpler tool and is well-suited for repositories that are not as comprehensive as the Debian repository.
# If we use debmirror for the Pardus mirror repository, it treats the source repository as if it were a full Debian repository and fetches it accordingly.
# This results in unnecessary extra work.
# If we use apt-mirror for the Debian mirror repository, it cannot fully explore the source repository.
#
# # Warning/Important
# If this script is run directly, the `apt-mirror` and `mirror-debian13.sh` commands will download very large files.
# Please read the following lines and make sure you understand them thoroughly
# ------------------------------------------------------------------------

apt-get update
apt-get -y install apt-mirror rsync gnupg nginx debmirror
mkdir -p /mnt/mirrors/debian
mkdir -p /mnt/mirrors/pardus

apt-mirror mirror-pardus.list
bash mirror-debian13.sh

