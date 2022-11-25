#!/usr/bin/env bash

set -e

mkdir -p root/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
mkdir tmp

cd tmp

git clone https://github.com/home-sweet-gnome/dash-to-panel
cd dash-to-panel
mkdir _build
make _build

cd ../..

ls
cp -r tmp/dash-to-panel/_build/* root/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/

rm -rf tmp
