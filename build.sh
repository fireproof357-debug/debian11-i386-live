#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mkdir -p output
lb clean --purge || true
lb config \
  --bootloader syslinux \
  --mode debian \
  --distribution bullseye \
  --architectures i386 \
  --firmware-chroot false \
  --linux-flavours 686-pae \
  --linux-packages linux-image \
  --binary-images iso-hybrid \
  --debian-installer false \
  --debian-installer-gui false \
  --security false \
  --archive-areas 'main contrib non-free' \
  --mirror-bootstrap 'http://archive.debian.org/debian/' \
  --mirror-chroot 'http://archive.debian.org/debian/' \
  --mirror-binary 'http://archive.debian.org/debian/' \
  --mirror-debian-installer 'http://archive.debian.org/debian/' \
  --apt-recommends false \
  --checksums sha256
mkdir -p config/package-lists config/hooks/normal
cat > config/package-lists/desktop.list.chroot <<'PACKAGES'
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
policykit-1
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
# Подготовка загрузчика для Legacy BIOS
apt-get update
apt-get install -y isolinux syslinux-common

# Исправляем шаблоны загрузчика ISOLINUX
apt-get install -y isolinux syslinux-common

# Исправление битых ссылок ISOLINUX
BOOTDIR=/usr/share/live/build/bootloaders/isolinux

if [ -d "$BOOTDIR" ]; then
    rm -f "$BOOTDIR/isolinux.bin"
    rm -f "$BOOTDIR/vesamenu.c32"

    cp /usr/lib/ISOLINUX/isolinux.bin "$BOOTDIR/isolinux.bin"
    cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$BOOTDIR/vesamenu.c32"

    echo "ISOLINUX: файлы загрузчика исправлены"
fi
# Совместимость старого live-build с librsvg
apt-get install -y librsvg2-bin

if ! command -v rsvg >/dev/null 2>&1; then
    ln -s "$(command -v rsvg-convert)" /usr/local/bin/rsvg
fi

echo "Проверка SVG:"
command -v rsvg
command -v rsvg-convert
lb build 2>&1 | tee build.log
find . -maxdepth 1 -name '*.iso' -exec cp -v {} output/ \;
sha256sum output/*.iso > output/SHA256SUMS
