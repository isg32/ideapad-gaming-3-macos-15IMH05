# Hackintosh install runbook — Lenovo IdeaPad Gaming 3 15IMH05 → macOS Sequoia 15

Full walkthrough: prep on Linux, then the parts that need you physically at the laptop.
Assumes you've run `scripts/fetch-components.sh`, `scripts/build-efi.py` and
`scripts/gen-smbios.sh` (see the main README).

---

## What was built

| Item | Path | Notes |
|---|---|---|
| OpenCore EFI (shareable, placeholder SMBIOS) | `EFI/` | OpenCore **1.0.7**, `ocvalidate` clean |
| OpenCore EFI (yours, real SMBIOS) | `EFI-local/` | made by `scripts/gen-smbios.sh`; git-ignored |
| macOS recovery | `build/recovery/com.apple.recovery.boot/` | Sequoia **15.7.4** BaseSystem (network installer) |
| USB writer | `scripts/make-usb.sh` | run with `sudo` |
| Rebuild scripts | `scripts/fetch-components.sh`, `scripts/build-efi.py` | re-generate `EFI/` from pinned sources |

### EFI contents

- **SMBIOS**: `MacBookPro16,1`. The committed `EFI/` has placeholder serials;
  `scripts/gen-smbios.sh` writes real ones into `EFI-local/`. They're randomly generated
  — fine for install; **regenerate on macOS with GenSMBIOS if you want iMessage/FaceTime**
  (see Post-install).
- **boot-args**: `-v keepsyms=1 debug=0x100 -igfxblr igfxonln=1`
  (verbose + logging for first boots; trimmed later)
- **audio**: ALC257 `layout-id 11` via DeviceProperties (proven value from the reference EFI)
- **iGPU**: UHD 630 spoofed to `device-id 0x3E9B`, `AAPL,ig-platform-id 0x3E9B0009`,
  DVMT stolen-mem framebuffer patch — proven values for this laptop
- **NVIDIA GTX 1650**: hard-disabled by `SSDT-DISABLE-NVIDIA.aml`
- **ACPI**: 10 SSDTs from the proven luchina-gabriel EFI (AWAC, EC-USBX, GPI0, GPRW,
  HPET, MCHC, PLUG, PNLF-CFL, TPD0, DISABLE-NVIDIA) + 4 ACPI rename patches
- **Kexts** (all current releases, Oct 2025–Mar 2026):
  Lilu 1.7.2, VirtualSMC 1.3.7 (+SMCProcessor/SMCSuperIO/SMCBatteryManager),
  WhateverGreen 1.7.0, AppleALC 1.9.7, **itlwm 2.3.0** (Wi-Fi — needs HeliPort),
  IntelBluetoothFirmware 2.4.0 + BlueToolFixup 2.7.2, RealtekRTL8111 3.0.0,
  ECEnabler 1.0.6, CpuTscSync 1.1.2, BrightnessKeys 1.0.3,
  VoodooPS2Controller 2.3.7 (keyboard), VoodooI2C 2.9.1 + VoodooI2CHID (trackpad),
  **USBToolBox + UTBDefault** (temporary "all USB ports on" — replace with a real map
  post-install). `USBMap.kext` (chassis map from the reference EFI) is staged but
  **disabled**.
- **SecureBootModel**: `Disabled`, **SIP**: enabled, **ScanPolicy**: 0 (shows Fedora too)

---

## Step 1 — BIOS settings

Reboot, tap **F2** (or Fn+F2) at the Lenovo logo.

- **Security → Secure Boot → Disabled** (already is on your machine)
- **Boot → Boot Mode → UEFI** (no CSM/Legacy)
- **Configuration → check that SATA is AHCI** (it is — no RAID/Optane option on this model)
- There is **no BIOS option** to disable the NVIDIA GPU or unlock CFG-Lock — both are
  handled in the EFI. Nothing to do.
- Save & exit (F10).

---

## Step 2 — Write the install USB (on Fedora)

Wait until the recovery download has finished:

```
bash scripts/download-macos.sh                      # if not already downloaded
ls -lh build/recovery/com.apple.recovery.boot/     # BaseSystem.dmg should be ~2 GB
```

Plug in the **64 GB flash drive**. Find its device node — it will be `/dev/sdX`
(NOT `sda`, NOT `nvme0n1`):

```
lsblk -o NAME,SIZE,TRAN,MODEL,MOUNTPOINT
```

Then (this **erases the flash drive**):

```
sudo bash scripts/make-usb.sh /dev/sdX
```

