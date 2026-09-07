#!/usr/bin/env bash
# Download every pinned component needed to build the EFI, into build/downloads/.
# Re-run any time; it re-fetches and re-extracts. No sudo, no network writes elsewhere.
#
#   bash scripts/fetch-components.sh
#   python3 scripts/build-efi.py
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DL="$REPO/build/downloads"
mkdir -p "$DL"/{kexts,oc}
cd "$DL"

# ----- pinned versions (bump here, then rebuild) -----
OPENCORE=1.0.7
LILU=1.7.2
VIRTUALSMC=1.3.7
WHATEVERGREEN=1.7.0
APPLEALC=1.9.7
VOODOOPS2=2.3.7
BRIGHTNESSKEYS=1.0.3
CPUTSCSYNC=1.1.2
RESTRICTEVENTS=1.1.6
VOODOOI2C=2.9.1
ITLWM=v2.3.0                       # itlwm (Wi-Fi via HeliPort) + AirportItlwm Sonoma14.4 (optional)
INTELBT=v2.4.0                     # IntelBluetoothFirmware
BRCMPATCHRAM=2.7.2                # provides BlueToolFixup.kext
ECENABLER=1.0.6
USBTOOLBOX=1.2.0
REALTEK8111=v3.0.0

GH=https://github.com
dl(){ echo "  $2"; curl -fsSL -o "$1/$2" "$3"; }

echo "== OpenCore $OPENCORE =="
dl oc OpenCore-RELEASE.zip "$GH/acidanthera/OpenCorePkg/releases/download/$OPENCORE/OpenCore-$OPENCORE-RELEASE.zip"

echo "== kexts =="
dl kexts Lilu.zip           "$GH/acidanthera/Lilu/releases/download/$LILU/Lilu-$LILU-RELEASE.zip"
dl kexts VirtualSMC.zip     "$GH/acidanthera/VirtualSMC/releases/download/$VIRTUALSMC/VirtualSMC-$VIRTUALSMC-RELEASE.zip"
dl kexts WhateverGreen.zip  "$GH/acidanthera/WhateverGreen/releases/download/$WHATEVERGREEN/WhateverGreen-$WHATEVERGREEN-RELEASE.zip"
dl kexts AppleALC.zip       "$GH/acidanthera/AppleALC/releases/download/$APPLEALC/AppleALC-$APPLEALC-RELEASE.zip"
dl kexts VoodooPS2.zip      "$GH/acidanthera/VoodooPS2/releases/download/$VOODOOPS2/VoodooPS2Controller-$VOODOOPS2-RELEASE.zip"
dl kexts BrightnessKeys.zip "$GH/acidanthera/BrightnessKeys/releases/download/$BRIGHTNESSKEYS/BrightnessKeys-$BRIGHTNESSKEYS-RELEASE.zip"
dl kexts CpuTscSync.zip     "$GH/acidanthera/CpuTscSync/releases/download/$CPUTSCSYNC/CpuTscSync-$CPUTSCSYNC-RELEASE.zip"
dl kexts RestrictEvents.zip "$GH/acidanthera/RestrictEvents/releases/download/$RESTRICTEVENTS/RestrictEvents-$RESTRICTEVENTS-RELEASE.zip"
dl kexts VoodooI2C.zip      "$GH/VoodooI2C/VoodooI2C/releases/download/v$VOODOOI2C/VoodooI2C-$VOODOOI2C-RELEASE.zip"
dl kexts itlwm.zip          "$GH/OpenIntelWireless/itlwm/releases/download/$ITLWM/itlwm_${ITLWM}_stable.kext.zip"
dl kexts AirportItlwm-Sonoma144.zip "$GH/OpenIntelWireless/itlwm/releases/download/$ITLWM/AirportItlwm_${ITLWM}_stable_Sonoma14.4.kext.zip"
dl kexts IntelBluetooth.zip "$GH/OpenIntelWireless/IntelBluetoothFirmware/releases/download/$INTELBT/IntelBluetooth-$INTELBT.zip"
dl kexts BrcmPatchRAM.zip   "$GH/acidanthera/BrcmPatchRAM/releases/download/$BRCMPATCHRAM/BrcmPatchRAM-$BRCMPATCHRAM-RELEASE.zip"
dl kexts ECEnabler.zip      "$GH/averycblack/ECEnabler/releases/download/$ECENABLER/ECEnabler-$ECENABLER-RELEASE.zip"
dl kexts USBToolBox.zip     "$GH/USBToolBox/kext/releases/download/$USBTOOLBOX/USBToolBox-$USBTOOLBOX-RELEASE.zip"
dl kexts RealtekRTL8111.zip "$GH/Mieze/RTL8111_driver_for_OS_X/releases/download/$REALTEK8111/RealtekRTL8111-${REALTEK8111^^}.zip"

echo "== extract =="
rm -rf extract oc-rel; mkdir -p extract
for z in kexts/*.zip; do d="extract/$(basename "$z" .zip)"; mkdir -p "$d"; (cd "$d" && unzip -oq "$DL/$z"); done
mkdir -p oc-rel && (cd oc-rel && unzip -oq "$DL/oc/OpenCore-RELEASE.zip")
chmod +x oc-rel/Utilities/ocvalidate/ocvalidate.linux oc-rel/Utilities/macserial/macserial.linux 2>/dev/null || true

echo "== git sources (reference EFI + OcBinaryData) =="
[ -d refEFI-luchina/.git ] || git clone --depth 1 \
  https://github.com/luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i-10300H-10750H-i5-i7-iGPU.git refEFI-luchina
[ -d OcBinaryData/.git ] || git clone --depth 1 https://github.com/acidanthera/OcBinaryData.git OcBinaryData

echo
echo "OK. Next: python3 scripts/build-efi.py   (then scripts/gen-smbios.sh for real serials)"
