#! /usr/bin/env bash

#
# (c)2021 nexryai
# calamares.sh
#

# config grub
sed -i -e 's/GRUB_TERMINAL="console"/GRUB_TERMINAL="gfxterm"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

