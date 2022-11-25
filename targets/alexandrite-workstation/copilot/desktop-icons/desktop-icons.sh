#!/usr/bin/env bash

set -e

# 各変数を最新バージョンに変える （https://gitlab.com/rastersoft/desktop-icons-ng/-/releases）
download_link="https://gitlab.com/rastersoft/desktop-icons-ng/-/archive/45/desktop-icons-ng-45.zip"


mkdir -p root/usr/share/gnome-shell/extensions/ding@rastersoft.com

mkdir tmp
cd tmp

wget ${download_link}
unzip *.zip
rm *.zip

cd *
./export-zip.sh 

unzip ding@rastersoft.com.zip -d ding@rastersoft.com


cd ../..

cp -r tmp/*/ding@rastersoft.com root/usr/share/gnome-shell/extensions/

rm -rf tmp



