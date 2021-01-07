#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2021 Joyent, Inc.
#

# shellcheck disable=SC2154
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

while getopts "a:d:n:p:z" options; do
    case $options in
        a) account="${OPTARG}" ;;
        d) datadir="${OPTARG}" ;;
        p) profile="${OPTARG}" ;;
        n) name="${OPTARG}" ;;
        z) delegate_dataset='--delegate-dataset' ;;
        *) usage 1 ;;
    esac
done

if [[ -z $name ]]; then
    name='netboot-{{shortId}}'
fi

opts=( -p "${profile:?}" -a "${account:?}" )
printf 'Creating netboot instance...'
inst=$( triton "${opts[@]}" inst create -j \
    base-64-lts g4-highcpu-256M \
    --name="$name" --network=Joyent-SDC-Public \
    -m triton.cns.status=down -m datadir="${datadir:-/data}" "${delegate_dataset}" \
    -t triton.cns.services=netboot \
    --script="${dirname}/tools/user-script.sh" | json id)
printf 'done.\n'

triton "${opts[@]}" inst wait "$inst"
