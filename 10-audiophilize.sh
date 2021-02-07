#!/bin/sh

LAN_IP='inet 192.168.0.'

# stop all not needed
systemctl stop exim4 netdata bluetooth cron openvpn-client@rpi4bkp1195 openvpn-client@rpi4bkp wpa_supplicant rsync "triggerhappy*" smartd hciuart systemd-timesyncd dbus.socket dbus rng-tools "systemd-journald*" systemd-journald systemd-journald.socket systemd-journald-audit.socket systemd-journald-dev-log.socket rsyslog syslog.socket systemd-tmpfiles-clean.timer systemd-tmpfiles-clean man-db.timer logrotate.timer apt-daily.timer apt-daily-upgrade.timer systemd-journald.socket systemd-journald alsa-state getty@tty1.service

# let journald running
#systemctl stop exim4 netdata bluetooth cron openvpn-client@rpi4bkp1195 openvpn-client@rpi4bkp wpa_supplicant rsync "triggerhappy*" smartd hciuart systemd-timesyncd dbus.socket dbus rng-tools systemd-tmpfiles-clean.timer systemd-tmpfiles-clean man-db.timer logrotate.timer apt-daily.timer apt-daily-upgrade.timer systemd-journald.socket systemd-journald alsa-state getty@tty1.service

# roonbridge  logs will go to ramdisk
mkdir -p /dev/shm/RAATServer/Logs
mkdir -p /dev/shm/RoonBridge/Logs
mv /var/roon/RoonBridge/Logs /var/roon/RoonBridge/Logs.old
mv /var/roon/RAATServer/Logs /var/roon/RAATServer/Logs.old
ln -s /dev/shm/RAATServer/Logs /var/roon/RAATServer/Logs
ln -s /dev/shm/RoonBridge/Logs /var/roon/RoonBridge/Logs

# start network audio services
systemctl start mpd mpd.socket upmpdcli networkaudiod roonbridge

# flush firewalll
iptables -P INPUT ACCEPT ; iptables -F INPUT
iptables -F LOG_DROP ; iptables -X LOG_DROP

sudo mount -o remount,size=32M /dev/shm
#sudo mount -o remount,size=512M /dev/shm

# give dhcpcd chance to setup eth0 during boot time
UPTIME=$(awk -F '.' '{print $1}' /proc/uptime)
if [ $UPTIME -lt 120 ] ; then
  sleep 20
fi

# if we got proper ip on ethernet (dhcpcd) then turn off wifi
ETH=$(/sbin/ifconfig eth0 | grep -q "$LAN_IP" ; echo $?)
if [ "$ETH" -eq 0 ] ; then
  echo "FOUND configured eth0 , DISABLING wlan"
  /sbin/ifconfig wlan0 down
fi

./tweaks.sh



###############################################################
# one-time setup stuff....
# reboot will be required if this script if executed for the 1st time
# borrowed from RuneOS
cat > /etc/sysctl.d/10-raspberrypi.conf << EOF
vm.min_free_kbytes=32768
vm.vfs_cache_pressure = 300
net.core.rmem_max=12582912
net.core.wmem_max=12582912
net.ipv4.tcp_rmem= 10240 87380 12582912
net.ipv4.tcp_wmem= 10240 87380 12582912
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 0
net.ipv4.tcp_no_metrics_save = 1
net.core.netdev_max_backlog = 5000
vm.overcommit_memory = 2
vm.overcommit_ratio = 100
EOF

echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/20-quiet-printk.conf

# nrpacks usb-audio option removed from newer kerbels :(
#echo "options snd-usb-audio nrpacks=8" > /etc/modprobe.d/modprobe.conf

# we don't need rpi onboard audio
echo "blacklist snd-soc-pcm512x" > /etc/modprobe.d/snd-soc-pcm512x.conf

