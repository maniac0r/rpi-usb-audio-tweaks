#!/bin/bash

#set -x

# ProcessusName
PROC_ROON="RoonServer"
PROC_BRIDGE="RoonBridge"
PROC_RAAT="RAATServer"
PROC_APPLIANCE="RoonAppliance"
PROC_UPM="upmpdcli"
PROC_MPD="mpd"
PROC_HQP="networkaudiod"
PROC_ETH="irq\/.*-eth0"
PROC_XHCI="irq\/.*-xhci_hcd"

R_KERNELMOD="irq|mmc_|kworker"


# Log File
STR_LOG="/var/log/roon-realtime.log"
echo "- - - - " > $STR_LOG
echo "## Date : $( date +'%D %r' )" >> $STR_LOG
echo "## User : $( whoami )" >> $STR_LOG
echo "- - - - " >> $STR_LOG

# Options
STR_HELP="
How to use this script :
 roon-realtime.sh PARAMETERS OPTIONS

Example for Server: roon-realtime.sh -p 99 -m FIFO -s y -a y -r y
Example for Brige: roon-realtime.sh -p 99 -m FIFO -b y -r y

 * Options (At least one of them)
 s = Server
 a = Appliance
 r = RAAT
 b = Bridge
 d = mpd
 u = upmpdcli
 q = HQP networkaudiod
 e = Ethernet
 x = Xhci USB

 * Parameters
 m = Scheduling >> {FIFO|RR}
 p = Priority   >> {0-99}
"
while getopts s:a:r:b:d:u:q:e:x:m:p:h: option
do
 case "${option}"
   in
        s)
                OPT_ROON=${OPTARG}
                echo "## Option $PROC_ROON selected..." >> $STR_LOG
                ;;
        a)
                OPT_APPLIANCE=${OPTARG}
                echo "## Option $PROC_APPLIANCE selected..." >> $STR_LOG
                ;;
        r)
                OPT_RAAT=${OPTARG}
                echo "## Option $PROC_RAAT selected..." >> $STR_LOG
                ;;
        b)
                OPT_BRIDGE=${OPTARG}
                echo "## Option $PROC_BRIDGE selected..." >> $STR_LOG
                ;;
        d)
                OPT_MPD=${OPTARG}
                echo "## Option $PROC_MPD selected..." >> $STR_LOG
                ;;
        u)
                OPT_UPM=${OPTARG}
                echo "## Option $PROC_UPM selected..." >> $STR_LOG
                ;;
        q)
                OPT_HQP=${OPTARG}
                echo "## Option $PROC_HQP selected..." >> $STR_LOG
                ;;
        e)
                OPT_ETH=${OPTARG}
                echo "## Option $PROC_ETH selected..." >> $STR_LOG
                ;;
        x)
                OPT_ETH=${OPTARG}
                echo "## Option $PROC_XHCI selected..." >> $STR_LOG
                ;;
        m)
                SCHED_CMD=${OPTARG}
                echo "## Scheduling $SCHED_CMD  selected..." >> $STR_LOG
                ;;
        p)
                SCHED_RANGE=${OPTARG}
                echo "## Priority $SCHED_RANGE selected..." >> $STR_LOG
                ;;
        h)
                echo $STR_HELP
                exit 0
                ;;
 esac
done
echo "- - - -" >> $STR_LOG

# # # # # # # # # #
# Function
# $1 = Value for Process Name
# $2 = Value for Log file
# # # # # # # # # #
function Get_ProcessStatus () {
        if [ "$3" == "pgrep" ] ; then
          GETPID="pgrep -f"
        else
          GETPID="pidof"
        fi
        # Check if the process is started
        if [ -f "/proc/$($GETPID $1)/exe" ]; then
                INT_RETURN=1
                echo "## Service $1 started..." >> $2
        elif [[ $1 =~ $R_KERNELMOD ]] ; then
                INT_RETURN=2
                echo "## Kernel process $1 started..." >> $2
        else
                INT_RETURN=0
                echo "## Service $1 not started..." >> $2
        fi

        # Return value of the flag
        return $INT_RETURN

}

# Pause
#echo "## Pause 8 secs (to be sure all services are running)..." >> $STR_LOG
#sleep 8
echo "- - - -" >> $STR_LOG

