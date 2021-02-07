#!/bin/bash

pstree

egrep -v '0\s+0\s+0\s+0' /proc/interrupts

cat /boot/cmdline.txt

egrep -v '^\s*#|^$' /boot/config.txt | tr \\n \ 

ifconfig eth0

ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:14,comm  | sort -n -k 7

echo "hit enter to continue"
read brm

ps ax -Lo psr,pid,cls,rtprio,pri,nice,cmd  | sort -n -k 5 | uniq  | egrep --color 'FF|'
 
echo "hit enter to continue"
read brm

sudo lsof | egrep -v 'pipe$| /dev/| TCP| UDP' | grep ' [0-9]\+w '
echo "hit enter to continue"
read brm
