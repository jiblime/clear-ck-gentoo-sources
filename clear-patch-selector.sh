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
echo -e "CVE patches\n${CVE}\n"
}

create_cve()
{
read -p "Include CVE patches?[Y/n] " create_cve
echo -e "User generated at: $(date)" > generated/0001-CL-CVE.patch

case "${create_cve}" in
	[Yy]* | '')
		cat submod-clear/CVE*.patch >> generated/0001-CL-CVE.patch && echo -e "\n\e[32mAdded CVE patches.\e[0m\n"
		;;
	[Nn]*)
		echo -e "\n\e[31mNot adding CVE patches and removing older patches.\e[0m\n";
		rm generated/0001-CL-CVE.patch
		;;
	*)
		echo "Input unrecognized..."; create_cve
esac
}


fpga-patches()
{
FPGA=$(cd submod-clear; ls | grep 'fpga.*\.patch'; cd $OLDPWD)
echo -e "FPGA patches\n${FPGA}\n"
}

create_fpga()
{
read -p "Include FPGA patches?[Y/n] " create_fpga
echo -e "User generated at: $(date)" > generated/0002-CL-FPGA.patch

case "${create_fpga}" in
	[Yy]* | '')
		cat submod-clear/*fpga*.patch >> generated/0002-CL-FPGA.patch && echo -e "\n\e[32mAdded FPGA patches.\e[0m\n"
		;;
	[Nn]*)
		echo -e "\n\e[31mNot adding FPGA patches and removing older patches.\e[0m\n"
		rm generated/0002-CL-FPGA.patch
		;;
	*)
		echo "Input unrecognized..."; create_fpga
esac
}


cl-patches()
{
shopt -s extglob

#  Excluded Clear Linux patches

cl_distro="*-Increase-the-ext4-default-commit-age.patch|"
# > (DISTRO TWEAK -- NOT FOR UPSTREAM)
cl_distro+="*-bootstats-add-printk-s-to-measure-boot-time-in-more-.patch|"
# > Few distro-tweaks to add printk's to visualize boot time better
cl_distro+="*-init-wait-for-partition-and-retry-scan.patch|"
# Adds a wait period for Clear Linux because it boots too fast
cl_distro+="*-Add-boot-option-to-allow-unsigned-modules.patch|"
# Adds option to allow unsigned modules when Secure Boot is off
cl_distro+="*-Enable-stateless-firmware-loading.patch|"
# Prefers firmware from the (Clear Linux's stateless) user directories first
cl_distro+="*-Migrate-some-systemd-defaults-to-the-kernel-defaults.patch|"
# > These settings are needed to prevent networking issues when the networking modules come up by default without explicit settings
cl_distro+="*-add-scheduler-turbo3-patch.patch|"
# Doesn't work for non CL distros
cl_distro+="*-use-lfence-instead-of-rep-and-nop.patch|"
# Need to determine if this is already resolved in another way/performance impact.  https://spectreattack.com/spectre.pdf https://newsroom.intel.com/wp-content/uploads/sites/11/2018/01/Intel-Analysis-of-Speculative-Execution-Side-Channels.pdf
cl_distro+="*-zero-extra-registers.patch|"
# Requires GCC patch. https://github.com/clearlinux-pkgs/gcc/blob/master/zero-regs-gcc8.patch
cl_distro+="*-x86-microcode-Force-update-a-uCode-even-if-the-rev-i.patch|"
# Intel specific? Unsure of the need for this.
cl_distro+="*-x86-microcode-echo-2-reload-to-force-load-ucode.patch"
# Same as above.


CLEAR=($(cd submod-clear; ls !(${cl_distro}) | grep -v 'fpga\|^CVE\|.*patch\-\|perfbias' | grep '^.*\.patch'; cd $OLDPWD))
echo -e "Clear Linux patches"
printf '%s\n' "${CLEAR[@]}"
echo # \n
shopt -u extglob

read -p "Show list of patches excluded for compatibility? [yN] " show_ex
case "${show_ex}" in
	[Yy]*)
		excluded_list=${cl_distro}
		echo -e "\e[2m"
		echo "Excluded list:"
		echo ${excluded_list} | sed 's/|/\n/g'
		echo -e "\e[22m"
		;;
	[Nn]* | *)
		return
esac
}

create_clr()
{
read -p "Include the rest of the Clear Linux patches?[Y/n] " create_clr
echo -e "User generated at: $(date)" > generated/0003-CL-CLR.patch

case "${create_clr}" in
	[Yy]* | '')
		warpten && echo -e "\n\e[32mAdded Clear Linux patches.\e[0m\n"
		;;
	[Nn]*)
		echo -e "\n\e[31mNot adding Clear Linux patches and removing older patches.\e[0m"
		rm generated/0003-CL-CLR.patch
		;;
	*)
		echo "Input unrecognized..."; create_clr
esac
}

warpten()
{
for ((i=0; i<${#CLEAR[@]}; i++)); do
	cat submod-clear/"${CLEAR[i]}" >> generated/0003-CL-CLR.patch;
done
}





# The functions are separate to prevent spamming of patchsets
cve-patches && create_cve
fpga-patches && create_fpga
cl-patches && create_clr


cat generated/00*CL*.patch > generated/clear.patch && echo -e "Created new Clear Linux patchset at generated/clear.patch."
