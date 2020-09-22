# ArchLinux Vloop
This tutorial is applicable to any Linux operating system based on Debian Linux,I'm using [ArchLinux 2020.09.01-x86_64](https://www.archlinux.org/) system for example.
## 1. Install ArchLinx on VHD file
You can install it on a fixed VHD file,or a non-partitioned img file,or a fixed with LVM VHD file,or an LVM on a real hard disk partition.
It is recommanded to install system with free software VirtualBox.Installation is omitted.
## 2.Install fixed ntfs-3g
Download modified ntfs-3g source file, and then go to the directory ,execute the following command:
```bash
./configure
make 
sudo make install
```
**Note** The purpose of dong this process aims to remove shutdown errors by systemd, konwn as buffer I/O errors.The method comes from the website [RootStorageDaemons](http://www.freedesktop.org/wiki/Software/systemd/RootStorageDaemons/).
## 3.Modify some system files
Two of the system files need to modify as follows:
```bash
/etc/mkinitcpio.conf
/usr/lib/initcpio/init 
```
### 3.1 Modifty `mkinitcpio` configuration file
Backup the file, and then modify the file with `nano` editor, etc.
```bash
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.back
sudo nano /etc/mkinitcpio.conf
```
Change two or three of these parameters as the following. These are added to the new `initramfs` kernel module and required binary command program files.
```bash
BINARIES="partx mount.fuse mount.ntfs-3g ntfs-3g shutdown "

MODULES="fuse ntfs loop"

HOOKS="base udev modconf block filesystems  keyboard usr fsck shutdown "
```
Some of software is recommanded when generate kernel.You should install the following software with `pacman`:
```bash
sudo pacman -S multipath-tools util-linux lvm2 mdadm
```
`multipath-tools` including `kpartx`tools.In some old edtions of archlinux,`mdadm_udev` should change to `mdadm`.
### 3.2 Modifty `init` file
Backup the file, and then modify the file with `nano` editor, etc.
```bash
sudo cp /usr/lib/initcpio/init  /usr/lib/initcpio/init.back
sudo nano /usr/lib/initcpio/init 
```
Add two pieces of code enclosed in the `############################# ##########`, as shown below:
```bash
# honor the old behavior of break=y as a synonym for break=premount
if [ "${break}" = "y" ] || [ "${break}" = "premount" ]; then
    echo ":: Pre-mount break requested, type 'exit' to resume operation"
    launch_interactive_shell
fi

	########################################################################
	###                   BOOT FROM VHD, VLOOP by niumao                 ###
	########################################################################

for x in $(cat /proc/cmdline); do

	case $x in

	vloop=*)
		VLOOP="${x#vloop=}"
		;;
	vlooppart=*)
		VLOOPPART="${x#vlooppart=}"
		;;	
	esac
done

if [ "$VLOOP" ]; then
		
        mkdir -p /host
        if  [ -x /sbin/blkid ]; then
		HOSTFSTYPE=$(/sbin/blkid -s TYPE -o value "${root}")
		[ -z "${HOSTFSTYPE}" -o  "${HOSTFSTYPE}"="ntfs" ] && HOSTFSTYPE="ntfs-3g"
	fi
	mount -t ${HOSTFSTYPE} -o rw  ${root} /host

	str=${VLOOP}

	disk_files="/host${str}"			
		
	# FIXME This has no error checking
	modprobe loop
	partx -av "${disk_files}"
	sleep 3

       	root="/dev/loop0${VLOOPPART}"

fi 

  	########################################################################
	###                 End,  BOOT FROM VHD, VLOOP by niumao             ###
	########################################################################

rootdev=$(resolve_device "$root") && root=$rootdev
unset rootdev

fsck_root

# Mount root at /new_root
"$mount_handler" /new_root

	########################################################################
	###                   BOOT FROM VHD, VLOOP by niumao                 ###
	########################################################################
		
		if [ -n "$VLOOP" -a -d /new_root/host ]; then
			mount -M /host /new_root/host
		fi
	
  	########################################################################
	###                 End,  BOOT FROM VHD, VLOOP by niumao             ###
	########################################################################

run_hookfunctions 'run_latehook' 'late hook' $LATEHOOKS
run_hookfunctions 'run_cleanuphook' 'cleanup hook' $CLEANUPHOOKS
```
## 4.Remake `initramfs` file.
Using the following command to generate the kernel:
```bash
sudo mkinitcpio -k $(uname -r) -g ~/initramfs-linux.img-$(uname -r)
```
The parameter `-k` represents the corresponding kernel version,and the `-g` represents the file name with the path for the generated `initramfs` file.The kernel version can be seen by looking up the folder name under `/lib/modules/`.
Copy the kernel into the root file in VHD file, you can also copy to other partition in the hard disk to boot the VHD.I copied the genrated kernel file `initramfs-linux.img` and `/boot/vmlinuz-linux` into the root directory in VHD file.
## 5. Boot menu settings
These two menu options can be used to automatically detect `UUID`.All you need to do is configure `GRUB4DOS` or `GRUB2` so that you can boot to either `GRUb4DOS` or `GRUB2`.

Some examples to boot VHD:
for GRUB4DOS:
```bash
title ArchLinux uuid-auto-probe
find --set-root --ignore-floppies --ignore-cd /arch.vhd
uuid ()
kernel  /vmlinuz-linux root=UUID=%?%  vloop=/vbuntufix/ARCHNEW.vhd vlooppart=p1
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
	linux	(lp0,1)/vmlinuz-linux root=UUID=${ddeeff}  vloop=$vhdfile vlooppart=p1
	initrd	(lp0,1)/initramfs-linux.img
}
```
**Note:** VHD can usually be mounted in a single partition,at this time `Vlooppart=p1`.If you have multiple partitions, be careful to change the value of the `vlooppart` parameter so that it points to the partition to boot.For example, if VHD has three partitions and root mounts on the third partition, the boot parameter is changed to `vlooppart=p3`.Logical partitioning is not supported.So if you have a lot of partitions, you can use the GPT format disk.If there are no partitions or the number of partitions does not exceed 4, you can use the MBR format and set all partitions as primary partitions.

