**Preface:** This is a *different* collection of patchsets for applying to bare GNU/Linux kernels for the Gentoo GNU/Linux distribution. These patchsets are meant to be applied to a vanilla Linux kernel with no sublevel. Using dev-util/quilt is recommended to handle patching.

Patches:
```
ck1 patchset

GCOV/PGO patchset for GCC/GCOV 9.2.0

Genpatches
Minor ck/systemd fix
Gen 3 Ryzen temperature sensor detection

4.19.78 patch

Gawk >=5.0 overescaping fix. This should not be applied if the
current system's Gawk is version 4 or below (likely the case for most distros).
```

I've profiled and am running a PGO'd 4.19.77 without issues, I haven't tested this one yet.


#### clearly-faster-gentoo-sources-ck1

The intention of this project is to streamline the process of using the patching system to harden/optimize the Linux kernel for Gentoo, primarily with the MuQSS patchset, Clear Linux patches, and Gentoo's genpatches for the x86-64 architecture. An emphasis is placed on the current stable kernel to follow ongoing development. 

---

**Currently included in the patchsets:**

**1.** Con Kolivas' MuQSS patchset, which includes his scheduler as well as modifications to the kernel. MuQSS was designed with the idea that the end user should not have to deal with multiple tunables to achieve smooth desktop usage. Although this repo is geared towards the x86-64 architechture, it would help with development of the scheduler if it was tested on other architechtures. You can find his contact information here: `http://www.users.on.net/~ckolivas/kernel/`

**2.** Clear Linux's distribution by Intel has patches designed for their own kernel, as well as contribute to kernel development. There are patches to increase general performance and CVE patches that have recently been fixed. Generally CVE patches become obsolete as they will be integrated into the kernel in the future. This is especially true for LTS kernels.

**3.** Genpatches for Gentoo is maintained by Tom Wijsman and Mike Pagano and a single hand sometimes. Technology is really advancing nowadays. These patches include the incremental patches released for LTS and for the most part they don't differ from an incremental patch you'd download from kernel.org. However, genpatches may release a hotfix before the next hotfix patch hits. Aside from that, the interesting stuff is the experimental and distro specific patches that give the config some more knobs to spin. What is included depends on the major kernel version.

**4.** Graysky2's Kernel_gcc_patch is actually already in Gentoo's *experimental* patches, but graysky2 has updated his patch for GCC 9 and the options now include newer CPUs. Generating code optimized for your processor is a guaranteed performance boost. Because this newest patch is meant for GCC >9.1 and a kernel version that is >4.13, you may be interested in using his older patches instead if you currently don't have the newest GCC available. graysky2's GitHub homepage is located at below.


---


**Con Kolivas' website/MuQSS details**
```
http://ck.kolivas.org/patches/muqss/sched-MuQSS.txt
http://ck-hack.blogspot.com/
```
**Gentoo's official Genpatches maintainers homepage**
```
https://dev.gentoo.org/~mpagano/genpatches/
```
**Clear Linux Intel CPU optimization and CVE hotfix repository**
```
https://github.com/clearlinux-pkgs/linux
```
**graysky2's architecture optimization patches**
```
https://github.com/graysky2/kernel_gcc_patch
```


Examples of what kernel tarballs to use, sourced from kernel.org. Using `git` to receive the kernel works as well, assuming the correct version is chosen.

`https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.20.tar.xz`

`https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.0.tar.xz`

[Bare 5.0.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.0.tar.xz)

[Bare 5.1.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.1.tar.xz)

[Bare 5.2.0 Linux kernel](https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.2.tar.xz)

# Notes:

- I have commented out some patches and explain why in the `series` file. 
- I've made changes on patches in the past to patch successfully or to reduce fuzz. 5.2 has been the cleanest so far and didn't require any changes.
- Enable the appropriate debugging modules if you face an issue you didn't experience prior to this kernel. The only time I've experienced severe stuttering was when I enabled compulsory IRQ threading. 
- MuQSS's recommended settings: `CONFIG_HZ_100=Y` `CONFIG_RQ_MC=Y` `CONFIG_PSI is not set` `CONFIG_FORCE_IRQ_THREADING is not set`


## Gentoo Example Installation (WIP)
```
# Run all these commands as root

emerge -avu quilt dev-vcs/git  #  Optionally run `perl-cleaner --really-all` afterwards if Perl was upgraded

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.2.tar.xz
xz -df linux-5.2.tar.xz && tar -xpf linux-5.2.tar && rm linux-5.2.tar

mv linux-5.2 linux-5.2.9
eselect kernel set linux-5.2.9
cd /usr/src/linux

git clone https://github.com/jiblime/clear-ck-gentoo-sources.git patches
cd patches
git submodule update --init submod-clear
cd submod-clear; git checkout 5.2.17-836; cd ..
./clear-patch-selector.sh

# Below is a simple script to get your current .config into the directory quickly.
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

# You'll still need to update the config. listnewconfig and oldconfig work well.
make listnewconfig

###
# Below is generic kernel installation

make -j4
make modules_install -j4
emerge @module-rebuild # Remember to manually sign your kernel modules if a signature is required
make install
dracut --kver [default would be 5.2.9 unless you customized it, which I do] --lz4
grub-mkconfig -o /boot/grub/grub.cfg
