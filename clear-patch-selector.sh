#!/bin/bash

# Splits clear patches by inclusion and finally puts them all into one without needing to edit the series file.

# TODO: Use case statements instead
# 	Identify and separate patches that reduce performance in lieu of security
#	Specifically 0123-use-lfence-instead-of-rep-and-nop.patch


version=$(cat submod-clear/upstream | sed 's/^.*\-//g; s/\.tar\.xz//g')
echo -e "Clear Linux's patches for $version.\n"


cve-patches()
{
CVE=$(cd submod-clear; ls | grep '^CVE.*\.patch'; cd $OLDPWD)
}


fpga-patches()
{
FPGA=$(cd submod-clear; ls | grep 'fpga.*\.patch'; cd $OLDPWD)
}


cl-patches()
{
shopt -s extglob

#  Excluded Clear Linux patches

cl_distro="0102-Increase-the-ext4-default-commit-age.patch|"
# > (DISTRO TWEAK -- NOT FOR UPSTREAM)
cl_distro+="0107-bootstats-add-printk-s-to-measure-boot-time-in-more-.patch|"
# > Few distro-tweaks to add printk's to visualize boot time better
cl_distro+="0116-init-wait-for-partition-and-retry-scan.patch|"
# Adds a wait period for Clear Linux because it boots too fast
cl_distro+="0118-Add-boot-option-to-allow-unsigned-modules.patch|"
# Adds option to allow unsigned modules when Secure Boot is off
cl_distro+="0119-Enable-stateless-firmware-loading.patch|"
# Prefers firmware from the (Clear Linux's stateless) user directories first
cl_distro+="0120-Migrate-some-systemd-defaults-to-the-kernel-defaults.patch|"
# > These settings are needed to prevent networking issues when the networking modules come up by default without explicit settings
cl_distro+="0122-add-scheduler-turbo3-patch.patch|"
# Doesn't work for non CL distros
cl_distro+="0123-use-lfence-instead-of-rep-and-nop.patch|"
# Need to determine if this is already resolved in another way/performance impact.  https://spectreattack.com/spectre.pdf https://newsroom.intel.com/wp-content/uploads/sites/11/2018/01/Intel-Analysis-of-Speculative-Execution-Side-Channels.pdf
cl_distro+="0125-zero-extra-registers.patch"
# Requires GCC patch. https://github.com/clearlinux-pkgs/gcc/blob/master/zero-regs-gcc8.patch


CLEAR=($(cd submod-clear; ls !(${cl_distro}) | grep -v 'fpga\|^CVE\|.*patch\-\|perfbias' | grep '^.*\.patch'; cd $OLDPWD))
echo -e "Clear Linux patches\n"
printf '%s\n' "${CLEAR[@]}"

shopt -u extglob
}

cve-patches

echo -e "CVE patches\n${CVE}\n"
read -p "Include CVE patches?[Y/n] " create_cve

if [[ $create_cve == [Yy]* ]]; then
	cat submod-clear/CVE*.patch > generated/0001-CL-CVE.patch && echo -e "\nAdded CVE patches.\n"; else
	"Not adding CVE patches."
fi

fpga-patches

echo -e "FPGA patches\n${FPGA}\n"
read -p "include FPGA patches?[Y/n] " create_fpga

if [[ $create_fpga == [Yy] ]]; then
	cat submod-clear/*fpga*.patch > generated/0002-CL-FPGA.patch && echo -e "\nAdded FPGA patches.\n"; else
	"Not adding FPGA patches."
fi

cl-patches
read -p "include the rest of the Clear Linux patches?[Y/n] " create_clr

if [[ $create_clr == [Yy] ]]; then
	rm generated/0003-CL-CLR.patch;
	for ((i=0; i<${#CLEAR[@]}; i++)); do
		cat submod-clear/"${CLEAR[i]}" >> generated/0003-CL-CLR.patch;
	done
	echo "Added Clear Linux patches."; else
	"Not adding Clear Linux patches."
fi

cat generated/00*CL*.patch > clear.patch && echo -e "\n\nCreated new Clear Linux patchset."

