#!/usr/bin/env bash
# Download a macOS Sequoia recovery installer (BaseSystem) using OpenCore's macrecovery.
# Output: build/recovery/com.apple.recovery.boot/   (copied onto the USB by make-usb.sh)
#
#   bash scripts/download-macos.sh            # Sequoia 15.7.4 (default board)
#   bash scripts/download-macos.sh <board-id> # override, see build/downloads/oc-rel/Utilities/macrecovery/boards.json
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MR="$REPO/build/downloads/oc-rel/Utilities/macrecovery/macrecovery.py"
OUT="$REPO/build/recovery/com.apple.recovery.boot"
BOARD="${1:-Mac-7BA5B2D9E42DDD94}"      # MacBookPro15,1 -> recovery caps at macOS 15.7.4 (Sequoia)

[ -f "$MR" ] || { echo "run scripts/fetch-components.sh first"; exit 1; }
mkdir -p "$OUT"

# macrecovery.py calls os.get_terminal_size(), which throws when stdout is not a TTY.
python3 - "$MR" "$BOARD" "$OUT" <<'PY'
import os, sys, runpy
mr, board, out = sys.argv[1:4]
os.get_terminal_size = lambda *a, **k: os.terminal_size((100, 24))
sys.argv = ["macrecovery.py", "-b", board, "-m", "00000000000000000",
            "-os", "default", "-o", out, "download"]
runpy.run_path(mr, run_name="__main__")
PY

echo
ls -lh "$OUT"
echo "Recovery ready. Next: sudo bash scripts/make-usb.sh /dev/sdX"
