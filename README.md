# Debian 11 i386 Live + GParted

Experimental Legacy BIOS 32-bit Debian 11 Bullseye Live ISO for IDE/SATA/USB disks. Uses Openbox and GParted. **Installer is disabled** in this first build. No image has been tested on hardware yet.

## GitHub
Upload `.github/workflows/build.yml`, `build.sh` and this README to the repository root. Open **Actions → Build Debian 11 i386 Live ISO → Run workflow**. After success download artifact `debian11-i386-gparted-live`.

## Notes
- Debian 11 is past standard security support; use offline or in trusted environments.
- Requires an i686-compatible processor with PAE for the `686-pae` kernel (many Pentium 4 models support it).
- Builds inside `debian:bullseye` with `--privileged` to allow chroot mounts.
- The build is experimental; validate boot, Openbox and GParted in a VM before writing a USB stick.
- If GParted does not start automatically, run `sudo gparted` in LXTerminal.
