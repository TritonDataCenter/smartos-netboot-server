#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

set -o errexit

dirname="$(cd "$(dirname "$0")"/../; pwd)"

data=./data
# shellcheck disable=SC1090
[[ -f ${dirname}/config ]] && source "${dirname}/config"

cat << "HEAD"
#!ipxe
###
### netboot.xyz-custom menu
###

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

:custom
clear smartos_build
clear kflags
set noimport false
set kmdb_e false
set kmdb_b false
set space:hex 20:20
set space ${space:string}
goto smartos_menu

:smartos_menu
menu Joyent SmartOS
item --gap Platform Images:
HEAD

###
### Note:
### Netboot.xyz depends on the last line of the HEAD and the first line
### of the FOOT HERE docs. If that text is not in the ipxe file their
### ingestion will break.
###

k='platform/i86pc/kernel/amd64/unix'
a='platform/i86pc/amd64/boot_archive'
h='platform/i86pc/amd64/boot_archive.hash'

cd ${data}/os/ || exit
for pattern in '20*T*Z' '*-20*T*Z'; do
    for pi in $(find . -type d -name "$pattern" | tr -d './' | sort -r); do
    # Only include item if the kernel, boot_archive and boot_archive.hash#exist.
        if [[ -f $pi/$k ]] && [[ -f $pi/$a ]] && [[ -f $pi/$h ]] && \
          ! [[ -f $pi/disable ]]; then
            # shellcheck disable=SC2016
            printf 'item %s ${space} %s\n' "$pi" "$pi"
        fi
    done
done

cat << "FOOT"
item --gap Options:
item toggle_pool ${space} Rescue mode: ${noimport}
item toggle_kmdb_e ${space} Load Kernel Debugger: ${kmdb_e}
item toggle_kmdb_b ${space} Boot Kernel Debugger First: ${kmdb_b}

iseq ${noimport} true && item --gap ${space} ||
iseq ${noimport} true && item --gap ${space} Zpool will not be imported. Rescue mode root password can be found at ||
iseq ${noimport} true && item --gap ${space} http://us-east.manta.joyent.com/Joyent_Dev/public/SmartOS/smartos.html ||

choose smartos_build || goto smartos_exit
iseq ${smartos_build} toggle_pool && goto toggle_pool ||
iseq ${smartos_build} toggle_kmdb_e && goto toggle_kmdb_e ||
iseq ${smartos_build} toggle_kmdb_b && goto toggle_kmdb_b ||
goto smartos_boot

:smartos_boot
iseq ${kmdb_e} true && set kflags:hex 2d:6b ||
iseq ${kmdb_b} true && set kflags:hex 2d:6b:64 ||
kernel https://netboot.joyent.com/os/${smartos_build}/platform/i86pc/kernel/amd64/unix ${kflags:string} -B console=text,text-mode="115200,8,n,1,-",smartos=true,noimport=${noimport}${root_shadow:string}
module https://netboot.joyent.com/os/${smartos_build}/platform/i86pc/amd64/boot_archive type=rootfs name=ramdisk || goto fail
module https://netboot.joyent.com/os/${smartos_build}/platform/i86pc/amd64/boot_archive.hash type=hash name=ramdisk || goto fail
boot

:toggle_pool
iseq ${noimport} true && set noimport false || set noimport true
iseq ${noimport} false && clear root_shadow || set root_shadow:hex 2c:72:6f:6f:74:5f:73:68:61:64:6f:77:3d:27:24:35:24:32:48:4f:48:52:6e:4b:33:24:4e:76:4c:6c:6d:2e:31:4b:51:42:62:42:30:57:6a:6f:50:37:78:63:49:77:47:6e:6c:6c:68:7a:70:32:48:6e:54:2e:6d:44:4f:37:44:70:78:59:41:27:0a
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
FOOT
