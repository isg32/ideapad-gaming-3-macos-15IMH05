# Lenovo IdeaPad Gaming 3 15IMH05 — Hackintosh (macOS Sequoia, OpenCore)

An OpenCore EFI + build/install scripts for turning the **Lenovo IdeaPad Gaming 3
15IMH05** (10th‑gen Comet Lake‑H, Intel UHD 630) into a Hackintosh running **macOS
Sequoia 15**.

Built and installed **entirely from Linux** — no existing Mac needed.

> **Status: bring-up.** The macOS installer now **boots** on real hardware (BIOS
> `EGCN41WW`, Insyde) after several firmware quirks — pick the **`install (dmg)`** entry
> in the OpenCore picker. Full install + first boot of the installed system still being
> validated. Boot fixes landed after `v1.0.0` — **use `EFI/` from `main`, not the
> v1.0.0 asset.** See [`CHANGELOG.md`](CHANGELOG.md) and the "Firmware quirks" section
> in [`docs/RUNBOOK.md`](docs/RUNBOOK.md).

| | |
|---|---|
| **Bootloader** | OpenCore 1.0.7 (`ocvalidate` clean) |
| **Target OS** | macOS Sequoia 15.x (14 Sonoma also works with the same EFI) |
| **SMBIOS** | `MacBookPro16,1` |
| **Base** | ported from [luchina‑gabriel's Sonoma EFI](https://github.com/luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i-10300H-10750H-i5-i7-iGPU) for this exact model |

> ⚠️ **macOS Tahoe 26** is intentionally *not* the target — Apple removed `AppleHDA` in
> Tahoe, which breaks analog audio on every Hackintosh. Sequoia is the sweet spot. A
> Tahoe upgrade path is documented in [`docs/RUNBOOK.md`](docs/RUNBOOK.md).

---

## Is this your laptop?

Machine type **81Y4** / board **LNVNB161216**. Check `Model name` in `lscpu` and the
sticker under the laptop.

| Component | This EFI targets | Notes |
|---|---|---|
| CPU | Intel Core **i5‑10300H** (Comet Lake‑H) | i7‑10750H works too — same silicon |
| iGPU | Intel **UHD Graphics 630** `8086:9BC4` | spoofed to `0x3E9B`, full QE/CI |
| dGPU | NVIDIA **GTX 1650 Mobile** `10DE:1F99` | **unsupported by macOS — disabled via SSDT** |
| Wi‑Fi | Intel **Wi‑Fi 6 AX201** (CNVi) | non‑native, see below |
| Ethernet | Realtek **RTL8168/8111** `10EC:8168` | |
| Audio | Realtek **ALC257** `10EC:0257` | `layout-id 11` |
| Touchpad | **Synaptics I2C‑HID** `SYNA0001` @ `\_SB.PCI0.I2C1.TPD0` | some units ship ELAN — see RUNBOOK |
| Keyboard | PS/2 | |
| RAM | DDR4 (16 GB tested) | |

If your Wi‑Fi card is **Realtek RTL8822CE** instead of the Intel AX201, this EFI's
Wi‑Fi/Bluetooth won't work as‑is — swap the M.2 card or adapt the kexts.

---

## What works

| ✅ Working | ⚠️ Partial | ❌ Not working |
|---|---|---|
| iGPU acceleration (QE/CI), brightness | **Wi‑Fi** — via `itlwm` + HeliPort app; no native menu, no AirDrop/Handoff | **HDMI out** — port is wired to the NVIDIA dGPU |
| Internal display, backlight, Fn brightness | **Bluetooth** — works, occasionally needs a re‑pair after cold boot | **NVIDIA GPU** — no macOS driver, permanently off |
| Audio: speakers, headphone jack, internal mic | **Sleep/wake** — unreliable on this chassis (as on the reference EFI) | External display over USB‑C — this model has **no** DP‑Alt (DisplayLink adapter only) |
| Keyboard + all Fn keys | USB‑C — data only | |
| Trackpad (gestures, tap, two‑finger) | | |
| Ethernet (RTL8111) | | |
| Battery %, AC detection | | |
| USB ports (temp map; make a real one post‑install) | | |
| CPU power management (native `MacBookPro16,1` plugin‑type) | | |

---

## Quick start

### Option A — use the prebuilt EFI

1. Grab the `EFI/` folder from this repo (or a [Release](../../releases)).
2. **Generate your own SMBIOS** — the committed `config.plist` ships placeholder serials:
   ```bash
   bash scripts/fetch-components.sh      # gets macserial + components
   bash scripts/gen-smbios.sh            # writes EFI-local/ with fresh MacBookPro16,1 IDs
   ```
3. Download a macOS Sequoia installer and write the USB (from Linux):
   ```bash
   bash scripts/download-macos.sh                 # -> build/recovery/
   lsblk -o NAME,SIZE,TRAN,MODEL                  # find your flash drive, e.g. /dev/sdb
   sudo bash scripts/make-usb.sh /dev/sdX         # WIPES the flash drive
   ```
4. Follow [`docs/RUNBOOK.md`](docs/RUNBOOK.md) for BIOS settings, the install, and
   post‑install (Wi‑Fi via HeliPort, real USB map, audio layout).

### Option B — rebuild the EFI from scratch

```bash
bash   scripts/fetch-components.sh     # download pinned OpenCore + kexts
python3 scripts/build-efi.py           # assemble ./EFI/ (placeholder SMBIOS) + ocvalidate
bash   scripts/gen-smbios.sh           # -> ./EFI-local/ with your own serials
```

Pinned component versions live at the top of `scripts/fetch-components.sh` and in
[`docs/COMPONENTS.md`](docs/COMPONENTS.md).

---

## Repo layout

```
EFI/                     ready-to-use OpenCore EFI (placeholder SMBIOS — regenerate!)
EFI-local/               your personalised EFI (git-ignored, created by gen-smbios.sh)
scripts/
  fetch-components.sh    download pinned OpenCore + kexts -> build/downloads/
  build-efi.py           assemble EFI/ from build/downloads/
  gen-smbios.sh          generate MacBookPro16,1 serials -> EFI-local/
  download-macos.sh      fetch a macOS Sequoia recovery installer (Linux)
  make-usb.sh            partition + write the install USB (needs sudo)
docs/
  RUNBOOK.md             full step-by-step install + troubleshooting
  HARDWARE.md            detected PCI/ACPI IDs from a real 15IMH05
  COMPONENTS.md          pinned versions + upstream links
build/                   local scratch (git-ignored): downloads, recovery image, work
```

---

## Credits

This is a re‑pack, not original reverse‑engineering. Standing on:

- **[Acidanthera](https://github.com/acidanthera)** — OpenCore, Lilu, VirtualSMC,
  WhateverGreen, AppleALC, VoodooPS2, BrcmPatchRAM, CpuTscSync, BrightnessKeys, RestrictEvents
- **[luchina‑gabriel](https://github.com/luchina-gabriel/EFI-NOTEBOOK-LENOVO-IDEAPAD-GAMING-3i-10300H-10750H-i5-i7-iGPU)**
  and the Universo Hackintosh community — the original 15IMH05 EFI, SSDTs and DeviceProperties
- **[OpenIntelWireless](https://github.com/OpenIntelWireless)** — itlwm / AirportItlwm,
  IntelBluetoothFirmware, HeliPort
- **[VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)**, **[Mieze](https://github.com/Mieze/RTL8111_driver_for_OS_X)**,
  **[USBToolBox](https://github.com/USBToolBox)**, **[1Revenger1/ECEnabler](https://github.com/1Revenger1/ECEnabler)**
- **[Dortania OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/)**

See [`CREDITS.md`](CREDITS.md) for per‑component versions and licenses.

## Disclaimer

Running macOS on non‑Apple hardware violates Apple's EULA. This is provided for
education and interoperability research. No warranty. You are responsible for your
data — back up before touching partitions.
