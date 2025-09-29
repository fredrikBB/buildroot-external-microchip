################################################################################
#
# dt overlay mchp
#
################################################################################

DT_OVERLAY_MCHP_VERSION = linux4microchip+fpga-2025.07
DT_OVERLAY_MCHP_SITE = $(call github,linux4microchip,dt-overlay-mchp,$(DT_OVERLAY_MCHP_VERSION))
DT_OVERLAY_MCHP_LICENSE = GPL-2.0 MIT
DT_OVERLAY_MCHP_LICENSE_FILES = COPYING LICENSES/GPL-2.0 LICENSES/MIT
DT_OVERLAY_MCHP_DEPENDENCIES = linux host-uboot-tools

# Add BeagleV-Fire support files after extraction
define DT_OVERLAY_MCHP_ADD_BEAGLEV_FIRE_SUPPORT
	# Copy BeagleV-Fire files
	cp -r $(BR2_EXTERNAL_MCHP_PATH)/package/dt-overlay-mchp/beaglev-fire-files/* $(@D)/
	# Update Makefile to include BeagleV-Fire support
	sed -i 's/mpfs_icicle_amp mpfs_video/mpfs_icicle_amp mpfs_beaglev_fire mpfs_video/' $(@D)/Makefile
	sed -i '/MPFS_ICICLE_AMP_DTBO_OBJECTS:=/a MPFS_BEAGLEV_FIRE_DTBO_OBJECTS:= $$(patsubst %.dtso,%.dtbo,$$(wildcard mpfs_beaglev_fire/*.dtso))' $(@D)/Makefile
	sed -i '/mpfs_icicle_amp_dtbos: $$(MPFS_ICICLE_AMP_DTBO_OBJECTS)/a \\nmpfs_beaglev_fire_dtbos: $$(MPFS_BEAGLEV_FIRE_DTBO_OBJECTS)' $(@D)/Makefile
endef
DT_OVERLAY_MCHP_POST_EXTRACT_HOOKS += DT_OVERLAY_MCHP_ADD_BEAGLEV_FIRE_SUPPORT

ifeq ($(BR2_PACKAGE_DT_OVERLAY_MCHP_ONLY),y)
define DT_OVERLAY_MCHP_BUILD_CMDS
	PATH="$(LINUX_DIR)/scripts/dtc:$(HOST_DIR)/bin:$(PATH)" $(MAKE) DTC="$(LINUX_DIR)/scripts/dtc/dtc" KERNEL_DIR="$(LINUX_DIR)" -C $(@D) $(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM)_dtbos
endef
define DT_OVERLAY_MCHP_INSTALL_TARGET_CMDS
	$(foreach f,$(notdir $(wildcard $(@D)/*/*.dtbo)),
		$(INSTALL) -m 0644 -D $(@D)/$(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM)/$(f) \
			$(BINARIES_DIR))
endef
else
ifeq ($(BR2_riscv),y)
	dt_overlay_arch := riscv
else
	dt_overlay_arch := arm
endif
define DT_OVERLAY_MCHP_BUILD_CMDS
	ARCH=$(dt_overlay_arch) PATH="$(LINUX_DIR)/scripts/dtc:$(HOST_DIR)/bin:$(PATH)" $(MAKE) DTC="$(LINUX_DIR)/scripts/dtc/dtc" KERNEL_DIR="$(LINUX_DIR)" -C $(@D) $(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM).itb
endef
define DT_OVERLAY_MCHP_INSTALL_TARGET_CMDS
	for f in $(@D)/$(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM)/*.dtbo; do \
		if [ -e "$$f" ]; then \
			$(INSTALL) -m 0644 -D "$$f" $(BINARIES_DIR)/; \
		fi; \
	done
	$(INSTALL) -m 0644 -D $(@D)/$(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM).itb $(BINARIES_DIR)/
	$(INSTALL) -m 0644 -D $(@D)/$(BR2_PACKAGE_DT_OVERLAY_MCHP_PLATFORM).its $(BINARIES_DIR)/
endef
endif

$(eval $(generic-package))
