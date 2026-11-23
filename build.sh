#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mkdir -p output
lb clean --purge || true
lb config \
  --mode debian \
  --distribution bullseye \
  --architectures i386 \
  --binary-images iso-hybrid \
  --bootloaders syslinux \
  --debian-installer live \
  --debian-installer-gui false \
  --archive-areas 'main contrib non-free' \
  --mirror-bootstrap 'http://archive.debian.org/debian/' \
  --mirror-chroot 'http://archive.debian.org/debian/' \
  --mirror-binary 'http://archive.debian.org/debian/' \
  --mirror-debian-installer 'http://archive.debian.org/debian/' \
  --apt-recommends false \
  --checksums sha256
mkdir -p config/package-lists config/hooks/normal
cat > config/package-lists/desktop.list.chroot <<'PACKAGES'
linux-image-686
live-boot
live-config
xorg
xinit
openbox
lightdm
lightdm-gtk-greeter
lxterminal
gparted
parted
fdisk
util-linux
e2fsprogs
dosfstools
ntfs-3g
smartmontools
hdparm
pciutils
usbutils
network-manager
sudo
polkitd
policykit-1-gnome
fonts-dejavu-core
PACKAGES
cat > config/hooks/normal/010-live-user.hook.chroot <<'HOOK'
#!/bin/sh
set -e
mkdir -p /etc/skel/.config/openbox
cat > /etc/skel/.config/openbox/autostart <<'AUTO'
(sleep 3; gparted) &
AUTO
HOOK
chmod +x config/hooks/normal/010-live-user.hook.chroot
lb build 2>&1 | tee build.log
find . -maxdepth 1 -name '*.iso' -exec cp -v {} output/ \;
sha256sum output/*.iso > output/SHA256SUMS
