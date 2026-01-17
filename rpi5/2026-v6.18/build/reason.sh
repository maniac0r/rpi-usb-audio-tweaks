#!/bin/sh

set -x

R=$(dmesg | grep 'rpi-rtc soc:rpi_rtc: setting system clock to' | sed -r  's/(^.*)\(([0-9][0-9]*)\)/\2/')
if [ $R -gt 60 ] ; then
  bootreason="reboot"
else
  bootreason="shutdown"
fi

if [ "${bootreason}" = "shutdown" ] ; then
  (date ; echo "sleeping to allow switch some time to recover after CleanWave") >> /home/maniac/iperf.sh_boot.logtest
  sleep 15
fi
