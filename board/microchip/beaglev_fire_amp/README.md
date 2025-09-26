# BeagleV-Fire AMP Demo Porting Guide

This guide provides step-by-step instructions for successfully porting the Asymmetric MultiProcessing (AMP) demo from PolarFire SoC (Icicle Kit) to BeagleV-Fire.

## Overview

The AMP demo allows running Linux on cores u54_1, u54_2, u54_3 and FreeRTOS on core u54_4, with communication between contexts via RPMSG/RemoteProc framework.

## Files Created

The following files have been created in the buildroot-external-microchip repository:

### Configuration Files
- `configs/beaglev_fire_amp_defconfig` - Main buildroot defconfig for BeagleV-Fire AMP
- `board/microchip/beaglev_fire_amp/` - Board-specific files directory

### Board Files
- `config.yaml` - HSS payload generator configuration
- `linux.fragment` - Kernel configuration fragment for AMP support
- `uboot-fragment.config` - U-Boot configuration fragment
- `genimage.cfg` - Image generation configuration
- `mpfs_beaglev_fire.its` - FIT image template
- `uEnv.txt` - U-Boot environment variables
- `uboot-env.txt` - Boot script for AMP configuration
- `post-build.sh` - Post-build script for device tree overlays
- `post-image.sh` - Post-image script for FIT image generation

## Prerequisites

1. **Buildroot Setup**: Ensure you have buildroot and buildroot-external-microchip configured
2. **Toolchain**: RISC-V 64-bit toolchain (automatically handled by buildroot)
3. **Hardware**: BeagleV-Fire board with proper power supply
4. **Storage**: microSD card (8GB+ recommended)

## Build Steps

### 1. Configure the Build

```bash
cd /path/to/buildroot
make BR2_EXTERNAL=/path/to/buildroot-external-microchip beaglev_fire_amp_defconfig
```

### 2. Build the System

```bash
make -j$(nproc)
```

This will:
- Build the Linux kernel with AMP support
- Build U-Boot with BeagleV-Fire AMP configuration
- Generate FreeRTOS firmware for the AMP context
- Create FIT image with Linux kernel and device tree
- Generate HSS payload with both Linux and FreeRTOS contexts
- Create bootable SD card image

### 3. Flash to SD Card

```bash
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=1M status=progress
sync
```

Replace `/dev/sdX` with your SD card device.

## Key Configuration Differences from Icicle AMP

### Hardware Abstraction Layer (HSS) Configuration
- Hart entry points configured for BeagleV-Fire memory layout
- Payload configuration adapted for BeagleV-Fire device tree

### Device Tree
- Uses `microchip/mpfs-beaglev-fire.dtb` instead of Icicle-specific DTB
- BeagleV-Fire specific peripheral configurations

### U-Boot Configuration
- Uses `beaglev_fire` U-Boot defconfig as base
- BeagleV-Fire specific board initialization

### Kernel Configuration
- Same MPFS kernel defconfig (compatible between boards)
- AMP-specific features enabled (REMOTEPROC, RPMSG, UIO)

## Memory Layout

The AMP configuration uses the following memory layout:
- **Linux Context (u54_1, u54_2, u54_3)**: 0x80200000 (SBI S-mode)
- **FreeRTOS Context (u54_4)**: 0x91C00000 (M-mode, skips OpenSBI)

## Testing the AMP Demo

### 1. Boot Verification
After booting, verify both contexts are running:

```bash
# Check Linux is running on expected cores
cat /proc/cpuinfo
dmesg | grep -i rpmsg
```

### 2. Inter-Core Communication
The RPMSG framework enables communication between Linux and FreeRTOS:

```bash
# Check RPMSG devices
ls /dev/rpmsg*

# Check remoteproc status
cat /sys/class/remoteproc/remoteproc0/state
```

### 3. AMP Examples
If MPFS_AMP_EXAMPLES is enabled, example applications will be available in `/lib/firmware/`.

## Troubleshooting

### Common Issues

1. **Boot Failure**
   - Verify SD card is properly flashed
   - Check HSS payload is correctly generated
   - Ensure BeagleV-Fire hardware is properly configured

2. **AMP Context Not Starting**
   - Check FreeRTOS firmware is built and included
   - Verify HSS configuration has correct hart assignments
   - Check memory layout doesn't conflict

3. **RPMSG Communication Issues**
   - Ensure kernel has RPMSG support enabled
   - Check device tree has proper RPMSG configuration
   - Verify FreeRTOS context implements RPMSG endpoint

### Debug Steps

1. **Check HSS Payload**:
   ```bash
   # Verify payload.bin contains both contexts
   file output/images/payload.bin
   ```

2. **Verify FIT Image**:
   ```bash
   # Check FIT image structure
   output/host/bin/dumpimage -l output/images/mpfs_beaglev_fire_amp.itb
   ```

3. **Console Output**:
   - Monitor serial console during boot
   - Check for HSS payload loading messages
   - Verify kernel boots with correct hart assignments

## Additional Notes

### Device Tree Overlays
The configuration supports device tree overlays for FPGA fabric interfaces. Overlays are automatically applied during boot if present.

### Package Differences
- Uses `linux4microchip+fpga-2025.07` kernel/u-boot versions
- Includes MPFS examples and AMP-specific packages
- DT overlay support enabled for BeagleV-Fire platform

### External Dependencies
The AMP examples depend on:
- `polarfire-soc-amp-examples` repository
- Compatible FreeRTOS port for MPFS
- RPMSG/RemoteProc kernel support

## Success Indicators

A successful AMP demo port will show:
1. Linux boots on cores 1-3
2. FreeRTOS context starts on core 4
3. RPMSG devices are created
4. Inter-core communication works
5. Both contexts can share peripherals appropriately

The demo provides a foundation for developing more complex AMP applications on BeagleV-Fire.