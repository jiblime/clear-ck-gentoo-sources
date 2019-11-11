**Preface:** This is a collection of patchsets for applying to bare GNU/Linux kernels for the Gentoo GNU/Linux distribution. These patchsets are meant to be applied to a vanilla Linux kernel with no sublevel. Using dev-util/quilt is recommended to handle patching.

#### clearly-faster-gentoo-sources-ck1

The intention of this project is to streamline the process of using the patching system to harden/optimize the Linux kernel for Gentoo, primarily with the MuQSS patchset, Clear Linux patches, and Gentoo's genpatches for the x86-64 architecture. An emphasis is placed on the current stable kernel to follow ongoing development. 

---

**Currently included in the patchsets:**

**1.** Con Kolivas' MuQSS patchset, which includes his scheduler as well as modifications to the kernel. MuQSS was designed with the idea that the end user should not have to deal with multiple tunables to achieve smooth desktop usage.

**2.** Clear Linux's distribution by Intel has pushes patches for their own distro kernel as well to mainline kernel development. There are patches to increase general performance, CVE hotfixes, and distro specific patches in the repository. The script in this repo will create a concatenated patch of all the Clear Linux patches. excluding patches made only for the Clear Linux distribution, are not AMD/Intel agnostic, or reduce performance in return for security. If it were important enough, I would hope that it'd be accepted upstream anyway. Note that the patch generator script may reference an older version by x.x.1 but that's fine.

**3.** Genpatches for Gentoo is maintained by Tom Wijsman and Mike Pagano and a single hand sometimes. I've included the experimental and distro specific patches that give the config some more knobs to spin. Note: these knobs are defaulted to making the .config making process easier by selecting what is generally needed to have a bootable kernel. What is included depends on the major kernel version but hasn't changed recently. Do note that the distro-specific patches do not cause incompatibility with other distributions.

**4.** Graysky2's Kernel_gcc_patch is actually already in Gentoo's experimental patches, but graysky2 has updated his patch for GCC 9 and the options now include newer CPUs. Generating code optimized for your processor is a guaranteed performance boost. Because this newest patch is meant for GCC >9.1 and a kernel version that is >4.13, you may be interested in using his older patches instead if you currently don't have the newest GCC available. graysky2's GitHub homepage is located at below.

**5.** ocerman's zenpower module is an in kernel module now so there will be no need to sign it or rebuild it after creating a new kernel.

**/6/7/etc.** Random patches I've piled in to test. Read the heads of each patch to get a URL to patch source and some information. The (now) unmaintainted it87.c replacement is *still* much further ahead in development than the in-kernel version. 


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


Examples of different ways to attain the two-point release kernel:

`wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.3.tar.xz`

`git clone --branch v5.3 https://github.com/torvalds/linux.git linux-5.3-ck1`

`git clone https://github.com/torvalds/linux.git linux-git ; cd linux-git ; git checkout v5.3`

[Bare 5.2.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.2.tar.xz)

[Bare 5.3.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.3.tar.xz)

# Notes:

- Within the clear patch generator script are reasons as to why a patch is excluded.

- Enable the appropriate debugging modules if you face an issue you didn't experience prior to this kernel. The only time I've experienced severe stuttering was when I enabled compulsory IRQ threading. 

- MuQSS's recommended settings: 
`CONFIG_HZ_100=Y`: Read the section under [*Tickless expiry:*](http://ck.kolivas.org/patches/muqss/sched-MuQSS.txt)

`CONFIG_RQ_MC=Y`: Best for those who are interested in low latency, but the other runqueues have their uses

- Note: 5.3 has introduced `CONFIG_RQ_LLC` for CPUs with multiple last level caches which many new processors have; worth testing!

 `CONFIG_FORCE_IRQ_THREADING is not set`: This is only needed for those who are unable to boot when `CONFIG_FORCE_IRQ_THREADING=Y`, and is off by default.



## Gentoo Example Installation (WIP)
```
# Run all these commands as root

emerge -avu quilt dev-vcs/git  #  Optionally run `perl-cleaner --really-all` afterwards if Perl was upgraded

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.3.tar.xz
xz -df linux-5.3.tar.xz && tar xpf linux-5.3.tar && rm linux-5.3.tar

mv linux-5.3 linux-5.3-ck1
eselect kernel set linux-5.3-ck1
cd /usr/src/linux

git clone --recurse-submodules https://github.com/jiblime/clear-ck-gentoo-sources.git patches && cd patches
-or-
git clone https://github.com/jiblime/clear-ck-gentoo-sources.git patches && cd patches
git submodule update --init

To checkout the latest tag for a submodule instead of a random branch:
cd submodules/clear
git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

And the same for submodules/zenpower


./clear-patch-selector.sh

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

# You'll still need to update the config. `make oldconfig` works. Run `make help` to view more options.

make oldconfig

###
# Below is a generic kernel installation using dracut to create a separate initrd that compiles in tmpfs to save...seconds?

mount --rbind /usr/src/linux /tmp/kernel -v
cd /tmp/kernel
make clean
make -j$(cat /proc/cpuinfo | grep processor | wc -l) &&
make modules_install install -j$(cat /proc/cpuinfo | grep processor | wc -l) &&
emerge @module-rebuild
dracut --kver $(file /usr/src/linux/arch/x86/boot/bzImage | sed 's/^.*version\ //g ; s/\ .*//g') --xz --fstab
grub-mkconfig -o /boot/grub/grub.cfg
```

