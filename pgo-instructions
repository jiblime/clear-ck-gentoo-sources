# Credits to /u/JATmatic on reddit.com
# and http://coolypf.com/kpgo

# https://reddit.com/r/kernel/comments/a2og7u/the_process_of_building_the_kernel_with_gcc/

# In /usr/src/linux, run:
./scripts/kgcov/buildGCOVKernel bzImage modules

# The build will happen in a bind mounted /tmp/kernelsrc. 
# When done, while still in /usr/src/linux, run
# make modules_install install
# as well as creating a initramfs, rebuilding/resigning modules, etc.

# When booted into the gcov kernel, go to /usr/src/linux
# and run:

mkdir profile
for (( x=0; x<10; x++ )); do
	sleep 3; ./scripts/kgcov/gather.sh profile/profile"${x}".tar.gz
done

./scripts/kgcov/mergegcov.sh $(ls profile/*)

# While still in /usr/src/linux, finally run:

./scripts/kgcov/genPGOKernel bzImage modules

# Then remove the gcov kernel files in /boot and /lib/modules
# prior to installing (or change the name of the kernel prior to
# building it again). 
