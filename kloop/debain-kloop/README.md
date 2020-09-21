# Debain Kloop
This tutorial is applicable to any Linux operating system based on Debian Linux,I'm using deepinV20Beta system for example.
## 1.Create a fixed size VHD virtual hard disk
Under Windows operating system,you can use diskpart management tool to create fixed size virtual disk files.Note that you need to use fixed-size virtual disk files instead of a dynamically allocated one to install VHD Linux. Here is an example of creating a VHD file:
```bat
diskpart
create vdisk file=<filepath> maimum=10240 type=fixed
select vdisk file=<filepath>
attach vdisk
create partition primary
format fs=ntfs quick label=<label name>
assign letter=<partition assign letter>
```
use `list disk` to see the virtual disk which is created just now,or use `list vol` to see the details of the disk.use `list partition` to see the details of the partition.
We can also using virtualbox to create a virtual hard disk file to install Linux.The process of installing Debain system is omitted here.
## 2. Install some of useful tools
At first,we should install `kpartx,kpartx-boot,util-linux,dm-setup,lvm2`.In the terminal of the virtualbox running system,we type the following command:
```bash
sudo apt-get install kpartx kpartx-boot util-linux dmsetup lvm2
```
## 3.Compile and install ntfs-3g tools
Use `apt-cache search ntfs-3g` we can find some of ntfs-3g tools.But here we fixed some problems of the ntfs-3g. So we use the project `ntfs-3g_ntfsprogs-2017.3.14.fixed` to install ntfs-3g.`ntfs-3g_ntfsprogs-2017.3.14.fixed` is the modified ntfs-3g source code.Compile and install it manually. After unziping to your `home` directory,open a terminal and go to the directory , execute the following commands in turn:
```bash
./configure
make
sudo make install
```
**Note: ** You need to install `gcc,g++ build-essential make` and other software in advance:
```bash
sudo apt install gcc,g++ build-essential make
```
## 4. Modify some files
Five files need to modify:·`local mkinitramfs modules ntfs_3g init`
### 4.1 Modify the `local` file
At first ,you need backup the system's local files
```bash
sudo cp /usr/share/initramfs-tools/scripts/local ~/local.backup
```
I'm familiar with `nano` editor,you can also use `vim gedit` ,etc.
```bash
sudo nano /usr/share/initramfs-tools/scripts/local
```
Make the appropriate changes as specified with the `local.pdf` file in the attachment.Typically modify the file in `local_mount()` function,and some sources also indicate that modify under `pre_mountroot` in the `mountroot()` function.We suggest to modify the file followed as `local.pdf` file.
### 4.2 Modify the `mkinitramfs` file
Backup the file:
```bash
sudo cp /usr/sbin/mkinitramfs ~/mkinitramfs.backup
```
And modify the file followed as file `mkinitramfs.pdf`
```bash
sudo nano /usr/sbin/mkinitramfs
```
### 4.3 Modify the `modules` file
This step is mainly to install some necessary modules for the kernel, backup and edit file:
```bash
sudo cp /etc/initramfs-tools/modules ~/modules.backup
sudo nano /etc/initramfs-tools/modules
```
And add some of the following kernel modules
```bash
loop
fuse
dm-mod
```
Or refer directly to modules.pdf to make the appropriate modifications.
### 4.4 Modify the `ntfs_3g` file
Backup and modify the file
```bash
sudo cp /usr/share/initramfs-tools/scripts/local-bottom/ntfs_3g ~/ntfs_3g
```
Copy the contents of `ntfs_3g` attached to this directory to cover the original contents and save them. It can also follows the `ntfs_3g.pdf` to modify the file. This step is mainly intended to resolve the "Buffer I/O error" during shutdown process on systemd Linux. Refered to the following website:[RootStorageDaemons](http://www.freedesktop.org/wiki/Software/systemd/RootStorageDaemons/) and [InitrdInterface](http://www.freedesktop.org/wiki/Software/systemd/InitrdInterface/).
### 4.5 Modify the `init` file
Backup and modify the file
```bash
sudo cp /usr/share/initramfs-tools/init ~/init
sudo nano /usr/share/initramfs-tools/init
```
Refer to `init.pdf` to modify the file.
## 5.Genrate the corresponding kernel file.
```bash
sudo /usr/sbin/mkinitramfs -o ~/initrd.img-$(uname -r)-generic 
```
Copy the generated these two files under a custom directory or under a root partition. By folder I mean the `ubuntu` directory.

## 6.Boot mode settings
### 6.1 A description of the system boot method
There are four ways to guide:`grub-efi,grub-i386-pc,grub4dos,grub4efi`
`grub-i386-pc,grub4dos` applies to `BIOS-MBR,Grub4DOS` automatic search UUID menu example.For UEFI boot, you can directly install the boot file in the appendix to the EFI partition to boot.For BIOS-MBR booted systems,You can set the files in the directory to the corresponding boot partition, and then modify the boot parameters of the hard disk, add `gldr` and so on.
### 6.2 Example of boot menu
Note the two parameters `kloop,kroot` passed to the kernel.
+ `kloop=<VHD file path>`
+ `kroot=<VHD system root partition>` 
In general is that `kroot=/dev/mapper/loop0p1`,If LVM is used, you need to set the parameter `klvm`.

A example of grub2
method one:
```bash
menuentry 'Deepin V20 Beta VHD '  --class deepin  {
	insmod gzio
	insmod part_msdos
	insmod part_gpt
	insmod ext2
	insmod ntfs
	insmod probe
	insmod search
    set vhdfile="/ubuntu/deepin.vhd"
	search --no-floppy -f --set=aabbcc $vhdfile 
	set root=${aabbcc}
	probe -u --set=ddeeff ${aabbcc}
	linux	/ubuntu/vmlinuz-5.3.0-3-generic root=UUID=${ddeeff} kloop=$vhdfile kroot=/dev/mapper/loop0p1 
	initrd	/ubuntu/initrd.img-5.3.0-3-generic
}
```
method two:
```bash
menuentry "Deepin V20 Beta VHD " --class deepin {
    insmod gzio
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod ntfs
    insmod probe
    set vhdfile="/ubuntu/deepin20beta.vhd"
    set root=(hd0,1)
    search --no-floppy -f --set=aabbcc  $vhdfile
    set root=${aabbcc}
    probe -u --set=ddeeff ${aabbcc}
    loopback lp0 $vhdfile
    linux	(lp0,1)/vmlinuz-5.3.0-3-amd64 root=UUID=${ddeeff}  kloop=$vhdfile  kroot=/dev/mapper/loop0p1 ro quiet splash 
    initrd	(lp0,1)/initrd.img-5.3.0-3-amd64
}
```
The second method requires the kernel file to be copied to the corresponding directory file. Here I copy the two kernel boot files to the root directory file in VHD.
## 7. Use the kernel to boot other systems
If you have a LINUX system installed using a fixed-size VHD, use the same version of the kernel module directory on the LINUX system as the `initrd. Img-xxxxxx-generic` that you made to boot VHD.For example, `/lib/modules/5.3.0-3-generic` copy to the `/lib/modules/` directory in the VHD system with permissions set to 755.You can use this Linux kernel to boot into the VHD system,otherwise it can't boot correctly or missing some of modules. It booted successfully on `Fedora Mageia OpensUse ArchLinux` and many other systems.
