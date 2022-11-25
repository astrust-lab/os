#!/usr/bin/env bash

set -e

# ここを最新バージョンに変える。 (https://github.com/aunetx/blur-my-shell/releases)
version="33"

mkdir -p root/usr/share/gnome-shell/extensions/blur-my-shell@aunetx
cd root/usr/share/gnome-shell/extensions/blur-my-shell@aunetx

wget https://github.com/aunetx/blur-my-shell/releases/download/v${version}/blur-my-shell@aunetx.zip
unzip blur-my-shell@aunetx.zip

rm blur-my-shell@aunetx.zip

exit 0
