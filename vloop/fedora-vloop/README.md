# Fedora Vloop

This tutorial is applicable to any Linux operating system based on Debian Linux,I'm using [CentOS 7.8 ](https://www.centos.org/) system for example.

# 1.Create a fixed size VHD virtual hard disk

First of all,create a fixed-size VHD file using virtualbox,and install centos linux system in the file.
# 2. Install some of useful tools

At first,we should install `kpartx,util-linux,dm-setup,lvm2`.In the terminal of the virtualbox running system,we type the following command:
```bash
sudo yum install kpartx util-linux device-mapper lvm2
```
# 3. Compile and install ntfs-3g

Download `ntfs-3g_ntfsprogs-2017.3.23-fixed` from the project,we compile and install it manually. After unziping to your home directory,open a terminal and go to the directory , execute the following commands in turn:
```bash
./configure
make
sudo make install
```
**Note:** You need to install `gcc,g++ build-essential make` and other software in advance:
```bash
sudo yum install gcc,g++ build-essential make
```
This step is mainly intended to resolve the "Buffer I/O error" during shutdown process on systemd Linux. Refered to the following website:[RootStorageDaemons](https://www.freedesktop.org/wiki/Software/systemd/RootStorageDaemons/) and [InitrdInterface](https://www.freedesktop.org/wiki/Software/systemd/InitrdInterface/).

# 4.Modify the file

Here we modify two files.The configuration of the file is that `/lib/dracut/dracut.conf.d/01-dist.conf.backup` the file and edit it:
```bash
sudo cp /lib/dracut/dracut.conf.d/01-dist.conf /lib/dracut/dracut.conf.d/01-dist.conf-backup
```
We can file the line where the string `install_optional_items+` in it,add `blkid losetup  partx mount.fuse mount.ntfs-3g ntfs-3g shutdown fuse loop` in the line,and fianlly modify it as follows:
```bash
install_optional_items+=" vi /etc/virc ps grep cat rm blkid losetup partx mount.fuse mount.ntfs-3g ntfs-3g shutdown fuse loop "
```
Comment out hostonly to make that line become as follows:
```bash
# hostonly=yes
```
# 5.Genrate the kernel

Download the `05-vhdmount-vloop.sh`, here we download the file in the home directory,and then open a terminal and using the following command to generate the kernel:
```bash
sudo dracut -i ~/05-vhdmount-vloop.sh /lib/dracut/hooks/pre-mount/05-vhdmount.sh  ~/initramfs-$(uname -r).img
```
The `initramfs-$(uname -r).img` file which is the kernel file to boot the VHD file generated in the home directory.Next,you should put the `initramfs-$(uname -r).img` file , the same version of vmlinuz file (which is located in directory `/boot/vmlinux-XXXXXXXXXXXXXX`) and the VHD file outside in a same directory.

# 6.Boot settings

Here we suppose that the three files are:`centos7.vhd,initramfs-3.10.0-1127.el7.x86_64.img,vmlinuz-3.10.0-1127.el7.x86_64`.Except that,we don't use LVM, and the root partition is on the first partition in the VHD file. So we set the parameter `vlooppart=p1`.

The boot menu as follows:

for GRUB4DOS:
```bash
title  CentOS 7 VHD
find --set-root --ignore-floppies --ignore-cd /vhd-disk/centos7.vhd
uuid ()
kernel   /boot/vmlinuz-3.10.0-1127.el7.x86_64  root=UUID=%?% vloop=/vhd-disk/centos7.vhd vlooppart=p1 
initrd   /boot/initramfs-3.10.0-1127.el7.x86_64.img
```

for grub2:
```bash
menuentry ' CentOS 7 VHD'  --class centos  {
	insmod gzio
	insmod part_msdos
	insmod part_gpt
	insmod ext2
	insmod ntfs
	insmod probe
	insmod search
    set vhdfile="/vhd-disk/centos7.vhd"
	search --no-floppy -f --set=aabbcc   $vhdfile
	set root=${aabbcc}
	probe -u --set=ddeeff ${aabbcc}
	linux	  /boot/vmlinuz-3.10.0-1127.el7.x86_64  root=UUID=${ddeeff} vloop=/vhd-disk/centos7.vhd vlooppart=p1   
	initrd	  /boot/initramfs-3.10.0-1127.el7.x86_64.img 
}
```
If you install CentOS with a fixed-size VHD and LVM is used on VHD,you can use the following menu to boot:
```bash
menuentry 'CentOS 7 VHD(Vloop) ' --class centos {
    insmod gzio
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod ntfs
    insmod probe
    set vhdfile="/vhd-disk/centos7.vhd"
    search --no-floppy -f --set=aabbcc  $vhdfile
    set root=${aabbcc}
    probe -u --set=ddeeff ${aabbcc}
    loopback lp0 $vhdfile
    linux     (lp0,1)/vmlinuz-3.10.0-1127.el7.x86_64  root=UUID=${ddeeff}  vloop=$vhdfile  vlooppart=p1 
    initrd    (lp0,1)/initramfs-3.10.0-1127.el7.x86_64.img

}
```
**Note1** : The `dracut` is made to correspond to the current kernel version.You can add the kernel version number to the end to get dracut used by other kernels.`ls /lib/modules/` is the name of each subdirectory in the dracut command,add the desired subdirectory name to the end of the dracut command.

**Note2** : The generated `dracut` file is large, about 45 MB. If you don't want add some of additional kernel modules, you can use `-o` to remove some `dracut` modules.
```bash
sudo dracut -i ~/05-vhdmount-vloop.sh /lib/dracut/hooks/pre-mount/05-vhdmount.sh -o " plymouth btrfs crypt dm dmraid lvm mdraid multipath cifs fcoe fcoe-uefi iscsi nfs nbd"  ~/initramfs-$(uname -r).img
```
But there are also over 35 MB. In addition, there will be some missing features such as network startup, network sharing, etc. So if you are not sure whether you need these features, it is recommended to use the original command in that instead of simplifying it.

**Note3** : The `lsinitrd initramfs-$(uname -r).img | less` command allows you to look inside `initramfs-$(uname -r).img` file's directory and see the various parameters.

