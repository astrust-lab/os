#!/usr/bin/env bash

set -e

# 各変数を最新バージョンに変える https://gitlab.gnome.org/GNOME/gnome-shell-extensions/-/tags）
download_link="https://gitlab.gnome.org/GNOME/gnome-shell-extensions/-/archive/42.1/gnome-shell-extensions-42.1.zip"
filename="gnome-shell-extensions-42.1.zip"

mkdir -p root/usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
mkdir tmp

cd tmp

wget ${download_link}
unzip ${filename}
rm ${filename}

cd *
./export-zips.sh

cd zip-files
unzip user-theme@gnome-shell-extensions.gcampax.github.com.shell-extension.zip -d user-theme@gnome-shell-extensions.gcampax.github.com

cd ../../..

cp -r tmp/*/zip-files/user-theme@gnome-shell-extensions.gcampax.github.com root/usr/share/gnome-shell/extensions/

rm -rf tmp



