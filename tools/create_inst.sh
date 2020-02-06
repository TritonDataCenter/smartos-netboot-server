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
set -o pipefail

dirname="$(cd "$(dirname "$0")"/../; pwd)"

function usage () {
    printf '%s -p triton_profile -a account -n instance_name\n' "$0"
    exit "$1"
}

while getopts "a:n:p:" options; do
    case $options in
        a) export SDC_ACCOUNT="${OPTARG}" ;;
        p) profile=( -p "${OPTARG}" ) ;;
        n) name="${OPTARG}" ;;
        *) usage 1 ;;
    esac
done

if [[ -z $name ]]; then
    name='netboot-{{shortId}}'
fi

printf 'Creating netboot instance...'

inst=$( triton "${profile[@]}" inst create -j base-64-lts g4-highcpu-256M \
    --name="$name" --network=Joyent-SDC-Public \
    -m triton.cns.status=down -t triton.cns.services=netboot \
    --script="${dirname}/tools/user-script.sh" | json id)
printf 'done.\n'

triton "${profile[@]}" inst wait "$inst"
