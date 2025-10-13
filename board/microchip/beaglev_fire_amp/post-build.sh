#!/usr/bin/env bash

if ! [ -d "${TARGET_DIR}"/boot ]; then
	mkdir "${TARGET_DIR}"/boot
fi
if [ -d "${BINARIES_DIR}"/mpfs_beaglev_fire ]; then
	cp "${BINARIES_DIR}"/mpfs_beaglev_fire/*.dtbo "${TARGET_DIR}"/boot 2>/dev/null || true
else
	cp "${BINARIES_DIR}"/*.dtbo "${TARGET_DIR}"/boot 2>/dev/null || true
fi