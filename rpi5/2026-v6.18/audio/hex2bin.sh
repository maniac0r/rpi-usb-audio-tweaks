#!/bin/bash
# SCRIPT:  hex2binary.sh
# USAGE:   hex2binary.sh Hex_Number(s)
# PURPOSE: Hex to Binary Conversion. Takes input as command line
#          arguments.
# VARIABLES:
#	BW:	bit width to pad (cpu cores)
#####################################################################
#                      Script Starts Here                           #
#####################################################################

# bit width (number of cpu cores..)
BW=4

if [ $# -eq 0 ]
then
    echo "Argument(s) not supplied "
    echo "Usage: hex2binary.sh hex_number(s)"
else
    echo -e "\033[1mHEX                 \t\t BINARY\033[0m"

    while [ $# -ne 0 ]
    do
	I=0
        DecNum=`printf "%d" $1`
        Binary=
        Number=$DecNum

        while [ $DecNum -ne 0 ]
        do
            Bit=$(expr $DecNum % 2)
            Binary=$Bit$Binary
            DecNum=$(expr $DecNum / 2)
            ((I++))
        done

        if [ $I -lt $BW ] ; then
          Binary=$(echo -n '\t ' ; printf %${BW}s $Binary | tr \  0 )
        fi

        echo -e "$Number              \t\t $Binary"
        shift
        # Shifts command line arguments one step.Now $1 holds second argument
        unset Binary
    done

fi
