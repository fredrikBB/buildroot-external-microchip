#!/bin/bash
set -e

GENIMAGE_CFG="$2"
MKIMAGE="${HOST_DIR}"/bin/mkimage
BOARD_DIR="$(pwd)"/"${0%/*}"

pushd "${BINARIES_DIR}"
mkdir -p dts
cp -r microchip/ dts/
mkdir -p mpfs_beaglev_fire

# Compile BeagleV-Fire AMP overlay
DTC="${HOST_DIR}/bin/dtc"
KERNEL_DIR="${BUILD_DIR}/linux-custom"

# Compile the overlay
"${HOST_DIR}/bin/cpp" -E -nostdinc \
	-I"${KERNEL_DIR}/include" \
	-I"${KERNEL_DIR}/arch/riscv/boot/dts" \
	-I"${KERNEL_DIR}/arch/riscv/boot/dts/microchip" \
	-x assembler-with-cpp -undef \
	-o mpfs_beaglev_fire_amp.pre.dtso \
	"${BOARD_DIR}/mpfs_beaglev_fire_amp.dtso"

"${DTC}" -@ -Wno-unit_address_vs_reg -I dts -O dtb \
	-o mpfs_beaglev_fire/mpfs_beaglev_fire_amp.dtbo \
	mpfs_beaglev_fire_amp.pre.dtso

# Move any other dtbo files to platform directory  
for file in ./*.dtbo
do
  if [ -e "$file" ] && [ "$file" != "./mpfs_beaglev_fire/mpfs_beaglev_fire_amp.dtbo" ]
  then
    mv "$file" mpfs_beaglev_fire/
  fi
done

gzip -9 Image -c > Image.gz
"${MKIMAGE}" -f mpfs-beaglev-fire-amp.its mpfs_beaglev_fire_amp.itb
popd
support/scripts/genimage.sh -c "${GENIMAGE_CFG}"

if [[ "${GENIMAGE_CFG}" == *"genimage.cfg"* ]]; then
    "${HOST_DIR}"/bin/bmaptool create -o "${BINARIES_DIR}"/sdcard.bmap "${BINARIES_DIR}"/sdcard.img
fi