#! /bin/bash
# This script is for dracut, and boot from kloop or vloop method

KLOOP=$(getarg kloop=)
KROOT=$(getarg kroot=)
KLOOPFSTYPE=$(getarg kloopfstype=)
KLVM=$(getarg  klvm=)
HOSTFSTYPE=$(getarg hostfstype=)
HOSTHIDDEN=$(getarg hosthidden=)
SQUASHFS=$(getarg squashfs=)
UPPERDIR=$(getarg upperdir=)
WORKDIR=$(getarg workdir=)

VLOOP=$(getarg vloop=)
VLOOPPART=$(getarg vlooppart=)
VLOOPFSTYPE=$(getarg vloopfstype=)
HOSTFSTYPE=$(getarg hostfstype=)


export KLOOP
export KROOT
export KLOOPFSTYPE
export KLVM
export HOSTFSTYPE
export HOSTHIDDEN
export SQUASHFS
export UPPERDIR
export WORKIDR

export VLOOP
export VLOOPPART
export VLOOPFSTYPE
export HOSTFSTYPE


if [ -n "$UPPERDIR" ] && [ -n $"WORKDIR" ];  then

	### reset the value of the root variable 
	HOSTDEV="${root#block:}"

	if ismounted "$NEWROOT"; then
		umount "$NEWROOT"
	fi
			
	###  auto probe the fs-type of the partition in which vhd-file live and mount it  /host 
	mkdir -p /host
	if [ -z "${HOSTFSTYPE}" ]; then
		HOSTFSTYPE="$(blkid -s TYPE -o value "$HOSTDEV")"
		[ -z "${HOSTFSTYPE}"  -o  "${HOSTFSTYPE}" = "ntfs" ] && HOSTFSTYPE="ntfs-3g" 
	fi
	[ "${HOSTFSTYPE}" = "ntfs-3g" ] || modprobe ${HOSTFSTYPE}
	mount -t "${HOSTFSTYPE}" -o rw   $HOSTDEV /host
	
	###try to boot from upperdir
	mkdir  /run/tmpreadroot 
	mount -t overlay overlay -o lowerdir=/run/tmpreadroot,upperdir=/host$UPPERDIR,workdir=/host$WORKDIR $NEWROOT

	### mount /host in initrd to /host of the realrootfs
	if [  "${HOSTHIDDEN}" != "y" ] ; then
		[ -d "${NEWROOT}"/host ] || mkdir -p ${NEWROOT}/host 
		mount -R /host   ${NEWROOT}/host
	fi
fi

if [ -n "$SQUASHFS" ];  then

	### reset the value of the root variable 
	HOSTDEV="${root#block:}"

	if ismounted "$NEWROOT"; then
		umount "$NEWROOT"
	fi
			
	###  auto probe the fs-type of the partition in which vhd-file live and mount it  /host 
	mkdir -p /host
	if [ -z "${HOSTFSTYPE}" ]; then
		HOSTFSTYPE="$(blkid -s TYPE -o value "$HOSTDEV")"
		[ -z "${HOSTFSTYPE}"  -o  "${HOSTFSTYPE}" = "ntfs" ] && HOSTFSTYPE="ntfs-3g" 
	fi
	[ "${HOSTFSTYPE}" = "ntfs-3g" ] || modprobe ${HOSTFSTYPE}
	mount -t "${HOSTFSTYPE}" -o rw   $HOSTDEV /host
	
	###try to boot from squashfs
	mkdir /run/upperdir /run/lowerdir /run/workdir
	mount /host$SQUASHFS /run/lowerdir
	mount -t overlay overlay -o lowerdir=/run/lowerdir,upperdir=/run/upperdir,workdir=/run/workdir $NEWROOT

	### mount /host in initrd to /host of the realrootfs
	if [  "${HOSTHIDDEN}" != "y" ] ; then
		[ -d "${NEWROOT}"/host ] || mkdir -p ${NEWROOT}/host 
		mount -R /host   ${NEWROOT}/host
	fi
fi	

