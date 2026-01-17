#!/bin/sh

INTS=$(ifconfig  | egrep '^e\S+[0-9]' | awk -F ':' '{print $1}')

#set -x

for I in $INTS ; do
  #echo $I
  IFC=$(ifconfig $I | egrep 'inet ' | awk '{print $2}')

  if [ "x${IFC}" = "x" ] ; then
    echo "$I noip: $IFC , bringing down"
    ifconfig $I down
  else
    echo "$I has IP: $IFC, skipping"
  fi 
  
done


