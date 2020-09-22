# Debain Vloop
This tutorial is applicable to any Linux operating system based on Debian Linux,I'm using [Elementary OS 5.1](https://elementary.io/) system for example.
## 1.Create a fixed size VHD virtual hard disk
Under Windows operating system,you can use diskpart management tool to create fixed size virtual disk files.Note that you need to use fixed-size virtual disk files instead of a dynamically allocated one to install VHD Linux.24GB size or larger is recommended,at least 8GB.Create a primary partition with 9GB in a vhd file and 1GB for swap is recommanded if you use to a MBR partition. If you use GPT partition to boot the system,it's okey to create three partitions of a VHD file,first partition is for EFI partition with type of fat32 and size of 300MB,second partition is for swap partition with size of 2GB, and the rest partition is for root partition with type of ext4 and size of 10GB. And then download the elementary os ISO installation file, install the system in the VHD file with virtualbox,it's omitted here.
## 2. Requirements of the software
First of all,some necessary softwares are recommanded here.You can install softwares under the terminial using the following commands:
```bash
sudo apt-get install kpartx kpartx-boot util-linux lvm2 dmsetup
```
Here `kpartx` is used for mount a VHD file during the boot process,`util-linux` including some of useful linux tools for boot.
## 3.Compile and install fixed ntfs-3g tools.
Use `apt-cache search ntfs-3g` we can find some of ntfs-3g tools.But here we fixed some problems of the ntfs-3g. So we use the project `ntfs-3g_ntfsprogs-2017.3.14.fixed` to install ntfs-3g.`ntfs-3g_ntfsprogs-2017.3.14.fixed` is the modified ntfs-3g source code.Compile and install it manually. After unziping to your `home` directory,open a terminal and go to the directory , execute the following commands in turn:
```bash
./configure
make
sudo make install
```
**Note:**You need to install `gcc,g++ build-essential make` and other software in advance:
```bash
sudo apt install gcc,g++ build-essential make
```
## 4.Modify files
In order to boot the system in VHD file,we should modify some system files in the installed system in VHD file.Including the following five files:
`local init mkinitramfs modules ntfs_3g`
These files are stored in the following folders:
```bash
/usr/share/initramfs-tools/scripts/local
/usr/share/initramfs-tools/init
/usr/sbin/mkinitramfs
/usr/share/initramfs-tools/scripts/local-bottom/ntfs_3g
/etc/initramfs-tools/modules
```
### 4.1 Modify the `local` file
Backup and edit the following file:
```bash
sudo cp /usr/share/initramfs-tools/scripts/local /usr/share/initramfs-tools/scripts/local.back
sudo nano /usr/share/initramfs-tools/scripts/local
```
Make the appropriate changes as specified with the `local` file in the attachment.Typically,the main modifications is under the `local_mount()` function in the file.
### 4.2 Modify the `init` file
Backup and edit the following file:
```bash
sudo cp /usr/share/initramfs-tools/init /usr/share/initramfs-tools/init.back
sudo nano /usr/share/initramfs-tools/init
```
Make the appropriate changes as specified with the `init` file in the attachment.This step aims to add some variables into the  kernel file.
### 4.3 Modify the `modules` file
This step is mainly to install some necessary modules for the kernel, backup and edit file:
```bash
sudo cp /etc/initramfs-tools/modules /etc/initramfs-tools/modules.backup
sudo nano /etc/initramfs-tools/modules
```
And add some of the following kernel modules
```bash
loop
fuse
dm-mod
```
Or refer directly to `modules` file to make the appropriate modifications.
### 4.4 Modify the `mkinitramfs` file
Backup the file:
```bash
sudo cp /usr/sbin/mkinitramfs /usr/sbin/mkinitramfs.backup
```
And modify the file followed as file `mkinitramfs`.
```bash
sudo nano /usr/sbin/mkinitramfs
```
The file changes often add some of `util-linx` tools when generating kernels.
### 4.5 Modify the `ntfs_3g` file.
Backup and modify the file
```bash
sudo cp /usr/share/initramfs-tools/scripts/local-bottom/ntfs_3g /usr/share/initramfs-tools/scripts/local-bottom/ntfs_3g.back
```
Copy the contents of `ntfs_3g` attached to this directory to cover the original contents and save them. It can also follows the `ntfs_3g.pdf` to modify the file. This step is mainly intended to resolve the "Buffer I/O error" during shutdown process on systemd Linux. Refered to the following website:[RootStorageDaemons](http://www.freedesktop.org/wiki/Software/systemd/RootStorageDaemons/) and [InitrdInterface](http://www.freedesktop.org/wiki/Software/systemd/InitrdInterface/).

## 5.Genrate the corresponding kernel file.
```bash
sudo /usr/sbin/mkinitramfs -o ~/initrd.img-$(uname -r) 
```
Copy the generated these two files under a custom directory or under a root partition. By folder I mean the `ubuntu` directory.

## 6.Boot settings
There are four ways to guide:`grub-efi,grub-i386-pc,grub4dos,grub4efi`,you can choose a appropriate configuration to install boot tools into you hardware.
Here are some examples of boot menu.Notice the two parameters `vloop` and `vlooppart` passed to kernel.`vloop` often means the path of the vhd files ,and `vlooppart` means the serial number of the root partition in the vhd file.

For grub4dos:
```bash
title Elementary OS 5.1 VHD
find --set-root --ignore-floppies --ignore-cd /ubuntu/elementary.vhd
uuid ()
kernel /ubuntu/vmlinuz-4.15.0-118-generic  root=UUID=%?% vloop=/ubuntu/elementary.vhd vlooppart=p1 
initrd /ubuntu/initrd.img-4.15.0-118-generic
```

For grub2:
```bash
menuentry 'Elementary OS 5.1 VHD'  --class elementary  {
	insmod gzio
	insmod part_msdos
	insmod part_gpt
	insmod ext2
	insmod ntfs
	insmod probe
	insmod search
    set vhdfile='/ubuntu/elementary.vhd'
	search --no-floppy -f --set=aabbcc $vhdfile
	set root=${aabbcc}
	probe -u --set=ddeeff ${aabbcc}
	linuxefi	/ubuntu/vmlinuz-4.15.0-118-generic root=UUID=${ddeeff} vloop=$vhdfile vlooppart=p1 
	initrdefi	/ubuntu/initrd.img-4.15.0-118-generic
}
```
If you copy the two kernel boot files to the root directory in the vhd file,you can write the menu klike this:
```bash
menuentry 'Elementary OS 5.1 VHD'  --class elementary  {
	insmod gzio
	insmod part_msdos
	insmod part_gpt
	insmod ext2
	insmod ntfs
	insmod probe
	insmod search
    set vhdfile='/ubuntu/elementary.vhd'
    set root=(hd0,1)
	search --no-floppy -f --set=aabbcc $vhdfile
	set root=${aabbcc}
	probe -u --set=ddeeff ${aabbcc}
    loopback lp0 $vhdfile
	linuxefi	(lp0,1)/vmlinuz-4.15.0-118-generic root=UUID=${ddeeff} vloop=$vhdfile vlooppart=p1 
	initrdefi	(lp0,1)/initrd.img-4.15.0-118-generic
}
```
## 7. Use the kernel to boot other systems
If you have a LINUX system installed using a fixed-size VHD, use the same version of the kernel module directory on the LINUX system as the `initrd. Img-xxxxxx-generic` that you made to boot VHD.For example, `/lib/modules/4.15.0-118-generic` copy to the `/lib/modules/` directory in the VHD system with permissions set to 755.You can use this Linux kernel to boot into the VHD system,otherwise it can't boot correctly or missing some of modules. It booted successfully on `Fedora Mageia OpensUse ArchLinux` and many other systems.
**Note:** You should change the root directory access in file A. If you do not, you may not be able to load the kernel and start the operating system because of access issues. So modifty it in the VHD file:
```bash
sudo nano /etc/fstab
```
The `/etc/fstab` file contains the following fields,separated by spaces or tabs:
```bash
<file system>	<dir>	<type>	<options>	<dump>	<pass>
```
+ **`<file system>`** The partition or storage device to mount.
+ **`<dir>`** Where `<file system>` mount. 
+ **`<type>`** system file tyeps of the devices or the partitions.Linux System supports many different filesystem types to mount devices or partitions: `ext2,ext3, ext4, reiserfs,xfs, jfs, smbfs,iso9660, vfat, ntfs,swap` and `auto`.If you set to `auto`, the mount command guesses the type of file system being used, which is useful for mobile devices like CDROM and DVD.
+ **`<options>`** Parameters used during mount. Note that some mount parameters are specific to a particular file system.Some commonly used parameters are:
  + `auto` Mount automatically at startup or when you type the `mount -a` command.
  + `noauto` Only mounted under your command.
  + `exec` Allows binary files for this partition to be executed.
  + `noexec` Binaries on this file system are not allowed to be executed.
  + `ro` Mounts the file system in read-only mode.
  + `rw` Mounts the file system in read - write mode.
  + `users` Allows any user to mount this file system. If there is no definition displayed, `noexec, nosuid, nodev` parameters are implicitly enabled.
  + `users` Allows users in all Users groups to mount the file system.
  + `nouser` Only the root user can be mounted.
  + `owner` Allows the device owner to mount.
  + `sync` I/O synchronizes.
  + `async` I/O asynchronous.
  + `dev` Resolves block special devices on the file system.
  + `nodev` Does not resolve block special devices on the file system.
  + `suid` Allows `suid` manipulation and set the `sgid` bit.This parameter is usually used for special tasks that allow the custom user to temporarily raise privileges while running the program.
  + `nosuid` Disables `suid` manipulation and sets the `sgid` bit.
  + `noatime` Does not update inode access records on the file system, which improves performance (see the `atime` parameter).
  + `nodiratime` Does not update directory inode access records on the file system, which improves performance (see the `atime` parameter).
  + `relatime` Updates the inode Access record in real time.Only access in the record earlier than the current access will be updated(Similar to `notime`, but does not interrupt processes such as `mutt` or other programs that detect whether files have been modified since the last time they were accessed.), which can improve performance (see the `atime` parameter).
  + `flush` `vfat`  option, flush data more frequently, copy dialog box or progress bar disappear after all data is written.
  + `default` use default mount parameters for file systems. For example, type of `ext4` default parameters are `rw, suid, dev, exec, auto, nouser, async`.
+ **`<dump>`**  The `dump` tool uses it to determine when to back up. `dump` examines its contents and uses numbers to determine whether or not to back up the file system.The allowed numbers are 0 and 1.0 means ignore, and 1 means backup.Most users don't have dump installed, `<dump>` should set to 0 for them.
+ **`<pass>`** `fsck` read `<pass>` to determine the order in which the file system needs to be checked.The allowed numbers are 0, 1, and 2.The root directory should have the highest priority 1, and all other devices that need to be checked should be set to 2. 0 to indicate that the device will not be checked by `fsck`.

You can set the values following the notations above.You should note that the `init` file also covers a number of file directories and how to read them.
