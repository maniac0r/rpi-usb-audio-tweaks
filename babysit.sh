#!/bin/bash

# retries to re-check non-runing-processess or OK processes
RETRY=2
SLEEP=5


P_BRIDGE="RoonBridge"
P_RAAT="RAATServer"
P_APPLIANCE="RoonAppliance"
P_UPMPD="upmpdcli"
P_MPD="mpd"

#AFFINITY_RAAT_RT="2"
AFFINITY_RAAT_RT="1-3"

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
  ARR0=($(ps axHo rtprio,lwp,cls,ni,pid,command | grep $1  | egrep -v '^\s+-\s+'))
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
      return 2
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
         egrep -v '^\s*-\s*' | \
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
         egrep -v '^\s*-\s*' | \
         awk '{print $6}' | \
         xargs -I%% taskset -c -p $1 %%
  fi
}


########################

I=0
I0=""
J=0
J0=""
while true ; do

  if [ -z "$I0" ] || [ "$I" -ge "$RETRY" ] ; then
    set_realtime $P_RAAT   FIFO 98 elevate # && raat_rt_affinity "$AFFINITY_RAAT_RT"
    I0=$?
    I=0
  elif [ -z "$J0" ] || [ "$J" -ge "$RETRY" ] ; then
    set_realtime $P_MPD    FIFO 98 elevate
    J0=$?
    J=0
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
