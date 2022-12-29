FROM fedora:37 as fedora_pkg

WORKDIR /rpm

RUN dnf update -y \
 && dnf install -y python3-dnf-plugins-core \
 && dnf download gnome-shell-extension-apps-menu gnome-shell-extension-blur-my-shell gnome-shell-extension-dash-to-dock gnome-shell-extension-user-theme

FROM opensuse/tumbleweed

COPY targets/astrust/main.packages .

RUN cd /etc/zypp/repos.d \
 && sed -i '/^baseurl=/c\\baseurl=https://ftp.riken.jp/Linux/opensuse/tumbleweed/repo/oss/' repo-oss.repo \
 && sed -i '/^baseurl=/c\\baseurl=https://ftp.riken.jp/Linux/opensuse/tumbleweed/repo/non-oss/' repo-non-oss.repo \
 && sed -i '/^baseurl=/c\\baseurl=https://twrepo.opensuse.id/update/tumbleweed/' repo-update.repo \
 && zypper --non-interactive dup \
 && zypper --non-interactive in find createrepo \
 && zypper --non-interactive addrepo https://download.opensuse.org/repositories/home:Dead_Mozay:GNOME:Apps/openSUSE_Tumbleweed/home:Dead_Mozay:GNOME:Apps.repo \
 && zypper --non-interactive addrepo -f https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/ codecs \
 && zypper --non-interactive addrepo -f https://opensuse-guide.org/repo/openSUSE_Tumbleweed/ dvd \
 && zypper --gpg-auto-import-keys refresh \
 && zypper --non-interactive --pkg-cache-dir /rpm install --download-only --no-recommends $(cat main.packages |  tr '\n' ' ')

COPY --from=fedora_pkg /rpm /rpm

COPY docker/mkrepo.sh /usr/libexec

CMD ["bash", "/usr/libexec/mkrepo.sh"]
