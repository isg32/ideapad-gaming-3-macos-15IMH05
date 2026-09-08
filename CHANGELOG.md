# Changelog

## 2026-09-08 — full offline install verified on real hardware

macOS Sequoia 15 installed end-to-end **from Fedora** and now boots **from the internal
SATA SSD** on a real 15IMH05 (BIOS `EGCN41WW`).

- **A wired Ethernet connection was still required during the install** even on the
  "offline" path — the installer's prepare/personalize phase reaches Apple. What the
  offline USB removes is the **~15 GB OS payload download** (served from the local
  `InstallAssistant.pkg` instead), which is the part that made the flaky Wi-Fi/tether
  route fail. Plug in the RJ45 cable; `RealtekRTL8111` works in the installer.

- **iGPU acceleration and audio worked on the first boot** — no `alcid=` sweep, no
  framebuffer retuning needed. The ported `MacBookPro16,1` DeviceProperties are correct
  for this laptop as-is.
- **Wi-Fi**: `itlwm` + **HeliPort** — connects and stays connected. (No native menu /
  AirDrop, as expected for `itlwm`.)
- **Bluetooth**: kexts shipped but **not yet tested** on this unit.
- **EFI migrated to the internal SSD's ESP** (copy `EFI/` from the USB ESP → `disk0s1`)
  boots standalone with the USB removed. **Heads-up: the first boot from the migrated
  EFI can sit on a black screen for 5–6 minutes** (first-boot kext cache /
  prelinkedkernel rebuild) before the Apple logo. One-time only.
- Offline install method that actually worked: `pkgutil --expand-full` the
  `InstallAssistant.pkg` onto the target, then run `startosinstall` from the extracted
  app. `installer -pkg … -target` does **not** work against a non-`/` target for this
  package. RUNBOOK Step 3-OFFLINE updated to match.
- The offline USB's second partition is **HFS+** (`MACOS`), not exFAT — the Sequoia
  recovery has no exFAT mount support. `scripts/fix-usb-hfsplus.sh` reformats an
  already-built USB's second partition in place.

Still open: USBToolBox port map, sleep/wake, Bluetooth test, trimming the bring-up
`boot-args` / picker timeout.

## v1.0.0 follow-up — boot fixes for BIOS EGCN41WW (Insyde/Lenovo)

First install attempts on a real 15IMH05 (BIOS `EGCN41WW`, 2023-06-09) black-screened.
OpenCore's own log pinned each cause; all three fixes are now in `EFI/`:

1. **`Booter/Quirks/FixupAppleEfiImages = true`** — log showed
   `OCB: StartImage failed - Invalid Parameter`; this firmware rejects Apple's `boot.efi`
   PE image. Required for macOS 14+/Sequoia here.
2. **`BOOTx64.efi` is now the full `OpenCore.efi`, not the Bootstrap shim** — log showed
   `OCM: Failed to start image - Already started` at 19 ms; the shim can't chainload
   OpenCore on this firmware, so OpenCore never ran.
3. **`Booter/Quirks/RebuildAppleMemoryMap = true`** and
   **`Kernel/Quirks/AppleCpuPmCfgLock = true`** — cross-referenced from
   [gajjartejas/Lenovo-Ideapad-3-15IML05-Hackintosh](https://github.com/gajjartejas/Lenovo-Ideapad-3-15IML05-Hackintosh),
   a working macOS Sequoia 15.5 EFI on a Lenovo IdeaPad Comet Lake (Insyde firmware).

Also: `Misc/Debug/ApplePanic = true` (writes `panic-*.txt` to the ESP).

**Result:** the macOS installer boots on BIOS `EGCN41WW`. The OpenCore picker shows
`No name` / `install` / `install (dmg)` / `Reset NVRAM`; the plain `install` entry fails
with `StartImage - Already started`, **`install (dmg)` works** (OpenCore booting
`BaseSystem.dmg` directly). Bring-up picker settings for now: `Timeout=0`,
`HideAuxiliary=false`.

### Offline installer (flaky Ethernet)

- `scripts/download-macos.sh --full` — resolves + downloads the full Sequoia
  `InstallAssistant.pkg` (~15 GB, resumable) via `gibMacOS`, alongside the BaseSystem.
- `scripts/make-usb.sh` — auto-detects the `.pkg` and builds a **two-partition** USB:
  FAT32 `INSTALL` (EFI + BaseSystem, boots) + exFAT `MACOS` (`InstallAssistant.pkg`).
- `docs/RUNBOOK.md` → **Step 3-OFFLINE**: boot `install (dmg)`, erase the SSD, then in
  Terminal `installer -pkg /Volumes/MACOS/InstallAssistant.pkg -target "/Volumes/Macintosh HD"`
  followed by `startosinstall --volume …` — no network used.
- `fetch-components.sh` now also clones `gibMacOS`.

## 2026-09-07 — initial release

- OpenCore **1.0.7**, `ocvalidate` clean.
- Ported from the luchina-gabriel Sonoma EFI (OpenCore 0.9.8) for the IdeaPad Gaming 3
  15IMH05 to **macOS Sequoia 15**:
  - all kexts bumped to current releases (see `docs/COMPONENTS.md`)
  - Wi-Fi kext changed `AirportItlwm` → **`itlwm` + HeliPort** (no stable AirportItlwm
    build exists for Sequoia)
  - added `ECEnabler` (battery), `RestrictEvents` staged for the Tahoe path
  - `SecureBootModel` → `Disabled` for a clean first install
  - `config.plist` migrated to the 1.0.7 schema (`Booter/Quirks/ClearTaskSwitchBit`)
- SSDTs, DeviceProperties and ACPI patches unchanged from the reference (verified against
  a live 15IMH05: touchpad at `\_SB.PCI0.I2C1.TPD0`, dGPU at `\_SB.PCI0.PEG0.PEGP`).
- Linux-only build tooling: `fetch-components.sh`, `build-efi.py`, `gen-smbios.sh`,
  `download-macos.sh`, `make-usb.sh`.
- Committed `EFI/` ships **placeholder SMBIOS** — run `scripts/gen-smbios.sh`.
