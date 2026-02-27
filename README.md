# script-nest
Collection of bash scripts, to make life easier in terminal.

## 📝 Full Automated Workflow

Here is the complete sequence of commands you should run:

### Initial Setup (Once):

```bash
chmod +x mount_chroot.sh unmount_chroot.sh kernel_identifier.sh kernel_fixer.sh
```

### Mount and Identify:

```bash
sudo ./mount_chroot.sh

sudo ./kernel_identifier.sh
```

Check the output of the identifier script for the version and confirm it saved to kernel_version.txt.

### Fix Kernel/Boot:

```bash
sudo ./kernel_fixer.sh
```

### Final Cleanup and Reboot:

```bash
sudo ./unmount_chroot.sh

sudo poweroff
```

This automated process addresses all the failed steps we encountered: the manual mounting, the missing `/dev/pts` and `/tmp` bind-mounts, the unknown kernel package name, and the missing kernel modules (`/lib/modules`). This is your best chance for a successful USB boot!
