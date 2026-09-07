#!/usr/bin/env bash
# One-shot fix: the Sequoia recovery has no exFAT support, so reformat the USB's
# second partition as HFS+ (which macOS reads everywhere) and re-copy InstallAssistant.pkg.
# The first partition (EFI + BaseSystem) is left untouched.
#
#   sudo bash scripts/fix-usb-hfsplus.sh /dev/sdX
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$REPO/build/fullinstaller/InstallAssistant.pkg"
DEV="${1:-}"

die(){ echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "run with sudo"
[[ -b "$DEV" ]] || die "usage: sudo bash scripts/fix-usb-hfsplus.sh /dev/sdX"
[[ -f "$PKG" && $(stat -c%s "$PKG") -gt 15000000000 ]] || die "pkg missing/small at $PKG"
command -v mkfs.hfsplus >/dev/null || die "dnf install hfsplus-tools"

BASE=$(basename "$DEV")
case "$BASE" in nvme0n1*|sda|sda[0-9]*) die "$DEV is a system disk. Refusing." ;; esac
[[ "$(lsblk -ndo TRAN "$DEV")" == "usb" ]] || die "$DEV is not a USB device. Refusing."

P2n=2
P2="${DEV}${P2n}"; [[ -b "$P2" ]] || P2="${DEV}p${P2n}"
[[ -b "$P2" ]] || die "no second partition on $DEV - run make-usb.sh first"

SZ=$(lsblk -ndo SIZE "$P2"); FS=$(lsblk -ndo FSTYPE "$P2" || true)
echo "============================================================"
echo " will REFORMAT : $P2   (currently ${FS:-none}, $SZ)  ->  HFS+  'MACOS'"
echo " keep intact   : ${DEV}1  (EFI + BaseSystem)"
echo " then copy     : $(du -h "$PKG" | cut -f1)  InstallAssistant.pkg"
echo "============================================================"
read -rp "Type YES to reformat $P2: " a; [[ "$a" == YES ]] || die "aborted"

echo "==> unmounting"
for p in "$P2" "${DEV}1" "${DEV}p1"; do umount "$p" 2>/dev/null || true; done
udisksctl unmount -b "$P2" 2>/dev/null || true

echo "==> mkfs.hfsplus (no journal, so Linux can write it)"
wipefs -a "$P2"
mkfs.hfsplus -v MACOS "$P2"

echo "==> setting GPT type to Apple HFS"
sfdisk --part-type "$DEV" "$P2n" 48465300-0000-11AA-AA11-00306543ECAC
partprobe "$DEV"; sleep 2
P2="${DEV}${P2n}"; [[ -b "$P2" ]] || P2="${DEV}p${P2n}"

echo "==> mounting + copying pkg (~15 min on flash, no progress bar)"
MNT=$(mktemp -d)
mount -t hfsplus -o rw,force "$P2" "$MNT"
cp "$PKG" "$MNT/InstallAssistant.pkg"
sync
ls -la "$MNT"
umount "$MNT"; rmdir "$MNT"
sync

echo "==> fsck the result"
fsck.hfsplus -f "$P2" || echo "  (fsck reported issues - see above)"

echo
echo "DONE. Re-insert the USB, boot: F12 -> UEFI USB -> OpenCore -> 'install (dmg)'."
echo "In the installer the MACOS volume now auto-mounts. Then run scripts/offline-install.sh"
echo "(or: installer -pkg '/Volumes/MACOS/InstallAssistant.pkg' -target '/Volumes/Macintosh HD')."
