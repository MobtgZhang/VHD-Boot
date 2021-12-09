
## vfuseloop for booting dynamic virtual disk files
More ways to support virtual disk booting in more formats, like vhd,vdi,vmdk format.
Recently we have a research on how to boot linux from virtual disks such as VHD. It can be noted that the VHD booted by Kloop and Vloop modes has many restrictions:
1. Only for VHD format.
2. The file of VHD must be fixed in size.

The fixed-size vhd is actually no different from the raw format used in [WUBI](https://github.com/hakuna-m/wubiuefi/wiki) method, except with a header added.In fact, `kloop` method is not required. You can manually get to the partition starting position and use `-o loop, offset=XXXX`.So it's not that different from [WUBI](https://github.com/hakuna-m/wubiuefi/wiki).This is a clear loss of virtual disk snapshots, dynamic capacity, and other features that do not meet the requirements.The principle of the `vloop`,`kloop` and `wubi` method is as follows:
`(physical device)-> loop partition -> ext4`. The idea of vfuseloop originally was put forward by the following article: [deploy linux into and boot from vhd](https://unix.stackexchange.com/questions/309900/deploy-linux-into-and-boot-from-vhd/465215#465215).  

## How to solve the problems

`vdfuse` uses the kernel module of the open source project `virtualbox` to read and write to the `virtualbox` supported formats (at least `vhd,vmdk,vdi`) to mount loops and support dynamically sized virtual disk files. 

## Comple and install `vdfuse`

## Install software dependencies
```bash
sudo apt-get install subversion git
sudo apt install libfuse-dev virtualbox pkg-config
```
This step install some of precomplies files of `virtualbox`.
## Download the `vdfuse`
Here , the `vdfuse` is fixed by [NyaMisty](https://github.com/NyaMisty/) on [vdfuse](https://github.com/NyaMisty/vdfuse).Actually, the project is also forked from [vdfuse](https://github.com/NyaMisty/vdfuse).
Complie and install the `vdfuse`, and excute the command:
```bash
./autogen.sh
./fetch_vbox_headers.sh
./configure
make
sudo make install
```
Here comes two of the methods to generate kernels:

## `dracut` solutions
1. Download or clone the project from github: [dracut-vdfuseloop](https://github.com/NyaMisty/dracut-vdfuseloop).
```bash
git clone https://github.com/NyaMisty/dracut-vdfuseloop
```
2. Copy `90vdfuseloop` to `/usr/lib/dracut/modules.d`
```bash
sudo cp -r 90vdfuseloop /usr/lib/dracut/modules.d/
```
3. Modify the file: `/etc/dracut.conf.d/10-debian.conf`, and change the `hostonly=no`,or Comment out the line before the line of `add_drivers`.
4. Generate the kernel using dracut:
```bash
sudo dracut ~/initrd.img-$(uname -r) --force
```
Using `--force` to overwrite the kernel file if it exists.

5. Copy two files: `initrd.img-$(uname -r)` and `vmlinuz-$(uname -r)` to boot the system.
6. Configure the grub

for GRUB4DOS:
```bash
title Ubuntu 20.04 VMDK
find --set-root --ignore-floppies --ignore-cd /ubuntu/ubuntu20.04.vmdk
uuid ()
kernel /ubuntu/vmlinuz-5.4.0-42-generic rw rd.hostdev=UUID=%?% rd.vdisk=/ubuntu/ubuntu.vmdk rd.vdloop=/dev/vdhost/Partition1 rd.debug rd.shell verbose nomodeset
initrd /ubuntu/initrd.img-5.4.0-42-generic
```

for grub2:
```bash
menuentry 'ubuntu 20.04 VMDK vfuseloop Extention' --class ubuntu {
    insmod gzio
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod ntfs
    insmod probe
    set vhdfile="/ubuntu/ubuntu.vmdk"
    search --no-floppy -f --set=aabbcc  $vhdfile
    set root=${aabbcc}
    probe -u --set=ddeeff ${aabbcc}
    linux	/ubuntu/vmlinuz-5.4.0-42-generic rw rd.hostdev=UUID=${ddeeff} rd.vdloop=/dev/vdhost/Partition1 rd.vdisk=$vhdfile rd.debug rd.shell 
    initrd	/ubuntu/initrd.img-5.4.0-42-generic
}
```
Where the parameter `host` refers to the partition device file path of the physical disk where `vhd` or other format file is located;`root` parameter refers to the partition where Linux `rootfs` resides after the virtual disk file is mounted.After `vdfuse` is mounted, `EntireDisk` will form under `/dev/vdhost`, and every partition, such as `Partition1`. Generally, `Partition1` is the first primary partition. `vdisk` represents the path in the partition where the `vhd` or other format virtual disk file is located;The parameters `kernel` and `initrd` are set to the copied kernels.

## `initramfs-tool` solutions

**Thanks to**
+ [2011niumao](http://wuyou.net/home.php?mod=space&uid=434443)
+ [Misty](http://wuyou.net/home.php?mod=space&uid=412891)
+ [Deploy Linux into, and boot from, VHD](https://unix.stackexchange.com/questions/309900/deploy-linux-into-and-boot-from-vhd/465215#465215)
