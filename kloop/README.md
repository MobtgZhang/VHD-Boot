# Kloop 
## 1. Origin and naming of Kloop
As far as I know, there are several ways to install Linux on the virtual hard drive and boot the computer directly into the Linux system in the VHD:
+ WUBI method (Which often used in ubuntu cd-install media such as ubuntu14.04 in the early)
+ Vloop method on webcite of [vmlite](http://www.vmlite.org/)(for ubuntu fedora)
+ hook-img method by carbonjiao(for ArchLinux) 

Here lists the method which is based on the kpartx on Vloop pattern (Used for ubuntu ArchLinux Fedora Opensuse Mageia). Boot Linux from Kloop mode began with an idea proposed by webmaster jxdeng on [WuYou BBS](http://bbs.wuyou.net/forum.php):Bootstrap LVM on VHD using a vloop. This requires modification of the Vloop mode. At that time,another webmaster [niumao](http://bbs.c3.wuyou.net/home.php?mod=space&uid=434443) reintegrate the vloop mode and named it kloop mode. It refers to the boot method based on the kpartx command and the loop device,or it's a loop mode that is completely controlled by the user.It can boot non-partitioned IMG systems, fixed VHD system and fixed VHD which is using LVM system,including LVM system on hard disk partitions.
There are four main parameters of kloop mode: `root kloop kroot klvm`
# 2. How to use the kloop parameters
+ **root:** This method often refers to the hard disk partition where the VHD file located.The value of the **root** parameter such as `root=/dev/sdaX` or `root=UUID=XXXXXXXXXXXXXXXXXXXX`.
+ **kloop:** The `kloop` parameter is the same as the  `vloop` parameter,just a name change. The value of the `kloop` parameter is the name of the path of VHD file.For example:
`kloop=/ubuntu/deepin.vhd`
+ **kroot:** The `kroot` parameter is the device name of the root paratition after starting the Linux.For example:
`kroot=/dev/mapper/loop0p1`
The corresponding relationship of the old parameter `vloop` is as follows:
If the old parameter describes as `vlooppart=p1`,then `kroot=/dev/mapper/loop0p1`.In the parameter `kroot=/dev/mapper/loopXpY`,the parameter `X` refers to the loop device,and anther parameter `Y` refers to the paratition of the looped device.
As you can see,the benefit of using `kroot` parameter is that the root device is completely user-specified,which gives you a lot of freedom to control the boot process.
Note: In the test,we fonund that ,for example `kroot=/dev/dm-1`,`kroot=/dev/dm-3` is also avaliable.
+ **klvm:** I don't have much idea about  this paramter.If you are using LVM on fixed VHD, you need to set the `klvm` parameter to name the volume group. For example, you use virtualbox to install fedora in a fixed-size VHD by default. At this time ,the parameter `klvm=fedora`,and the parameter `kroot=/dev/mapper/fedora-root` or `kroot=/dev/fedora/root`
## 3. How to boot a linux using a grub2 or grub4dos menu 

Here are examples of the menu to boot the fixed VHD using lvm:
for grub2
```bash
menutry "Fedora 32 LVM-VHD " --class fedora{
    insmod gzio
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod ntfs
    insmod probe
    set root=(hd0,1)
    set vhdfile="/fedora/fedora32-lvm.vhd"
    search --no-floppy -f --set=aabbcc $vhdfile
    set root=${aabbcc}
    probe -u --set=ddeeff ${aabbcc}
    linux /fedora/vmlinuz-fedora root=UUID=${ddeeff} kloop=$vhdfile kroot=/dev/mapper/fedora-root klvm=fedora
    initrd	/fedora/dracut-fedora-kloop
}
```
Also it can boot from debian linux initrd:
```bash
menutry "Fedora 32 LVM-VHD " --class fedora{
    insmod gzio
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod ntfs
    insmod probe
    set root=(hd0,1)
    set vhdfile="/fedora/fedora32-lvm.vhd"
    search --no-floppy -f --set=aabbcc $vhdfile
    set root=${aabbcc}
    probe -u --set=ddeeff ${aabbcc}
    linux /fedora/vmlinuz-5.3.0-3-amd64 root=UUID=${ddeeff} kloop=$vhdfile kroot=/dev/mapper/fedora-root klvm=fedora
    initrd	/ubuntu/initrd.img--5.3.0-3-amd64
}
```
for grub4dos
```bash
title Fedora 32 LVM-VHD
find --set-root --ignore-floppies --ignore-cd /fedora/fedora32lvm.vhd
uuid ()
kernel /fedora/vmlinuz-fedora root=UUID=%?% kloop=$vhdfile kroot=/dev/mapper/fedora-root klvm=fedora
initrd /fedora/dracut-fedora-kloop
```
The details of the menu can be found in the project.
## 4. Description of startup parameters for virtual disk in other situations where kloop mode can boot
+ IMG files without partition table:`kloop=<path of img file>`,don't set `kroot,klvm` ,or `kroot=/dev/loop0`
+ Fixed VHD without LVM files: `kloop=<path of VHD file>,kroot=/dev/mapper/loop0pX`,don't set klvm.You can also use the type such as `kroot=/dev/dm-1`,`kroot=/dev/dm-3`.
+ LVM on hard disk: `root=<partition on hard disk>,kroot=/dev/mapper/XXX-XXX kloop=1 klvm=<volume group name>`

## Thanks to
[1] [2011niumao](http://bbs.c3.wuyou.net/home.php?mod=space&uid=434443)
