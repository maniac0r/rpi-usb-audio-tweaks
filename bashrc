# Show important metrics upon ssh login , including network throughput from RoonServer
#

ROONSERVER="192.168.0.9"
SSHUSER="roonuser"

echo ""

sensors | egrep --color=no ^temp
/opt/vc/bin/vcgencmd measure_clock arm 2>/dev/null
echo -n "eth0 speed:  "
ethtool eth0 2>/dev/null| grep --color=no Speed: | sed 's/\s\+/ /g'
echo -n "eth0 issues:  "
E=$(/sbin/ethtool -S eth0 | egrep 'err|fail|drop' | egrep -v ': 0$' | tr -d \\n  | sed 's/^\s\+//' | sed 's/$/\n/')
echo "$E"
/usr/sbin/ifconfig eth0 | grep errors | egrep '[1-9]'

echo -n "iperf3 downl: PLEASE WAIT..."
I=$(ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 SSHUSER@$ROONSERVER "iperf3 -p 31337 --server --daemon --one-off" && iperf3 -p 31337 -c $ROONSERVER --time 1 | egrep sender | awk '{print $7" "$8" , Retr:"$9} ')
echo -n -e "\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
echo "$I"

echo -n "USB audio:    "
U=$(sudo lsusb -vd 20b1:2004 | head -n 50 | grep -A 50 'Configuration Descriptor:' | grep -A 2  'bmAttributes' | tail -n2 | sed 's/^\s*//')
echo "$U" | tr \\n \| | sed 's/|$//' | sed 's/|/ | /g' | sed 's/\s\+/ /g'
echo ""

echo -n "Isolate CPUs: "
C=$(cat /sys/devices/system/cpu/isolated)
if [ -z "$C" ] ; then
  echo "none"
else
  echo "$C"
fi

pstree