# Check if the service are running
FLAG=0
FLAG_MAX=3
# Identify the number of service
if [ "$PROC_BRIDGE" == "Y" ] || [ "$PROC_BRIDGE" == "y" ]; then
        FLAG_MAX=2
fi

# Iteration
while (( FLAG < FLAG_MAX ))
do
        # Check for RoonServer
        Get_ProcessStatus $PROC_ROON $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for RoonAppliance
        Get_ProcessStatus $PROC_APPLIANCE $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for RAATServer
        Get_ProcessStatus $PROC_RAAT $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for RoonBridge
        Get_ProcessStatus $PROC_BRIDGE $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for MPD
        Get_ProcessStatus $PROC_MPD $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for Upmpdcli
        Get_ProcessStatus $PROC_UPM $STR_LOG pgrep
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for HQPlayer NAA
        Get_ProcessStatus $PROC_HQP $STR_LOG
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for Ethernet IRQ
        Get_ProcessStatus $PROC_ETH $STR_LOG pgrep
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

        # Check for XHCI USB IRQ
        Get_ProcessStatus $PROC_XHCI $STR_LOG pgrep
        INT_RESULT=$?
        FLAG=$(($FLAG + $INT_RESULT))

done
echo "- - - -" >> $STR_LOG

# Schedule Round robin
if [ "$SCHED_CMD" == "RR" ] || [ "$SCHED_CMD" == "rr" ]; then
        SCHED_CMD="-r"
fi

# Schedule First in, first out
if [ "$SCHED_CMD" == "FIFO" ] || [ "$SCHED_CMD" == "fifo" ]; then
        SCHED_CMD="-f"
fi

# # # # # # # # # #
# Function
# $1 = Value for Option
# $2 = Value for Parent Process Name
# $3 = Value for Scheduling
# $4 = Value for Priority
# # # # # # # # # #
function Set_RealTime () {
        if [ "$5" == "pgrep" ] ; then
          GETPID="pgrep -f"
        else
          GETPID="pidof"
        fi

        if [ "$1" == "Y" ] || [ "$1" == "y" ]; then
                [[ -d /proc/$($GETPID $2)/task ]] || return 1
                ARR_PID=$(ls /proc/$($GETPID $2)/task)
#                [[ "x${ARR_PID}" == "x" ]] && return
                INT_ROWS=0
                for p_id in $ARR_PID;
                        do
                                echo "## Process : $(tail /proc/$(pidof $2)/task/$p_id/comm) | PID = $p_id" >> $STR_LOG
                                chrt $3 -p $4 $p_id >> $STR_LOG
                                chrt -p $p_id >> $STR_LOG
                                INT_ROWS=$(($INT_ROWS + 1));
                        done
                echo "## -----------------------------------------------------------------" >> $STR_LOG
                echo "## Parent Process [$2] >> $INT_ROWS child process updated..." >> $STR_LOG
                echo "## -----------------------------------------------------------------" >> $STR_LOG
                echo "- - - - " >> $STR_LOG
        fi

}


# Iteration for RoonServer
Set_RealTime $OPT_ROON $PROC_ROON $SCHED_CMD $SCHED_RANGE

# Iteration for RoonBridge
Set_RealTime $OPT_BRIDGE $PROC_BRIDGE $SCHED_CMD $SCHED_RANGE

# Iteration for RAATServer
Set_RealTime $OPT_RAAT $PROC_RAAT $SCHED_CMD $SCHED_RANGE

# Iteration for RoonAppliance
Set_RealTime $OPT_APPLIANCE $PROC_APPLIANCE $SCHED_CMD $SCHED_RANGE

# Iteration for MPD
Set_RealTime $OPT_MPD $PROC_MPD $SCHED_CMD $SCHED_RANGE

# Iteration for Upmpdcli
Set_RealTime $OPT_UPM $PROC_UPM $SCHED_CMD $SCHED_RANGE pgrep

# Iteration for HQP
Set_RealTime $OPT_HQP $PROC_HQP $SCHED_CMD $SCHED_RANGE

# Iteration for ETH
Set_RealTime $OPT_ETH $PROC_ETH $SCHED_CMD $SCHED_RANGE pgrep

# Iteration for XHCI USB
Set_RealTime $OPT_XHCI $PROC_XHCI $SCHED_CMD $SCHED_RANGE pgrep

# End
exit 0
