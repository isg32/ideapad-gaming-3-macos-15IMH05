# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Not a software project — a **Hackintosh OpenCore EFI plus Linux-only build tooling** for
one specific machine: the Lenovo IdeaPad Gaming 3 **15IMH05** (Core i5‑10300H, Comet
Lake‑H, Intel UHD 630), target **macOS Sequoia 15**, SMBIOS `MacBookPro16,1`. There is no
compiler and no unit-test suite; the "build" assembles an `EFI/` folder and validates it
with `ocvalidate`. Everything is designed to run on Fedora/Linux with no Mac involved.

Status: a full offline install has been completed on real hardware and macOS boots from
the internal SATA SSD. Remaining polish items are tracked at the top of `CHANGELOG.md`.

## The pipeline

```
scripts/fetch-components.sh   # download pinned OpenCore + kexts + reference EFI -> build/downloads/
scripts/build-efi.py          # assemble ./EFI/ from build/downloads/, then run ocvalidate
scripts/gen-smbios.sh         # generate real MacBookPro16,1 serials -> ./EFI-local/ (git-ignored)
scripts/download-macos.sh     # macOS installer media -> build/recovery/ (add --full for build/fullinstaller/)
sudo bash scripts/make-usb.sh /dev/sdX   # partition + write the install USB
scripts/offline-install.sh    # runs in the macOS installer Terminal (pkgutil --expand-full + startosinstall)
```

CI (`.github/workflows/build.yml`) runs only the first three steps: `fetch-components.sh`,
`build-efi.py`, then `ocvalidate EFI/OC/config.plist`. On a `v*` tag it zips `EFI/` +
the three `docs/*.md` and attaches them to the GitHub release.

Common commands:
- Rebuild the shareable EFI: `python3 scripts/build-efi.py` (writes `./EFI/` with
  placeholder SMBIOS; prints the `ocvalidate` result at the end).
- Rebuild your personal EFI: `bash scripts/gen-smbios.sh` (writes `./EFI-local/`).
- Validate a config by hand: `build/downloads/oc-rel/Utilities/ocvalidate/ocvalidate.linux EFI/OC/config.plist`.
- Bump a component: edit the pinned version at the top of `scripts/fetch-components.sh`,
  re-run it, then rebuild. Never drop binaries into `EFI/` by hand.
- Build tooling deps: `python3`, `unzip`, `curl`, `git`; for USB creation also
  `dosfstools`, `util-linux` (sfdisk/partprobe) and `hfsplus-tools` (`mkfs.hfsplus`).

`sudo` on this machine requires a password — the user must run `make-usb.sh` /
`fix-usb-hfsplus.sh` themselves.

## Architecture — how the EFI is produced

**`scripts/build-efi.py` is the single source of truth for the EFI.** It loads the proven
`config.plist` from the vendored luchina‑gabriel reference EFI
(`build/downloads/refEFI-luchina/`) and applies a small, individually commented delta:
port to the OpenCore 1.0.7 schema, swap kexts to current pinned releases, swap Wi‑Fi to
`itlwm` (no stable AirportItlwm for Sequoia), set `MacBookPro16,1` SMBIOS, set bring-up
`boot-args` / picker / debug options, and add the BIOS-specific quirks below. The
SSDTs and DeviceProperties are copied from the reference unchanged.

Do **not** hand-edit `EFI/OC/config.plist` or drop kexts into `EFI/OC/Kexts/` for
anything the script can express — change `build-efi.py` so the output stays reproducible
(`CONTRIBUTING.md` makes this a rule). `EFI/` is committed on purpose (redistributed
third-party binaries; see `CREDITS.md`); `build/` and `EFI-local/` are git-ignored.

Load-order matters: the `KEXTS` list in `build-efi.py` is strict — Lilu first, each
parent kext before its plugins.

### Non-obvious invariants (breaking these black-screens the laptop)

