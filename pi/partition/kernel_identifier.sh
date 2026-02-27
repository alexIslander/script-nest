#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
# ---------------------

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo ./kernel_identifier.sh"
  exit 1
fi

echo "--- 🔍 Identifying Kernel Version ---"

# Check if the target root partition is mounted
if ! mountpoint -q "$NEW_ROOT"; then
    echo "ERROR: $NEW_ROOT is not mounted. Run mount_chroot.sh first."
    exit 1
fi

# Find the installed kernel image package (e.g., linux-image-6.1.0-rpi8-rpi-v8)
# This lists package status from the target drive and extracts the version.
KERNEL_VERSION=$(dpkg --root="$NEW_ROOT" -l 'linux-image-rpi*' | grep '^ii' | awk '{print $2}' | sed 's/linux-image-//')

if [ -z "$KERNEL_VERSION" ]; then
    echo "ERROR: Could not automatically find the kernel image package name on the external drive."
    echo "Please check manually inside chroot using: dpkg --get-selections | grep 'linux-image'"
    exit 1
fi

echo "✅ Found Kernel Image Package: linux-image-$KERNEL_VERSION"

# Extract the specific module version from the /lib/modules directory
MODULE_VERSION=$(ls -d "$NEW_ROOT/lib/modules/"*/ | head -n 1 | xargs basename)

if [ -z "$MODULE_VERSION" ]; then
    echo "WARNING: Could not find module directory in $NEW_ROOT/lib/modules/."
    echo "Using the image package name as the version."
    MODULE_VERSION=$KERNEL_VERSION
else
    echo "✅ Found Module Version: $MODULE_VERSION"
fi

echo "--- 💡 Use this version in the kernel_fixer.sh script: $MODULE_VERSION ---"
echo "$MODULE_VERSION" > kernel_version.txt
echo "Version saved to kernel_version.txt"