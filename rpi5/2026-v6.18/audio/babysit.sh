#!/bin/bash

# retries to re-check non-runing-processess or OK processes
RETRY=2
SLEEP=5


P_BRIDGE="RoonBridge"
P_RAAT="RAATServer"
P_APPLIANCE="RoonAppliance"
P_UPMPD="upmpdcli"
P_MPD="mpd"

AFFINITY_RAAT_RT="2"
#AFFINITY_RAAT_RT="1-3"
AFFINITY_MPD_RT="2"

#PRIO_AUDIOAPP="95"
PRIO_AUDIOAPP="99"
SCHED_AUDIOAPP="FIFO"


#STR_LOG=/dev/null
STR_LOG="&2"

ARG="$1"

# parameter "d" means debug mode
if [ "X$ARG" == "X" ] ; then
  DEBUG="/usr/bin/true"
  true
elif  [ "X$ARG" == "Xd" ] ; then
  DEBUG="/usr/bin/echo"
  echo "debug enabled"
fi

  OIFS="$IFS"
  NLIFS='
'

#set -x

# # # # # # # # # #
# Function
# $1 = Value for Parent Process Name
# $2 = Value for Scheduling
# $3 = Value for Priority
# $4 = pidof/pgrep method
# # # # # # # # # #
set_realtime() {
  $DEBUG "set_realtime $1 $2 $3"
  if [ "$2" == "FIFO" ] ; then
    SCHED="-f"
    SCHEDNAME="FF"
  else
    SCHED="-r"
    SCHEDAME="RR"
  fi

  IFS=$NLIFS
  ARR0=($(ps axHo rtprio,lwp,cls,ni,pid,command | grep $1  | grep -E -v '^\s+-\s+'))
#  ARR=($(ps axHo rtprio,lwp,cls,ni,pid,command | grep $1  | egrep -v '^\s+-\s+'))

  #$DEBUG ARR0:${ARR0[@]}

  for ARR1 in ${ARR0[@]} ; do		# for each line ...
    $DEBUG ARR1:$ARR1
    IFS="$OIFS" 
    ARR=($(echo "$ARR1"))
######
    #$DEBUG "ARR:${ARR[@]}"
#set -x
    ARR_PID=${ARR[1]}
    # finish if parameters already set
    THR_PRIO=${ARR[0]}
    THR_SCHED=${ARR[2]}
#set +x
    if [ -z "$ARR_PID" ] || [ -z "$THR_PRIO" ] || [ -z "$THR_SCHED" ] ; then
      $DEBUG "$1 thread not found"
      #export Y=0 Y1=0
      return 1
    fi

    Y=0
    for X in $THR_PRIO ; do
      if [ "$X" -eq "$3" ] ; then
        ((Y++))
      else
        Y=0
        #$DEBUG "debug: Y=0 , continue"
        break	# some thread needs setup
      fi
    done
    Y1=0
    for X in $THR_SCHED ; do
      if [ "$X" == "$SCHEDNAME" ] ; then
        ((Y1++))
      else
        Y1=0
        #$DEBUG "debug: Y1=0 , continue"
        break	# some thread needs setup
      fi
    done

    if [ "x$Y" == "x" ] || [ "x$Y1" == "x" ] ; then
      $DEBUG "Thread not found"
      return 1
    fi


    #if [ "$THR_PRIO" -eq "$3" ] && [ "$THR_SCHED" == "$SCHEDNAME" ] ; then
    if [ $Y -eq 1 ] && [ $Y1 -eq 1 ] ; then
      $DEBUG "$1 already OK"
#      return 2
      continue
    fi
    #INT_ROWS=0
    for p_id in $ARR_PID;
      do
  #      echo "DEBUG p_id: $p_id"
  #      echo "## Process : $(tail /proc/$($GETPID $1)/task/$p_id/comm) | PID = $p_id" >> $STR_LOG
        chrt $SCHED -p $3 $p_id #>> $STR_LOG
        chrt -p $p_id #>> $STR_LOG
        #INT_ROWS=$(($INT_ROWS + 1));
      done

  done	# FOR 1 LINE...  
  
#####  


  return 0
}

####

