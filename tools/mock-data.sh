#!/bin/bash

datadir="${1:-./data}"

mock_names=(
    20200101T000000Z
    20210101T000000Z
    OS-XXXX-20200101T000000Z
)

k='platform/i86pc/kernel/amd64/unix'
a='platform/i86pc/amd64/boot_archive'
h='platform/i86pc/amd64/boot_archive.hash'

for m in "${mock_names[@]}"; do
    mkdir -p "${datadir}"/os/"${m}"/platform/i86pc/{amd64,kernel/amd64}
    touch "${datadir}/os/${m}/${k}"
    touch "${datadir}/os/${m}/${a}"
    touch "${datadir}/os/${m}/${h}"
done