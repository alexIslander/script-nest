#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
# ---------------------

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo ./unmount_chroot.sh"
  exit 1
fi

echo "--- 🧹 Starting Unmount Process ---"

# Unmount all mounts in reverse order (using lazy unmount for safety if busy)
echo "Unmounting temporary and bind mounts..."
umount -l "$NEW_ROOT/dev/pts" 2>/dev/null
umount -l "$NEW_ROOT/tmp" 2>/dev/null
umount -l "$NEW_ROOT/proc" 2>/dev/null
umount -l "$NEW_ROOT/sys" 2>/dev/null
umount -l "$NEW_ROOT/dev" 2>/dev/null

# Unmount the partitions (boot partition first)
echo "Unmounting partitions..."
umount -l "$NEW_ROOT/boot/firmware" 2>/dev/null
umount -l "$NEW_ROOT" 2>/dev/null

echo "--- ✅ Unmount Complete. ---"