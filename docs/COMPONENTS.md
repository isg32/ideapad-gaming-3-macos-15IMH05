# Components — pinned versions

These are the exact versions bundled in `EFI/` and pinned in
`scripts/fetch-components.sh`. Bump the variables at the top of that script, re-run it,
then `python3 scripts/build-efi.py` to rebuild.

## Bootloader

| Component | Version | Source |
|---|---|---|
| OpenCore | **1.0.7** | https://github.com/acidanthera/OpenCorePkg |
| OcBinaryData (HfsPlus.efi, Resources) | latest `master` | https://github.com/acidanthera/OcBinaryData |

## Kexts

| Kext | Version | Source | License |
|---|---|---|---|
| Lilu | **1.7.2** | acidanthera/Lilu | BSD-3-Clause |
| VirtualSMC (+ SMCProcessor, SMCSuperIO, SMCBatteryManager) | **1.3.7** | acidanthera/VirtualSMC | BSD-3-Clause |
| WhateverGreen | **1.7.0** | acidanthera/WhateverGreen | BSD-3-Clause |
| AppleALC | **1.9.7** | acidanthera/AppleALC | BSD-3-Clause |
| itlwm | **2.3.0** | OpenIntelWireless/itlwm | GPLv2 |
| AirportItlwm (Sonoma 14.4 build, *optional/stashed*) | **2.3.0** | OpenIntelWireless/itlwm | GPLv2 |
| IntelBluetoothFirmware | **2.4.0** | OpenIntelWireless/IntelBluetoothFirmware | GPLv2 |
| BlueToolFixup (from BrcmPatchRAM) | **2.7.2** | acidanthera/BrcmPatchRAM | BSD-3-Clause |
| RealtekRTL8111 | **3.0.0** | Mieze/RTL8111_driver_for_OS_X | GPLv2 |
| ECEnabler | **1.0.6** | 1Revenger1/ECEnabler | BSD-3-Clause |
| CpuTscSync | **1.1.2** | acidanthera/CpuTscSync | BSD-3-Clause |
| BrightnessKeys | **1.0.3** | acidanthera/BrightnessKeys | BSD-3-Clause |
| VoodooPS2Controller (+ VoodooInput, VoodooPS2Keyboard) | **2.3.7** | acidanthera/VoodooPS2 | (see repo) |
| VoodooI2C (+ VoodooGPIO, VoodooI2CServices) + VoodooI2CHID | **2.9.1** | VoodooI2C/VoodooI2C | MIT |
| USBToolBox + UTBDefault (temporary port map) | **1.2.0** | USBToolBox/kext | (see repo) |

`RestrictEvents 1.1.6` is downloaded by the fetch script but **not** in the EFI — it is
only needed for the macOS Tahoe upgrade path (`revpatch=sbvmm`).

## ACPI (SSDTs)

Taken verbatim from the reference EFI
([luchina-gabriel](https://github.com/luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i-10300H-10750H-i5-i7-iGPU));
built for this exact board:

```
SSDT-AWAC   SSDT-DISABLE-NVIDIA   SSDT-EC-USBX   SSDT-GPI0   SSDT-GPRW
SSDT-HPET   SSDT-MCHC            SSDT-PLUG      SSDT-PNLF-CFL   SSDT-TPD0
```

plus 4 ACPI rename patches in `config.plist` (`_CRS`→`XCRS` on HPET, `GPRW`→`XPRW`,
RTC IRQ fix, `_DSM`→`XDSM`).

## macOS installer

`scripts/download-macos.sh` pulls a **Sequoia 15.7.4** recovery (`BaseSystem.dmg`) via
OpenCore's `macrecovery.py` using board id `Mac-7BA5B2D9E42DDD94`. It is a *network*
installer — the full OS downloads during install, so use Ethernet.
