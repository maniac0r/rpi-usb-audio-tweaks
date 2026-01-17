#!/bin/bash
STR_LOG="/var/log/audio-tweaks.log"

P_ROON="RoonServer"
P_BRIDGE="RoonBridge"
P_RAAT="RAATServer"
P_APPLIANCE="RoonAppliance"
P_UPMPD="upmpdcli"
P_MPD="mpd"
P_HQP="networkaudiod"
P_SQUEEZE="squeezelite"
#P_ETH="irq\/.*-eth0"			# RPi4
P_ETH="irq\/.*-eth%d"			# RPi5
#P_ETH_INTEL="eth.-[r|t]x"
P_ETH_INTEL="eth0|eth1|DMA"
#P_XHCI="irq\/.*-xhci_hcd"		# RPi4
#P_XHCI="irq\/.*-xhci-hcd:usb3"		# RPi5 USB no3
P_XHCI="irq\/.*-xhci-hcd:usb"		# RPi5 USB ANY
R_KERNELMOD="irq|mmc_|kworker"

# bit mask mapping for accesing /proc/irq/../smp_affinity files
CPU0=1	# 0001
CPU1=2	# 0010
CPU2=4	# 0100
CPU3=8	# 1000


#PRIO_AUDIOAPP="95"
PRIO_AUDIOAPP="99"
SCHED_AUDIOAPP="FIFO"
CORE_AUDIOAPP="2"

PRIO_USB="99"
SCHED_USB="FIFO"
CORE_USB="1"


PRIO_NIC="99"
SCHED_NIC="FIFO"
CORE=NIC="3"


#set -x

cpu_affinity_eth0() {
  #pgrep "irq\/.*-eth0" | xargs -n 1 /usr/bin/taskset -a -c -p $1	# RPi4
  pgrep "${P_ETH}" | xargs -n 1 /usr/bin/taskset -a -c -p $1	# RPi5
}

cpu_affinity_eth_intel() {
  #pgrep "irq\/.*-eth0" | xargs -n 1 /usr/bin/taskset -a -c -p $1	# RPi4
#  for IRQ in `grep "$P_ETH_INTEL" /proc/interrupts | awk '{print $1}' | sed 's/:$//'` ; do
  for PID in `pgrep "$P_ETH_INTEL"` ; do
    #echo "$PID"
    /usr/bin/taskset -a -c -p $1 $PID	# RPi5
  done
}

cpu_affinity_usbxhci() {
  #/usr/bin/taskset -a -c -p $1 $(pgrep "irq\/.*-xhci_hcd")		# RPi4
  for PID in `pgrep "${P_XHCI}"` ; do
    /usr/bin/taskset -a -c -p $1 $PID		# RPi5 USB no3
    # set also irqs 2026-01-15
    USBIRQ=$(ps ${PID} | egrep -v 'PID' | awk '{print $5}' | sed 's/^\[irq\///' | sed 's/-.*$//' )
    echo ${CPU1} > /proc/irq/${USBIRQ}/smp_affinity
  done
}

cpu_affinity_upmpdcli() {
  /usr/bin/taskset -a -c -p $1 $(pgrep "$P_UPMPD")
}

#  raat all
cpu_affinity_raat() {
  # pozor, z nejakeho dovodu sa musi pouzit taskset uz pri startovani raatu, takze uprava je hlavne v startup skripte potrebna..
#set -x
  echo "### cpu_affinity_raat" >&2
  CPU="$1"
  pgrep -f RAATServer | xargs -I%% /usr/bin/taskset -a -c -p $CPU %%
#set +x
}

# raat rt
cpu_affinity_raat_rt() {
  # pozor, z nejakeho dovodu sa musi pouzit taskset uz pri startovani raatu, takze uprava je hlavne v startup skripte potrebna..
#set -x
  RTPID=$(ps -eLo rtprio,cls,pri,ni,pid,lwp,rss,maj_flt,min_flt,command,comm  | grep RAATServer | egrep -v '^\s*-\s*' | awk ' {print $6}')
  CPU=$1
  echo $RTPID | xargs -I%% /usr/bin/taskset -c -p $CPU  %%
#set +x
}

cpu_affinity_mpd() {
  # pozor, z nejakeho dovodu sa musi pouzit taskset uz pri startovani mpd (systemd service file)
  /usr/bin/taskset -a -c -p $1 $(pidof mpd)
}

