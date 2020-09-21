# Kloop 
## 1. Kloop 的起源与命名

在虚拟硬盘上安装LINUX并且引导电脑直接启动到VHD内的LINUX系统,据我所知到目前为止有这样几种方式:
+ WUBI 方法 (经常在早期ubuntu的CD安装介质中使用，例如ubuntu14.04)
+ [vmlite](http://www.vmlite.org/)网站上提及到的vloop的方式启动 (对于 ubuntu fedora系统)
+ carbonjiao给出的hook-img方式 (对于 ArchLinux) 
这里列举出基于kpartx命令vloop模式(用于 ubuntu ArchLinux Fedora Opensuse Mageia操作系统). KLOOP的模式起源于[无忧启动论坛](http://bbs.wuyou.net/forum.php)网友 jxdeng 提出的一个想法： 使用vloop方式引导VHD上的LVM.在那时候，另外一位网友[niumao](http://bbs.c3.wuyou.net/home.php?mod=space&uid=434443) 重新整合了vloop启动的方式并命名它为kloop方式. 指的是基于kpartx命令和LOOP设备的引导方式.或者,指完全由用户控制的loop引导模式.它可以引导无分区的img系统,固定vhd系统,固定vhd并且使用LVM系统,以及硬盘分区上LVM系统
kloop 引导方式有四个参数: `root kloop kroot klvm`
## 2. 如何使用kloop参数
+ **root:** 这个参数经常指的是VHD文件在硬盘分区上的位置. **root** 参数的值通常是指 `root=/dev/sdaX` 或者是 `root=UUID=XXXXXXXXXXXXXXXXXXXX`.
+ **kloop:** `kloop`和`vloop` 参数是一致的，只是改变了名字而已. `kloop` 参数的值指的是VHD文件的名字，例如 `kloop=/ubuntu/deepin.vhd`
+ **kroot:** `kroot`的值是Linux启动以后根分区的设备名称.例如:`kroot=/dev/mapper/loop0p1`. 与旧参数vlooppart的对应关系如下:如果旧参数`vlooppart=p1`,则 `kroot=/dev/mapper/loop0p1`.参数`kroot=/dev/mapper/loopXpY`,参数字母 `X` 指的是启动的回环设备(loop),另外一个参数字母 `Y`指的是回环设备(loop)指向的分区.可以看出,使用`kroot `的好处是根设备完全由用户指定,这样就有很大的自由来控制启动过程. 
注释:在测试中，我们发现,例如这样的参数`kroot=/dev/dm-1`,`kroot=/dev/dm-3` 也是可行的.
+ **klvm:** 目前我对这个参数的值用法了解不多.如果你正在使用基于LVM固定大小的VHD系统，你需要设置 `klvm` 的值为卷组(volume group)名称，例如你使用virtualbox在固定大小的VHD安装默认的fedora系统。在这种情况下，参数`klvm=fedora`,参数`kroot=/dev/mapper/fedora-root` 或 `kroot=/dev/fedora/root`
## 3. 如何使用 grub2 或者 grub4dos 菜单启动Linux 
这里有一些例子启动用lvm的VHD系统：
对于 grub2
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
当然也可以从debian系的linux内核启动:
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
对于 grub4dos
```bash
title Fedora 32 LVM-VHD
find --set-root --ignore-floppies --ignore-cd /fedora/fedora32lvm.vhd
uuid ()
kernel /fedora/vmlinuz-fedora root=UUID=%?% kloop=$vhdfile kroot=/dev/mapper/fedora-root klvm=fedora
initrd /fedora/dracut-fedora-kloop
```
详细的菜单可以在本项目中找到.
## 4. kloop 可引导的其他情形下虚拟磁盘的启动参数说明
+ 无固定分区的IMG 文件:`kloop=<img文件目录>`,不需要设置 `kroot,klvm` ,或者是设置 `kroot=/dev/loop0`
+ 无LVM的固定大小VHD: `kloop=<VHD文件目录>,kroot=/dev/mapper/loop0pX`,不需要设置`klvm`.当然可以适用参数`kroot=/dev/dm-1`,`kroot=/dev/dm-3`.
+ 硬盘上适用LVM `root=<硬盘上的分区>,kroot=/dev/mapper/XXX-XXX kloop=1 klvm=<卷组名称>`

