#! /usr/bin/env bash

#    Alexandrite OS
#    Copyright (C) 2021-2022 Project Alexandrite
#
#
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.



# Functions...
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# Greeting...
echo "Configure image: [${kiwi_iname}]..."

# Setup baseproduct link
suseSetupProduct

# Activate services
suseInsertService sshd

# Setup default target, multi-user
baseSetRunlevel 3

# Remove yast if not in use
#suseRemoveYaST

# enable services
ln -fs /usr/lib/systemd/system/NetworkManager.service /etc/systemd/system/network.service
systemctl enable NetworkManager
systemctl enable firewalld

ln -fs /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target

# set nopassword login for live user
groupadd nopasswdlogin
usermod -aG nopasswdlogin live

# fix sudoers file permission
chmod 440 /etc/sudoers

# setting audit group
groupadd -r audit
usermod -aG audit live

# disable slow daemons
systemctl mask systemd-udev-settle
systemctl disable sshd
systemctl disable NetworkManager-wait-online.service

# remove .gitkeep
rm /home/*/*/.gitkeep

# GRUB setting
#sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
#grub2-mkconfig -o /boot/grub2/grub.cfg

# update dconf
dconf update

# fix extension files parmission
#chmod 644 /usr/share/gnome-shell/extensions/*/metadata.json

# import gpg keys and instsll some packages
#printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=gitlab.com_paulcarroty_vscodium_repo\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | tee -a /etc/zypp/repos.d/vscodium.repo
#srpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
#zypper --gpg-auto-import-keys refresh
#zypper --non-interactive in codium

# disable GDM logo
sudo -u gdm gsettings set org.gnome.login-screen logo ''

# fix gnome-shell extensions
chmod 644 /usr/share/gnome-shell/extensions/*/metadata.json
chmod -R 644 /usr/share/gnome-shell/extensions/*
chmod -R +x /usr/share/gnome-shell/extensions/*

# kill packagekit forever
systemctl stop packagekit
systemctl mask packagekit
zypper -n rm gnome-packagekit

rm -f /usr/lib64/gnome-software/plugins-*/libgs_plugin_packagekit.so
rm -f /usr/lib64/gnome-software/plugins-*/libgs_plugin_packagekit-refresh.so
rm -f /usr/lib64/gnome-software/plugins-*/libgs_plugin_packagekit-refine-repos.so

systemctl enable autoremove-gnome-software-packagekit-pulgin.service
systemctl enable autoremove-gnome-software-packagekit-pulgin.path

# enable alexandriteos-osinfo-fixer
systemctl enable alexandriteos-osinfo-fixer.service
systemctl enable alexandriteos-osinfo-fixer.path

# remove packages
zypper -n rm gnome-terminal gnome-terminal-lang nautilus-extension-terminal lftp easytag nautilus-plugin-easytag gedit
zypper -n al gnome-terminal gnome-terminal-lang nautilus-extension-terminal lftp easytag nautilus-plugin-easytag gedit

#zypper -n rm zypper rpm | echo "done"

# fix zypper config for update
echo "installRecommends = no" >> /etc/zypp/zypper.conf

# Hide tty login prompt at tty1
# systemctl disable getty@tty1.service

# fix terminal
ln -s /usr/bin/kgx /usr/bin/gnome-terminal

# update MIME database
update-mime-database /usr/share/mime
update-desktop-database
