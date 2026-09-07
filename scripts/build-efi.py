#!/usr/bin/env python3
"""
Assemble the OpenCore EFI for the Lenovo IdeaPad Gaming 3 15IMH05 (i5-10300H / UHD 630).

Inputs : build/downloads/   (populated by scripts/fetch-components.sh)
Output : ./EFI/             (repo root, ready to drop on an ESP)

The committed EFI/ ships PLACEHOLDER SMBIOS values. Generate real ones with
    scripts/gen-smbios.sh
which writes a personalised copy to ./EFI-local/ (git-ignored).

Base config: the proven luchina-gabriel Sonoma EFI for this exact model, ported to
OpenCore 1.0.7 with current kext releases and the Wi-Fi kext swapped to itlwm
(no stable AirportItlwm exists for macOS Sequoia).
"""
import argparse, os, plistlib, random, shutil, sys, uuid

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DL   = f"{REPO}/build/downloads"
REF  = f"{DL}/refEFI-luchina/EFI"
OCR  = f"{DL}/oc-rel/X64/EFI"
OCBD = f"{DL}/OcBinaryData"
EX   = f"{DL}/extract"

SSDTS = ["SSDT-AWAC", "SSDT-DISABLE-NVIDIA", "SSDT-EC-USBX", "SSDT-GPI0", "SSDT-GPRW",
         "SSDT-HPET", "SSDT-MCHC", "SSDT-PLUG", "SSDT-PNLF-CFL", "SSDT-TPD0"]

DRIVERS = ["OpenRuntime.efi", "OpenCanopy.efi", "ResetNvramEntry.efi", "HfsPlus.efi", "AudioDxe.efi"]

# (BundlePath, has-executable) — strict Lilu-first / parent-before-plugin order
KEXTS = [
    ("Lilu.kext", True),
    ("VirtualSMC.kext", True),
    ("SMCProcessor.kext", True),
    ("SMCSuperIO.kext", True),
    ("SMCBatteryManager.kext", True),
    ("WhateverGreen.kext", True),
    ("AppleALC.kext", True),
    ("itlwm.kext", True),
    ("IntelBluetoothFirmware.kext", True),
    ("BlueToolFixup.kext", True),
    ("RealtekRTL8111.kext", True),
    ("ECEnabler.kext", True),
    ("CpuTscSync.kext", True),
    ("BrightnessKeys.kext", True),
    ("VoodooPS2Controller.kext", True),
    ("VoodooPS2Controller.kext/Contents/PlugIns/VoodooInput.kext", True),
    ("VoodooPS2Controller.kext/Contents/PlugIns/VoodooPS2Keyboard.kext", True),
    ("VoodooI2C.kext", True),
    ("VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext", True),
    ("VoodooI2C.kext/Contents/PlugIns/VoodooI2CServices.kext", True),
    ("VoodooI2CHID.kext", True),
    ("USBToolBox.kext", True),
    ("UTBDefault.kext", False),
]

# where each top-level .kext bundle lives inside build/downloads/extract
KEXT_SRC = {
    "Lilu.kext":                  f"{EX}/Lilu/Lilu.kext",
    "VirtualSMC.kext":            f"{EX}/VirtualSMC/Kexts/VirtualSMC.kext",
    "SMCProcessor.kext":          f"{EX}/VirtualSMC/Kexts/SMCProcessor.kext",
    "SMCSuperIO.kext":            f"{EX}/VirtualSMC/Kexts/SMCSuperIO.kext",
    "SMCBatteryManager.kext":     f"{EX}/VirtualSMC/Kexts/SMCBatteryManager.kext",
    "WhateverGreen.kext":         f"{EX}/WhateverGreen/WhateverGreen.kext",
    "AppleALC.kext":              f"{EX}/AppleALC/AppleALC.kext",
    "itlwm.kext":                 f"{EX}/itlwm/itlwm.kext",
    "IntelBluetoothFirmware.kext":f"{EX}/IntelBluetooth/IntelBluetoothFirmware.kext",
    "BlueToolFixup.kext":         f"{EX}/BrcmPatchRAM/BlueToolFixup.kext",
    "RealtekRTL8111.kext":        f"{EX}/RealtekRTL8111/RealtekRTL8111-V3.0.0/Release/RealtekRTL8111.kext",
    "ECEnabler.kext":             f"{EX}/ECEnabler/ECEnabler.kext",
    "CpuTscSync.kext":            f"{EX}/CpuTscSync/CpuTscSync.kext",
    "BrightnessKeys.kext":        f"{EX}/BrightnessKeys/BrightnessKeys.kext",
    "VoodooPS2Controller.kext":   f"{EX}/VoodooPS2/VoodooPS2Controller.kext",
    "VoodooI2C.kext":             f"{EX}/VoodooI2C/VoodooI2C.kext",
    "VoodooI2CHID.kext":          f"{EX}/VoodooI2C/VoodooI2CHID.kext",
    "USBToolBox.kext":            f"{EX}/USBToolBox/USBToolBox.kext",
    "UTBDefault.kext":            f"{EX}/USBToolBox/UTBDefault.kext",
}

