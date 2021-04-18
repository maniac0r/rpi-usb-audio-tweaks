#!/bin/bash
STR_LOG="/var/log/audio-tweaks.log"

P_ROON="RoonServer"
P_BRIDGE="RoonBridge"
P_RAAT="RAATServer"
P_APPLIANCE="RoonAppliance"
P_UPMPD="upmpdcli"
P_MPD="mpd"
P_HQP="networkaudiod"
P_ETH="irq\/.*-eth0"
P_XHCI="irq\/.*-xhci_hcd"
R_KERNELMOD="irq|mmc_|kworker"

# bit mask mapping for accesing /proc/irq/../smp_affinity files
CPU0=1	# 0001
CPU1=2	# 0010
CPU2=4	# 0100
CPU3=8	# 1000


cpu_affinity_eth0() {
  pgrep "irq\/.*-eth0" | xargs -n 1 /usr/bin/taskset -a -c -p $1
}

cpu_affinity_usbxhci() {
  /usr/bin/taskset -a -c -p $1 $(pgrep "irq\/.*-xhci_hcd")
}

cpu_affinity_upmpdcli() {
  /usr/bin/taskset -a -c -p $1 $(pgrep "$P_UPMPD")
}

cpu_affinity_raat() {
  # pozor, z nejakeho dovodu sa musi pouzit taskset uz pri startovani raatu, takze uprava je hlavne v startup skripte potrebna..
  pgrep -f RAATServer | xargs -n 1 /usr/bin/taskset -c -p $1
}

cpu_affinity_mpd() {
  # pozor, z nejakeho dovodu sa musi pouzit taskset uz pri startovani mpd (systemd service file)
  /usr/bin/taskset -a -c -p $1 $(pidof mpd)
}

cpu_affinity_naa() {
  /usr/bin/taskset -a -c -p $1 $(pidof networkaudiod)
}

cpu_affinity_trash() {
  # trash goes to this cpu
  /usr/bin/taskset -c -p $1 $(pidof RoonBridgeHelper)
  /usr/bin/taskset -c -p $1 $(pidof processreaper)
  /usr/bin/taskset -c -p $1 $(pgrep -f RoonBridge.exe)
  /usr/bin/taskset -c -p $1 $(pgrep -f rcu_preempt)
}

renice_usb() {
  # USB BUS
  /usr/bin/renice $1 -p $(pgrep "irq\/.*-xhci_hcd")
}

renice_mpd() {
  /usr/bin/renice $1 -p $(pgrep -w -f /mpd)
}

renice_raat() {
  /usr/bin/renice $1 -p $(pgrep -w -f RAATServer)
}

renice_hpq() {
  # HQP NAA
  /usr/bin/renice $1 -p $(pidof networkaudiod)
}

renice_upmpdcli() {
  /usr/bin/renice $1 -p $(pidof upmpdcli)
}

renice_eth0() {
  # ETHERNET
  pgrep "irq\/.*-eth0" | xargs /usr/bin/renice $1
}

#  * Options (At least one of them)
# s = roon Server
# a = roon Appliance
# r = RAAT
# b = roon Bridge
# d = mpD
# u = Upmpdcli
# q = HQP networkaudiod
# e = Ethernet
# x = Xhci USB
#
# Parameters
# m = Scheduling >> {FIFO|RR}
# p = Priority   >> {0-99}

realtime_usb_raat_hpq_mpd() {
  /home/pi/roonbridge/roon-realtime.sh -p 99 -m FIFO -b n -r y -d y -u n -q y -e n -x y
  # USB BUS (lebo skript hore asi nezafunguje?)
  # FIFO prio 99 (highest)
  chrt -f -p 99 $(pgrep "irq\/.*-xhci_hcd") >> $STR_LOG
  chrt -p $(pgrep "irq\/.*-xhci_hcd") >> $STR_LOG
  # ETH lowest priority, round robin
  # Round-Robin prio 1 (lowest)
  #pgrep "irq\/.*-eth0" | xargs -n 1 chrt -r -p 1 >> $STR_LOG
  #pgrep "irq\/.*-eth0" | xargs -n 1 chrt -p >> $STR_LOG
}

# # # # # # # # # #
# Function
# $1 = Value for Parent Process Name
# $2 = Value for Scheduling
# $3 = Value for Priority
# $4 = pidof/pgrep method
# # # # # # # # # # 
set_realtime() {
        if [ "$4" == "pgrep" ] ; then
          GETPID="pgrep -f"
        else
          GETPID="pidof"
        fi
        
        if [ "$2" == "FIFO" ] ; then
          SCHED="-f"
        else
          SCHED="-r"
        fi
        
                [[ -d /proc/$($GETPID $1)/task ]] || return 1
                ARR_PID=$(ls /proc/$($GETPID $1)/task)
#                [[ "x${ARR_PID}" == "x" ]] && return
                INT_ROWS=0
                for p_id in $ARR_PID;
                        do
                                echo "## Process : $(tail /proc/$($GETPID $1)/task/$p_id/comm) | PID = $p_id" >> $STR_LOG
                                chrt -a $SCHED -p $3 $p_id >> $STR_LOG
                                chrt -a -p $p_id >> $STR_LOG
                                INT_ROWS=$(($INT_ROWS + 1));
                        done
                echo "## -----------------------------------------------------------------" >> $STR_LOG
                echo "## Parent Process [$1] >> $INT_ROWS child process updated..." >> $STR_LOG
                echo "## -----------------------------------------------------------------" >> $STR_LOG
                echo "- - - - " >> $STR_LOG
}

