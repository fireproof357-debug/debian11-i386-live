# Debian 11 i386 Live ISO with GParted

Experimental GitHub Actions build for older 32-bit x86 PCs, using Debian Bullseye and live-build.

## Build
Open **Actions → Build Debian 11 i386 Live ISO → Run workflow**. Download the ISO artifact when the workflow succeeds.

## Notes
- Debian 11 is old and its repositories may be archived; building against archive.debian.org can require additional adjustments.
- The `--debian-installer live` option is intended to include the live installer, but availability of archived i386 installer components is not guaranteed. Verify the boot menu and installation in a virtual machine before using real disks.
- Requires i686-class CPU; not original Intel 80386.
- This is an untested build recipe, not a verified bootable ISO.
- GParted performs destructive disk operations; back up data before editing partitions.
