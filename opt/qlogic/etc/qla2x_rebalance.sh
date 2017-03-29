#!/usr/bin/bash

TCPU=$(lscpu |awk -F: '/^CPU\(s\)/ {print $NF}')

irqset()
{
	[[ $1 -gt $TCPU ]] && C=1
	echo Setting IRQ $2 to mask $C
	echo $C > /proc/irq/$2/smp_affinity_list
}

C=1

for irq in `cat /proc/interrupts | grep qla2xxx | awk -F: '{print $1}'`
do
	irqset $C $irq
	C=$((C+2))
done