PLACEHOLDER = dict(serial="CHANGEME-RUN-GENSMBIOS", mlb="CHANGEME-RUN-GENSMBIOS",
                   uuid="00000000-0000-0000-0000-000000000000", rom=b"\x00" * 6)


def rm(p):
    if os.path.isdir(p) and not os.path.islink(p):
        shutil.rmtree(p)
    elif os.path.exists(p):
        os.remove(p)


def need(path, hint):
    if not os.path.exists(path):
        sys.exit(f"missing {path}\n  -> {hint}")


def build(out, smbios):
    need(OCR, "run scripts/fetch-components.sh")
    need(REF, "run scripts/fetch-components.sh")
    need(EX, "run scripts/fetch-components.sh")

    rm(out)
    for d in ("ACPI", "Drivers", "Kexts", "Tools", "Resources"):
        os.makedirs(f"{out}/OC/{d}", exist_ok=True)
    os.makedirs(f"{out}/BOOT", exist_ok=True)

    shutil.copy2(f"{OCR}/BOOT/BOOTx64.efi", f"{out}/BOOT/BOOTx64.efi")
    shutil.copy2(f"{OCR}/OC/OpenCore.efi",  f"{out}/OC/OpenCore.efi")

    for d in ("OpenRuntime.efi", "OpenCanopy.efi", "ResetNvramEntry.efi", "AudioDxe.efi"):
        shutil.copy2(f"{OCR}/OC/Drivers/{d}", f"{out}/OC/Drivers/{d}")
    shutil.copy2(f"{OCBD}/Drivers/HfsPlus.efi", f"{out}/OC/Drivers/HfsPlus.efi")

    for t in ("OpenShell.efi", "ControlMsrE2.efi"):
        shutil.copy2(f"{OCR}/OC/Tools/{t}", f"{out}/OC/Tools/{t}")

    # OpenCanopy GUI needs Font/Image/Label. Skip Resources/Audio (~360 localisation
    # mp3s) - only used by PickerAudioAssist, which is off.
    for d in ("Font", "Image", "Label"):
        shutil.copytree(f"{OCBD}/Resources/{d}", f"{out}/OC/Resources/{d}")

    for s in SSDTS:
        shutil.copy2(f"{REF}/OC/ACPI/{s}.aml", f"{out}/OC/ACPI/{s}.aml")

    for bundle, _ in KEXTS:
        if "/" in bundle:            # plugin: comes with its parent
            continue
        shutil.copytree(KEXT_SRC[bundle], f"{out}/OC/Kexts/{bundle}")
    # chassis USB map from the reference EFI, staged but disabled in config
    shutil.copytree(f"{REF}/OC/Kexts/USBMap.kext", f"{out}/OC/Kexts/USBMap.kext")

    # ---- config.plist : proven reference + minimal delta ----
    cfg = plistlib.load(open(f"{REF}/OC/config.plist", "rb"))
    for k in [k for k in cfg if k.startswith("#")]:
        del cfg[k]

    def kext_entry(path, exe):
        name = os.path.basename(path)[:-5]
        return {"Arch": "Any", "BundlePath": path, "Comment": path, "Enabled": True,
                "ExecutablePath": f"Contents/MacOS/{name}" if exe else "",
                "MaxKernel": "", "MinKernel": "", "PlistPath": "Contents/Info.plist"}

    adds = [kext_entry(p, e) for p, e in KEXTS]
    dis = kext_entry("USBMap.kext", False)
    dis["Enabled"] = False
    dis["Comment"] = ("USBMap.kext (chassis map, DISABLED). After making a real UTBMap.kext, "
                      "enable this or your UTBMap and remove USBToolBox+UTBDefault.")
    adds.append(dis)
    cfg["Kernel"]["Add"] = adds

    g = cfg["PlatformInfo"]["Generic"]
    g["SystemProductName"]  = "MacBookPro16,1"
    g["SystemSerialNumber"] = smbios["serial"]
    g["MLB"]                = smbios["mlb"]
    g["SystemUUID"]         = smbios["uuid"]
    g["ROM"]                = smbios["rom"]

    GUID = "7C436110-AB2A-4BBB-A880-FE41995C9F82"
    nv = cfg["NVRAM"]["Add"][GUID]
    nv["boot-args"]      = "-v keepsyms=1 debug=0x100 -igfxblr igfxonln=1"
    nv["prev-lang:kbd"]  = "en-US:0"
    nv["csr-active-config"] = b"\x00\x00\x00\x00"
    dl = cfg["NVRAM"]["Delete"].setdefault(GUID, [])
    if "boot-args" not in dl:
        dl.append("boot-args")

    sec = cfg["Misc"]["Security"]
    sec["SecureBootModel"] = "Disabled"
    sec["ScanPolicy"] = 0
    sec["Vault"] = "Optional"
    cfg["Misc"]["Boot"]["Timeout"] = 10
    cfg["Misc"]["Boot"]["HideAuxiliary"] = True
    cfg["Misc"]["Debug"]["Target"] = 67          # log to ESP file during bring-up

    cfg["Booter"]["Quirks"]["ClearTaskSwitchBit"] = False   # OC 1.0.7 schema
    # Lenovo/Insyde firmware (BIOS EGCN41WW) rejects Apple's boot.efi with
    # EFI_INVALID_PARAMETER from StartImage -> macOS 14+/Sequoia needs this.
    cfg["Booter"]["Quirks"]["FixupAppleEfiImages"] = True
    cfg["Booter"]["Quirks"] = {k: cfg["Booter"]["Quirks"][k]
                               for k in sorted(cfg["Booter"]["Quirks"])}

    cfg["Misc"]["Debug"]["ApplePanic"] = True     # write panic-*.txt to the ESP

    cfg["UEFI"]["Drivers"] = [{"Arguments": "", "Comment": x, "Enabled": True,
                               "LoadEarly": False, "Path": x} for x in DRIVERS]
    cfg["UEFI"].setdefault("Unload", [])

    cfg["ACPI"]["Add"] = [{"Comment": f"{s}.aml", "Enabled": True, "Path": f"{s}.aml"}
                          for s in SSDTS]

    plistlib.dump(cfg, open(f"{out}/OC/config.plist", "wb"), sort_keys=False)

    n = sum(len(f) for _, _, f in os.walk(out))
    print(f"built {out}  ({n} files)  SMBIOS serial={smbios['serial']}")
    ocv = f"{DL}/oc-rel/Utilities/ocvalidate/ocvalidate.linux"
    if os.path.exists(ocv):
        os.chmod(ocv, 0o755)
        os.system(f'"{ocv}" "{out}/OC/config.plist"')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--out", default=f"{REPO}/EFI", help="output EFI dir")
    ap.add_argument("--serial", help="SystemSerialNumber (default: placeholder)")
    ap.add_argument("--mlb", help="MLB / board serial")
    ap.add_argument("--uuid", help="SystemUUID (default: random)")
    ap.add_argument("--random-uuid", action="store_true",
                    help="use a random SystemUUID even in placeholder mode")
    a = ap.parse_args()

    s = dict(serial=a.serial or PLACEHOLDER["serial"],
             mlb=a.mlb or PLACEHOLDER["mlb"],
             uuid=a.uuid or (str(uuid.uuid4()).upper() if (a.serial or a.random_uuid)
                             else PLACEHOLDER["uuid"]),
             rom=(bytes(random.randint(0, 255) for _ in range(6)) if a.serial
                  else PLACEHOLDER["rom"]))
    build(a.out, s)


if __name__ == "__main__":
    main()
