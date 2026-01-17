#!/bin/sh
export TZ=Europe/Bratislava

systemctl stop bluetooth ; systemctl disable bluetooth ; systemctl stop  wpa_supplicant  systemd-timesyncd  dbus systemd-logind systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket NetworkManager dbus.socket
systemctl stop systemd-journald systemd-journald-dev-log.socket systemd-journald-audit.socket systemd-journald.socket '*.timer' systemd-journal-flush.service systemd-update-utmp.service rpi-eeprom-update.service 
systemctl stop '*getty*'

# rpi5 with pcie ethernet force 100mbps
# 2024-10-17 after powerdown 100mbps has issues
#ethtool -s eth0 speed 100 duplex full autoneg on
##ethtool -s eth1 speed 100 duplex full autoneg on

echo "-"
sleep 0.2

# https://hackmd.io/@cantfindagoodname/notes
echo 0 > /proc/sys/kernel/randomize_va_space

mkdir -p /dev/shm/RAATServer/Logs
mkdir -p /dev/shm/RoonBridge/Logs

mv /var/roon/RoonBridge/Logs /var/roon/RoonBridge/Logs.old
mv /var/roon/RAATServer/Logs /var/roon/RAATServer/Logs.old

ln -s /dev/shm/RAATServer/Logs /var/roon/RAATServer/Logs
ln -s /dev/shm/RoonBridge/Logs /var/roon/RoonBridge/Logs

systemctl restart roonbridge	# TODO!

sudo mount -o remount,size=32M /dev/shm


# set pi5 fan to 3k rpm
echo -n "Current fan level: "$(cat /sys/class/thermal/cooling_device0/cur_state)
echo -n " , setting level: "
echo 1 | tee /sys/class/thermal/cooling_device0/cur_state


# check if we have IP
R=$(/usr/sbin/route -n | egrep -v '^Kernel IP routing table|^Destination' |wc -l)
if [ $R -gt 0 ] ; then
    # rpi5 shutdown interfaces without IP assigned
    INTS=$(ifconfig  | egrep '^e\S+[0-9]' | awk -F ':' '{print $1}')
    for I in $INTS ; do
      #echo $I
      IFC=$(ifconfig $I | egrep 'inet ' | awk '{print $2}')
      if [ "x${IFC}" = "x" ] ; then
        echo "$I noip: $IFC , bringing down"
        ifconfig $I down
      else
        echo "$I has IP: $IFC, skipping"
      fi
    done
else
    echo "No IP configured! Keeping interfaces active!"
fi

# TODO!
/home/maniac/audio/tweaks.sh 



# systemctl start babysit
# borrowed from RuneOS
cat > /etc/sysctl.d/10-raspberrypi.conf << EOF
vm.min_free_kbytes=32768
vm.vfs_cache_pressure = 300
net.core.rmem_max=12582912
net.core.wmem_max=12582912
net.ipv4.tcp_rmem= 10240 87380 12582912
net.ipv4.tcp_wmem= 10240 87380 12582912
net.ipv4.tcp_timestamps = 0
#net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 0
#net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 5000
vm.overcommit_memory = 2
vm.overcommit_ratio = 100
vm.stat_interval = 120
vm.swappiness = 0
vm.dirty_background_ratio = 2
vm.dirty_ratio=5
EOF

echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/20-quiet-printk.conf


# sleep in case of cold boot 
#bootreason=$(last -x | head -n 2 | egrep 'shutdown|reboot' | tail -n 1 | sed 's/ .*//')
R=$(dmesg | grep 'rpi-rtc soc:rpi_rtc: setting system clock to' | sed -r  's/(^.*)\(([0-9][0-9]*)\)/\2/')
if [ $R -gt 60 ] ; then
  bootreason="reboot"
else
  bootreason="shutdown"
fi

date > /home/maniac/iperf.sh_boot.log
echo "Boot Reason: ${bootreason} (${R})" >> /home/maniac/iperf.sh_boot.log

if [ "${bootreason}" = "shutdown" ] ; then
  (date ; echo "sleeping to allow switch some time to recover after CleanWave") >> /home/maniac/iperf.sh_boot.log
  #sleep 35
  /bin/ping -q -c 25 -W 1 192.168.0.9 -s 65500
fi

# wait till server is reachable/available, then run stability test, report to influxdb
#last -x | head -n 2 >> /home/maniac/iperf.sh_boot.log
chown maniac /home/maniac/iperf.sh_boot.log 2>/dev/null
su maniac -c "echo -n 'Warmup    ' ; date ; /home/maniac/audio/test-server.sh && /home/maniac/iperf.sh 2>&1 >> /home/maniac/iperf.sh_boot.log 2>&1"
su maniac -c "echo -n 'Real test ' ; date ; /home/maniac/audio/test-server.sh && /home/maniac/iperf.sh sum 2>&1 >> /home/maniac/iperf.sh_boot.log 2>&1"
RC=$?
date >> /home/maniac/iperf.sh_boot.log
echo "DONE , RC:${RC}" >> /home/maniac/iperf.sh_boot.log

###########################################################
# RPi5 Fan Speed
#/usr/bin/pinctrl FAN_PWM dl	# Off
#/usr/bin/pinctrl FAN_PWM ah	# On (Full)
/usr/bin/pinctrl FAN_PWM a0	# Auto


# Disable EEE - needed for PaulPang Quad switch, else about 10% packetloss :/
/usr/sbin/ethtool --set-eee eth2 eee off
