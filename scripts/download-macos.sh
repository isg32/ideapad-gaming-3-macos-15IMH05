#!/usr/bin/env bash
# Fetch a macOS Sequoia installer for the USB.
#
#   bash scripts/download-macos.sh            # ONLINE installer  -> build/recovery/
#                                             #   (small BaseSystem, downloads ~15 GB during install)
#   bash scripts/download-macos.sh --full     # OFFLINE installer -> build/fullinstaller/
#                                             #   (BaseSystem to boot + full InstallAssistant.pkg,
#                                             #    no network needed during install)
#   bash scripts/download-macos.sh <board-id> # override recovery board id
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MR="$REPO/build/downloads/oc-rel/Utilities/macrecovery/macrecovery.py"
GIB="$REPO/build/downloads/gibMacOS/gibMacOS.py"

# ---------- recovery BaseSystem (needed for both modes: it's what boots) ----------
get_recovery() {
  local board="${1:-Mac-7BA5B2D9E42DDD94}" out="$REPO/build/recovery/com.apple.recovery.boot"
  [ -s "$out/BaseSystem.dmg" ] && { echo "recovery: already have $out/BaseSystem.dmg"; return; }
  [ -f "$MR" ] || { echo "run scripts/fetch-components.sh first"; exit 1; }
  mkdir -p "$out"
  for a in 1 2 3 4 5; do
    echo "== recovery download attempt $a =="
    python3 - "$MR" "$board" "$out" <<'PY' && break
import os, sys, runpy, socket
mr, board, out = sys.argv[1:4]
socket.setdefaulttimeout(90)
os.get_terminal_size = lambda *a, **k: os.terminal_size((100, 24))
sys.argv = ["macrecovery.py","-b",board,"-m","00000000000000000","-os","default","-o",out,"download"]
runpy.run_path(mr, run_name="__main__")
PY
    echo "  stalled, retrying in 10s"; sleep 10
  done
  test -s "$out/BaseSystem.dmg"
}

if [ "${1:-}" != "--full" ]; then
  get_recovery "${1:-}"
  echo
  ls -lh "$REPO/build/recovery/com.apple.recovery.boot"
  echo "ONLINE installer ready. Next: sudo bash scripts/make-usb.sh /dev/sdX"
  exit 0
fi

# ---------- --full : also grab InstallAssistant.pkg ----------
get_recovery
[ -f "$GIB" ] || { echo "missing gibMacOS - run scripts/fetch-components.sh"; exit 1; }

echo "== resolving latest Sequoia InstallAssistant.pkg URL =="
URL=$(python3 "$GIB" -c publicrelease -v 15 -i --no-interactive 2>/dev/null \
      | grep -Eo 'https://[^ ]*InstallAssistant\.pkg' | tail -1)
[ -n "$URL" ] || { echo "could not resolve InstallAssistant URL"; exit 1; }
echo "  $URL"

DST="$REPO/build/fullinstaller"
mkdir -p "$DST"
echo "== downloading InstallAssistant.pkg (~15 GB, resumable) =="
curl -L -C - --retry 999 --retry-delay 5 --retry-all-errors -o "$DST/InstallAssistant.pkg" "$URL"

sz=$(stat -c%s "$DST/InstallAssistant.pkg")
echo "  got $((sz/1024/1024)) MB"
[ "$sz" -gt 10000000000 ] || { echo "file looks too small - incomplete?"; exit 1; }
echo
echo "OFFLINE installer ready. Next: sudo bash scripts/make-usb.sh /dev/sdX"
echo "(make-usb.sh auto-detects the .pkg and adds a second exFAT partition for it)"
