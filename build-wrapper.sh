#!/bin/bash

# Uses dracut and Gentoo specific (sort of) locations. You can easily use this on Ubuntu by adding update-initramfs -u -k all and update-grub
# Needs graphite supported in GCC

make_kernel(){
PJOB="$(cat /proc/cpuinfo | grep processor | wc -l)"

make -j"${PJOB}" \
	KCFLAGS="-fgraphite-identity -floop-nest-optimize \
	-malign-data=cacheline -mtls-dialect=gnu2 \
	--param=max-unroll-times=2 -fno-inline-functions -fno-tree-loop-distribute-patterns \
	--param=max-unrolled-insns=32 --param=max-average-unrolled-insns=16" && return || exit 1
}

poof_old(){
read -p "Remove running kernel from /boot and /lib/modules? [y/n] " poof

RUNNING_KVER=`uname -r`

CURR_KVER="$(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g')"

case "${poof}" in
        [Yy]* | '')
		echo -e "Deleting ${RUNNING_KVER}, moving /boot/${RUNNING_KVER}.config to /tmp"
		mv -v "/boot/config-`uname -r`" "/tmp/"
		rm -v "/boot/initramfs-${RUNNING_KVER}.img"
		rm -v "/boot/vmlinuz-${RUNNING_KVER}"
		rm -v "/boot/System.map-${RUNNING_KVER}"
                ;;
        [Nn]*)
		if [[ "${RUNNING_KVER}" = "${CURR_KVER}" ]] ; then
			echo -e "The running kernel and compiled kernel have the same kernel release. Select yes to remove or abort the script" ; poof_old
		else
			echo -e "Keeping the running kernel"
		fi
                ;;
        *)
                echo "Input unrecognized..."; poof_old
esac
}

install_kernel(){
make modules_install install -j"${PJOB}"

EMERGE_DEFAULT_OPTS="-j${PJOB}" emerge -1 @module-rebuild

[[ -n $(command -v dracut >/dev/null) ]] &&
dracut --kver "${CURR_KVER}" --lz4 --fstab &&
cp -v "/boot/loader/entries/${RUNNING_KVER}.conf" "/boot/loader/entries/${CURR_KVER}.conf" ||
echo -e "dracut is not installed in the current system"
}

make_kernel
poof_old
install_kernel
