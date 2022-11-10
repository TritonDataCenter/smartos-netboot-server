#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2022 MNX Cloud, Inc.
#

set -o errexit

manta_base='https://us-central.manta.mnx.io/Joyent_Dev/public/SmartDataCenter'

ver=$(curl -sf ${manta_base} | json json -ga -c 'this.name.match(/^release/)' name | tail -1)
pi=$(cut -d '-' -f 2 <<< "$ver")
manta_url="${manta_base}/release-${ver}/headnode/ipxe-release-${ver}.tgz"

basedir=/data/triton-installer

cd "${basedir}" || exit

if [[ -f $(basename "$manta_url") ]]; then
    printf 'Already downloaded %s\n' "$(basename "$manta_url")"
    exit
fi

printf 'Downloading headnode iamge...\n'
curl -# -f -LOC - "$manta_url"

printf 'Extracting image. This will take a while...'
tar zxf "ipxe-release-${ver}.tgz"
printf 'done.\n'
printf 'Linking boot files to new media...'
ln -sf "fulliso-release-${ver}.tgz" fulliso.tgz

cat << EOF > triton-installer.ipxe.new
#!ipxe
dhcp
kernel ${pi}/platform/i86pc/kernel/amd64/unix -B console=ttyb,ttyb-mode="115200,8,n,1,-",headnode=true,triton_installer=ipxe
module ${pi}/platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk
module ${pi}/platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk
boot
EOF

t=$(mktemp)
sed '/^boot$/d' triton-installer.ipxe > "$t"
printf 'module http://metadata.platformequinix.com/metadata type=file name=tinkerbell.json ||\nboot\n' >> "${t}"
mv "${t}" "${basedir}/packet.ipxe.new"
printf 'done.\n'
printf 'All done. You can remove old versions now.\n'
