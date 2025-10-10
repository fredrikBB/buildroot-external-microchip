# BeagleV-Fire AMP Demo
(This README is generated with GitHub Copilot and edited by the authour).

This directory in addition to the beaglev_fire_amp_defconfig contains the complete BeagleV-Fire AMP (Asymmetric MultiProcessing) demo configuration. This is based on Microchips AMP demo for the Icicle kit: https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/applications-and-demos/asymmetric-multiprocessing/amp.md.

It is not successfully ported at this time.

## Overview

The AMP demo runs Linux on cores u54_1, u54_2, u54_3 and FreeRTOS on core u54_4, with communication between contexts via RPMSG/RemoteProc framework.

## Implementation Approach

This BeagleV-Fire AMP configuration uses a **device tree overlay approach** that closely follows the Icicle AMP pattern:

### Key Architecture
- **Base Device Tree**: Uses upstream `mpfs-beaglev-fire.dtb` from Linux kernel
- **AMP Overlay**: Custom `mpfs_beaglev_fire_amp.dtso` overlay for AMP modifications
- **FIT Image**: Dual-configuration FIT image with base + overlay configurations
- **Boot Process**: U-Boot loads base DT + overlay using dual-config bootm syntax

### Files in this Directory

#### Core AMP Configuration Files
- `mpfs-beaglv-fire-amp.its` - FIT image template (kernel + base DT + AMP overlay)
- `mpfs_beaglev_fire_amp.dtso` - Device tree overlay with AMP modifications
- `uboot-env.txt` - U-Boot boot script using dual-config syntax  
- `post-image.sh` - Compiles overlay and generates FIT image
- `config.yaml` - HSS payload generator configuration for AMP
- `linux.fragment` - Kernel configuration fragment with AMP and console settings
- `uboot-fragment.config` - U-Boot configuration fragment 
- `genimage.cfg` - SD card image generation configuration
- `post-build.sh` - Post-build processing script

#### Supporting Files
- `uEnv.txt` - U-Boot environment variables
- `rootfs-overlay/` - Root filesystem customizations

### Overlay-Based Implementation
This approach provides several key advantages:

1. **Upstream Compatibility**: Uses standard BeagleV-Fire device tree from Linux kernel
2. **Minimal Changes**: Only AMP-specific modifications in overlay
3. **Maintainability**: Easy to track changes and update with upstream
4. **Proven Pattern**: Follows Icicle AMP overlay architecture

## Technical Implementation

### Device Tree Overlay Architecture
The AMP configuration uses a device tree overlay approach:

### AMP Overlay Content (`mpfs_beaglev_fire_amp.dtso`)

The overlay makes the following key modifications:

- **CPU4 Reservation**: Frees up `&cpu4` for FreeRTOS context
- **Memory Layout**: Reserves memory regions for RPMSG communication and for the FreeRTOS context
- **Device Assignments**: Assigns devices to appropriate contexts:
  - `&mmuart3` → disabled (reserved for FreeRTOS)
  - `&wdt4` → disabled (reserved for FreeRTOS)

### Boot Process Flow

1. **U-Boot Load**: Loads `mpfs_beaglv_fire_amp.itb` FIT image
2. **Dual Configuration**: Uses syntax `#conf-base#conf-overlay` to load both the base and the overlay
3. **Device Tree Merge**: U-Boot merges base DT with AMP overlay
4. **Linux Boot**: Kernel boots with merged device tree containing AMP config

## Key Configuration Differences from Icicle AMP

1. **No dt-overlay-mchp package**: The dt-overlay-mchp package were not supported for BealgeV-Fire. Therefore both DT overlay files (.dtso) and Flattend Image Tree files (.its) are located in this folder. A consequence of this is that the host needs a device tree compiler (DTC) to compile the overlay manually in the `post-image.sh` script. This is provided with the configuration BR2_PACKAGE_HOST_DTC=y in `beaglev_fire_amp_defconfig`.

2. **No CONFIG_OF_BOARD=y**: The U-Boot configuration CONFIG_OF_BOARD located in `uboot-fragment.config` did not have support for BeagleV-Fire in Microchip's U-Boot repository. CONFIG_DISTRO_DEFAULTS was used instead.

3. **Extra argument in kernel command line**: After the kernel has booted up and doing console handoff from legacy bootconsole to tty0, the host did not recieve any more data on the serial connection. To temporary resolve this issue the `linux.fragment` inlcudes the argument console=ttyS0,115200 in its CONFIG_CMDLINE. This was not done in the Icicle implementation, but got included here in order to help debug the boot process.