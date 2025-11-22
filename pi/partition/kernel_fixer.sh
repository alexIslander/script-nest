#!/bin/bash

# The target would be to fix the kernel on the new drive to the same version as the SD card.
# then update the fstab to use the new drive.
# proc            /proc           proc    defaults          0       0
# # PARTUUID=ffd4df76-01  /boot/firmware  vfat    defaults          0       2
# UUID=8283350d-2bd1-bd4f-94b5-f82b34d16d79 /media/sda5 ext4 defaults 0 0
# UUID=af012898-a4d1-224d-8e14-c729020e87d4 /media/sda6 ext4 defaults 0 0
# PARTUUID=d75d9edd-01 /boot/firmware vfat defaults 0 2
# PARTUUID=d75d9edd-02 / ext4 defaults,noatime 0 1

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
BOOT_PART="/dev/sda1"
ROOT_PART="/dev/sda2"
# ---------------------

echo "--- ⚙️ Starting Kernel Fixer and Final Config Process ---"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run as root: sudo ./kernel_fixer.sh"
  exit 1
fi

# Check if mount_chroot.sh was run
if ! mountpoint -q "$NEW_ROOT/dev"; then
    echo "ERROR: Bind mounts not found. Run mount_chroot.sh first."
    exit 1
fi

# 2. Identify the required kernel and PARTUUIDs
echo "Identifying kernel version and PARTUUIDs..."
MODULE_VERSION=$(ls -d /lib/modules/*/ | head -n 1 | xargs basename)
NEW_BOOT_PARTUUID=$(blkid -s PARTUUID -o value "$BOOT_PART")
NEW_ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")

if [ -z "$MODULE_VERSION" ]; then
    echo "FATAL ERROR: Could not find kernel module version on running OS."
    exit 1
fi

if [ -z "$NEW_BOOT_PARTUUID" ] || [ -z "$NEW_ROOT_PARTUUID" ]; then
    echo "FATAL ERROR: Could not get PARTUUIDs for SSD partitions."
    exit 1
fi

echo "Module Version: $MODULE_VERSION"
echo "New Boot PARTUUID: $NEW_BOOT_PARTUUID"
echo "New Root PARTUUID: $NEW_ROOT_PARTUUID"

# 3. Update fstab on the new drive (Done before chroot)
FSTAB_FILE="$NEW_ROOT/etc/fstab"
echo "Updating $FSTAB_FILE..."

# Get SD card PARTUUIDs to specifically remove them
SD_BOOT_PARTUUID=$(blkid -s PARTUUID -o value /dev/mmcblk0p1 2>/dev/null)
SD_ROOT_PARTUUID=$(blkid -s PARTUUID -o value /dev/mmcblk0p2 2>/dev/null)

if [ -n "$SD_BOOT_PARTUUID" ]; then
    echo "Detected SD card boot PARTUUID: $SD_BOOT_PARTUUID (will be removed)"
    # Remove lines containing the SD card boot PARTUUID
    sed -i "/PARTUUID=$SD_BOOT_PARTUUID/d" "$FSTAB_FILE"
fi

if [ -n "$SD_ROOT_PARTUUID" ]; then
    echo "Detected SD card root PARTUUID: $SD_ROOT_PARTUUID (will be removed)"
    # Remove lines containing the SD card root PARTUUID
    sed -i "/PARTUUID=$SD_ROOT_PARTUUID/d" "$FSTAB_FILE"
fi

# Remove any remaining lines with /boot/firmware or /boot mount points (catch any variations)
sed -i '/[[:space:]]\/boot\/firmware[[:space:]]/d' "$FSTAB_FILE"
sed -i '/[[:space:]]\/boot[[:space:]]/d' "$FSTAB_FILE"

# Remove any remaining lines with / root mount point (but preserve comments and other entries)
sed -i '/^[^#]*[[:space:]]\/[[:space:]]/d' "$FSTAB_FILE"

# Add the new PARTUUIDs to fstab with correct mount points
# Raspberry Pi 5 uses /boot/firmware, not /boot
echo "PARTUUID=$NEW_BOOT_PARTUUID /boot/firmware vfat defaults 0 2" >> "$FSTAB_FILE"
echo "PARTUUID=$NEW_ROOT_PARTUUID / ext4 defaults,noatime 0 1" >> "$FSTAB_FILE"

echo "fstab updated successfully."

# 4. Enter chroot for final kernel regeneration
echo "--- Entering chroot for final kernel regeneration ---"
sudo chroot "$NEW_ROOT" <<EOF
  echo "-> Inside chroot: Updating apt lists..."
  # Use sudo inside chroot for robustness
  sudo apt update
  
  # Reinstall package to force correct setup scripts to run
  echo "-> Inside chroot: Reinstalling linux-image-rpi-v8..."
  sudo apt install --reinstall linux-image-rpi-v8
  
  # Force initial ramdisk (initrd) creation
  echo "-> Inside chroot: Forcing initrd update for version $MODULE_VERSION..."
  update-initramfs -c -k "$MODULE_VERSION"
  
  echo "-> Inside chroot: Kernel fix complete."
EOF

echo "--- ✅ Kernel Fixer Finished ---"
echo "Run unmount_chroot.sh, remove the SD card, and reboot."