#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2021 Joyent, Inc.
# Copyright 2022 MNX Cloud, Inc.
#

# This script is usable as a Triton user-script.

set -o errexit
set -o pipefail
set -o xtrace

PATH=/usr/local/sbin:/usr/local/bin:/opt/local/sbin:/opt/local/bin:/usr/sbin:/usr/bin:/sbin

[[ -f /opt/netboot/.setup-complete ]] && exit

mdata-put triton.cns.status down
datadir=$(mdata-get datadir)

if [[ -d /zones/$(zonename)/data ]]; then
        zfs create -o "mountpoint=${datadir}" "zones/$(zonename)/data/repo"
else
        mkdir -p "$datadir"
fi
pkgin -y install git-base
cd /opt
git clone https://github.com/TritonDataCenter/smartos-netboot-server netboot
cd netboot
TRACE=1 ./tools/setup.sh
