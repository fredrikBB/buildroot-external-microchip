#!/usr/bin/env bash

# Create boot directory for any additional files if needed
if ! [ -d "${TARGET_DIR}"/boot ]; then
	mkdir "${TARGET_DIR}"/boot
fi

# Copy any device tree overlays to boot directory (optional)
cp "${BINARIES_DIR}"/*.dtbo "${TARGET_DIR}"/boot 2>/dev/null || true