# chceme ci nie??
#prioritize_eth0() {
#  pgrep "irq\/.*-eth0" | xargs -n 1 chrt -f -p $1
#  pgrep "irq\/.*-eth0" | xargs -n 1 chrt -p
#  pgrep "irq\/.*-eth0" | xargs /usr/bin/renice $2
#}

set_kernelparams() {
   echo 1 > /sys/bus/workqueue/devices/writeback/cpumask
   echo 5000000 > /proc/sys/kernel/sched_migration_cost_ns
  #echo 6000000 > /proc/sys/kernel/sched_latency_ns	# default
  #echo 1500000 > /proc/sys/kernel/sched_latency_ns	# rune audio
   echo 1000000 > /proc/sys/kernel/sched_latency_ns
   echo 100000  > /proc/sys/kernel/sched_min_granularity_ns
  #echo 225000  > /proc/sys/kernel/sched_min_granularity_ns
   echo 25000   > /proc/sys/kernel/sched_wakeup_granularity_ns
   echo -1      > /proc/sys/kernel/sched_rt_runtime_us
   echo 1       > /proc/sys/kernel/hung_task_check_count
   echo 0       > /proc/sys/vm/swappiness
   echo 20      > /proc/sys/vm/stat_interval
   echo 10      > /proc/sys/vm/dirty_ratio
  #echo 3       > /proc/sys/vm/dirty_background_ratio
   echo 5       > /proc/sys/vm/dirty_background_ratio
   echo -n performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
}

remove_kernelmodules() {
  echo -n "Removing unused kernel modules:"
  if [ -z "$(ifconfig | grep wlan)" ] ; then
    echo "no wlan interface found, will remove wifi related kernel modules too."
    WIFI=""
  else
    WIFI="|8021q|brcmfmac|cfg80211|rfkill|brcmutil"
  fi

  USBAUDIO='|snd_usb_audio|snd_hwdep|snd_pcm|snd_timer|mc'

  R=1
  while [ "$R" -eq 1 ] ; do 
    MODS=$(/sbin/lsmod | grep '  0' | egrep -v "ipv6${WIFI}${USBAUDIO}" | awk '{print $1}')
    if [ -n "$MODS" ] ; then
      echo "$MODS" | xargs /sbin/rmmod
    else
      R=0
    fi
    echo -n "$MODS."
  done
  echo ""
}

tune_default() {
  ifconfig eth0 mtu 1500
  ifconfig eth0 txqueuelen 1000
  echo 0 > /proc/sys/vm/swappiness
  echo "6000000" /proc/sys/kernel/sched_latency_ns
}

tune_runeaudio() {
  ifconfig eth0 mtu 1500
  ifconfig eth0 txqueuelen 1000
  echo 0 > /proc/sys/vm/swappiness
  echo "1500000" > /proc/sys/kernel/sched_latency_ns
}

tune_acx() {
  ifconfig eth0 mtu 1500
  ifconfig eth0 txqueuelen 4000
  echo "850000" > /proc/sys/kernel/sched_latency_ns
}

tune_orion() {
  ifconfig eth0 mtu 1000
  ifconfig eth0 txqueuelen 1000
  echo 20 > /proc/sys/vm/swappiness
  echo "500000" > /proc/sys/kernel/sched_latency_ns
}

tune_orionv2() {
  ifconfig eth0 mtu 1000
  ifconfig eth0 txqueuelen 4000
  echo 0 > /proc/sys/vm/swappiness
  echo "120000" > /proc/sys/kernel/sched_latency_ns
}

tune_um3gg1h1u() {
  ifconfig eth0 mtu 1500
  ifconfig eth0 txqueuelen 1000
  echo 0 > /proc/sys/vm/swappiness
  echo "500000" > /proc/sys/kernel/sched_latency_ns
}

###################################
#

set_kernelparams

remove_kernelmodules

# USB
renice_usb	-19
set_realtime $P_XHCI		FIFO 99	pgrep
cpu_affinity_usbxhci	0	# stay together with XHCI IRQ on CPU0

# MMC SDcard
 echo $CPU1 > /proc/irq/40/smp_affinity

# Ethernet
 cpu_affinity_eth0	3
 echo $CPU3  > /proc/irq/46/smp_affinity	# RPI4 ETH0 RX
 echo $CPU3 > /proc/irq/47/smp_affinity		# RPI4 ETH0 TX


exit

# RAAT
cpu_affinity_raat	2
renice_raat		-18
set_realtime $P_RAAT	FIFO 95

# HQP NAA
cpu_affinity_naa	2
renice_hpq		-18
set_realtime $P_HQP	FIFO 95


cpu_affinity_mpd	2
cpu_affinity_upmpdcli	1
cpu_affinity_trash	1

# ETH0
 echo $CPU3  > /proc/irq/46/smp_affinity	# RPI4 ETH0 RX
 echo $CPU3 > /proc/irq/47/smp_affinity		# RPI4 ETH0 TX

  # USB XHCI (is fixed to cpu0...)
  # echo $CPU0 > /proc/irq/54/smp_affinity

  # arch timer (is fixed to all cpus...)
  # echo $CPU123 > /proc/irq/19/smp_affinity

#renice_mpd	-18

renice_upmpdcli -17
renice_eth0	-5


# MPD si handluje RTPRIO sam (rtprio 40 len pre potrebne thready)
#set_realtime $P_MPD		FIFO 95

exit

# network servicec, not directly players
#set_realtime $P_BRIDGE		FIFO 90
#set_realtime $P_UPMPD		FIFO 90	pgrep

# 20210324 toto ked je zapnute tak seka zaciatok tracku a potom kazdych cca 10sec sek. vtedy mpd cachuje zo siete
#set_realtime $P_ETH		FIFO 80	pgrep

#set_realtime $P_APPLIANCE	RR 70
#set_realtime $P_ROON		RR 70

