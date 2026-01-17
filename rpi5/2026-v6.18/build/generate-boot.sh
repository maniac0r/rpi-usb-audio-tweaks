#VER="6.1.68-rt20-v8mnc5+"
#VER="6.1.68-rt20-v8mnc4d+"
#VER="6.1.68-rt20-v8mnc5+"

#VER="6.6.21-rt25-v8mnc4g+"   # rpi git kernel-6.6.21 a -rt25 patch, DEBUG , kompilovane na ubunbu-22.04 vagrant (prerelease)
#KERN_VER="rt-neresiev-debug"

#VER="6.6.21-rt25-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug-ipv6"

#VER="6.6.32-rt25-v8mnc9+"
#VER="6.6.40-rt25-v8mnc4g+"
#VER="6.6.40-rt25-v8mnc9+"

#VER="6.6.40-rt36-v8mnc4g+"
#VER="6.6.40-rt36-v8mnc9+"
#KERN_VER="rt-neresiev-debug"
#KERN_VER="rt-neresiev-nodebug"


#VER="6.6.42-rt38-v8mnc4g+"
#KERN_VER="rt-neresiev-debug"
#VER="6.6.42-rt38-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug"

#VER="6.6.44-rt39-v8mnc4g+"
#KERN_VER="rt-neresiev-debug"

#VER="6.6.69-rt47-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug"

###

#VER="6.12.8-rt6-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug"

#VER="6.12.8-rt6-v8mnc4g+"
#KERN_VER="rt-neresiev-debug"

####

#VER="6.14.0-rc7-rt1-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug"

#VER="6.14.0-rc7-rt1-v8mnc9nomod+"
#KERN_VER="rt-neresiev-nodebug"

#VER="6.14.0-rc7-rt1-v8mnc4g+"
#KERN_VER="rt-neresiev-debug"

#VER="6.14.0-rc7-rt1-v8mnc4gnomod+"
#KERN_VER="rt-neresiev-debug"

#VER="6.14.11-rt3-mnc+"
#KERN_VER="rt-neresiev-nodebug"

#VER="6.18.4-rt3-mnc+"
#KERN_VER="rt-neresiev-debug"

#VER="6.18.4-rt3-mnc+"
#KERN_VER="rt-neresiev-debug"

#VER="6.12.64-rt14-v8mnc9+"
#KERN_VER="rt-neresiev-nodebug"

# 6.18 nejde neviem preco..
# TENTO JE OK...
VER="6.17.12-rt7-mnc+"
KERN_VER="rt-neresiev-nodebug"

# OK
#VER="6.18.4-rt3-mnc+"
#KERN_VER="rt-neresiev-debug"

# OK, jupii! 2026-01-14 21:00CET
# 2026-01-15 tuned update..
VER="6.18.4-rt3-mnc+"
KERN_VER="rt-neresiev-nodebug"


#1. put modules in place
cp -r out/${VER} /lib/modules

#2. put kernel config in /boot
#cp out/config-${VER} /boot/
cp out/config-${VER}-${KERN_VER} /boot/config-${VER}-${KERN_VER}

# put kernel image in place
#cp out/kernel_2712rt-neresiev.img /boot/firmware/kernel_2712rt-neresiev-nodebugi350.img
cp out/kernel_2712-${VER}-${KERN_VER} /boot/firmware/kernel_2712-${VER}-${KERN_VER}

# put dtbs in place
#cp out/*.dtb /boot/firmware

# put overlays in place
#cp out/overlays/* /boot/firmware/overlays/

exit

#3. create initramfs
#update-initramfs -c -v -k ${VER}
#cp /boot/initrd.img-${VER} /boot/firmware/