cpu_affinity_naa() {
  /usr/bin/taskset -a -c -p $1 $(pidof networkaudiod)
}

cpu_affinity_squeeze() {
  /usr/bin/taskset -a -c -p $1 $(pidof squeezelite)
}

cpu_affinity_trash() {
  echo "### cpu_affinity_trash"
  # trash goes to this cpu
  /usr/bin/taskset -a -c -p $1 $(pidof RoonBridgeHelper)
  /usr/bin/taskset -a -c -p $1 $(pidof processreaper)
  /usr/bin/taskset -a -c -p $1 $(pgrep -f RoonBridge.exe)
  #  /usr/bin/taskset -c -p $1 $(pgrep -f rcu_preempt)
  taskset -c -p $1 `pgrep irq/[0-9]*-s-aerdrv`
  taskset -c -p $1 `pgrep irq/[0-9]*-s-mmc0`
  taskset -c -p $1 `pgrep irq/[0-9]*-aerdrv`

  echo -n "ARM MailBoxes: "
  for PID in `pgrep 'irq/[0-9]*-.*\.mailbox'` ; do
    taskset -c -p $1 $PID
  done

  echo -n "onboard eth2 via rpi1 (eth0/1 is pcie intel..): "
  taskset -c -p $1 `pgrep 'irq/[0-9]+-eth%d'`

  echo -n "EXT4: "
  taskset -c -p $1 `pgrep 'kworker.*ext4'`
  taskset -c -p $1 `pgrep '^ext4'`
  echo -n "NFS: "
  taskset -c -p 1,3 `pgrep 'kworker.*nfsiod'`
  taskset -c -p 1,3 `pgrep '^nfsidod'`
  echo -n "kswapd: "
  taskset -c -p $1 `pgrep '^kswapd0'`
  echo -n "kdevtmpfs: "
  taskset -c -p $1 `pgrep '^kdevtmpfs'`
  echo -n "oom_reaper: "
  taskset -c -p $1 `pgrep '^oom_reaper'`
  echo -n "kcompactd0: "
  taskset -c -p $1 `pgrep '^kcompactd0'`
  echo -n "lockd: "
  taskset -c -p $1 `pgrep '^lockd'`

  echo -n "lockd: "
  taskset -c -p $1 `pgrep 'uart-pl'`

  echo "VCHIQ do"
  taskset -c -p $1 `pgrep "irq/[0-9]*-VCHIQ do"`
  echo  "watchdogd"
  taskset -c -p 0 `pgrep watchdogd`
  echo  "PCIe PME"
  taskset -c -p 0 `pgrep "irq/[0-9]*-PCIe PME"` 2>/dev/null
  echo  "DMA IRQ"
  taskset -c -p 0 `pgrep "irq/[0-9]*-DMA IRQ"` 2>/dev/null
  echo "fe00b880"
  taskset -c -p 0 `pgrep "irq/[0-9]*-fe00b880"`
  # all cpu
  echo "rcub/0"
  taskset -c -p 0-3 `pgrep "rcub/0"`
  echo "rcu_preempt"
  taskset -c -p 0-3 `pgrep "rcu_preempt"`

  # 1110 = 0xEh
  [[ `grep -q '99 Level' /proc/interrupts` ]] && echo e >  /proc/irq/`grep '99 Level' /proc/interrupts |awk '{print $1}' | tr -d :`/smp_affinity

  # 0xEh = cpu 3+2+1 (not 0)
  #echo e > /proc/irq/17/smp_affinity
  #echo e > /proc/irq/29/smp_affinity
}

