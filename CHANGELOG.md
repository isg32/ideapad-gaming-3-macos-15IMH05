# Changelog

## Unreleased — boot fixes for BIOS EGCN41WW (Insyde/Lenovo)

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
