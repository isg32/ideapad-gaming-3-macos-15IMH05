#!/usr/bin/env bash
# Write the macOS Sequoia OpenCore install USB for the Lenovo IdeaPad Gaming 3 15IMH05.
#
#   sudo bash scripts/make-usb.sh /dev/sdX
#
# WIPES the target device. Target must be the USB flash drive, NOT sda / nvme0n1.
# Uses EFI-local/ if present (personalised SMBIOS), otherwise the committed EFI/.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
EFI_SRC="$REPO/EFI-local"; [ -d "$EFI_SRC/OC" ] || EFI_SRC="$REPO/EFI"
REC_SRC="$REPO/build/recovery/com.apple.recovery.boot"
DEV="${1:-}"

die(){ echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "run with sudo"
[[ -n "$DEV" ]] || die "usage: sudo bash scripts/make-usb.sh /dev/sdX"
[[ -b "$DEV" ]] || die "$DEV is not a block device"
[[ -d "$EFI_SRC/OC" ]] || die "no EFI found (run: python3 scripts/build-efi.py)"
[[ -f "$REC_SRC/BaseSystem.dmg" ]] || die "no recovery image (run: bash scripts/download-macos.sh)"

BASE="$(basename "$DEV")"
case "$BASE" in
  nvme0n1*|sda|sda[0-9]*) die "$DEV is a fixed system disk. Refusing." ;;
esac
while read -r src tgt; do
  case "$tgt" in /|/home|/boot|/boot/efi) die "$src is mounted at $tgt. Refusing." ;; esac
done < <(lsblk -nr -o PATH,MOUNTPOINT "$DEV" | awk '$2!=""')

TRAN=$(lsblk -ndo TRAN "$DEV" || true)
echo "============================================================"
echo " EFI source : $EFI_SRC"
echo " TARGET     : $DEV   ($(lsblk -ndo MODEL "$DEV" || true), $(lsblk -ndo SIZE "$DEV"), bus=${TRAN:-?})"
lsblk "$DEV"
echo "============================================================"
[[ "$TRAN" == "usb" ]] || echo "WARNING: bus is not 'usb' - double-check this is your flash drive!"
read -rp "Type ERASE to wipe $DEV and write the installer: " ans
[[ "$ans" == "ERASE" ]] || die "aborted"

echo "==> unmounting"
for p in $(lsblk -nr -o PATH "$DEV" | tail -n +2); do umount "$p" 2>/dev/null || true; done

echo "==> GPT + EFI System partition"
wipefs -a "$DEV"
sfdisk --delete "$DEV" 2>/dev/null || true
sfdisk "$DEV" <<'SFD'
label: gpt
unit: sectors
start=2048, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
SFD
partprobe "$DEV"; sleep 2

PART="${DEV}1"; [[ -b "$PART" ]] || PART="${DEV}p1"
[[ -b "$PART" ]] || die "partition node not found"

echo "==> FAT32 (INSTALL)"
mkfs.vfat -F 32 -n INSTALL "$PART"

MNT="$(mktemp -d)"
mount "$PART" "$MNT"
cp -r "$EFI_SRC" "$MNT/EFI"
cp -r "$REC_SRC" "$MNT/com.apple.recovery.boot"
sync
find "$MNT" -maxdepth 2 -mindepth 1 | sed "s#$MNT#/#"
umount "$MNT"; rmdir "$MNT"; sync
echo
echo "DONE: $DEV  -> boot with F12 -> UEFI USB -> 'macOS Base System'"
