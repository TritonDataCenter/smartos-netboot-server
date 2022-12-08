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
set -o xtrace

dirname="$(cd "$(dirname "$0")"/../; pwd)"

data="${1:-./data}"

"${dirname}/tools/fetch_pi.sh" latest "$data"
"${dirname}/tools/prune_platforms.sh" "$data"
"${dirname}/tools/render_ipxe_file.sh" "${data}" > "${data}/smartos.ipxe"
TINKERBELL=1 "${dirname}/tools/render_ipxe_file.sh" "${data}" > "${data}/packet.ipxe"
chmod ugo+r "$data"
