#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
# Debian 11 archive: avoid obsolete security and updates endpoints.
printf 'deb [check-valid-until=no] http://archive.debian.org/debian bullseye main contrib non-free\n' > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*.list
cat >/etc/apt/apt.conf.d/80-live-retries <<'APT'
Acquire::Retries "8";
Acquire::http::Timeout "180";
Acquire::Check-Valid-Until "false";
APT
apt-get update
apt-get install -y --no-install-recommends live-build debootstrap ca-certificates wget curl gnupg xorriso isolinux syslinux-common syslinux-utils squashfs-tools dosfstools mtools librsvg2-bin python3
# Compatibility with old live-build scripts expecting the old rsvg executable.
if ! command -v rsvg >/dev/null 2>&1; then
  ln -sf /usr/bin/rsvg-convert /usr/local/bin/rsvg
fi
# Repair broken template symlinks in this container if present.
for d in /usr/share/live/build/bootloaders/isolinux /usr/share/live/build/bootloaders/syslinux_common; do
  if [ -d "$d" ]; then
    for f in isolinux.bin vesamenu.c32; do
      case "$f" in
        isolinux.bin) src=/usr/lib/ISOLINUX/isolinux.bin ;;
        vesamenu.c32) src=/usr/lib/syslinux/modules/bios/vesamenu.c32 ;;
      esac
      if [ -e "$src" ]; then rm -f "$d/$f"; cp "$src" "$d/$f"; fi
    done
  fi
done
mkdir -p output
lb clean --purge || true
lb config \
  --mode debian \
  --distribution bullseye \
  --architectures i386 \
  --binary-images iso-hybrid \
  --debian-installer false \
  --security false \
  --firmware-chroot false \
  --linux-packages linux-image \
  --linux-flavours 686-pae \
  --archive-areas 'main contrib non-free' \
  --mirror-bootstrap 'http://archive.debian.org/debian' \
  --mirror-chroot 'http://archive.debian.org/debian' \
  --mirror-binary 'http://archive.debian.org/debian' \
  --apt-recommends false \
  --checksums sha256
mkdir -p config/package-lists config/includes.chroot/etc/skel/.config/openbox config/includes.chroot/etc/lightdm/lightdm.conf.d config/includes.chroot/etc/apt/apt.conf.d
cat > config/package-lists/desktop.list.chroot <<'PACKAGES'
live-boot
live-config
linux-image-686-pae
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
sudo
policykit-1
policykit-1-gnome
fonts-dejavu-core
PACKAGES
cat > config/includes.chroot/etc/skel/.config/openbox/autostart <<'AUTO'
(sleep 4; pkexec /usr/sbin/gparted) &
AUTO
cat > config/includes.chroot/etc/lightdm/lightdm.conf.d/50-live.conf <<'LIGHTDM'
[Seat:*]
autologin-user=user
autologin-user-timeout=0
user-session=openbox
LIGHTDM
cat > config/includes.chroot/etc/apt/apt.conf.d/80-retries <<'APT'
Acquire::Retries "8";
Acquire::http::Timeout "180";
Acquire::Check-Valid-Until "false";
APT
# Make a live user with sudo access and an explicit Openbox session.
mkdir -p config/hooks/normal
cat > config/hooks/normal/010-live-user.hook.chroot <<'HOOK'
#!/bin/sh
set -e
if ! id user >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo,video,audio,plugdev user
fi
passwd -d user
mkdir -p /home/user/.config/openbox
cp /etc/skel/.config/openbox/autostart /home/user/.config/openbox/autostart
chown -R user:user /home/user/.config
cat >/etc/sudoers.d/90-live-user <<'SUDO'
user ALL=(ALL) NOPASSWD: ALL
SUDO
chmod 440 /etc/sudoers.d/90-live-user
HOOK
chmod +x config/hooks/normal/010-live-user.hook.chroot
# No installer for this first verified Live-only iteration.
lb build 2>&1 | tee build.log
find . -maxdepth 1 -type f -name '*.iso' -exec cp -v {} output/ \;
shopt -s nullglob
isos=(output/*.iso)
((${#isos[@]})) || { echo 'ERROR: ISO not produced'; exit 1; }
(cd output && sha256sum ./*.iso > SHA256SUMS)