raat_rt_affinity(){
  AFF=$(ps -eLo rtprio,cls,pri,ni,pid,lwp,rss,maj_flt,min_flt,command,comm  | \
         grep RAATServer | \
         grep -E -v '^\s*-\s*' | \
         awk '{print $6}' | \
         xargs -I%% taskset -c -p %% | \
         sed 's/.*: //'
       )
  if [ "$AFF" == "$AFFINITY_RAAT_RT" ] ; then
    $DEBUG "debug: $AFF ==  $AFFINITY_RAAT_RT"
    return 0
  else
    ps -eLo rtprio,cls,pri,ni,pid,lwp,rss,maj_flt,min_flt,command,comm  | \
         grep RAATServer | \
         grep -E -v '^\s*-\s*' | \
         awk '{print $6}' | \
         xargs -I%% taskset -c -p $1 %%
  fi
}

mpd_rt_affinity(){
  AFF=$(ps -eLo rtprio,cls,pri,ni,pid,lwp,rss,maj_flt,min_flt,command,comm  | \
         grep mpd | \
         grep -E -v '^\s*-\s*' | \
         awk '{print $6}' | \
         xargs -I%% taskset -c -p %% | \
         sed 's/.*: //'
       )
  if [ "$AFF" == "$AFFINITY_MPD_RT" ] ; then
    $DEBUG "debug: $AFF ==  $AFFINITY_MPD_RT"
    return 0
  else
    ps -eLo rtprio,cls,pri,ni,pid,lwp,rss,maj_flt,min_flt,command,comm  | \
         grep mpd | \
         grep -E -v '^\s*-\s*' | \
         awk '{print $6}' | \
         xargs -I%% taskset -c -p $1 %%
  fi
}

cache_bins_to_ram(){
  mkdir /dev/shm/bin 2>/dev/null
  for B in /bin/true /bin/echo /bin/ps /bin/awk /bin/grep /bin/awk /bin/sed /bin/bash /usr/bin/echo /usr/bin/chrt /usr/bin/taskset /usr/bin/xargs /usr/bin/pgrep /usr/bin/sleep ; do
    cp -a --dereference "$B" /dev/shm/bin/
  done
}

########################

cache_bins_to_ram
export PATH=/dev/shm/bin:$PATH
$DEBUG "PATH:$PATH"

I=0
I0=""
J=0
J0=""

#set -x
MPD_LAST_PID=""
ROON_LAST_PID=""

while true ; do

MPD_UP=0
ROON_UP=0
MPD_PID=$(pgrep mpd)
[ -z "$MPD_PID" ] || MPD_UP=1
ROON_PID=$(ps axHo rtprio,lwp,command | grep -E '^\s*[0-9].*RAATServer' | awk '{print $2}')
#pgrep -f RAATServer && ROON_UP=1)
[ -z "$ROON_PID" ] || ROON_UP=1

  if [ $ROON_UP -eq 1 ] && ([ -z "$I0" ] || [ "$I" -ge "$RETRY" ]) ; then
    if [ "$ROON_PID" != "$ROON_LAST_PID" ] ; then
      set_realtime $P_RAAT   ${SCHED_AUDIOAPP} ${PRIO_AUDIOAPP} elevate && raat_rt_affinity "$AFFINITY_RAAT_RT"
      I0=$?
      I=0
      ROON_LAST_PID=$ROON_PID
    else
      $DEBUG "Roon already set."
      I=0
    fi
  elif [ $MPD_UP -eq 1 ] && ([ -z "$J0" ] || [ "$J" -ge "$RETRY" ]) ; then
    if [ "$MPD_PID" != "$MPD_LAST_PID" ] ; then
      set_realtime $P_MPD    ${SCHED_AUDIOAPP} ${PRIO_AUDIOAPP} elevate # && mpd_rt_affinity "$AFFINITY_MPD_RT"
      J0=$?
      J=0
      MPD_LAST_PID=$MPD_PID
    else
      $DEBUG "mpd already set."
      J=0
    fi
  else
    #echo -n "."
    ((J++))
    ((I++))
  sleep $SLEEP
  fi
#  sleep $SLEEP
  if [ "$ARG" == "1" ] ; then
    exit 0
  fi    
done
