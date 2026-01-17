#!/bin/bash
# Nastaví affinity pre všetky kworker a ksoftirqd na CPU0/1 (mask 0x3)
for pid in $(pgrep -f 'kworker|ksoftirqd'); do
#    taskset -pc 0,1 $pid
    echo taskset -pc 0 $pid
done
