#!/bin/bash
# Run this in the macOS *installer* Terminal (Utilities -> Terminal), after Disk Utility
# has erased the SATA SSD as APFS named "Macintosh HD".
#
#   bash "/Volumes/INSTALL/offline-install.sh"      # if the FAT partition is mounted
#   bash /tmp/oi.sh                                 # if you pasted it to /tmp
#
# It mounts the USB's HFS+ MACOS partition, finds InstallAssistant.pkg, extracts the
# installer app onto Macintosh HD, and runs startosinstall from it - so the ~15 GB OS
# payload never downloads. A wired Ethernet cable is STILL needed: the installer's
# prepare/personalize phase contacts Apple.
set -u

TARGET="/Volumes/Macintosh HD"

say(){ printf '\n>>> %s\n' "$*"; }

say "mounting every partition diskutil can see"
for d in $(diskutil list 2>/dev/null | grep -oE 'disk[0-9]+s[0-9]+' | sort -u); do
  diskutil mount "$d" >/dev/null 2>&1 && echo "    mounted $d"
done

say "looking for InstallAssistant.pkg"
PKG=""
for v in /Volumes/*; do
  if [ -f "$v/InstallAssistant.pkg" ]; then PKG="$v/InstallAssistant.pkg"; break; fi
done

if [ -z "$PKG" ]; then
  say "not auto-mounted - forcing the HFS+ MACOS partition"
  for d in $(diskutil list 2>/dev/null | grep -iE 'Apple_HFS|MACOS' | grep -oE 'disk[0-9]+s[0-9]+'); do
    diskutil mount "$d" >/dev/null 2>&1
    if [ -f "/Volumes/MACOS/InstallAssistant.pkg" ]; then PKG=/Volumes/MACOS/InstallAssistant.pkg; break; fi
  done
fi

if [ -z "$PKG" ]; then
  say "InstallAssistant.pkg NOT found. Full disk layout:"
  diskutil list
  echo
  echo "The MACOS partition must be HFS+ (not exFAT - this recovery can't mount exFAT)."
  echo "From Fedora: sudo bash scripts/fix-usb-hfsplus.sh /dev/sdX"
  exit 1
fi
echo "    found: $PKG"

if [ ! -d "$TARGET" ]; then
  say "'$TARGET' is missing - erase the SATA SSD as APFS named exactly 'Macintosh HD' first."
  diskutil list
  exit 1
fi

# free space check (~30 GB needed)
FREE=$(df -g "$TARGET" | awk 'NR==2{print $4}')
echo "    free on Macintosh HD: ${FREE} GB"
[ "${FREE:-0}" -lt 25 ] && { say "not enough free space on $TARGET (need ~25+ GB)"; exit 1; }

say "clearing any half-finished install data on the target"
rm -rf "$TARGET/macOS InstallData" "$TARGET/IA" 2>/dev/null

# NOTE: `installer -pkg InstallAssistant.pkg -target <non-/>` does NOT work - it fails
# with "the installer encountered an error". Extract the payload directly instead.
say "extracting InstallAssistant.pkg onto Macintosh HD (~15 GB, several minutes, no progress bar)"
mkdir -p "$TARGET/IA"
pkgutil --expand-full "$PKG" "$TARGET/IA" || { say "pkgutil --expand-full failed - see output above"; exit 1; }

APP="$(find "$TARGET/IA" -maxdepth 6 -name 'Install macOS*.app' -print -quit 2>/dev/null)"
[ -n "$APP" ] || { say "Install macOS app not found after extraction"; find "$TARGET/IA" -maxdepth 4 -name '*.app'; exit 1; }
echo "    app: $APP"

say "starting the offline install - the machine will reboot itself when prep is done"
echo "    after it reboots: F12 -> UEFI USB -> OpenCore picker -> 'macOS Installer'"
echo "    (repeat that each reboot; finally pick 'Macintosh HD')"
sleep 3
exec "$APP/Contents/Resources/startosinstall" --volume "$TARGET" --agreetolicense --nointeraction
