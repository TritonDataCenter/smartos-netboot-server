#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

# This script is usable as a Triton user-script.

set -o errexit
set -o pipefail
set -o xtrace

PATH=/usr/local/sbin:/usr/local/bin:/opt/local/sbin:/opt/local/bin:/usr/sbin:/usr/bin:/sbin

[[ -f /data/smartos.ipxe ]] && exit

mdata-put triton.cns.status down
pkgin -y install git-base
cd /opt
git clone https://github.com/joyent/smartos-netboot-server netboot
cd netboot
printf 'data=/data\nkeep=6\n' > config
./tools/setup.sh
