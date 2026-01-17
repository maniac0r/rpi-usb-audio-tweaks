#!/bin/bash

GW="192.168.0.9"
WAIT=120
PORT=22

# specify GW and wait time in seconds
wait4server(){
  T=0
  while [ $T -lt $2 ] ; do
    #OUT=$(/bin/ping -c 1 -W 1 $1)                  # 3 pings, 5 seconds altogether max
    OUT=$( nc -z --wait 1 $1 $3)
    RC=$?                                          # return code of ping
    if [ $RC -ne 0 ]  ; then                       # ping not ok
      (( T++ ))
      continue
    else					   # ping ok
      break
    fi

  done
}

wait4server ${GW} ${WAIT} ${PORT}

#echo "RC: $?"