cpu_affinity_trash_b() {
  echo "### cpu_affinity_trash_b"
  # trash goes to this cpu
  /usr/bin/taskset -a -c -p $1 $(pidof RoonBridgeHelper)
  /usr/bin/taskset -a -c -p $1 $(pidof processreaper)
  /usr/bin/taskset -a -c -p $1 $(pgrep -f RoonBridge.exe)
  #  /usr/bin/taskset -c -p $1 $(pgrep -f rcu_preempt)
#  taskset -c -p $1 `pgrep irq/[0-9]*-s-aerdrv`
#  taskset -c -p $1 `pgrep irq/[0-9]*-s-mmc0`
#  taskset -c -p $1 `pgrep irq/[0-9]*-aerdrv`

#  echo -n "ARM MailBoxes: "
#  for PID in `pgrep 'irq/[0-9]*-.*\.mailbox'` ; do
#    taskset -c -p $1 $PID
#  done

  echo -n "onboard eth2 via rpi1 (eth0/1 is pcie intel..): "
  taskset -c -p $1 `pgrep 'irq/[0-9]+-eth%d'`

 # echo -n "EXT4: "
 # taskset -c -p $1 `pgrep 'kworker.*ext4'`
 # taskset -c -p $1 `pgrep '^ext4'`
 # echo -n "NFS: "
 # taskset -c -p 1,3 `pgrep 'kworker.*nfsiod'`
 # taskset -c -p 1,3 `pgrep '^nfsidod'`
 # echo -n "kswapd: "
 # taskset -c -p $1 `pgrep '^kswapd0'`
  echo -n "kdevtmpfs: "
  taskset -c -p $1 `pgrep '^kdevtmpfs'`
  echo -n "oom_reaper: "
  taskset -c -p $1 `pgrep '^oom_reaper'`
  echo -n "kcompactd0: "
  taskset -c -p $1 `pgrep '^kcompactd0'`
 # echo -n "lockd: "
 # taskset -c -p $1 `pgrep '^lockd'`

#  echo -n "uart-pl: "
#  taskset -c -p $1 `pgrep 'uart-pl'`

 # echo "VCHIQ do"
 # taskset -c -p $1 `pgrep "irq/[0-9]*-VCHIQ do"`
  echo  "watchdogd"
  taskset -c -p 0 `pgrep watchdogd`
#  echo  "PCIe PME"
#  taskset -c -p 0 `pgrep "irq/[0-9]*-PCIe PME"` 2>/dev/null
#  echo  "DMA IRQ"
#  taskset -c -p 0 `pgrep "irq/[0-9]*-DMA IRQ"` 2>/dev/null
#  echo "fe00b880"
#  taskset -c -p 0 `pgrep "irq/[0-9]*-fe00b880"`
  # all cpu
#  echo "rcub/0"
#  taskset -c -p 0-3 `pgrep "rcub/0"`
 # echo "rcu_preempt"
 # taskset -c -p 0-3 `pgrep "rcu_preempt"`

  # 1110 = 0xEh
#  [[ `grep -q '99 Level' /proc/interrupts` ]] && echo e >  /proc/irq/`grep '99 Level' /proc/interrupts |awk '{print $1}' | tr -d :`/smp_affinity

  # 0xEh = cpu 3+2+1 (not 0)
  #echo e > /proc/irq/17/smp_affinity
  #echo e > /proc/irq/29/smp_affinity
}


renice_usb() {
  # USB BUS
  echo "### renice_usb:"
  /usr/bin/renice $1 -p $(pgrep "$P_XHCI")
}

renice_mpd() {
  /usr/bin/renice $1 -p $(pgrep -w -f /mpd)
}

renice_raat() {
  echo "### renice_raat:"
  /usr/bin/renice $1 -p $(pgrep -w -f RAATServer)
}

renice_hpq() {
  # HQP NAA
  /usr/bin/renice $1 -p $(pidof networkaudiod)
}

renice_upmpdcli() {
  /usr/bin/renice $1 -p $(pidof upmpdcli)
}

renice_squeeze() {
  /usr/bin/renice $1 -p $(pidof squeezelite)
}

renice_eth0() {
  echo "### renice_eth0"
  # ETHERNET
  #pgrep "irq\/.*-eth0" | xargs /usr/bin/renice $1		# RPi4
  pgrep "${P_ETH}" | xargs /usr/bin/renice $1		# RPi5
}

