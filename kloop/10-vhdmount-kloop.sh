#####################################
###  KLOOP by niumao              ###
#####################################

KLOOP=$(getarg kloop=)
KROOT=$(getarg kroot=)
KLOOPFSTYPE=$(getarg kloopfstype=)
KLVM=$(getarg  klvm=)
HOSTFSTYPE=$(getarg hostfstype=)
HOSTHIDDEN=$(getarg hosthidden=)
SQUASHFS=$(getarg squashfs=)
UPPERDIR=$(getarg upperdir=)
WORKDIR=$(getarg workdir=)

export KLOOP
export KROOT
export KLOOPFSTYPE
export KLVM
export HOSTFSTYPE
export HOSTHIDDEN
export SQUASHFS
export UPPERDIR
export WORKIDR

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
#####################################
###  KLOOP by niumao              ###
#####################################