- **`EFI/BOOT/` is a full mirror of `EFI/OC/`** — `config.plist` plus
  `ACPI/Drivers/Kexts/Resources/Tools` — and **`BOOT/BOOTx64.efi` is a copy of the full
  `OpenCore.efi`, not the Bootstrap shim.** BIOS `EGCN41WW` (Insyde) runs
  `\EFI\BOOT\BOOTx64.efi` directly and the shim fails with `EFI_ALREADY_STARTED`; the
  full binary then looks for its config/ACPI/Kexts *next to itself*, hence the mirror.
  Any change to payload assembly in `build-efi.py` must keep both copies in sync.
- **Firmware quirks for BIOS `EGCN41WW`**, set in `build-efi.py` with inline reasons:
  `Booter/Quirks/FixupAppleEfiImages`, `Booter/Quirks/RebuildAppleMemoryMap`,
  `Kernel/Quirks/AppleCpuPmCfgLock` (BIOS has no CFG-Lock unlock; `AppleXcpmCfgLock` is
  already on). Removing any of these needs a re-test on real hardware. The symptom→fix
  table is in `docs/RUNBOOK.md` ("Firmware quirks — BIOS EGCN41WW").
- **`EFI/` must ship PLACEHOLDER SMBIOS** (`CHANGEME-RUN-GENSMBIOS`, zero UUID/ROM).
  Real serials only ever live in `EFI-local/`. CI and `CONTRIBUTING.md` enforce this;
  never commit a real `SystemSerialNumber` / `MLB` / `SystemUUID` / `ROM`.
- The committed EFI is still on **bring-up settings** on purpose: verbose+debug
  `boot-args`, `Misc/Boot/Timeout=0`, `HideAuxiliary=False`, `Misc/Debug/Target=67`
  (logs to the ESP). Trimming these to production values is an open item in `CHANGELOG.md`.
- `USBToolBox.kext` + `UTBDefault.kext` = "all USB ports on" placeholder; the chassis
  `USBMap.kext` from the reference is copied in but staged **disabled**. A real port map
  is a post-install task.

### Hardware-specific facts

- iGPU UHD 630 is spoofed to `device-id 0x3E9B`, `AAPL,ig-platform-id 0x3E9B0009` with a
  DVMT stolen-mem framebuffer patch — proven values for this exact panel.
- NVIDIA GTX 1650 Mobile is unsupported and **hard-disabled** by `SSDT-DISABLE-NVIDIA`
  (`\_SB.PCI0.PEG0.PEGP._OFF`). HDMI is wired to the dGPU, so there is no external video.
- Touchpad is Synaptics I2C‑HID at `\_SB.PCI0.I2C1.TPD0` (`SSDT-GPI0` + `SSDT-TPD0`);
  some units ship ELAN and need different handling.
- Wi‑Fi (Intel AX201) runs via `itlwm` + the HeliPort app — no native Wi‑Fi menu.
- Real PCI/USB IDs from the actual unit are in `docs/HARDWARE.md`.

### The macOS installer paths

`download-macos.sh` (no args) fetches a small recovery `BaseSystem` that downloads ~15 GB
during install; `--full` also downloads the complete `InstallAssistant.pkg` for an
offline install. Either way a **wired Ethernet connection is still required** — even the
offline installer's prepare/personalize phase contacts Apple; the `.pkg` only removes the
big OS-payload download. The offline USB's second partition is **HFS+** (`fix-usb-hfsplus.sh`),
not exFAT — the Sequoia recovery cannot mount exFAT. On the target, `InstallAssistant.pkg`
must be extracted with `pkgutil --expand-full` and installed via `startosinstall`;
`installer -pkg … -target <non-/>` does not work for this package.

## Docs are a contract

`CONTRIBUTING.md`: the README "what works" table and `CHANGELOG.md` must stay honest —
document flaky things as flaky. When behaviour on real hardware changes, update
`README.md` (status block + table), `CHANGELOG.md`, and the relevant `docs/RUNBOOK.md`
step together. `docs/COMPONENTS.md` mirrors the pinned versions in `fetch-components.sh`.

Commit messages in this repo use conventional-commit prefixes: `feat:`, `fix:`, `docs:`,
`efi:`.
