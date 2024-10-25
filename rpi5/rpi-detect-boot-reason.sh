#!/bin/sh
# 2024-10-25 maniac
# Based on internal RPi SoC uptime timer, identify boot reason: reboot/shutdown
# Use cases:
#   - no NTP available
#   - no persisten log available
# Parameter SECONDS defines thresholld after which we consider resaon to be reboot

SECONDS=60

R=$(dmesg | grep 'rpi-rtc soc:rpi_rtc: setting system clock to' | sed -r  's/(^.*)\(([0-9][0-9]*)\)/\2/')
if [ $R -gt $SECONDS ] ; then
  bootreason="reboot"
else
  bootreason="shutdown"
fi
