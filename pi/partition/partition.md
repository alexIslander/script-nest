# Description
Since you're committed to the external drive boot and you want to automate the entire process, including the partition formatting and copy, let's create a robust, two-script solution. This will replicate the actions of $\text{rpi-clone}$ but specifically protect your `/dev/sda5` data partition.

I'll keep the scripts as simple and focused as possible.

-----

## 🛑 Critical Assumption for New Scripts

The following scripts assume the following based on your previous outputs:

1.  **Source Disk (SD Card):** $\text{/dev/mmcblk0}$
2.  **Target Disk (External Drive):** $\text{/dev/sda}$
3.  **Partitions to Format/Overwrite:** $\text{/dev/sda1}$ (Boot) and $\text{/dev/sda2}$ (Root)
4.  **Partition to KEEP:** $\text{/dev/sda5}$ (Your data partition)

-----

## 📜 Script 1: Preparation, Format, Copy ($\text{prepare\_and\_copy.sh}$)

This script will get the partition IDs, format $\text{sda1}$ and $\text{sda2}$, copy the OS content, and update the crucial $\text{cmdline.txt}$ file.

### 1\. Script Code ($\text{prepare\_and\_copy.sh}$)

Save the following code as $\text{prepare\_and\_copy.sh}$:

```bash
#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
NEW_BOOT="/mnt/new_boot"
ROOT_PART="/dev/sda2"
BOOT_PART="/dev/sda1"
# ---------------------

echo "--- 🛠️ Starting OS Copy Preparation and Execution ---"

...

echo "--- ✅ Copy Preparation Complete. Run kernel_fixer.sh next! ---"
```

-----

## 📜 Script 2: Kernel Fix & Final Configuration ($\text{kernel\_fixer.sh}$)

This script will be updated to include the automatic $\text{fstab}$ update, the kernel module copy, and the $\text{initrd}$ generation, all within the robust $\text{chroot}$ environment defined in your previous $\text{mount\_chroot.sh}$ script.

### 1\. Script Code ($\text{kernel\_fixer.sh}$ Updated)

Save the following code as $\text{kernel\_fixer.sh}$ (it replaces the previous version):

```bash
#!/bin/bash

# --- Configuration ---
NEW_ROOT="/mnt/new_root"
BOOT_PART="/dev/sda1"
ROOT_PART="/dev/sda2"
# ---------------------

echo "--- ⚙️ Starting Kernel Fixer and Final Config Process ---"

...

echo "--- ✅ Kernel Fixer Finished ---"
echo "Run unmount_chroot.sh, remove the SD card, and reboot."
```

-----

## 📝 Full Automated Workflow

Here is the complete sequence using all three scripts (`mount\_chroot.sh`, $\text{prepare\_and\_copy.sh}$, and the new $\text{kernel\_fixer.sh}$):

1.  **Initial Setup (Once):**

    ```bash
    chmod +x prepare_and_copy.sh mount_chroot.sh unmount_chroot.sh kernel_fixer.sh
    ```

2.  **Prepare and Copy OS (Only run this once):**

    ```bash
    sudo ./prepare_and_copy.sh
    ```

    *(Confirm the warning to format $\text{sda1}$ and $\text{sda2}$)*

3.  **Mount Environment and Fix Kernel:**

    ```bash
    sudo ./mount_chroot.sh
    sudo ./kernel_fixer.sh
    ```

4.  **Final Cleanup and Reboot:**

    ```bash
    sudo ./unmount_chroot.sh
    sudo poweroff
    ```

This final set of automated scripts is the most robust solution for a manual copy, incorporating all the fixes we identified.


----
----

# 📝 Manual fixing method

Just in case

It is extremely likely that the `PARTUUID`s in my previous example are **placeholders** or incorrect for your specific disk.

Because `PARTUUID`s are derived from the disk's unique signature (assigned when the partition table is created), I cannot know your real ones until you generate them. **If you use the wrong PARTUUIDs, your Pi will fail to boot.**

Here is how to find the **correct** values and fix them before you reboot.

