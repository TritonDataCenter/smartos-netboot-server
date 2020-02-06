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
set -o xtrace

dirname="$(cd "$(dirname "$0")"/../; pwd)"

data=./data
# shellcheck disable=SC1090
[[ -f ${dirname}/config ]] && source "${dirname}/config"

"${dirname}/tools/fetch_pi.sh"
"${dirname}/tools/prune_platforms.sh"
"${dirname}/tools/render_ipxe_file.sh" > "${data}/smartos.ipxe"
