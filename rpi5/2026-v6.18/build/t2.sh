#!/bin/sh

bootreason=$(last -x | head -n 2 | egrep 'shutdown|reboot' | head | sed 's/ .*//')

if [ "${bootreason}" = "shutdown" ] ; then
  (date ; echo "sleeping to allow switch some time to recover after CleanWave") >> /home/maniac/iperf.sh_boot.log
  sleep 20
fi

