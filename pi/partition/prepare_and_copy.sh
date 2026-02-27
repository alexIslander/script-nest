#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
NEW_BOOT="/mnt/new_boot"
ROOT_PART="/dev/sda2"
BOOT_PART="/dev/sda1"
# ---------------------

echo "--- 🛠️ Starting OS Copy Preparation and Execution ---"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run as root: sudo ./prepare_and_copy.sh"
  exit 1
fi

# 2. Safety Check: Unmount everything from the external drive before starting
echo "Unmounting all temporary mounts and /dev/sda partitions before format..."
# Lazy unmounts for safety
umount -l "$NEW_BOOT" 2>/dev/null
umount -l "$NEW_ROOT" 2>/dev/null
# Unmount data partitions that might be auto-mounted
umount -l /dev/sda6 2>/dev/null
umount -l /dev/sda5 2>/dev/null
umount -l /dev/sda4 2>/dev/null
umount -l /dev/sda3 2>/dev/null

# 3. Safety Check: Confirm formatting partitions
read -r -p "WARNING! This will DELETE ALL DATA on $BOOT_PART and $ROOT_PART. Continue? (y/N): " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Operation cancelled by user."
    exit 0
fi

# 4. Create top-level mount points
mkdir -p "$NEW_ROOT" "$NEW_BOOT"

# 5. Format target partitions (sda1=FAT32, sda2=EXT4)
echo "Formatting $BOOT_PART (FAT32)..."
mkfs.vfat -F 32 "$BOOT_PART" || { echo "ERROR: Formatting $BOOT_PART failed."; exit 1; }

echo "Formatting $ROOT_PART (EXT4)..."
mkfs.ext4 -F "$ROOT_PART" || { echo "ERROR: Formatting $ROOT_PART failed."; exit 1; }

# 6. Get the PARTUUIDs of the newly formatted partitions
NEW_ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
echo "New Root PARTUUID: $NEW_ROOT_PARTUUID"

# 7. Mount newly formatted partitions
echo "Mounting new partitions..."
mount "$ROOT_PART" "$NEW_ROOT"
mount "$BOOT_PART" "$NEW_BOOT"

# 8. Copy the entire Root Filesystem using cp (safer for recursion issues)
echo "Starting FULL OS copy from SD card to $ROOT_PART using cp..."
# Use find to locate files and cpio to copy, which is the most robust way to avoid recursion.
cd /
find . -xdev -path ./proc -prune -o -path ./sys -prune -o -path ./tmp -prune -o -path ./mnt -prune -o -path ./media -prune -o -path ./dev -prune -o -path ./boot/firmware -prune -o -print0 | sudo cpio --null -pd "$NEW_ROOT"
echo "OS copy complete."

# 9. Copy Boot Partition Content (Pi 5 structure)
echo "Copying /boot/firmware content to $NEW_BOOT/..."
cp -a /boot/firmware/. "$NEW_BOOT/" || { echo "ERROR: Boot copy failed."; exit 1; }

# 10. Update cmdline.txt on the new drive
echo "Updating $NEW_BOOT/cmdline.txt with new PARTUUID..."
CMDLINE_FILE="$NEW_BOOT/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
    echo "FATAL ERROR: $CMDLINE_FILE not found. Cannot configure boot."
    exit 1
fi

# Use sed to replace the existing PARTUUID with the new one
sed -i "s/root=PARTUUID=[a-f0-9-]*/root=PARTUUID=$NEW_ROOT_PARTUUID/" "$CMDLINE_FILE"
echo "cmdline.txt updated successfully."

# 11. Cleanup (Unmount the temporary copy mount)
echo "Unmounting temporary mount points..."
umount "$NEW_BOOT"
umount "$NEW_ROOT"

echo "--- ✅ Copy Preparation Complete. Run mount_chroot.sh then kernel_fixer.sh next! ---"