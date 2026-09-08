#!/usr/bin/env bash
# Write the macOS Sequoia OpenCore install USB for the Lenovo IdeaPad Gaming 3 15IMH05.
#
#   sudo bash scripts/make-usb.sh /dev/sdX
#
# WIPES the target device. Target must be the USB flash drive, NOT sda / nvme0n1.
# Uses EFI-local/ if present (personalised SMBIOS), otherwise the committed EFI/.
#
# Layout:
#   p1  FAT32  INSTALL  ~2.5 GB  -> /EFI (OpenCore) + /com.apple.recovery.boot (boots the installer)
#   p2  HFS+   MACOS     rest    -> InstallAssistant.pkg   (ONLY if build/fullinstaller/ has it;
#                                     makes the install work with no network. HFS+ not exFAT -
#                                     the Sequoia recovery has no exFAT support.)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
EFI_SRC="$REPO/EFI-local"; [ -d "$EFI_SRC/OC" ] || EFI_SRC="$REPO/EFI"
REC_SRC="$REPO/build/recovery/com.apple.recovery.boot"
PKG="$REPO/build/fullinstaller/InstallAssistant.pkg"
DEV="${1:-}"

die(){ echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "run with sudo"
[[ -n "$DEV" ]] || die "usage: sudo bash scripts/make-usb.sh /dev/sdX"
[[ -b "$DEV" ]] || die "$DEV is not a block device"
[[ -d "$EFI_SRC/OC" ]] || die "no EFI found (run: python3 scripts/build-efi.py)"
[[ -f "$REC_SRC/BaseSystem.dmg" ]] || die "no recovery image (run: bash scripts/download-macos.sh)"
command -v mkfs.hfsplus >/dev/null || die "need hfsplus-tools (dnf install hfsplus-tools)"

OFFLINE=0
[[ -f "$PKG" && $(stat -c%s "$PKG") -gt 10000000000 ]] && OFFLINE=1

BASE="$(basename "$DEV")"
case "$BASE" in nvme0n1*|sda|sda[0-9]*) die "$DEV is a fixed system disk. Refusing." ;; esac
while read -r src tgt; do
  case "$tgt" in /|/home|/boot|/boot/efi) die "$src is mounted at $tgt. Refusing." ;; esac
done < <(lsblk -nr -o PATH,MOUNTPOINT "$DEV" | awk '$2!=""')

TRAN=$(lsblk -ndo TRAN "$DEV" || true)
echo "============================================================"
echo " EFI source : $EFI_SRC"
echo " Mode       : $([ $OFFLINE = 1 ] && echo 'OFFLINE (FAT32 + HFS+, local InstallAssistant.pkg; Ethernet still needed for the personalize phase)' || echo 'ONLINE (FAT32 only, ~15 GB downloaded during install)')"
echo " TARGET     : $DEV   ($(lsblk -ndo MODEL "$DEV" || true), $(lsblk -ndo SIZE "$DEV"), bus=${TRAN:-?})"
lsblk "$DEV"
echo "============================================================"
[[ "$TRAN" == "usb" ]] || echo "WARNING: bus is not 'usb' - double-check this is your flash drive!"
read -rp "Type ERASE to wipe $DEV and write the installer: " ans
[[ "$ans" == "ERASE" ]] || die "aborted"

echo "==> unmounting"
for p in $(lsblk -nr -o PATH "$DEV" | tail -n +2); do umount "$p" 2>/dev/null || true; done

echo "==> partitioning ($([ $OFFLINE = 1 ] && echo 'FAT32 + HFS+' || echo 'FAT32'))"
wipefs -a "$DEV"
sfdisk --delete "$DEV" 2>/dev/null || true
if [[ $OFFLINE == 1 ]]; then
sfdisk "$DEV" <<'SFD'
label: gpt
unit: sectors
start=2048, size=5120000, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
type=48465300-0000-11AA-AA11-00306543ECAC, name="MACOS"
SFD
else
sfdisk "$DEV" <<'SFD'
label: gpt
unit: sectors
start=2048, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name="EFI"
SFD
fi
partprobe "$DEV"; sleep 2

p(){ local n=$1; [[ -b "${DEV}${n}" ]] && echo "${DEV}${n}" || echo "${DEV}p${n}"; }
P1=$(p 1)

echo "==> FAT32 $P1 (INSTALL)"
mkfs.vfat -F 32 -n INSTALL "$P1"
M1="$(mktemp -d)"; mount "$P1" "$M1"
cp -r "$EFI_SRC" "$M1/EFI"
cp -r "$REC_SRC" "$M1/com.apple.recovery.boot"
sync; umount "$M1"; rmdir "$M1"

if [[ $OFFLINE == 1 ]]; then
  P2=$(p 2)
  echo "==> HFS+ $P2 (MACOS)"
  mkfs.hfsplus -v MACOS "$P2"
  M2="$(mktemp -d)"; mount -t hfsplus -o rw,force "$P2" "$M2"
  echo "    copying InstallAssistant.pkg ($(du -h "$PKG" | cut -f1))..."
  cp "$PKG" "$M2/InstallAssistant.pkg"
  sync; umount "$M2"; rmdir "$M2"
fi

sync
echo
echo "DONE: $DEV"
echo "Boot: F12 -> UEFI USB -> OpenCore picker -> 'install (dmg)'"
[[ $OFFLINE == 1 ]] && echo "Then follow docs/RUNBOOK.md 'Offline install' (Terminal + startosinstall)."
