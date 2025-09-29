# BeagleV-Fire AMP Demo

This directory contains the complete BeagleV-Fire AMP (Asymmetric MultiProcessing) demo configuration, successfully ported from the PolarFire SoC Icicle Kit.

## Overview

The AMP demo runs Linux on cores u54_1, u54_2, u54_3 and FreeRTOS on core u54_4, with communication between contexts via RPMSG/RemoteProc framework.

## Implementation

This BeagleV-Fire AMP configuration integrates with the `dt-overlay-mchp` package to provide device tree overlay support. The implementation uses a post-extract hook approach that automatically includes BeagleV-Fire overlay files during the build process.

### Key Configuration
- **Platform**: `BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM="mpfs_beaglev_fire"`
- **Device Tree Overlay**: Automatic build of `mpfs_beaglev_fire_amp.dtbo`
- **FIT Image**: Generated as `mpfs_beaglev_fire_amp.itb` with kernel + overlays

### Files in this Directory

#### Board Configuration Files  
- `config.yaml` - HSS payload generator configuration for AMP
- `linux.fragment` - Kernel configuration fragment for AMP support
- `uboot-fragment.config` - U-Boot configuration fragment with AMP bootargs
- `genimage.cfg` - Image generation configuration for SD card
- `uEnv.txt` - U-Boot environment variables
- `uboot-env.txt` - Boot script for AMP configuration
- `post-build.sh` - Script to copy device tree overlays to boot partition
- `post-image.sh` - Script for FIT image generation

#### Device Tree Overlay Integration
The BeagleV-Fire device tree overlays are maintained in:
- `package/dt-overlay-mchp/beaglev-fire-files/mpfs_beaglev_fire.its` - FIT image template
- `package/dt-overlay-mchp/beaglev-fire-files/mpfs_beaglev_fire/mpfs_beaglev_fire_amp.dtso` - AMP overlay

These files are automatically integrated into the dt-overlay-mchp package build via post-extract hooks.

## Technical Implementation

### Post-Extract Hook Architecture
This BeagleV-Fire AMP configuration uses an innovative approach for device tree overlay integration:

1. **Local Control**: BeagleV-Fire overlay files are maintained locally in the buildroot-external-microchip repository
2. **Automatic Integration**: A post-extract hook (`DT_OVERLAY_MCHP_ADD_BEAGLEV_FIRE_SUPPORT`) copies files into the dt-overlay-mchp build directory
3. **Makefile Patching**: The hook automatically updates the dt-overlay-mchp Makefile to include BeagleV-Fire platform support
4. **Build-time Resolution**: Files are integrated during the package extract phase, ensuring consistent builds

This approach provides several advantages:
- **Independence**: No dependency on upstream dt-overlay-mchp repository for BeagleV-Fire support
- **Maintainability**: Local control over BeagleV-Fire-specific overlays and templates
- **Reliability**: Automatic integration eliminates manual patching steps
- **Consistency**: Ensures BeagleV-Fire support is always available regardless of upstream changes

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

### Device Tree Overlays
- Base device tree: `microchip/mpfs-beaglev-fire.dtb`
- AMP overlay: `mpfs_beaglev_fire_amp.dtbo` (built from dt-overlay-mchp package)
- Automatic integration via post-extract hooks in dt-overlay-mchp

### U-Boot Configuration  
- Uses `beaglv_fire` U-Boot defconfig as base (shared with non-AMP configuration)
- AMP-specific settings applied via `uboot-fragment.config`
- Bootargs include UIO driver support: `uio_pdrv_genirq.of_id=generic-uio`

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
   
   # Verify dt-overlay-mchp integration
   ls -la output/build/dt-overlay-mchp-*/mpfs_beaglev_fire/
   ```

3. **Check BeagleV-Fire Integration**:
   ```bash
   # Verify post-extract hook worked
   grep -r "beaglev_fire" output/build/dt-overlay-mchp-*/Makefile
   
   # Check overlay files were copied
   ls output/build/dt-overlay-mchp-*/mpfs_beaglev_fire*
   ```

3. **Console Output**:
   - Monitor serial console during boot
   - Check for HSS payload loading messages
   - Verify kernel boots with correct hart assignments

## Additional Notes

### Device Tree Overlays
The configuration supports device tree overlays for FPGA fabric interfaces. Overlays are automatically applied during boot if present.

### Package Configuration
- Uses `linux4microchip+fpga-2025.07` kernel/u-boot versions
- Includes MPFS examples and AMP-specific packages (`BR2_PACKAGE_MPFS_AMP_EXAMPLES=y`)
- Device tree overlay support: `BR2_PACKAGE_DT_OVERLAY_MCHP=y` with `mpfs_beaglev_fire` platform
- Post-extract hook automatically adds BeagleV-Fire overlay files to dt-overlay-mchp build

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