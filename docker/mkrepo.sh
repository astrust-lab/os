#! /bin/bash
mkdir /repo
find /rpm -name '*.rpm' -exec mv {} /repo/ \;
createrepo /repo