The script uses `EFI-local/` if present (else `EFI/`), guards against writing to
`sda`/`nvme0n1`, shows you the target, and asks you to type `ERASE` to confirm. When done
you'll have one FAT32 partition `INSTALL` containing `/EFI` and `/com.apple.recovery.boot`.

---

## Step 3 — Install macOS

1. **Plug an Ethernet cable in** (the network installer downloads ~15 GB during install;
   Wi-Fi is not available in the installer). USB tethering from a phone also works.
2. Plug the USB into a **left-side USB-A port**. Power on, tap **F12** → pick the
   **UEFI USB** entry (not the plain one).
3. OpenCore picker appears → choose **"macOS Base System"** (EFI Boot / reset NVRAM entry
   also shown — ignore).
4. If it reaches the macOS Utilities screen: open **Disk Utility**.
   - View → **Show All Devices**
   - Select the **whole ~477 GB SATA SSD** (top-level "Secure Net" device, *not* a
     sub-volume) → **Erase**
   - Name `Macintosh HD`, Format **APFS**, Scheme **GUID Partition Map** → Erase
   - Quit Disk Utility
5. **Reinstall macOS Sequoia** → agree → target **Macintosh HD** → Install.
6. The laptop reboots itself several times. **Each reboot: F12 → UEFI USB**, and in the
   OpenCore picker choose:
   - first the entry named **"macOS Installer"** (a few times, ~20–40 min while it
     downloads + installs),
   - then finally **"Macintosh HD"**.
7. At the Setup Assistant, skip Wi-Fi (use the Ethernet cable), create your account.

---

## Step 4 — First successful boot

You're booting off the **USB's** OpenCore still. Make the internal SSD self-sufficient:

1. Download **MountEFI** or use Hackintool / `diskutil`:
   ```
   diskutil list                       # find the SATA disk's EFI partition, e.g. disk0s1
   sudo diskutil mount disk0s1         # internal SSD ESP  (should be empty / just have EFI/)
   sudo diskutil mount disk2s1         # the USB's ESP (INSTALL)  -- adjust numbers
   sudo cp -R /Volumes/EFI\ 1/EFI /Volumes/EFI/     # copy USB EFI -> internal ESP
   ```
   (Simplest: mount both, copy the `EFI` folder from the USB volume onto the internal
   SSD's EFI volume.)
2. Reboot **without** pressing F12 — it should boot straight to Macintosh HD from the
   internal SSD. If the Lenovo firmware doesn't pick it up automatically, see
   Troubleshooting → "laptop won't boot without the USB".

---

## Step 5 — Post-install fixes

### 5a. Wi-Fi (Intel AX201)
`itlwm` presents the connection as Ethernet and is driven by an app:
- Download **HeliPort** (github.com/OpenIntelWireless/HeliPort) → put in `/Applications`,
  launch, add it to Login Items.
- It gives you a Wi-Fi-style menu; connect normally. Internet works fully; AirDrop/Handoff
  do not (that needs a Broadcom/Fenvi card — optional hardware swap later).
- *Optional upgrade:* a nightly `AirportItlwm` build for Sequoia (OpenIntelWireless nightly)
  restores the native Wi-Fi menu. Swap `itlwm.kext` → `AirportItlwm.kext` in
  `EFI/OC/Kexts` and update `config.plist` if you want it.

### 5b. USB port map (do this once)
The EFI currently uses `USBToolBox` + `UTBDefault` = every port on, no 15-port trimming.
To get proper USB power management + reliable sleep:
- Download **USBToolBox** app (github.com/USBToolBox/tool), run it, select the
  `XHC` controller, plug a USB2 **and** USB3 stick into **every physical port** (incl.
  the internal webcam/BT which show as ports), mark each, **Export → `UTBMap.kext`**.
- Put `UTBMap.kext` in `EFI/OC/Kexts`, add it to `config.plist` Kernel→Add, keep
  `USBToolBox.kext`, **remove `UTBDefault.kext`** from Kernel→Add. Rebuild kext order.

### 5c. Audio (Realtek ALC257)
The EFI sets `layout-id 11` on `PciRoot(0x0)/Pci(0x1F,0x3)` (the proven value for this
laptop). If no sound or no headphone-jack switching, add boot-arg `alcid=<n>` to override
and reboot, trying: **11, 13, 21, 22, 28, 66, 99**. Bake the working value into the
`layout-id` DeviceProperty and drop `alcid`.
(Sequoia keeps `AppleHDA`, so `AppleALC` works normally — this is just codec layout tuning.)

### 5d. Trim boot-args
Once stable, in `config.plist` set boot-args to just:
`-igfxblr igfxonln=1 alcid=<working id>` and `Misc → Debug → Target = 0`,
`Misc → Boot → Timeout = 5`.

### 5e. Battery / brightness
`ECEnabler` + `SMCBatteryManager` should give a correct % immediately.
`BrightnessKeys` + `SSDT-PNLF-CFL` give the brightness slider and Fn keys.

### 5f. iMessage / FaceTime (only if you need them)
Generate a fresh SMBIOS **on macOS**: run [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS),
pick `MacBookPro16,1`, paste the new Serial / MLB / SmUUID / ROM into
`config.plist → PlatformInfo → Generic`. Then Apple ID sign-in for iServices.
(The `scripts/gen-smbios.sh` serials are structurally valid but randomly generated.)

---

## Step 6 — Dual-boot with Fedora

- Fedora is untouched on the **NVMe**; macOS is on the **SATA SSD**, each with its own ESP.
- Pick the OS at power-on with **F12**: NVMe entry = Fedora, SATA entry = macOS.
- OpenCore's picker (`ScanPolicy = 0`) will also list Fedora's bootloader; you can boot
  Fedora through it too.
- Do **not** point macOS's OpenCore at the NVMe ESP. `WriteFlash` is on but only touches
  the ESP OpenCore booted from.
- macOS updates only ever touch the SATA disk.

---

## Troubleshooting — common first-boot stalls

| Symptom (last visible line / behaviour) | Fix |
|---|---|
| Stuck at `[EB|#LOG:EXITBS:START]` | firmware map issue — in `config.plist` toggle `Booter → Quirks → RebuildAppleMemoryMap = true`, and if still stuck also `EnableWriteUnprotector = false` + `ProtectUefiServices = true` (already set) |
| Reboots instantly at the Apple logo | usually SMBIOS/CPU PM — confirm `AppleXcpmCfgLock = true` (it is). If it persists, add `Kernel → Quirks → AppleCpuPmCfgLock = true` |
| Stuck ~30 s then panic mentioning `AppleIntelCPUPowerManagement` | `AppleXcpmCfgLock`/`AppleCpuPmCfgLock` not taking — use `ControlMsrE2.efi` (in `EFI/OC/Tools`, add to `Misc → Tools`) to check if CFG-Lock can be cleared |
| Hang right after `+++++++...` with no GPU accel / black screen after picker | iGPU: try boot-arg `-igfxvesa` to get to desktop, then verify `AAPL,ig-platform-id`; alternate id `00001B3E` / device-id `9B3E0000` |
| Black screen but disk active (installer) | add `igfxonln=1` (present) / try removing `-igfxblr`; plug in external nothing (HDMI is dead — it's on the NVIDIA) |
| `Waiting for root device` / no install disk | USB: move to the other side's ports; ensure `USBToolBox.kext` + `UTBDefault.kext` both enabled |
| Trackpad dead, keyboard fine | `VoodooI2C` GPIO pin — confirm `SSDT-GPI0.aml` + `SSDT-TPD0.aml` loaded; check `\_SB.PCI0.I2C1.TPD0` in a full DSDT dump matches |
| No Ethernet in installer | `RealtekRTL8111.kext` is included; try a different cable/port; DHCP only |
| Laptop won't boot without the USB | mount internal ESP, ensure `/EFI/BOOT/BOOTx64.efi` + `/EFI/OC/` are there; then in macOS: `sudo bless --mount /Volumes/EFI --setBoot --file /Volumes/EFI/EFI/OC/OpenCore.efi` — or add a firmware boot entry with `efibootmgr` from Fedora |
| Kernel panic `IOPCIFamily` / NVIDIA | `SSDT-DISABLE-NVIDIA.aml` didn't apply — verify it's enabled in `config.plist → ACPI → Add` |

**Getting logs:** the EFI writes `opencore-YYYY-MM-DD-HHMMSS.txt` to the USB's root
(because `Misc → Debug → Target = 67`). Read it from Fedora after a failed boot.

---

## If you want to move to macOS Tahoe 26 later

Tahoe is the last Intel-capable macOS ever. After Sequoia is rock-solid:
1. Bump OpenCore + every kext to the newest release; keep `itlwm` + HeliPort.
2. Add boot-arg `-ibtcompatbeta` (Intel Bluetooth on Tahoe).
3. **Audio breaks** — Tahoe removed `AppleHDA`. Restore it with `VoodooHDA` via AuxKC, or
   re-inject `AppleHDA.kext` (perez987/AppleHDA-back-on-macOS-26-Tahoe). Both need SIP
   partially disabled.
4. `RestrictEvents` with `revpatch=sbvmm` for OTA updates.
5. iGPU / trackpad / Ethernet / battery carry over unchanged.
