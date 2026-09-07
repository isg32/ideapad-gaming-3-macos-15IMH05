# Hardware — Lenovo IdeaPad Gaming 3 15IMH05

Detected on a real unit running Fedora Linux. Use this to confirm your machine matches
before flashing, and as a reference when adapting the EFI.

## System
```
sys_vendor    : LENOVO
product_name  : 81Y4
product_version (machine type) : IdeaPad Gaming 3 15IMH05
board_name    : LNVNB161216
BIOS          : EGCN41WW (06/09/2023)
CPU           : Intel(R) Core(TM) i5-10300H CPU @ 2.50GHz
```

## PCI (`lspci -nn`)
```
00:02.0 VGA compatible controller [0300]: Intel Corporation CometLake-H GT2 [UHD Graphics] [8086:9bc4] (rev 05)
00:14.0 USB controller [0c03]: Intel Corporation 400 Series Chipset Family USB 3.2 Gen 2x1 (10 Gbs) xHCI Host Controller [8086:06ed]
00:14.3 Network controller [0280]: Intel Corporation 400 Series Chipset Family CNVi Wi-Fi [8086:06f0]
00:16.0 Communication controller [0780]: Intel Corporation 400 Series Chipset Family HECI #1 [8086:06e0]
00:17.0 SATA controller [0106]: Intel Corporation 400 Series Chipset Family SATA Controller (AHCI) (Mobile) [8086:06d3]
00:1f.0 ISA bridge [0601]: Intel Corporation HM470 Chipset LPC/eSPI Controller [8086:068d]
00:1f.3 Audio device [0403]: Intel Corporation 400 Series Chipset Family HD Audio [8086:06c8]
00:1f.4 SMBus [0c05]: Intel Corporation 400 Series Chipset Family SMBus [8086:06a3]
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile / Max-Q] [10de:1f99] (rev a1)
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:10fa] (rev a1)
06:00.0 Non-Volatile memory controller [0108]: KIOXIA Corporation NVMe SSD Controller BG4 (DRAM-less) [1e0f:0001]
0c:00.0 Ethernet controller [0200]: Realtek Semiconductor Co., Ltd. RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet Controller [10ec:8168] (rev 10)
```

## USB (`lsusb`)
```
Bus 001 Device 002: ID 04f2:b6c2 Chicony Electronics Co., Ltd Integrated Camera
Bus 001 Device 003: ID 8087:0026 Intel Corp. AX201 Bluetooth
```

## Key IDs used by the EFI

| Device | ID | Handling |
|---|---|---|
| iGPU UHD 630 (Comet Lake-H) | `8086:9BC4` | fake `device-id 0x3E9B`, `AAPL,ig-platform-id 0x3E9B0009`, DVMT stolen-mem patch |
| dGPU GTX 1650 Mobile (TU117M) | `10DE:1F99` | disabled: `SSDT-DISABLE-NVIDIA.aml` (`\\_SB.PCI0.PEG0.PEGP._OFF`) |
| Wi-Fi AX201 (CNVi) | `8086:06F0` / `8086:0074` | `itlwm.kext` + HeliPort |
| Bluetooth AX201 | USB `8087:0026` | `IntelBluetoothFirmware` + `BlueToolFixup` |
| Ethernet RTL8168 | `10EC:8168` | `RealtekRTL8111.kext` |
| Audio ALC257 | `10EC:0257` (subsys `17AA:3874`) | `AppleALC`, `layout-id 11` on `PciRoot(0x0)/Pci(0x1F,0x3)` |
| Touchpad | Synaptics I2C-HID `SYNA0001` `06CB:CE2D` | `VoodooI2C` + `VoodooI2CHID`; `SSDT-GPI0` + `SSDT-TPD0` (ACPI `\\_SB.PCI0.I2C1.TPD0`) |
| Keyboard | PS/2 "AT Translated Set 2" | `VoodooPS2Controller` |
| SATA (macOS target) | `8086:06D3` AHCI | install to the 2.5" SATA SSD |
| NVMe (Fedora, untouched) | KIOXIA/Toshiba BG4 `1E0F:0001` | left alone |

## ACPI paths referenced by the SSDTs
```
touchpad : \_SB.PCI0.I2C1.TPD0     (SSDT-TPD0)   -- verified on this unit
GPIO ctrl: \_SB.PCI0.GPI0          (SSDT-GPI0)
dGPU     : \_SB.PCI0.PEG0.PEGP     (SSDT-DISABLE-NVIDIA)
backlight: \_SB.PCI0.GFX0.PNLF     (SSDT-PNLF-CFL)
EC       : \_SB.PCI0.LPCB + USBX   (SSDT-EC-USBX)
```
