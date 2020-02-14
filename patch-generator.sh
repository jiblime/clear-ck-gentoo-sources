#!/bin/bash

update_mods() {
	git submodule update --init
	cd submodules/clear ; git fetch ; git checkout $(git describe --tags `git rev-list --tags --max-count=1`) ; cd $OLDPWD
	cd submodules/zenpower; git fetch ; git pull ; git checkout master ; cd $OLDPWD
	# git submodule foreach "git fetch ; git pull ; git checkout master" # still needs work...
}
update_mods

# For Ryzen 3000 voltage/temp/clock detection.

if [[ -f submodules/zenpower/zenpower.c ]] ; then
	cp submodules/.zenpower-skel/zenpower.skel misc/008-Add-git-version-of-zenpower-as-a-builtin-module.patch
	echo "@@ -0,0 +1,$(cat submodules/zenpower/zenpower.c | wc -l) @@" >> misc/008-Add-git-version-of-zenpower-as-a-builtin-module.patch
	cp submodules/zenpower/zenpower.c submodules/.zenpower-skel/zenpower.potch
	sed -i 's/^/+/g' submodules/.zenpower-skel/zenpower.potch
	cat submodules/.zenpower-skel/zenpower.potch  >> misc/008-Add-git-version-of-zenpower-as-a-builtin-module.patch &&
	ls --color=always misc/008-Add-git-version-of-zenpower-as-a-builtin-module.patch
	echo -e "Created the freshest zenpower built in module available, courtesy of:"
	echo -e "https://github.com/ocerman. Best used with https://github.com/ocerman/zenmonitor"
	echo -e "If you do not have a Ryzen processor, disable CONFIG_SENSORS_ZENPOWER"
fi

# Below, Clear patches are categorized and then combined all into one so the series file doesn't need adjustment

# IDEAS: Use case statements instead
# 	Identify and exclude patches that reduce performance in lieu of security
#	Create an additional prompt for Intel exclusive patches that have been excluded by default
#	Separate anything performance related into its own section

version=$(cat submodules/clear/upstream | sed 's/^.*\-//g; s/\.tar\.xz//g')
echo -e "Clear Linux's patches for $version.\n"


cve-patches()
{
#rm submodules/clear/CVE-2019-19054.patch # This whole script needs to be better, this is a terrible way to do things
CVE=$(cd submodules/clear; ls | grep '^CVE.*\.patch'; cd $OLDPWD)
echo -e "CVE patches\n${CVE}\n"
}

create_cve()
{
echo -e "CVE patches are patches made to fix security issues in the kernel"
read -p "Include CVE patches?[Y/n] " create_cve
echo -e "User generated at: $(date)" > submodules/.generated/0001-CL-CVE.patch

case "${create_cve}" in
	[Yy]* | '')
		cat submodules/clear/CVE*.patch >> submodules/.generated/0001-CL-CVE.patch && echo -e "\n\e[32mAdded CVE patches.\e[0m\n"
		;;
	[Nn]*)
		echo -e "\n\e[31mNot adding CVE patches and removing older patches.\e[0m\n";
		rm submodules/.generated/0001-CL-CVE.patch
		;;
	*)
		echo "Input unrecognized..."; create_cve
esac
}


cl-patches()
{
shopt -s extglob

#  Excluded Clear Linux patches

cl_distro="*-bootstats-add-printk-s-to-measure-boot-time-in-more-.patch|"
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

cl_distro+="*-x86-microcode-Force-update-a-uCode-even-if-the-rev-i.patch|"
# Intel specific? Unsure of the need for this.
cl_distro+="*-x86-microcode-echo-2-reload-to-force-load-ucode.patch|"
# Same as above.
cl_distro+="*-fix-bug-in-ucode-force-reload-revision-check.patch|"
# Same as above.

#cl_distro+="*-use-lfence-instead-of-rep-and-nop.patch|" ## pause does not serialize on AMD, therefore rep/nop do not either afaik
# ~~Need to determine if this is already resolved in another way/performance impact.  https://spectreattack.com/spectre.pdf https://newsroom.intel.com/wp-content/uploads/sites/11/2018/01/Intel-Analysis-of-Speculative-Execution-Side-Channels.pdf~~

#[[ -z $(gcc -shared -mzero-caller-saved-regs=used /dev/null -o /dev/null) ]] &&
cl_distro+="*-zero-extra-registers.patch|"
# Requires GCC patch. https://github.com/clearlinux-pkgs/gcc/blob/master/zero-regs-gcc8.patch


[[ -z $(grep 'ck' './version') ]] &&
cl_distro+="*-WireGuard-fast-modern-secure-kernel-VPN-tunnel.patch|"
# pf-kernel merged, ck did not

[[ -z "$(as -mbranches-within-no-boundaries --warn /dev/null >/dev/null 2>&1)" ]] &&
cl_distro+="*-add-workaround-for-binutils-optimization.patch|"
# binutils's assembler needs a patch from https://github.com/clearlinux-pkgs/binutils/
# This patch is no longer included in their binutils or kernel's patchset
# I could not find "mbranches-within-no-boundaries" nor "OPTION_MBRANCHES_WITH_NO_BOUNDARIES" anywhere on the internet besides GitHub

cl_distro+="*-Increase-the-ext4-default-commit-age.patch"
# > (DISTRO TWEAK -- NOT FOR UPSTREAM) | Moved to the bottom so the last patch will never have "|" appended



CLEAR=($(cd submodules/clear; ls !(${cl_distro}) | grep -v 'fpga\|^CVE\|.*patch\-\|perfbias' | grep '^.*\.patch'; cd $OLDPWD))
echo -e "Clear Linux patches"
printf '%s\n' "${CLEAR[@]}"
echo # \n
shopt -u extglob

echo -e "The rest of the patches; this is definitely what you're using Clear Linux patches for\n"
read -p "Show list of patches excluded for compatibility? (These will not be added if you say yes or no) [yN] " show_ex
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
read -p "Include the rest of the Clear Linux patches? (Recommended)[Y/n] " create_clr
echo -e "User generated at: $(date)" > submodules/.generated/0003-CL-CLR.patch

case "${create_clr}" in
	[Yy]* | '')
		warpten && echo -e "\n\e[32mAdded Clear Linux patches.\e[0m\n"
		;;
	[Nn]*)
		echo -e "\n\e[31mNot adding Clear Linux patches and removing older patches.\e[0m"
		rm submodules/.generated/0003-CL-CLR.patch
		;;
	*)
		echo "Input unrecognized..."; create_clr
esac
}

warpten()
{
for ((i=0; i<${#CLEAR[@]}; i++)); do
	cat submodules/clear/"${CLEAR[i]}" >> submodules/.generated/0003-CL-CLR.patch;
done
}





# The functions are separate to prevent spamming of patchsets
cve-patches && create_cve
cl-patches && create_clr


cat submodules/.generated/00*CL*.patch > submodules/.generated/clear.patch && echo -e "Created new Clear Linux patchset at submodules/.generated/clear.patch."
