**Preface:** This is a *different* collection of patchsets for applying to bare GNU/Linux kernels for the Gentoo GNU/Linux distribution. These patchsets are meant to be applied to a vanilla Linux kernel with no sublevel. Using dev-util/quilt is recommended to handle patching.

Requirements: GCC 9.2.0 built with configuration option --with-isl.

Patches:
```
ck1 patchset

4.19.78 patch along with minor fixes

GCOV/PGO patchset for GCC/GCOV 9.2.0

Gentoo specific patches

graysky2's GCC CPU architecture patch

-O3 and -Og configs patch

Ryzen 2/3 k10temp support

Gawk >=5.0 overescaping fix. This should not be applied if the
current system's Gawk is version 4 or below (likely the case for most distros).
```

This patchset is working for at least one person (me).

#### clearly-faster-gentoo-sources-ck1

The intention of this project is to streamline the process of using the patching system to harden/optimize the Linux kernel for Gentoo, primarily with the MuQSS patchset, Clear Linux patches, and Gentoo's genpatches for the x86-64 architecture. An emphasis is placed on the current stable kernel to follow ongoing development. 

The intention of this branch is to have a working PGO'd kernel.

Missing profile data can be gathered by loading the module prior to using scripts/gcov/gather.sh.
