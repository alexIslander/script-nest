# Raspberry Pi Setup Guide

## Initial Setup

Partition the hard drive according to your needs. (32-64-128GB for system)

Install OS with the new awesome installer

Customize the install setting up: wifi, ssh, locale

```bash
sudo raspi-config
```

## User Management

Create a new user other than default pi: See more in Commands in -User management- section

OR run this scripts:

```bash
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/create_cloned_user.sh -o create_cloned_user.sh
bash create_cloned_user.sh
```

Then delete pi user:

```bash
su alex
sudo deluser pi
```

## Boot Configuration

Activate bootmenu selector and update boot order according to your need in raspi-config. [How to install and use the new Raspberry Pi boot menu](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#the-boot-menu)

## System Updates

Setup a scheduled system update script execution:

```bash
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/scheduled_sys_update.sh | bash
```

## Mount Data Partitions

Mount discs (sda5, sda6):

```bash
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/mount_drive.sh -o mount_drive.sh
bash mount_drive.sh /dev/sda5
bash mount_drive.sh /dev/sda6
```

## Migrate OS from SD Card to SSD

Before installing CasaOS, if you want to migrate your Raspberry Pi OS from the SD card to an external SSD/HDD for better performance and reliability, use the following automated workflow:

### Download Migration Scripts

```bash
mkdir -p ~/partition_migration
cd ~/partition_migration
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/partition/prepare_and_copy.sh -o prepare_and_copy.sh
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/partition/mount_chroot.sh -o mount_chroot.sh
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/partition/kernel_fixer.sh -o kernel_fixer.sh
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/partition/unmount_chroot.sh -o unmount_chroot.sh
chmod +x *.sh
```

### Full Automated Workflow

The migration process consists of three main steps:

1. **Prepare and Copy OS** - Formats the target partitions (sda1 for boot, sda2 for root), copies the entire OS from SD card to SSD, and updates boot configuration:
   ```bash
   sudo ./prepare_and_copy.sh
   ```
   ⚠️ **Warning:** This will format and delete all data on `/dev/sda1` and `/dev/sda2`. Your data partition (`/dev/sda5`) will be preserved.

2. **Mount Environment and Fix Kernel** - Sets up chroot environment and fixes kernel modules, updates fstab with correct PARTUUIDs:
   ```bash
   sudo ./mount_chroot.sh
   sudo ./kernel_fixer.sh
   ```

3. **Final Cleanup and Reboot** - Unmounts everything and prepares for boot from SSD:
   ```bash
   sudo ./unmount_chroot.sh
   sudo poweroff
   ```
   After poweroff, **remove the SD card** and power the Pi back on. It should boot from the SSD.

**Note:** The scripts automatically detect and remove SD card partition references from fstab, ensuring the SSD can boot independently. For detailed information, see [partition.md](partition/partition.md).

## Install Docker

```bash
curl -sSL https://raw.githubusercontent.com/alexIslander/script-nest/main/pi/install_docker.sh | bash
```

Or

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

## Install CasaOS

```bash
curl -fsSL https://get.casaos.io | sudo bash
```

