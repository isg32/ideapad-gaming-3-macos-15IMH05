# Changelog

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
