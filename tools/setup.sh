#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

set -o errexit
set -o pipefail

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

nginx_conf_dir=/opt/local/etc/nginx
packages=(
    nginx
)

dirname="$(cd "$(dirname "$0")"/../; pwd)"

pkgin -y install "${packages[@]}"

mkdir -p "${nginx_conf_dir}/sites.d/" /opt/ssl
cp "${dirname}/nginx/nginx.conf" "${nginx_conf_dir}/nginx.conf"
cp "${dirname}/nginx/site-netboot.conf" "${nginx_conf_dir}/sites.d/site-netboot.conf"
cp "${dirname}/nginx/dhparam.pem" /opt/ssl/dhparam.pem

cd /opt
git clone https://github.com/joyent/triton-dehydrated
(
    cd triton-dehydrated
    printf 'netboot.joyent.com netboot.smartos.org\n' > domains.ecdsa.txt
    printf '#CA="https://acme-staging-v02.api.letsencrypt.org/directory"\n' >> config.overrides
    printf 'SERVICES=( nginx )\n' >> config.overrides
    cp "${dirname}/tools/dehydrated-override-hook" override-hook
    bmake deps/dehydrated/dehydrated
    ./dehydrated --register --accept-terms
    set +o errexit
    for tries in {1..5}; do
        if ./dehydrated -f config.ecdsa -c -o /opt/ssl ; then
            break
        fi
        : $tries
    done
)

printf 'data=/data' > config
mkdir -p /data/os

# If nginx config check passes, then try to first restart, second enable
# nginx. If nginx was newly installed it will be disabled. But if someone is
# re-running this, or already installed/enabled nginx then it'll need to be
# restarted.
if nginx -t ; then
    svcadm restart nginx
    svcadm enable nginx
fi

cron_tmp=$(mktemp)
crontab -l | grep -v dehydrated | grep -v netboot > "${cron_tmp:?}"
cat "${dirname}/tools/crontab" >> "${cron_tmp:?}"
crontab "${cron_tmp:?}"
rm -f "${cron_tmp:?}"

printf '=======================================\n'
printf 'System is ready. Use %s/tools/fetch_pi.sh to populate the PIs.\n' "$dirname"
printf '=======================================\n'
