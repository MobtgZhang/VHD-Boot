# ArchLinux Kloop
This tutorial is applicable to any Linux operating system based on Debian Linux,I'm using [ArchLinux 2020.09.01-x86_64](https://www.archlinux.org/) system for example.
## 1. Install ArchLinx on VHD file
You can install it on a fixed VHD file,or a non-partitioned img file,or a fixed with LVM VHD file,or an LVM on a real hard disk partition.
It is recommanded to install system with free software VirtualBox.Installation is omitted.
## 2. Install some softwares
At first,we should install `kpartx,kpartx-boot,util-linux,dm-setup,lvm2`.In the terminal of the virtualbox running system,we type the following command:
```bash
sudo pacman -S multipath-tools lvm2 device-mapper util-linux
```

## 3.Install fixed ntfs-3g
Download modified ntfs-3g source file, and then go to the directory ,execute the following command:
```bash
./configure
make 
sudo make install
```
**Note** The purpose of dong this process aims to remove shutdown errors by systemd, konwn as buffer I/O errors.The method comes from the website [RootStorageDaemons](http://www.freedesktop.org/wiki/Software/systemd/RootStorageDaemons/).
## 4.Modify some system files
Two of the system files need to modify as follows:
```bash
/etc/mkinitcpio.conf
/usr/lib/initcpio/init 
```
### 4.1 Modifty `mkinitcpio` configuration file
Backup the file, and then modify the file with `nano` editor, etc.
```bash
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.back
sudo nano /etc/mkinitcpio.conf
```
Change two or three of these parameters as the following. These are added to the new `initramfs` kernel module and required binary command program files.
```bash
BINARIES=( losetup partx mount.fuse mount.ntfs-3g ntfs-3g shutdown lvm vgscan vgchange )

MODULES=( fuse ntfs loop dm-mod )

HOOKS=( base udev modconf block keyboard lvm2 filesystems  mdadm_udev usr fsck shutdown )
```
Some of software is recommanded when generate kernel.You should install the following software with `pacman`:
```bash
sudo pacman -S multipath-tools util-linux lvm2 mdadm
```
`multipath-tools` including `kpartx`tools.In some old edtions of archlinux,`mdadm_udev` should change to `mdadm`.
### 4.2 Modifty `init` file
Backup the file, and then modify the file with `nano` editor, etc.
```bash
sudo cp /usr/lib/initcpio/init  /usr/lib/initcpio/init.back
sudo nano /usr/lib/initcpio/init 
```
First find the following statement(about 13 lines)
```bash
mount -t tmpfs run /run -o nosuid,nodev,mode=0755
```
Delete the parameter `nosuid`,and change to 
```bash
mount -t tmpfs run /run -o nodev,mode=0755
```
And then find the following paragraph:
```bash
rootdev=$(resolve_device "$root") && root=$rootdev
unset rootdev

fsck_root

# Mount root at /new_root
"$mount_handler" /new_root
```
And then change to
```bash
rootdev=$(resolve_device "$root") && root=$rootdev
unset rootdev

if [ -z "$kloop" ] && [ -z "$squashfs" ]; then

	fsck_root

	# Mount root at /new_root
	"$mount_handler" /new_root

fi
```
After that , add the code enclosed in the following comments in the attachment to the `init` file(with the two comments of course),save it and exit.
```bash
    ##############################################################
	#                BOOT FROM VHD, KLOOP by niumao              #
	##############################################################


	##############################################################
	#            end, BOOT FROM VHD, KLOOP by niumao             #
	##############################################################
```
## 5.Remake `initramfs` file.
Using the following command to generate the kernel:
```bash
sudo mkinitcpio -k $(uname -r) -g ~/initramfs-linux.img-$(uname -r)
```
The parameter `-k` represents the corresponding kernel version,and the `-g` represents the file name with the path for the generated `initramfs` file.The kernel version can be seen by looking up the folder name under `/lib/modules/`.
Copy the kernel into the root file in VHD file, you can also copy to other partition in the hard disk to boot the VHD.I copied the genrated kernel file `initramfs-linux.img` and `/boot/vmlinuz-linux` into the root directory in VHD file.
## 6. Boot menu settings
These two menu options can be used to automatically detect `UUID`.All you need to do is configure `GRUB4DOS` or `GRUB2` so that you can boot to either `GRUb4DOS` or `GRUB2`.

Some examples to boot VHD:
for GRUB4DOS:
```bash
title ArchLinux uuid-auto-probe
find --set-root --ignore-floppies --ignore-cd /arch.vhd
uuid ()
kernel  /vmlinuz-linux root=UUID=%?%  kloop=/vbuntufix/ARCHNEW.vhd kroot=/dev/loop0p1
initrd  /initramfs-linux.img
```

for GRUB2
```bash
menuentry 'ArchLinux' --class arch{
	insmod gzio
	insmod part_msdos
	insmod part_gpt
	insmod ext2
	insmod ntfs
	insmod probe
    set vhdfile="/vhd-disk/arch.vhd"
	search --no-floppy -f --set=aabbcc 
	set root=${aabbcc}
	probe -u --set=ddeeff ${aabbcc}
    loopback lp0 $vhdfile
	linux	(lp0,1)/vmlinuz-linux root=UUID=${ddeeff}  kloop=$vhdfile kroot=/dev/loop0p1
	initrd	(lp0,1)/initramfs-linux.img
}
```
## 7. `kloop` boot parameter settings for other cases
+ `img` file without partition table:`kloop=<img file path>` and other parameters are not set or `kroot=/dev/loop0`
+ fixed VHD file with LVM: `root=<the partition where VHD file partition located in>`,`kloop=<the VHD file with path name>`,`kroot=/dev/mapper/<vgn-lvn name>`,`klvm=<volume name>`.
+ LVM on the real partition: `root=<the partition where LVM located in>`,`kloop=1`,`klvm` and `kroot`are the same as above.

**Note:** If your ArchLinux has `kpartx` installed, you can replace `partx` with `kpartx` from all of the above.The difference is that for fixed VHD, the parameter `kroot` is different without LVM, and the other cases are the same.
Assume that the upper root partition of the VHD is the first primary partition (and so on):
For the `kpartx` case: `kroot=/dev/mapper/loop0p1`
For the case using `partx`: `kroot=/dev/loop0p1`
It's not the same thing, it's a mapper.