if [ -n "$KLOOP" ]; then

	### reset the value of the root variable 
	HOSTDEV="${root#block:}"
	[ -n "$KROOT" ]  ||  root="/dev/loop0"
	[ -n "$KROOT" ]  &&  root="$KROOT"
	realroot="$root"
	export root
	if ismounted "$NEWROOT"; then
		umount "$NEWROOT"
	fi
			
	###  auto probe the fs-type of the partition in which vhd-file live and mount it  /host 
	mkdir -p /host
	if [ -z "${HOSTFSTYPE}" ]; then
		HOSTFSTYPE="$(blkid -s TYPE -o value "$HOSTDEV")"
		[ -z "${HOSTFSTYPE}"  -o  "${HOSTFSTYPE}" = "ntfs" ] && HOSTFSTYPE="ntfs-3g" 
	fi
	[ "${HOSTFSTYPE}" = "ntfs-3g" ] || modprobe ${HOSTFSTYPE}
	mount -t "${HOSTFSTYPE}" -o rw   $HOSTDEV /host
	
	### mount the vhd-file on a loop-device
	if [ "${KLOOP#/}" != "${KLOOP}" ]; then
		modprobe  loop 
		kpartx -av /host$KLOOP
		[ -e "$realroot" ] ||  sleep 3
	fi

	### probe lvm on vhd-file and active them
	if [ -n "$KLVM" ];  then
		modprobe  dm-mod
		vgscan
		vgchange  -ay  "$KLVM"
		[ -e "$realroot" ] ||  sleep 3
	fi 

	### mount the realroot / in vhd-file on $NEWROOT 
	if [ -z "${KLOOPFSTYPE}" ]; then
		KLOOPFSTYPE="$(blkid -s TYPE -o value "$realroot")"
		[ -z "${KLOOPFSTYPE}" ] && KLOOPFSTYPE="ext4"
	fi
	[ -e "$realroot" ] || sleep 3
	mount -t "${KLOOPFSTYPE}" -o rw $realroot $NEWROOT
	
	### mount /host in initrd to /host of the realrootfs
	if [  "${HOSTHIDDEN}" != "y" ] ; then
		[ -d "${NEWROOT}"/host ] || mkdir -p ${NEWROOT}/host 
		mount -R /host   ${NEWROOT}/host
	fi

fi

if [ -n "$VLOOP" ]; then
	
	### reset the value of the root variable
	HOSTDEV="${root#block:}"
	[ -n "$VLOOPPART" ]  ||  root=/dev/loop0
	[ -n "$VLOOPPART" ]  &&  root=/dev/mapper/loop0$VLOOPPART
	export  root
	realroot="$root"
	if ismounted "$NEWROOT"; then
		umount    "$NEWROOT"
	fi
                   
	###  auto probe the fs-type of the partition in which vhd-file live and mount it  /host
	mkdir -p /host
	if  [  -z "${HOSTFSTYPE}"  ]; then
		HOSTFSTYPE="$(blkid -s TYPE -o value "$HOSTDEV")"
		[  -z "${HOSTFSTYPE}" -o  "${HOSTFSTYPE}" = "ntfs" ] && HOSTFSTYPE="ntfs-3g"
	fi
	mount -t "${HOSTFSTYPE}" -o rw   "${HOSTDEV}"    /host
           
	### mount the vhd-file on a loop-device
	if [ "${VLOOP#/}" != "${VLOOP}" ]; then
		modprobe loop
		kpartx -av  "/host$VLOOP"

		[ -e "$realroot" ] ||  sleep 3
	fi
           
	### mount the realroot / in vhd-file on $NEWROOT
	[ -e "$realroot" ] ||  sleep 3
	if  [  -z  "${VLOOPFSTYPE}"   ];  then
		VLOOPFSTYPE="$(blkid -s TYPE -o value "$realroot")"
		[ -z "${VLOOPFSTYPE}" ] && VLOOPFSTYPE="ext4"
	fi
	mount  -t  "${VLOOPFSTYPE}"   -o   rw   $realroot    $NEWROOT
           
	### mount /host in initrd to /host of the realrootfs
	[ -d $NEWROOT/host ] || mkdir -p $NEWROOT/host 
	mount -R  /host  $NEWROOT/host
fi
