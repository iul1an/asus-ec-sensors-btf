# asus-ec-sensors-btf

![build](https://github.com/iul1an/asus-ec-sensors-btf/actions/workflows/build.yml/badge.svg)

The Linux hwmon driver `asus-ec-sensors`, as the module `asus_ec_sensors_btf`,
for the ASUS ROG CROSSHAIR X870E HERO BTF: its EC sensors plus the current on
each of the six 12 V pins of the GC-HPWR connector of the BTF graphics slot.

## Sensors

| hwmon | Label | EC bank 0 |
|---|---|---|
| temp1..temp5 | CPU, CPU Package, Motherboard, T_Sensor, VRM | 0x30, 0x31, 0x32, 0x36, 0x33 |
| fan1 | CPU_Opt | 0xb0..0xb1 |
| curr1..curr6 | GC-HPWR pin 1..6 | write channel 0..5 to 0xd8, read 0xd9 (high), 0xda (low) |

A pin's current is a big-endian 16-bit value in mA; 0xfff8 and above
means no reading and gives `ENODATA`. After each read the driver reads
0xd8 back, and if another EC user changed the channel the whole update
fails with `EIO`. All reads run under the ACPI global lock, at most once
a second; the event handlers of this board's firmware hold the same
lock around their EC bank switches. The kernel log names the guard when
the module loads. A failed EC read stops the update at once, and every
sensor then returns `EIO` until an update succeeds again; the driver
tries again at most once a second.

The EC bank found before a read is restored after it. A bank other
than 0 is reported once in the kernel log with its value, and again
whenever it changes, and once more when the EC is back on bank 0.

## Build

Needs the running kernel's headers (`linux-headers` on Arch).

    make
    make checkpatch

## Install

Arch package, which DKMS builds for every installed kernel:

    make package
    sudo pacman -U dist/asus-ec-sensors-btf-dkms-0.1.1-1-x86_64.pkg.tar.zst

DKMS by hand:

    sudo install -Dm644 -t /usr/src/asus-ec-sensors-btf-0.1.1 dkms.conf src/Makefile src/asus-ec-sensors-btf.c
    sudo dkms install asus-ec-sensors-btf/0.1.1

The module loads at boot through the board's DMI alias. To load it now
and check it:

    sudo modprobe asus_ec_sensors_btf
    sensors 'asusec-*'

## Refresh on a new kernel

`upstream/asus-ec-sensors.c` is Linux v7.2.7's `drivers/hwmon/asus-ec-sensors.c`,
SHA-256 `703ad556d01d3eb3c1eb9d14ed2eda283c88c84830ddb55be85d977540b20649`.

1. Put the new kernel's `drivers/hwmon/asus-ec-sensors.c` in `upstream/`.
2. `patch -o src/asus-ec-sensors-btf.c upstream/asus-ec-sensors.c < patch/0001-btf-gc-hpwr.patch`
3. Fix any rejected hunk, then `make patch` to regenerate the patch.
4. Bump `VERSION` and `PACKAGE_VERSION` in `dkms.conf` together.

## Licence

GPL-2.0-or-later, as the driver's SPDX line says; `LICENSE` holds the text.
The driver is by Eugene Shalygin and the other `asus-ec-sensors` authors.
