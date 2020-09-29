#！ /bin/bash

VLOOP=$(getarg vloop=)
VLOOPPART=$(getarg vlooppart=)
VLOOPFSTYPE=$(getarg vloopfstype=)
HOSTFSTYPE=$(getarg hostfstype=)

export VLOOP
export VLOOPPART
export VLOOPFSTYPE
export HOSTFSTYPE

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
