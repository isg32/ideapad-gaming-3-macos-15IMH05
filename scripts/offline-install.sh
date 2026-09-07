#!/bin/bash
# Run this in the macOS *installer* Terminal (Utilities -> Terminal), after Disk Utility
# has erased the SATA SSD as APFS named "Macintosh HD".
#
#   bash "/Volumes/INSTALL/offline-install.sh"      # if the FAT partition is mounted
#   bash /tmp/oi.sh                                 # if you pasted it to /tmp
#
# It mounts the USB's exFAT MACOS partition, finds InstallAssistant.pkg, lays the
# installer app onto Macintosh HD, and starts an OFFLINE install (no network).
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
  say "not mounted yet - trying exFAT directly"
  for d in $(diskutil list 2>/dev/null | grep -iE 'Microsoft Basic Data|Windows_NTFS|exfat' | grep -oE 'disk[0-9]+s[0-9]+'); do
    mkdir -p /Volumes/MACOS
    if mount_exfat "/dev/$d" /Volumes/MACOS 2>/dev/null; then echo "    mount_exfat /dev/$d ok"; fi
    if [ -f /Volumes/MACOS/InstallAssistant.pkg ]; then PKG=/Volumes/MACOS/InstallAssistant.pkg; break; fi
  done
fi

if [ -z "$PKG" ]; then
  say "InstallAssistant.pkg NOT found. Full disk layout:"
  diskutil list
  echo
  echo "If the ~55 GB partition shows but won't mount, this recovery lacks exFAT"
  echo "support - reformat that partition as HFS+ from Fedora and copy the pkg again."
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
rm -rf "$TARGET/macOS InstallData" 2>/dev/null

say "installing InstallAssistant.pkg onto Macintosh HD (~5 min, no progress bar)"
installer -verbose -pkg "$PKG" -target "$TARGET" || { say "installer failed - see output above"; exit 1; }

APP=""
for cand in "$TARGET/Applications/"Install\ macOS*.app "/Applications/"Install\ macOS*.app; do
  [ -d "$cand" ] && APP="$cand" && break
done
[ -n "$APP" ] || { say "Install macOS app not found after pkg install"; ls -la "$TARGET/Applications" 2>/dev/null; exit 1; }
echo "    app: $APP"

say "starting the offline install - the machine will reboot itself when prep is done"
echo "    after it reboots: F12 -> UEFI USB -> OpenCore picker -> 'macOS Installer'"
echo "    (repeat that each reboot; finally pick 'Macintosh HD')"
sleep 3
exec "$APP/Contents/Resources/startosinstall" --volume "$TARGET" --agreetolicense --nointeraction
