
#VER="6.1.68-rt20-v8mnc4+"
#VER="6.1.68-rt20-v8mnc3+"
#VER="6.1.68-rt20-v8mnc4b+"
#VER="6.1.68-rt20-v8mnc4c+" -> NAJLEPSIA
#VER="6.1.68-rt20-v8mnc4d+" -> fuci vetrak
#VER="6.1.68-rt20-v8mnc4e+" -> vetrak po zapnuti modulov (initrd?) ok
#VER="6.1.68-rt20-v8mnc4f+" #  odobratych par veci
#VER="6.1.68-rt20-v8mnc4g+" # 
#VER="6.1.68-rt20-v8mnc5+"   # komplet vypnuty debug/stats
#VER="6.1.68-rt20-v8mnc6+"   # odpatchovany rng - inspired by https://432evo.be/index.php/432-evo-master-music-server/
#VER="6.1.68-rt20-v8mnc7+"   # vypnuty cpufreq a device PM
#VER="6.1.68-rt20-v8mnc8+"   # vypnuty cpuidle
#VER="6.1.68-rt20-v8mnc9+"   # git pull na jadro a -rt24 patch
#VER="6.6.21-rt25-v8mnc4g+"   # rpi git kernel-6.6.21 a -rt25 patch, kompilovane na ubunbu-22.04 vagrant (prerelease)

VER="6.6.42-rt38-v8mnc9+"   # 
KERN_VER="rt-neresiev-nodebug"

echo 1. put modules in place
cp -r out/${VER} /lib/modules
echo ""

echo 2. put kernel config in /boot
#cp out/config-${VER} /boot/
#cp $(ls out/config-${VER}* | tail -n1) /boot/
cp out/config-${VER}-${KERN_VER} /boot/config-${VER}
echo ""

echo  put kernel image in place
#cp out/kernel_2712rt-neresiev.img /boot/firmware/
#cp out/kernel_2712rt-neresiev.img /boot/firmware/kernel_2712rt-neresiev-nodebug.img
#cp out/kernel_2712rt-neresiev.img /boot/firmware/kernel_2712rt-neresiev-nonrngpm.img
#cp out/kernel_2712rt-neresiev.img /boot/firmware/kernel_2712rt-neresiev-nonrngpmidle.img
#cp out/kernel_2712-${VER}-${KERN_VER} /boot/firmware/
cp out/kernel_2712-${VER}-${KERN_VER} /boot/firmware/kernel_2712-${VER}
echo ""

echo 3. create initramfs
#update-initramfs -c -v -k ${VER}-${KERN_VER}
update-initramfs -c -v -k ${VER}
#cp /boot/initrd.img-${VER}-${KERN_VER} /boot/firmware/
cp /boot/initrd.img-${VER} /boot/firmware/


echo "!!! DO NOT FORGET ADD NEW KERNEL in /boot/firmware/config.txt !!!"
echo \G
echo ""
