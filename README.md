**Preface:** This is a collection of patchsets for applying to bare GNU/Linux kernels for the Gentoo GNU/Linux distribution. These patchsets are meant to be applied to a vanilla Linux kernel with no sublevel. Using dev-util/quilt is recommended to handle patching.

#### clearly-faster-gentoo-sources-ck1

The intention of this project is to streamline the process of using the patching system to harden/optimize the Linux kernel for Gentoo, primarily with the MuQSS patchset, Clear Linux patches, and Gentoo's genpatches for the x86-64 architecture. An emphasis is placed on the current stable kernel to follow ongoing development. 

Now there is a splinter branch for the BMQ scheduler by Alfred Chen, using Oleksandr Natalenko's pf-kernel patchset. So the information below may be different than what is in the patch series.

---

**Currently included in the patchsets:**

**1.** Con Kolivas' MuQSS patchset, which includes his scheduler as well as modifications to the kernel. MuQSS was designed with the idea that the end user should not have to deal with multiple tunables to achieve smooth desktop usage.

**2.** Clear Linux's distribution by Intel has pushes patches for their own distro kernel as well to mainline kernel development. There are patches to increase general performance, CVE hotfixes, and distro specific patches in the repository. The script in this repo will create a concatenated patch of all the Clear Linux patches. excluding patches made only for the Clear Linux distribution, are not AMD/Intel agnostic, or reduce performance in return for security. If it were important enough, I would hope that it'd be accepted upstream anyway. Note that the patch generator script may reference an older version by x.x.1 but that's fine.

**3.** Genpatches for Gentoo is maintained by Tom Wijsman and Mike Pagano and a single hand sometimes. I've included the experimental and distro specific patches that give the config some more knobs to spin. Note: these knobs are defaulted to making the .config making process easier by selecting what is generally needed to have a bootable kernel. What is included depends on the major kernel version but hasn't changed recently. Do note that the distro-specific patches do not cause incompatibility with other distributions.

**4.** Graysky2's Kernel_gcc_patch is actually already in Gentoo's experimental patches, but graysky2 has updated his patch for GCC 9 and the options now include newer CPUs. Generating code optimized for your processor is a guaranteed performance boost. Because this newest patch is meant for GCC >9.1 and a kernel version that is >4.13, you may be interested in using his older patches instead if you currently don't have the newest GCC available. graysky2's GitHub homepage is located at below.

**5.** ocerman's zenpower module is an in kernel module now so there will be no need to sign it or rebuild it after creating a new kernel.

**/6/7/etc.** Random patches I've piled in to test. Read the series or heads of each patch to get a URL to patch source and some information. The (now) unmaintainted it87.c replacement is *still* much further ahead in development than the in-kernel version. 


BMQ/pf-kernel patchsets:

**1.** pf-kernel .diff which contains a mish mash of things, foremost the BMQ scheduler
	- A userspace interface to handle kernel samepage merging (uksmd) made by Oleksandr Natalenko
	- Other stuff that's not listed, like which patch x.x.? it is on

**2.** All the above listed, sans MuQSS/ck1. The main difference is the scheduler. 

---


**Con Kolivas' website/MuQSS details**
```
http://ck-hack.blogspot.com/
http://ck.kolivas.org/patches/muqss/sched-MuQSS.txt

	Tunables:
	[1-1000] /proc/sys/kernel/rr_interval 
	   [0-1] /proc/sys/kernel/interactive 
	 [0-100] /proc/sys/kernel/iso_cpu
```
**Clear Linux pkgs repo for the Linux kernel**
```
https://github.com/clearlinux-pkgs/linux
```
**Gentoo's official Genpatches maintainers homepage**
```
https://dev.gentoo.org/~mpagano/genpatches/
```
**graysky2's architecture optimization patches**
```
https://github.com/graysky2/kernel_gcc_patch
```
**ocerman's zenpower (and zenmonitor)**
```
https://github.com/ocerman/zenpower
https://github.com/ocerman/zenmonitor
```

BMQ is based off of PDS and inspired by Google's own kernel/OS project, Zircon (for Fuschia). 

