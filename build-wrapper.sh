#!/bin/bash

# Uses dracut and Gentoo specific (sort of) locations. You can easily use this on Ubuntu by adding update-initramfs -u -k all and update-grub
# Needs graphite supported in GCC

export PJOB="$(cat /proc/cpuinfo | grep processor | wc -l)"
export RUNNING_KVER="$(uname -r)"
export CURR_KVER="$(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g')"

cd /usr/src/linux

make_kernel(){

#make -j"${PJOB}" \
#        KCFLAGS="-fgraphite-identity -floop-nest-optimize \
#	-ftree-vectorize -floop-parallelize-all \
 #       -finline-functions -flimit-function-alignment \
  #      --param=loop-block-tile-size=121 --param=vect-epilogues-nomask=1 \
   #     -malign-data=cacheline -mtls-dialect=gnu2 \
    #    --param=max-unroll-times=2 -fno-tree-loop-distribute-patterns \
     #   --param=max-unrolled-insns=32 --param=max-average-unrolled-insns=16 \
      #  -fvect-cost-model=unlimited -fno-tree-loop-distribute-patterns " && return || exit 1
#make -j"${PJOB}" KCFLAGS="-fgraphite-identity -floop-nest-optimize -fno-tree-loop-distribute-patterns -flimit-function-alignment" && return || exit 1
make -j"${PJOB}" KCFLAGS="-fgraphite-identity -floop-nest-optimize -fno-tree-loop-distribute-patterns -flimit-function-alignment -fno-unroll-loops -malign-data=cacheline"
}

poof_old(){

export RUNNING_KVER="$(uname -r)"
export CURR_KVER="$(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g')"

read -p "Remove running kernel from /boot and /lib/modules? [y/N] " poof

case "${poof}" in
        [Yy]*)
		echo -e "Deleting ${RUNNING_KVER}, moving /boot/${RUNNING_KVER}.config to /tmp"
		mv -v "/boot/config-`uname -r`" "/tmp/"
		rm -v "/boot/initramfs-${RUNNING_KVER}.img"
		rm -v "/boot/vmlinuz-${RUNNING_KVER}"
		rm -v "/boot/System.map-${RUNNING_KVER}"
		rm -rv "/lib/modules/${RUNNING_KVER}"
                ;;
        [Nn]* | '')
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
# Unsure why this function only sometimes does not detect the prev. exported variables
export PJOB="$(cat /proc/cpuinfo | grep processor | wc -l)"
export RUNNING_KVER="$(uname -r)"
export CURR_KVER="$(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g')"


[[ ! -e /lib/modules/"${CURR_KVER}" ]] &&
make modules_install install -j"${PJOB}" ||
echo -e "Skipping installation in /lib/modules/${CURR_KVER} as it already exists\n"

#echo -e "Send SIGINT to skip module-rebuild and continue build-wrapper.sh"
#emerge -1av @module-rebuild

if [[ -n $(command -v dracut) ]] ; then
	dracut --kver "${CURR_KVER}" --lz4 --fstab -f
else
	echo -e "dracut is not installed in the current system"
fi
}

copy_conf() {
if [[ -e "/boot/loader/entries/Gentoo-${RUNNING_KVER}.conf" ]] && [[ -n $(command -v bootctl) ]] ; then
	cp -v "/boot/loader/entries/Gentoo-${RUNNING_KVER}.conf" "/boot/loader/entries/Gentoo-${CURR_KVER}.conf" &&
	sed -i "s/${RUNNING_KVER}/${CURR_KVER}/g" "/boot/loader/entries/Gentoo-${CURR_KVER}.conf" &&
	echo -e "\n Successfully copied and updated the running kernel's systemd-boot configuration to the compiled kernel"
elif [[ -n $(command -v bootctl) ]] ; then
	read -p "Could not find Gentoo-${RUNNING_KVER}.conf. Manually specify a name or enter [skip]: " bconf
	case "${bconf}" in
		'skip')
			echo -e "Skipping creating a new systemd-boot configuration"
	;;
		*)
			cp -vi "/boot/loader/entries/${bconf}" "/boot/loader/entries/Gentoo-${CURR_KVER}.conf" &&
			sed -i "s/${bconf}/${CURR_KVER}/g" "/boot/loader/entries/Gentoo-${CURR_KVER}.conf" &&
			echo -e "default Gentoo-${CURR_KVER}" | tee -a /boot/loader/loader.conf >/dev/null &&
			echo -e "\n Successfully copied and updated the running kernel's systemd-boot configuration to the compiled kernel"
	esac
else
	echo -e "Did not find bootctl, skipping"
fi
}



make_kernel

poof_old

install_kernel

copy_conf
