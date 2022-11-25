#! /usr/bin/env bash

#
# (c)2021-2022 project alexandrite
# calamares.sh
#

# disable slow daemons
systemctl mask systemd-udev-settle
systemctl disable sshd
systemctl disable NetworkManager-wait-online.service

# config grub
sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
sed -i -e "s/nomodeset//" /etc/default/grub
cat "GRUB_DISABLE_LINUX_RECOVERY=\"true\"" >> /etc/default/grub
bash /usr/share/alexandrite/createRecoveryEntry.sh
grub2-mkconfig -o /boot/grub2/grub.cfg

# disable autologin
sed -i -e '/AutomaticLogin=/d' /etc/gdm/custom.conf 
sed -i -e '/AutomaticLoginEnable=/d' /etc/gdm/custom.conf
sed -i -e 's/DISPLAYMANAGER_AUTOLOGIN="live"/DISPLAYMANAGER_AUTOLOGIN=""/g' /etc/sysconfig/displaymanager

# refresh package manager
zypper --gpg-auto-import-keys refresh

# enable trusted boot
tpm=`ls /sys/class/tpm/`

if [ -n "$tpm" ]; then
  zypper -n in trustedgrub2 trustedgrub2-i386-pc
fi

# Disable vbox_screen.sh
# echo "rm -f \$HOME/.config/autostart/after-install.desktop" >>/usr/share/alexandrite/afterInstall.sh

# create snapshot
# sudo snapper -c root create-config /

# remove Polkit config for live user
rm -f /etc/polkit-1/rules.d/49-nopassword.rules

