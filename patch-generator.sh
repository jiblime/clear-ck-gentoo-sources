#!/bin/bash

# Clear Linux kernel repository:
#	https://github.com/clearlinux-pkgs/linux

# zenpower author:
#	https://github.com/ocerman
#	For use with https://github.com/ocerman/zenmonitor

update_mods()
{

	git submodule update --force --remote --quiet

	echo -e "\nZenpower: "$(git -C submodules/zenpower describe --tags)"\nCommit date: "$(git -C submodules/zenpower show -s --format=%ci)"\c"
	echo -e "\nClear Linux: "$(git -C submodules/clear describe --tags)"\nCommit date: "$(git -C submodules/clear show -s --format=%ci)"\c"
	echo -e "\n---\n"
}


zen_module()
{

# For Ryzen 3000 voltage/temp/clock detection.

if [[ -f submodules/zenpower/zenpower.c ]] ; then
	cp submodules/.zenpower-skel/zenpower.skel misc/006-Add-git-version-of-zenpower-as-a-builtin-module.patch
	echo "@@ -0,0 +1,$(cat submodules/zenpower/zenpower.c | wc -l) @@" >> misc/006-Add-git-version-of-zenpower-as-a-builtin-module.patch
	cp submodules/zenpower/zenpower.c submodules/.zenpower-skel/zenpower.potch
	sed -i 's/^/+/g' submodules/.zenpower-skel/zenpower.potch
	cat submodules/.zenpower-skel/zenpower.potch  >> misc/006-Add-git-version-of-zenpower-as-a-builtin-module.patch
fi

}


cl-patches()
{

#version=$(cat submodules/clear/upstream | sed 's/^.*\-//g; s/\.tar\.xz//g')
#echo -e "Clear Linux's patches for $version.\n"

#  /Excluded Clear Linux patches

# > Few distro-tweaks to add printk's to visualize boot time better
cl_distro+="[bB]ootstats-add-printk-s-to-measure-boot-time-in-more-.patch\|"

# Adds option to allow unsigned modules when Secure Boot is off
cl_distro+="[aA]dd-boot-option-to-allow-unsigned-modules.patch\|"

# Prefers firmware from the (Clear Linux's stateless) user directories first
cl_distro+="[eE]nable-stateless-firmware-loading.patch\|"

# > These settings are needed to prevent networking issues when the networking modules come up by default without explicit settings
cl_distro+="[mM]igrate-some-systemd-defaults-to-the-kernel-defaults.patch\|"

# Doesn't work for non CL distros
cl_distro+="[aA]dd-scheduler-turbo3-patch.patch\|"

# Intel specific? Unsure of the need for this.
cl_distro+="x86-microcode-Force-update-a-uCode-even-if-the-rev-i.patch\|"
# Same as above.
cl_distro+="x86-microcode-echo-2-reload-to-force-load-ucode.patch\|"
# Same as above.
cl_distro+="[fF]ix-bug-in-ucode-force-reload-revision-check.patch\|"

# > (DISTRO TWEAK -- NOT FOR UPSTREAM)
cl_distro+="[iI]ncrease-the-ext4-default-commit-age.patch"

# ~~Need to determine if this is already resolved in another way/performance impact.
# https://spectreattack.com/spectre.pdf
# https://newsroom.intel.com/wp-content/uploads/sites/11/2018/01/Intel-Analysis-of-Speculative-Execution-Side-Channels.pdf
#cl_distro+="use-lfence-instead-of-rep-and-nop.patch" ## pause does not serialize on AMD, therefore rep/nop do not either(?)

#  \Excluded Clear Linux patches


# shell-escape should be enough?
ALL_CLEAR=$(ls --quoting-style=shell-escape submodules/clear/*patch)
CLEAR=$(echo -n -E "${ALL_CLEAR[@]}" | grep -v "${cl_distro[@]}")

echo -e "Clear Linux patches:\n"
echo -n -E "${CLEAR}" |sed 's/^.*clear\///g'
echo -e "\n"

read -p "Show list of excluded patches? [yN] " show_ex
case "${show_ex}" in
	[Yy]*)
		comm <(echo "${ALL_CLEAR}") <(echo "${CLEAR}") -3 | sed 's/^.*clear\///g'
		echo ""
		;;
	[Nn]* | *)
		return
esac
}

create_clr()
{
read -p "Update and overwrite any existing Clear Linux patchset? [Y/n] " create_clr
echo -e "User generated at: $(date)" > submodules/.generated/clear.patch
echo -e "Tag: $(git -C submodules/clear describe --tags)"

case "${create_clr}" in
	[Yy]* | '')
		warpten
		;;
	[Nn]*)
		echo -e "Skipping..."
		return
		;;
	*)
		echo "Input unrecognized..."; create_clr
esac
}

warpten()
{

CLEAR=($(echo -n -E "${CLEAR}" | tr '\n' ' '))

for ((i=0; i<${#CLEAR[@]}; i++)); do
	cat "${CLEAR[i]}" >> submodules/.generated/clear.patch;
done

[[ $? != "0" ]] && echo "Something strange happened" || echo "Generated at submodules/.generated/clear.patch"

}



update_mods

zen_module

cl-patches && create_clr


