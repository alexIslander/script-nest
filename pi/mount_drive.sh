#!/bin/bash

# Script to mount a specified partition to /media/<partition_name>
# Usage: ./mount_drive.sh /dev/sda5

# Check if the user provided a partition argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <partition>"
    echo "Example: $0 /dev/sda5"
    exit 1
fi

PARTITION="$1"
MOUNT_POINT="/media/$(basename "$PARTITION")"
CURRENT_USER=$(whoami)

# Function to display messages
function echo_message {
    echo -e "\n*** $1 ***\n"
}

# Check if the partition exists
if [ ! -e "$PARTITION" ]; then
    echo_message "Error: Partition $PARTITION does not exist."
    exit 1
fi

# Create mount point if it does not exist
if [ ! -d "$MOUNT_POINT" ]; then
    echo_message "Creating mount point at $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"
    if [ $? -ne 0 ]; then
        echo_message "Failed to create mount point. Exiting."
        exit 1
    fi
else
    echo_message "Mount point $MOUNT_POINT already exists."
fi

# Attempt to mount the partition
echo_message "Mounting $PARTITION to $MOUNT_POINT..."
sudo mount -t ext4 "$PARTITION" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo_message "Failed to mount $PARTITION. Please check the filesystem."
    exit 1
fi

echo_message "Successfully mounted $PARTITION to $MOUNT_POINT."

# Change ownership to the current user
echo_message "Changing ownership of $MOUNT_POINT to user '$CURRENT_USER'..."
sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo_message "Failed to change ownership. You may need to do this manually."
else
    echo_message "Ownership changed successfully."
fi

# Get UUID for fstab entry
UUID=$(sudo blkid -s UUID -o value "$PARTITION")
if [ -z "$UUID" ]; then
    echo_message "Error: Could not retrieve UUID for $PARTITION."
    exit 1
fi

# Add entry to /etc/fstab if it doesn't exist
if ! grep -q "$UUID" /etc/fstab; then
    echo_message "Adding entry to /etc/fstab..."
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 0" | sudo tee -a /etc/fstab > /dev/null
    if [ $? -ne 0 ]; then
        echo_message "Failed to add entry to /etc/fstab. Please check permissions."
        exit 1
    fi
else
    echo_message "Entry for $UUID already exists in /etc/fstab."
fi

# Test the fstab configuration by unmounting and remounting all filesystems
echo_message "Testing fstab configuration..."
sudo umount "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo_message "Failed to unmount $MOUNT_POINT. Please check if it's in use."
    exit 1
fi

sudo mount -a
if [ $? -ne 0 ]; then
    echo_message "Failed to remount filesystems. Check /etc/fstab for errors."
    exit 1
fi

echo_message "All operations completed successfully!"
