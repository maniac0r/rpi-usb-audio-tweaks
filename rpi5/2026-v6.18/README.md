```
With RPi5 and kernel6.17 (mid-2025) or newer, it is now possible to natively
  route USB XHCI to any core (e.g. previous limitation with core0 is now gone, yay!)

Besides allowing to have isolated USB core, it also allows much simpler CPU pinning we
  now boot with isolated cores1-3 and just assign USB,Audio,NIC RT tasks to teir dedicated cores, e.g.
- core0 Anything else
- core1 USB XHCI
- core2 Audio app RT thread (RoonBridge/MPD..)
- core3 Network Interface

Some notable kernel config changes from previous versions:

- support for all RPi5 internal HW
- ARM 16k Pages
- kernel compilation optimized for RPI5 Cortex A76 


Comments:
- quite signifficant sound change with HZ_1000 , but not really for better, staying with HZ_100
- still can't get EEE settings working for onboard NIC




Quick install overview (BACKUP first!):
- copy kernel, rpi5 dtb , config.txt and cmdline.txt to /boot/firmware
  cp boot_firmware/cmdline.txt /boot/firmware
  cp boot_firmware/config.txt /boot/firmware
  cp kernels/bcm2712*-rpi-5-b.dtb /boot/firmware

- copy audio folder to homedir
  cp -a audio ~

- setup systemd babysit service
  cp audio/babysit.service /etc/systemd/system/

- setup post-boot initialization
  cp audio/rc.local /etc/
  systemctl enable rc-local.service

- finally reboot

```
TODO: cleanup ... as always..
