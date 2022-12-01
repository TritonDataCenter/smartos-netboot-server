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

# shellcheck disable=SC2154
if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

set -o errexit

data="${1:-./data}"

k='platform/i86pc/kernel/amd64/unix'
a='platform/i86pc/amd64/boot_archive'
h='platform/i86pc/amd64/boot_archive.hash'

cd "${data}/os/" || exit
list=()
while IFS='' read -r line; do list+=("$line"); done < <(
    # Want normal PIs to be first. experimetnal next
    /usr/bin/find -E . -maxdepth 1 -type d -regex '\./20[[:digit:]]{6}T[[:digit:]]{6}Z' | tr -d './' | sort -r
    /usr/bin/find -E . -maxdepth 1 -type d -regex '\./.*-20[[:digit:]]{6}T[[:digit:]]{6}Z' | tr -d './' | sort -r
)

cat << "CHUNK1"
#!ipxe

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2021 Joyent, Inc.
# Copyright 2022 MNX Cloud, Inc.
#

:custom
clear smartos_build
clear kflags
set base_url https://netboot.smartos.org
set bp_console ttyb
set bp_smartos true
set bp_noimport false
set kmdb_e false
set kmdb_b false
set space:hex 20:20
set space ${space:string}
goto smartos_menu

:smartos_menu
menu Triton SmartOS
CHUNK1

###
### Note:
### Netboot.xyz depends on these marker lines. If that text is not in the ipxe
### file their ingestion will break. Everything between these markers will be
### included in their menu.
###

# BEGIN netboot.xyz marker -- do not change this
printf 'item --gap Platform Images:\n'
# END netboot.xyz marker -- do not change this

for pi in "${list[@]}"; do
# Only include item if the kernel, boot_archive and boot_archive.hash#exist.
    if [[ -f $pi/$k ]] && [[ -f $pi/$a ]] && [[ -f $pi/$h ]] && \
      ! [[ -f $pi/disable ]]; then
        # shellcheck disable=SC2016
        printf 'item %s ${space} %s\n' "$pi" "$pi"
    fi
done

# BEGIN netboot.xyz marker -- do not change this
printf 'item --gap Options:\n'
# END netboot.xyz marker -- do not change this

cat << "CHUNK2"
item change_console ${space} OS Console: ${bp_console}
item toggle_pool ${space} Rescue mode: ${bp_noimport}
item toggle_kmdb_e ${space} Load Kernel Debugger: ${kmdb_e}
item toggle_kmdb_b ${space} Boot Kernel Debugger First: ${kmdb_b}

iseq ${bp_noimport} true && item --gap ${space} ||
iseq ${bp_noimport} true && item --gap ${space} Zpool will not be imported. Rescue mode root password can be found at ||
iseq ${bp_noimport} true && item --gap ${space} https://us-central.manta.mnx.io/Joyent_Dev/public/SmartOS/smartos.html ||
CHUNK2

printf '\nchoose --default %s --timeout 10000 smartos_build &&\n' "${list[0]}"

cat << "CHUNK3"
iseq ${smartos_build} change_console && goto change_console ||
iseq ${smartos_build} toggle_pool && goto toggle_pool ||
iseq ${smartos_build} toggle_kmdb_e && goto toggle_kmdb_e ||
iseq ${smartos_build} toggle_kmdb_b && goto toggle_kmdb_b ||
goto smartos_boot

:smartos_boot
iseq ${kmdb_e} true && set kflags:hex 2d:6b ||
iseq ${kmdb_b} true && set kflags:hex 2d:6b:64 ||
kernel ${base_url}/os/${smartos_build}/platform/i86pc/kernel/amd64/unix ${kflags:string} -B console=${bp_console},${bp_console}-mode="115200,8,n,1,-",smartos=${bp_smartos},noimport=${bp_noimport}${root_shadow:string}
module ${base_url}/os/${smartos_build}/platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk || goto fail
module ${base_url}/os/${smartos_build}/platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk || goto fail
CHUNK3

if [[ -n $TINKERBELL ]]; then
    printf 'module http://metadata.platformequinix.com/metadata type=file name=tinkerbell.json ||\n'
fi

cat << "CHUNK_Z"
boot || goto smartos_menu

:change_console
iseq ${bp_console} text && set bp_console ttya && goto smartos_menu ||
iseq ${bp_console} ttya && set bp_console ttyb && goto smartos_menu ||
iseq ${bp_console} ttyb && set bp_console ttyc && goto smartos_menu ||
iseq ${bp_console} ttyc && set bp_console ttyd && goto smartos_menu ||
iseq ${bp_console} ttyd && set bp_console text && goto smartos_menu

:toggle_pool
iseq ${bp_noimport} true && set bp_noimport false || set bp_noimport true
iseq ${bp_noimport} true && set bp_smartos false || set bp_smartos true
iseq ${bp_noimport} false && clear root_shadow || set root_shadow:hex 2c:72:6f:6f:74:5f:73:68:61:64:6f:77:3d:27:24:35:24:32:48:4f:48:52:6e:4b:33:24:4e:76:4c:6c:6d:2e:31:4b:51:42:62:42:30:57:6a:6f:50:37:78:63:49:77:47:6e:6c:6c:68:7a:70:32:48:6e:54:2e:6d:44:4f:37:44:70:78:59:41:27:0a
goto smartos_menu

:toggle_kmdb_e
iseq ${kmdb_e} true && set kmdb_e false || set kmdb_e true
iseq ${kmdb_e} false && set kmdb_b false ||
goto smartos_menu

:toggle_kmdb_b
iseq ${kmdb_b} true && set kmdb_b false || set kmdb_b true
iseq ${kmdb_b} true && set kmdb_e true ||
goto smartos_menu

:smartos_exit
clear menu
exit 0
CHUNK_Z