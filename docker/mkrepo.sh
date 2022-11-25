#! /bin/bash
mkdir -f /rpm
zypper --non-interactive --pkg-cache-dir /rpm install --download-only --no-recommends qemu
find /rpm -name '*.rpm' -exec mv {} /repo/ \;
createrepo /repo