```
https://cchalpha.blogspot.com/
https://gitlab.com/alfredchen/linux-bmq/raw/linux-5.4.y-bmq/Documentation/scheduler/sched-BMQ.txt
https://fuchsia.dev/fuchsia-src/concepts/kernel/kernel_scheduling.md
```

pf-kernel is a quickly maintained patchset that utilizes BMQ and enhances other areas of the kernel, much in the same way that Con Kolivas' entire patchset is beneficial to his scheduler.
```
https://gitlab.com/post-factum/pf-kernel/-/wikis/README
https://gitlab.com/post-factum/uksmd
```



Examples of different ways to attain the two-point release kernel:

`wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.tar.xz`

`git clone --branch v5.5 https://github.com/torvalds/linux.git linux-5.5-ck1`

`git clone https://github.com/torvalds/linux.git linux-git ; cd linux-git ; git checkout v5.5`

[Bare 5.2.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.2.tar.xz)

[Bare 5.5.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.tar.xz)

# Notes:

- Within the clear patch generator script are reasons as to why a patch is excluded.

- Enable the appropriate debugging modules if you face an issue you didn't experience prior to this kernel. The only time I've experienced severe stuttering was when I enabled compulsory IRQ threading. 

- MuQSS's recommended settings: 
`CONFIG_HZ_100=Y`: Read the section under [*Tickless expiry:*](http://ck.kolivas.org/patches/muqss/sched-MuQSS.txt)

- `CONFIG_RQ_MC=Y`: Best for those who are interested in low latency, but the other runqueues have their uses

- Note: 5.3 has introduced `CONFIG_RQ_LLC` for CPUs with multiple last level caches which many new processors have; worth testing!

-  `CONFIG_FORCE_IRQ_THREADING is not set`: This is only needed for those who are unable to boot when `CONFIG_FORCE_IRQ_THREADING=Y`, and is off by default. Users should try first try booting a kernel with it set on

- BMQ notes: When switching schedulers, remember to run `make oldconfig`;  CONFIG_HZ is dependent on application, vs. the recommended 100Hz for MuQSS; read [this](https://cchalpha.blogspot.com/2020/02/bmq-v55-r1-release.html) for notes on kernel param bmq.timeslice


## Gentoo Example Installation (WIP)
```
# Run all these commands as root

emerge -avu quilt dev-vcs/git  #  Optionally run `perl-cleaner --really-all` afterwards if Perl was upgraded

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.tar.xz
xz -df linux-5.5.tar.xz && tar xpf linux-5.5.tar && rm linux-5.5.tar

mv linux-5.5 linux-5.5-ck1
eselect kernel set linux-5.5-ck1
cd /usr/src/linux

git clone --recurse-submodules https://github.com/jiblime/clear-ck-gentoo-sources.git patches && cd patches
-or-
git clone https://github.com/jiblime/clear-ck-gentoo-sources.git patches && cd patches

./patch-generator.sh # Will automatically fetch and update the submodules, be sure to run this before applying patches and do not update until patches are removed

# Below is a simple script to get your current .config into the directory quickly if you need one provided.
# It first checks /proc/config.gz then /boot. All you need to do is copy/paste it into terminal.
# Both have interactive mode on, just in case you might overwrite an existing .config.

if  [ -r /proc/config.gz ]; then
	zcat /proc/config.gz > /tmp/.config && mv -iv /tmp/.config /usr/src/linux ;
elif
	 echo $?
	 [[ -r /boot/config-`uname -r` ]]; then
     cp -iv /boot/config-`uname -r` /usr/src/linux/.config
	echo mv -iv /tmp/.config /usr/src/linux ;
fi

# You'll still need to update the config. `make oldconfig` works. Run `make help` to view more options and 'make listnewconfig' to view the new configurations.

make oldconfig

###
# Below is a generic kernel installation using dracut to create a separate initrd that compiles in tmpfs to save...seconds?

#!/bin/bash
mkdir /tmp/fslinux
mount --rbind /usr/src/linux /tmp/fslinux -v
cd /tmp/fslinux
make clean
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && cd /usr/src/linux &&
make modules_install install -j$(cat /proc/cpuinfo | grep processor | wc -l) &&
emerge @module-rebuild
dracut --kver $(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g') --xz --fstab
grub-mkconfig -o /boot/grub/grub.cfg
```
