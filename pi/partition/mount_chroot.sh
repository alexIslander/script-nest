#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
BOOT_PART="/dev/sda1"
ROOT_PART="/dev/sda2"
# ---------------------

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo ./mount_chroot.sh"
  exit 1
fi

echo "--- 🛠️ Starting Chroot Mount Process ---"

# 1. Create top-level mount point if it doesn't exist
if [ ! -d "$NEW_ROOT" ]; then
    mkdir -p "$NEW_ROOT"
fi

# 2. Mount Root Partition (sda2)
echo "Mounting $ROOT_PART to $NEW_ROOT..."
mount "$ROOT_PART" "$NEW_ROOT"

# 3. Mount Boot Partition (sda1) at the new Pi 5 location (/boot/firmware)
echo "Mounting $BOOT_PART to $NEW_ROOT/boot/firmware..."
mkdir -p "$NEW_ROOT/boot/firmware"
mount "$BOOT_PART" "$NEW_ROOT/boot/firmware"

# 4. Create and Bind-Mount essential directories for chroot
echo "Binding essential system directories..."
mkdir -p "$NEW_ROOT/dev" "$NEW_ROOT/sys" "$NEW_ROOT/proc" "$NEW_ROOT/tmp" "$NEW_ROOT/dev/pts"

mount --bind /dev "$NEW_ROOT/dev"
mount --bind /sys "$NEW_ROOT/sys"
mount --bind /proc "$NEW_ROOT/proc"
mount --bind /dev/pts "$NEW_ROOT/dev/pts"
mount -t tmpfs tmpfs "$NEW_ROOT/tmp"

echo "--- ✅ Mount Complete. Ready for chroot ---"
echo "To enter chroot: sudo chroot /mnt/new_root"