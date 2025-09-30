#!/bin/bash
set -e

GENIMAGE_CFG="$2"
MKIMAGE="${HOST_DIR}"/bin/mkimage

# Add HOST_DIR/bin to PATH for dtc and other tools
export PATH="${HOST_DIR}/bin:${PATH}"

pushd "${BINARIES_DIR}"
# Copy device tree files
mkdir -p dts
cp -r microchip/ dts/
# Compress kernel (must be done before creating FIT image)
# Remove existing Image.gz if it exists, then compress
rm -f Image.gz
gzip -9 -c Image > Image.gz

# Copy .its file to binaries directory and generate FIT image
cp "${BR2_EXTERNAL_MCHP_PATH}/board/microchip/beaglev_fire_amp/mpfs-beaglev-fire-amp.its" ./mpfs-beaglev-fire-amp.its
"${MKIMAGE}" -f mpfs-beaglev-fire-amp.its mpfs_beaglev_fire_amp.itb
popd
support/scripts/genimage.sh -c "${GENIMAGE_CFG}"

if [[ "${GENIMAGE_CFG}" == *"genimage.cfg"* ]]; then
    "${HOST_DIR}"/bin/bmaptool create -o "${BINARIES_DIR}"/sdcard.bmap "${BINARIES_DIR}"/sdcard.img
fi