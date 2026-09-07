# Contributing

This EFI is maintained by people who own the laptop. Useful contributions:

## Report a result
Open an issue with the **Hardware report** template. Always include:
- machine type (`cat /sys/class/dmi/id/product_version`) and BIOS version
- `lspci -nn` and `lsusb` (or `docs/HARDWARE.md` regenerated on your unit)
- macOS version, OpenCore version, which `EFI` you used
- what works / what doesn't, and the last line before any hang (photo is fine)
- for boot failures: attach the `opencore-*.txt` from the USB root

## Variants we'd like data on
- **i7-10750H** units (should be identical — confirm)
- **ELAN** touchpad instead of Synaptics (`\_SB.PCI0.I2C1.TPD0` device id differs) —
  needs `VoodooI2CELAN` or an ELAN SSDT
- **Realtek RTL8822CE** Wi-Fi units — different kext path entirely
- other BIOS versions (CFG-Lock / DVMT behaviour)

## Changing the EFI
- Don't hand-edit `EFI/OC/config.plist` for anything the build script can do — change
  `scripts/build-efi.py` so the result is reproducible.
- Bump component versions in `scripts/fetch-components.sh`, not by dropping binaries in.
- Run `python3 scripts/build-efi.py` and make sure `ocvalidate` still passes before PR.
- Never commit a real SMBIOS serial. `EFI/` must keep placeholder values; personal
  serials live in `EFI-local/` (git-ignored).

## Keep it honest
If something is flaky, document it as flaky. This README's "what works" table is a
promise to the next person with this laptop.
