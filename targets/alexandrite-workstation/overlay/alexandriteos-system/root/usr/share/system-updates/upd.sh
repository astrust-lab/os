#!/usr/bin/env bash

#
# (c) 2022 Project Alexandrite
#

# GLORY TO UKRAINE


# 日本語入力のバグ修正
dconf write /org/gnome/desktop/input-sources/mru-sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]" && dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"

# 3.20アップデート
gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
rm ~/.config/autostart/shell-optimizer.desktop

dconf load / < /usr/share/system-updates/dconf-update.conf

cp /etc/skel/.config/autostart/sysupd-notify.desktop ~/.config/autostart/