renice_eth_intel() {
  echo "### renice_eth_intel"
  # ETHERNET
  #pgrep "irq\/.*-eth0" | xargs /usr/bin/renice $1		# RPi4
  pgrep "${P_ETH_INTEL}" | xargs /usr/bin/renice $1		# RPi5
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

realtime_eth_prio() {
  echo "### realtime_eth_prio"
  PIDS=$(pgrep "${P_ETH_INTEL}") 
  echo "$PIDS" | xargs -n1 chrt -f -p $1
}

realtime_usb_raat_hpq_mpd() {
  echo "### realtime_usb_raat_hpq_mpd"
#  /home/pi/roonbridge/roon-realtime.sh -p 99 -m FIFO -b n -r y -d y -u n -q y -e n -x y
  # USB BUS (lebo skript hore asi nezafunguje?)
  # FIFO prio 99 (highest)
  #chrt -f -p 99 $(pgrep "$P_XHCI") >> $STR_LOG
  #pgrep "irq\/.*-xhci-hcd:usb" | xargs -n1 chrt -f -p 98
  pgrep "$P_XHCI" | xargs -n1 chrt -f -p ${PRIO_USB}
  #chrt -p $(pgrep "$P_XHCI") >> $STR_LOG
  pgrep "$P_XHCI" | xargs -n1 chrt -p
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
        echo -n "### set_realtime \"$1\" \"$2\" \"$3\" \"$4\"	-	"
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

	# just elevate prio of RT threads (mpd)
        if [ "$4" == "elevate" ] ; then
           ARR_PID=$( ps axHo rtprio,lwp,ni,pid,command | grep $1  | egrep -v '^\s+-\s+' | awk '{print $2}' )
	   INT_ROWS=0
           for p_id in $ARR_PID;
             do
               # echo "DEBUG p_id: $p_id"
               # echo "## Process : $(tail /proc/$($GETPID $1)/task/$p_id/comm) | PID = $p_id" >> $STR_LOG
               chrt $SCHED -p $3 $p_id >> $STR_LOG
               chrt -p $p_id >> $STR_LOG
               INT_ROWS=$(($INT_ROWS + 1));
             done
             return
        fi

        #echo "debug:/proc/$($GETPID $1)/task"
        for TPID in $($GETPID $1) ; do
          TPID2=$(echo "$TPID" | sed 's/\/.*//' )
          [[ -d /proc/$TPID2/task ]] || return 1
          ARR_PID=$(ls /proc/$TPID2/task)
          #[[ "x${ARR_PID}" == "x" ]] && return
          INT_ROWS=0
          for p_id in $ARR_PID;
            do
              echo "## Process : $(tail /proc/$TPID2/task/$p_id/comm) | PID = $p_id" >> $STR_LOG
              echo -n "| PID:$p_id SCHED:$SCHED PRIO:$3"
              chrt -a $SCHED -p $3 $p_id >> $STR_LOG
              chrt -a -p $p_id >> $STR_LOG
              INT_ROWS=$(($INT_ROWS + 1));
            done
          echo "## -----------------------------------------------------------------" >> $STR_LOG
          echo "## Parent Process [$1] >> $INT_ROWS child process updated..." >> $STR_LOG
          echo "## -----------------------------------------------------------------" >> $STR_LOG
          echo "- - - - " >> $STR_LOG

          done
	  echo ""               
}

# chceme ci nie??
#prioritize_eth0() {
#  pgrep "irq\/.*-eth0" | xargs -n 1 chrt -f -p $1
#  pgrep "irq\/.*-eth0" | xargs -n 1 chrt -p
#  pgrep "irq\/.*-eth0" | xargs /usr/bin/renice $2
#}

set_kernelparams() {
   echo "### set_kernelparams"
   #  kernel workqueues moved away from isolated core to cpu1.

  # echo 5000000 > /proc/sys/kernel/sched_migration_cost_ns
  #echo 6000000 > /proc/sys/kernel/sched_latency_ns	# default
  #echo 1500000 > /proc/sys/kernel/sched_latency_ns	# rune audio
  # echo 1000000 > /proc/sys/kernel/sched_latency_ns
  # echo 100000  > /proc/sys/kernel/sched_min_granularity_ns
  #echo 225000  > /proc/sys/kernel/sched_min_granularity_ns
  # echo 25000  > /proc/sys/kernel/sched_wakeup_granularity_ns
   echo -1      > /proc/sys/kernel/sched_rt_runtime_us
   echo 50      > /proc/sys/net/core/busy_read
   echo 50      > /proc/sys/net/core/busy_poll
   echo 1       > /proc/sys/kernel/hung_task_check_count
   echo 0       > /proc/sys/vm/swappiness
   echo 20      > /proc/sys/vm/stat_interval
   echo 5      > /proc/sys/vm/dirty_ratio
  #echo 3       > /proc/sys/vm/dirty_background_ratio
   echo 2       > /proc/sys/vm/dirty_background_ratio
  #echo 1       > /proc/sys/net/ipv4/tcp_low_latency
   echo -n performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
   echo -n performance > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
}

set_kernelparams_affinity() {
   echo "### set_kernelparams_affinity"
   echo 1 > /sys/bus/workqueue/devices/writeback/cpumask
   echo 1 > /sys/devices/virtual/workqueue/blkcg_punt_bio/cpumask
   echo 1 > /sys/devices/virtual/workqueue/cpumask
}

remove_kernelmodules() {
  echo -n "### Removing unused kernel modules:"
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

affinity_isolcpu0() {
  # move what is possible to elsewhere
  echo "### Tuna isolate"
  /usr/bin/tuna --cpus=0 --isolate
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



# move all from cpu0 elsewhere
# .. disabled as ressheduling to cpu1 occurs, not sure why
#affinity_isolcpu0

# 
#/usr/bin/taskset -c -p 0-3 $(pgrep -f rcu_preempt)
#/usr/bin/taskset -c -p 0-3 $(pgrep "rcub/0")


# MMC SDcard
mmc_affinity() {
  echo "### mmc_affinity MMC:"
  ##echo $CPU1 > /proc/irq/40/smp_affinity
  IRQ=`cat /proc/interrupts | grep mmc |awk '{print $1}' | tr -d :`
  echo $CPU0 > /proc/irq/$IRQ/smp_affinity

   echo -n "mmc pids: "
   for PID in `pgrep "irq/[0-9].*-mmc"` ; do
     #echo $CPU3 > /proc/irq/54/smp_affinity		# RPI4 ETH0 RX
     #echo $CPU3 > /proc/irq/55/smp_affinity		# RPI4 ETH0 TX
     echo -n "$PID "
     #echo $CPU1  > /proc/irq/$IRQ/smp_affinity
     taskset -c -p 0 $PID
   done  
   echo "."

  #pgrep -f  'sdhci|mmc_complete|mmcblk' |  xargs -n1 -I%% taskset -c -p 1,2,3 %%
  pgrep -f  'mmcblk' |  xargs -I%% taskset -c -p 0 %%
}
#mmc_affinity

# RAAT
affinity_raat() {
  echo "### Affinity RAAT:"
  #cpu_affinity_raat	1,2,3
  cpu_affinity_raat	0
  cpu_affinity_raat_rt	${CORE_AUDIOAPP}
  renice_raat		-18
  #set_realtime $P_RAAT	FIFO 93 elevate
}

affinity_mpd() {
  echo "### Affinity mpd:"
  cpu_affinity_mpd	1,2,3
  #cpu_affinity_sqeeze	2
  #cpu_affinity_upmpdcli	1
  echo "Affinity others:"
  cpu_affinity_trash	0
  # 
}

affinity_nfs() {
  # NFS
  echo "### Affinity NFS"
  pgrep -f  'NFS' |  xargs -I%% taskset -c -p 0,3 %%
}

# RPi5 mask is all cpus: f - not possible to change
affinity_eth0() {
  echo "### affinity_eth0"
  DECMASK=$1
  # this part is RPi4 only
  ## ETH0
  # echo -n "eth0 irqs: "
  # for IRQ in `cat /proc/interrupts | grep eth0 |awk '{print $1}' | tr -d :` ; do
  #   #echo $CPU3 > /proc/irq/54/smp_affinity		# RPI4 ETH0 RX
  #   #echo $CPU3 > /proc/irq/55/smp_affinity		# RPI4 ETH0 TX
  #   echo -n "$IRQ "
  #   #cat /proc/irq/$IRQ/smp_affinity
  #   echo $DECMASK  > /proc/irq/$IRQ/smp_affinity
  # done  
  # echo "."

  echo "put network work queues to cpu 3 (1-0-0-0)"
  #for F in `ls /sys/class/net/eth0/queues/*/xps_cpus` ; do echo $DECMASK | sudo tee $F ; done	# RPi4 only
  # 2023-12-05 pokus new RPi5..
  for F in `ls /sys/class/net/eth0/queues/*/rps_cpus` ; do echo $DECMASK | sudo tee $F ; done
}

affinity_eth_intel() {
  echo "### affinity_eth_intel"
  DECMASK=$1
  # this part is RPi4 only
  ## ETH0
   echo -n "eth intel irqs: "
    for IRQ in `cat /proc/interrupts | grep eth1 |awk '{print $1}' | tr -d :` ; do
  #   #echo $CPU3 > /proc/irq/54/smp_affinity		# RPI4 ETH0 RX
  #   #echo $CPU3 > /proc/irq/55/smp_affinity		# RPI4 ETH0 TX
     echo -n "$IRQ "
     #cat /proc/irq/$IRQ/smp_affinity
     echo $DECMASK  > /proc/irq/$IRQ/smp_affinity
   done  
   echo "."

  echo "put network work queues to cpu 3 (1-0-0-0)"
  #for F in `ls /sys/class/net/eth0/queues/*/xps_cpus` ; do echo $DECMASK | sudo tee $F ; done	# RPi4 only
  # 2023-12-05 pokus new RPi5..
  for F in `ls /sys/class/net/eth?/queues/*/rps_cpus` ; do echo $DECMASK | sudo tee $F ; done

#set +x
}

affinity_usb_fix_reschedule() {
  # enabling this removes "resheduling interrupt"s from cpu1-3, but increases cpu0 avg jitter from 3,0 to 3,5 (old kernels, does not apply anymore after 6.17)
  echo  "### affinity_usb_fix_reschedule:"
#  cpu_affinity_usbxhci    0-3
#  cpu_affinity_usbxhci    1,3
# pokus 2024-03-06
#  cpu_affinity_usbxhci    0-1
  cpu_affinity_usbxhci    1
}



# dissable Kernel Same-page Merging to avoid latency
#if [ -f /sys/kernel/mm/ksm/run ] ; then
#  echo "KSM:"
#  echo 2 > /sys/kernel/mm/ksm/run 2>/dev/null
#fi

# Ethernet
#cpu_affinity_eth0	3
# echo 8  > /proc/irq/46/smp_affinity	# RPI4 ETH0 RX
# echo 8 > /proc/irq/47/smp_affinity		# RPI4 ETH0 TX
# taskset -c -p 8 `pgrep "irq/46-eth0"`
# taskset -c -p 8 `pgrep "irq/47-eth0"`
# taskset -c -p 8 `pgrep irq/26`
# bind eth0 queues to core3
#for F in $(ls /sys/class/net/eth0/queues/tx-*/xps_cpus) ; do echo 8 > $F ; done
#for F in $(ls /sys/class/net/eth0/queues/tx-*/xps_rxqs) ; do echo 8 > $F ; done
#echo 8 > /sys/class/net/eth0/queues/rx-0/rps_cpus

#exit

##################################################################################################
# MAIN


set_kernelparams 2>/dev/null
#set_kernelparams_affinity 2>/dev/null


# USB
echo "USB:"
renice_usb		-19
#set -x
set_realtime 		$P_XHCI ${SCHED_USB} ${PRIO_USB} pgrep
cpu_affinity_usbxhci    ${CORE_USB}       # stay together with XHCI IRQ on CPU1 (taskset)

# not needed - handled via babysit (actually maybe the non-rt processes...)
affinity_raat

# HQP NAA
#cpu_affinity_naa	2
#renice_hpq		-18
#set_realtime $P_HQP	FIFO 94

# SQUEEZELITE
#cpu_affinity_naa	2
#renice_squeeze		-18
#set_realtime $P_SQUEEZE	FIFO 94



#affinity_nfs
 
  # USB XHCI (is fixed to cpu0...)
  # echo $CPU0 > /proc/irq/54/smp_affinity

  # arch timer (is fixed to all cpus...)
  # echo $CPU123 > /proc/irq/19/smp_affinity

#renice_mpd	-18

#renice_upmpdcli -17
echo "Renice eth0:"
renice_eth0	-5
affinity_eth0	${CPU3} 	# 2026-01-15
#cpu_affinity_eth0 0-3
cpu_affinity_eth0 3

echo "intel eth affinity:"
#affinity_eth_intel ${CPU3}
renice_eth_intel -5
cpu_affinity_eth_intel 3
echo $CPU3 > /proc/irq/33/smp_affinity
#echo $CPU3 > /proc/irq/35/smp_affinity
realtime_eth_prio 99


#realtime_usb_raat_hpq_mpd

# MPD si handluje RTPRIO sam (rtprio 40 len pre potrebne thready)
#set_realtime $P_MPD		FIFO 95 elevate

cpu_affinity_trash_b    0



affinity_usb_fix_reschedule


exit

# network services, not directly players
#set_realtime $P_BRIDGE		FIFO 90
#set_realtime $P_UPMPD		FIFO 90	pgrep

# 20210324 toto ked je zapnute tak seka zaciatok tracku a potom kazdych cca 10sec sek. vtedy mpd cachuje zo siete
#set_realtime $P_ETH		FIFO 80	pgrep

#set_realtime $P_APPLIANCE	RR 70
#set_realtime $P_ROON		RR 70

