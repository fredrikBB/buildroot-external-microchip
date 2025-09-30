# BeagleV-Fire AMP Demo

This directory contains the complete BeagleV-Fire AMP (Asymmetric MultiProcessing) demo configuration, successfully ported from the Icicle AMP demo. **Verify FIT Image**:
   ```bash
   # Check FIT image structure  
   output/host/bin/dumpimage -l output/images/mpfs_beaglv_fire_amp.itb
   
   # Verify board-specific files are used
   ls -la output/images/mpfs-beaglv-fire-amp.dtb
   ```it.

## Overview

The AMP demo runs Linux on cores u54_1, u54_2, u54_3 and FreeRTOS on core u54_4, with communication between contexts via RPMSG/RemoteProc framework.

## Implementation

This BeagleV-Fire AMP configuration uses a simplified board-specific approach similar to the Icicle AMP configuration. All AMP-specific files are maintained locally in this board directory.

### Key Configuration
- **Device Tree**: Custom AMP device tree with all modifications included
- **FIT Image**: Single board-specific `.its` file generates `mpfs_beaglev_fire_amp.itb`
- **Boot Script**: Simple `bootm` command loads AMP configuration directly

### Files in this Directory

#### Board Configuration Files  
- `mpfs-beaglv-fire-amp.its` - FIT image template (kernel + base DT + AMP DT)
- `mpfs-beaglv-fire-amp.dts` - Complete AMP device tree with all modifications
- `config.yaml` - HSS payload generator configuration for AMP
- `linux.fragment` - Kernel configuration fragment for AMP support
- `uboot-fragment.config` - U-Boot configuration fragment with AMP bootargs
- `genimage.cfg` - Image generation configuration for SD card
- `uEnv.txt` - U-Boot environment variables
- `uboot-env.txt` - Simple AMP boot script
- `post-build.sh` - Post-build processing script
- `post-image.sh` - FIT image generation script

#### Implementation Approach
This approach eliminates the complexity of overlay extraction and provides:
- **Direct AMP device tree**: All AMP modifications in a single `.dts` file
- **Simple boot process**: Standard U-Boot `bootm` command with configuration selection
- **Local control**: All BeagleV-Fire AMP files maintained in this board directory
- **Proven architecture**: Follows the successful Icicle AMP pattern

## Technical Implementation

### Board-Specific Architecture
This BeagleV-Fire AMP configuration uses a simplified board-specific approach:

1. **Self-Contained**: All BeagleV-Fire AMP files are maintained in this board directory
2. **Direct Device Tree Build**: Custom AMP device tree built directly via `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`
3. **FIT Image Generation**: Board-specific `.its` file creates the complete AMP boot image
4. **No External Dependencies**: No reliance on dt-overlay-mchp or other external packages

This approach provides several advantages:
- **Simplicity**: Single board directory contains all necessary files
- **Maintainability**: Direct control over all AMP-specific configuration
- **Reliability**: No complex package integration or post-extract hooks
- **Consistency**: Self-contained approach ensures reproducible builds

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

### Device Tree Configuration
- Base device tree: `microchip/mpfs-beaglev-fire.dtb` (from Linux kernel)
- AMP device tree: `mpfs-beaglv-fire-amp.dtb` (built from board-specific `.dts` file)
- Both device trees included in FIT image with configurations: `conf-base` (regular) and `conf-amp` (AMP mode)

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
   
   # Verify board-specific files are used
   ls -la output/images/mpfs-beaglv-fire-amp.dtb
   ```

3. **Check AMP Device Tree**:
   ```bash
   # Verify AMP device tree was built
   ls output/images/mpfs-beaglv-fire-amp.dtb
   
   # Check FIT image contains both device trees
   output/host/bin/dumpimage -l output/images/mpfs_beaglv_fire_amp.itb
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
- Custom device tree support: Board-specific AMP device tree built via `BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`
- Board-specific FIT image: Generated from local `.its` file in post-image.sh
- Self-contained approach: No external package dependencies

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