### 1\. Find Your REAL Partition UUIDs

Run this command on your Pi (or the machine where the drives are plugged in):

```bash
sudo blkid
```

Look for the entries matching your **Target Disk** (`/dev/sda`). You will see output like this:

> `/dev/sda1: LABEL="boot" UUID="AAAA-BBBB" TYPE="vfat" PARTUUID="12345678-01"`
> `/dev/sda2: LABEL="rootfs" UUID="abcdef-1234..." TYPE="ext4" PARTUUID="12345678-02"`
> `/dev/sda5: LABEL="data" UUID="..." TYPE="ext4" PARTUUID="12345678-05"`

  * **Note:** If your disk is **MBR** formatted (standard for Pi), the PARTUUID will look like a short code with a suffix (e.g., `a1b2c3d4-01`).
  * If it is **GPT** formatted, it will be a long string (e.g., `88392819-2039-49...`).

### 2\. The Fix: Update the Config Files

You need to update two files on the **Source SD Card** (`/dev/mmcblk0`) so it knows where to look for the new system on the external drive.

#### A. Edit `cmdline.txt` (The Boot Pointer)

This tells the Pi kernel "The root filesystem is actually on the external drive now."

1.  Mount the SD card's boot partition (if not already mounted):
    ```bash
    sudo mount /dev/mmcblk0p1 /mnt/sd_boot
    ```
2.  Edit the file:
    ```bash
    sudo nano /mnt/sd_boot/cmdline.txt
    ```
3.  Find the text `root=PARTUUID=...`.
4.  **Replace** that ID with the **PARTUUID of your new external ROOT partition** (`/dev/sda2`).
      * *Example:* Change `root=PARTUUID=old-id-02` to `root=PARTUUID=12345678-02`
5.  **Critical:** Ensure everything stays on **one single line**. Do not add line breaks.
6.  Save (`Ctrl+O`, `Enter`) and Exit (`Ctrl+X`).

#### B. Edit `fstab` (The Mount Table)

This tells the OS how to mount drives once it starts running. You need to edit the `fstab` that is **located on the new external drive** (not the one currently running on the SD card).

1.  Mount your new external root partition:

    ```bash
    sudo mount /dev/sda2 /mnt/new_drive
    ```

2.  Edit the fstab file inside it:

    ```bash
    sudo nano /mnt/new_drive/etc/fstab
    ```

3.  Update the entries for `/boot` and `/`:

      * **For `/boot`:** Use the PARTUUID of your **SD Card Boot Partition** (`/dev/mmcblk0p1`). (Since the Pi 4/3 boots from SD, `/boot` must still point to the SD card).
      * **For `/` (Root):** Use the PARTUUID of your **External Root Partition** (`/dev/sda2`).
      * **For `/data` (sda5):** Add a line for your kept partition using its PARTUUID (`/dev/sda5`).

    *Example `fstab`:*

    ```text
    proc            /proc           proc    defaults          0       0
    PARTUUID=a1b2c3d4-01  /boot           vfat    defaults          0       2
    PARTUUID=12345678-02  /               ext4    defaults,noatime  0       1
    PARTUUID=12345678-05  /mnt/data       ext4    defaults          0       2
    ```

### Summary Checklist

| Config File | Location | Which PARTUUID to use? |
| :--- | :--- | :--- |
| **cmdline.txt** | SD Card (`/boot`) | **Target Root** (`sda2`) |
| **fstab** (Root entry) | External Drive (`/etc/fstab`) | **Target Root** (`sda2`) |
| **fstab** (Boot entry) | External Drive (`/etc/fstab`) | **Source Boot** (`mmcblk0p1`) |

### 🛑 Critical Warning on "Keeping sda5"

If the script you ran **re-created the partition table** (e.g., using `mklabel` or `o` in fdisk), the "Disk Signature" (the `12345678` prefix) **HAS CHANGED**.

This means even though you "kept" partition 5, its PARTUUID is likely different now (e.g., it changed from `old-id-05` to `new-id-05`). **Always run `sudo blkid` after partitioning to get the new correct IDs.**