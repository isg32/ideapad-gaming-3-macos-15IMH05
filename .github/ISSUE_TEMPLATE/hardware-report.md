---
name: Hardware report / result
about: Share how this EFI worked (or didn't) on your 15IMH05
title: "[report] <macOS version> — <works / boot fail / partial>"
labels: report
---

## Machine
- Machine type (`cat /sys/class/dmi/id/product_version`):
- BIOS version (`cat /sys/class/dmi/id/bios_version`):
- CPU (i5-10300H / i7-10750H):
- Wi-Fi card (Intel AX201 / Realtek RTL8822CE / other):
- Touchpad (Synaptics `SYNA0001` / ELAN / not sure):

## Software
- EFI used (commit hash or Release tag):
- OpenCore version:
- macOS version installed:
- SMBIOS: generated with `gen-smbios.sh`? yes / no

## Result
- [ ] Installer boots
- [ ] Installs to disk
- [ ] Boots installed system
- [ ] Graphics acceleration (About This Mac shows "1536 MB")
- [ ] Wi-Fi (itlwm + HeliPort)
- [ ] Bluetooth
- [ ] Audio out / mic
- [ ] Trackpad gestures
- [ ] Ethernet
- [ ] Battery %
- [ ] Sleep/wake

### What broke / notes
<last visible line before a hang, photos, `opencore-*.txt` from the USB root>

## `lspci -nn`
```
```

## `lsusb`
```
```
