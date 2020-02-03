#!/bin/bash

# Uses dracut and Gentoo specific (sort of) locations. You can easily use this on Ubuntu by adding update-initramfs -u -k all and update-grub
# Needs graphite supported in GCC

make -j$(cat /proc/cpuinfo | grep processor | wc -l) \
	KCFLAGS="-fgraphite-identity -floop-nest-optimize \
	-malign-data=cacheline -mtls-dialect=gnu2 \
	--param=max-unroll-times=2 -fno-inline-functions -fno-tree-loop-distribute-patterns \
	--param=max-unrolled-insns=32 --param=max-average-unrolled-insns=16"

read -p "Did it work?"

echo  "Deleting `uname -r` from /boot without regex (moving config to /tmp just in case)"

mv "/boot/config-`uname -r`" "/tmp/" -v
rm "/boot/initramfs-`uname -r`.img" -v
rm "/boot/vmlinuz-`uname -r`" -v
rm "/boot/System.map-`uname -r`" -v

# Only for systems that have modules at /lib/modules

echo "Removing /lib/modules/`uname -r`"

rm -r "/lib/modules/`uname -r`" -v

make modules_install install -j$(cat /proc/cpuinfo | grep processor | wc -l)

dracut --xz --fstab -f
