#! /usr/bin/env bash

rm -f $HOME/.config/autostart/after-install.desktop
rm -f $HOME/*/.gitkeep

if [ -f "/usr/bin/calamares" ]; then
	kdesu /usr/bin/calamares
else
	# /usr/libexec/gnome-initial-setup
	dconf write /org/gnome/desktop/input-sources/mru-sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]" && dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"
fi


