#!/bin/bash
# 2024-10-17 maniac
# being run at boot from audiophilize.sh with sum parameter!
#

debug="true"
#debug="echo"

#set -x

TIME=10
SERVER=192.168.0.9
PORT=31338
MODE="--bidir" # can be: "" / "--reverse" / "--bidir"
URL="http://192.168.124.39:8086/write?db=opentsdb"
AUTH=""

## func
send2influx(){
  DATA='iperf3.retrans_in,host=rpi5 value='"$1"
  DATA=$DATA$'\niperf3.retrans_out,host=rpi5 value='"$2"
  DATA=$DATA$'\niperf3.mbps_in,host=rpi5 value='"$3"
  DATA=$DATA$'\niperf3.mbps_out,host=rpi5 value='"$4"

  curl $AUTH -s --connect-timeout 5 --max-time 10 -X POST --data "$DATA" "$URL" || echo "curl error" >&2
}



if [[ "x$1" == "x" ]] ; then
  ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 maniac@${SERVER} \
    "iperf3 -p ${PORT} --server --daemon --one-off" && \
      iperf3 -p ${PORT} -c ${SERVER} --time ${TIME} ${MODE}
elif [[ "x$1" == "xsum" ]] ; then
  R=$(ssh -o ConnectTimeout=1 -o ConnectionAttempts=3 maniac@${SERVER} \
    "iperf3 -p ${PORT} --server --daemon --one-off" && \
      iperf3 -p ${PORT} -c ${SERVER} --time ${TIME} ${MODE} | egrep -A6 '^- -' | \
        sed 's/.*Bytes //' | egrep 'sender' | awk '{print $3" "$1}')

  #R=$(ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 maniac@192.168.0.9 "iperf3 -p 31338 --server --daemon --one-off" && iperf3 -p 31338 -c 192.168.0.9 --time 1 --bidir | egrep -A6 '^- -'  | sed 's/.*Bytes //' | egrep 'sender' | awk '{print $3" "$1}')

  E=0
  R2=""
  $debug $R
  retrans1=$(echo $R | awk '{print $1}')
  mbps1=$(echo $R | awk '{print $2}')
  retrans2=$(echo $R | awk '{print $3}')
  mbps2=$(echo $R | awk '{print $4}')

  E=$(expr $retrans1 + $retrans2)
  $debug "E:$E"
  if [[ $E -gt 0 ]] ; then
    echo "LOSS"
    curl -s "https://fbi.sk/cgi-bin/pushsafer?rpi5&Link%20ERROR&20"
    send2influx $retrans1 $retrans2 $mbps1 $mbps2
  else
    echo "OK"
    curl -s "https://fbi.sk/cgi-bin/pushsafer?rpi5&Link%20OK&2"
    send2influx $retrans1 $retrans2 $mbps1 $mbps2

  fi
else
    ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 maniac@${SERVER} \
    "iperf3 -p ${PORT} --server --daemon --one-off" && \
      iperf3 -p ${PORT} -c ${SERVER} --time ${TIME} ${MODE} | egrep -A6 '^- -'
fi

