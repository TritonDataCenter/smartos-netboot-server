#!/bin/bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2021 Joyent, Inc.
#

set -o errexit
set -o pipefail

# shellcheck disable=SC2154
if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

nginx_conf_dir=/opt/local/etc/nginx
packages=(
    nginx
)

dirname="$(cd "$(dirname "$0")"/../; pwd)"
marker="${dirname}/.setup-complete"

pkgin -y install "${packages[@]}"

mkdir -p "${nginx_conf_dir}/sites.d/" /opt/ssl
cp "${dirname}/nginx/nginx.conf" "${nginx_conf_dir}/nginx.conf"
cp "${dirname}/nginx/site-netboot.conf" "${nginx_conf_dir}/sites.d/site-netboot.conf"
cp "${dirname}/nginx/dhparam.pem" /opt/ssl/dhparam.pem

pushd /opt
if ! [[ -d /opt/dehydrated ]]; then
    mkdir -p /opt/dehydrated
    latest=$(curl -s https://api.github.com/repos/joyent/triton-dehydrated/releases/latest | json assets.0.browser_download_url)
    curl -#L "$latest" | gtar --no-same-owner -zxv -C /opt/dehydrated
    pushd dehydrated
    printf 'netboot.smartos.org netboot.joyent.com\n' > domains.txt
    printf '#CA="https://acme-staging-v02.api.letsencrypt.org/directory"\n' >> config.overrides
    printf 'SERVICES=( nginx )\n' >> config.overrides
    cp "${dirname}/tools/dehydrated-override-hook" override-hook
    popd
fi
if ! [[ -f /opt/ssl/netboot.smartos.org/fullchain.pem ]]; then
    /opt/dehydrated/dehydrated --register --accept-terms
    set +o errexit
    for tries in {1..5}; do
        if SKIP_VERIFY=1 /opt/dehydrated/dehydrated -c -o /opt/ssl ; then
            break
        fi
        : "$tries"
    done
fi
popd

datadir=$(mdata-get datadir)
printf 'data=%s\nkeep=6\n' "$datadir" > config
mkdir -p "${datadir}/os"

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

touch "${marker}"
printf '=======================================\n'
# shellcheck disable=2016
printf 'System is ready. Use `%s/tools/fetch_pi.sh latest %s` to populate the PIs.\n' "$dirname" "$datadir"
printf '=======================================\n'
