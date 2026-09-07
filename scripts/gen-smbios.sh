#!/usr/bin/env bash
# Generate fresh MacBookPro16,1 SMBIOS identifiers and build a personalised EFI-local/.
# EFI-local/ is git-ignored - it is YOUR copy, do not commit or share it.
#
#   bash scripts/fetch-components.sh      # once
#   bash scripts/gen-smbios.sh            # -> EFI-local/
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MS="$REPO/build/downloads/oc-rel/Utilities/macserial/macserial.linux"
[ -x "$MS" ] || { chmod +x "$MS" 2>/dev/null || { echo "run scripts/fetch-components.sh first"; exit 1; }; }

read -r SERIAL MLB < <("$MS" --model MacBookPro16,1 --num 1 2>/dev/null | tr -d '|' | awk '{print $1, $2}')
UUID="$(cat /proc/sys/kernel/random/uuid | tr '[:lower:]' '[:upper:]')"

echo "Generated:"
echo "  SystemSerialNumber : $SERIAL"
echo "  MLB                : $MLB"
echo "  SystemUUID         : $UUID"
echo
python3 "$REPO/scripts/build-efi.py" -o "$REPO/EFI-local" \
  --serial "$SERIAL" --mlb "$MLB" --uuid "$UUID"
echo
echo "Personalised EFI at: $REPO/EFI-local"
echo "NOTE: this serial is randomly generated - fine to install, but for iMessage/FaceTime"
echo "      generate a fresh one on macOS with GenSMBIOS and verify it in Apple's coverage checker."
