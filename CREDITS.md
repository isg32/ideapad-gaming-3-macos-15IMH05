# Credits & licenses

This repository redistributes third-party binaries in `EFI/` for convenience. None of
them are the work of this repo's authors. Each is under its own upstream license.

| Project | Author | License | Used for |
|---|---|---|---|
| [OpenCore](https://github.com/acidanthera/OpenCorePkg) | Acidanthera | BSD-3-Clause | bootloader |
| [OcBinaryData](https://github.com/acidanthera/OcBinaryData) | Acidanthera | BSD-3-Clause | HfsPlus.efi, GUI resources |
| [Lilu](https://github.com/acidanthera/Lilu) | vit9696 / Acidanthera | BSD-3-Clause | kext platform |
| [VirtualSMC](https://github.com/acidanthera/VirtualSMC) | Acidanthera | BSD-3-Clause | SMC emulation, sensors, battery |
| [WhateverGreen](https://github.com/acidanthera/WhateverGreen) | Acidanthera | BSD-3-Clause | iGPU patching |
| [AppleALC](https://github.com/acidanthera/AppleALC) | Acidanthera | BSD-3-Clause | audio (ALC257) |
| [VoodooPS2](https://github.com/acidanthera/VoodooPS2) | Acidanthera / RehabMan lineage | GPLv2 + APSL | PS/2 keyboard |
| [BrcmPatchRAM](https://github.com/acidanthera/BrcmPatchRAM) | Acidanthera | BSD-3-Clause | BlueToolFixup |
| [CpuTscSync](https://github.com/acidanthera/CpuTscSync) | Acidanthera | BSD-3-Clause | TSC sync |
| [BrightnessKeys](https://github.com/acidanthera/BrightnessKeys) | Acidanthera | BSD-3-Clause | brightness Fn keys |
| [RestrictEvents](https://github.com/acidanthera/RestrictEvents) | Acidanthera | BSD-3-Clause | (Tahoe path only) |
| [itlwm / AirportItlwm](https://github.com/OpenIntelWireless/itlwm) | OpenIntelWireless | GPLv2 | Intel AX201 Wi-Fi |
| [IntelBluetoothFirmware](https://github.com/OpenIntelWireless/IntelBluetoothFirmware) | OpenIntelWireless | GPLv2 | Intel AX201 Bluetooth |
| [HeliPort](https://github.com/OpenIntelWireless/HeliPort) | OpenIntelWireless | GPLv3 | Wi-Fi client app (not bundled; install separately) |
| [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) | VoodooI2C / Alexandre Daoud | MIT | Synaptics I2C trackpad |
| [RealtekRTL8111](https://github.com/Mieze/RTL8111_driver_for_OS_X) | Mieze | GPLv2 | RTL8111 Ethernet |
| [ECEnabler](https://github.com/1Revenger1/ECEnabler) | 1Revenger1 | BSD-3-Clause | battery EC field reads |
| [USBToolBox kext](https://github.com/USBToolBox/kext) | USBToolBox | Custom (non-commercial) | temporary USB port map |

### Base EFI

The `config.plist`, DeviceProperties and all SSDTs originate from
**[luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i](https://github.com/luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i-10300H-10750H-i5-i7-iGPU)**
and the Universo Hackintosh community. This repo ports that work to OpenCore 1.0.7 /
macOS Sequoia and adds Linux build tooling.

### Guides

- [Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [Dortania: macOS 26 Tahoe notes](https://dortania.github.io/OpenCore-Install-Guide/extras/tahoe.html)

If you are a listed author and want attribution changed or a component removed, open an issue.
