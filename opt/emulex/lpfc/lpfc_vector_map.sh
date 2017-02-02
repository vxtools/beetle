# /bin/bash
# lpfc_vector_map [hba | driver]
# 
# Map lpfc driver vectors to a specific CPU. The hba option maps all 
# vectors for each specific HBA, starting with CPU0, then sequentially assigning
# a new CPU for each vector belonging to that HBA. The driver option maps
# all vectors for the driver, starting with CPU0, then sequentially assigning
# a new CPU for each vector belonging to entire driver.
#
# This will map to at most 16 CPUs, then it will wrap back to CPU0 and
# continue mapping.
#

style=${1:-driver}
[[ "$style" == hba || "$style" == driver ]] || {
    echo "Usage: lpfc_vector_map [hba | driver]" 1>&2
    exit 1
}

# Setup CPU masks for each CPU
cpumask=(1 2 4 8 10 20 40 80 100 200 400 800 1000 2000 4000 8000 \
	10000 20000 40000 80000 100000 200000 400000 800000 1000000 \
	2000000 4000000 8000000 10000000 20000000 40000000 80000000)

numcpu=$(grep -c processor < /proc/cpuinfo)
(( numcpu > 32 )) && numcpu=32

# Get the vectors associated with the lpfc driver
vectors=$(awk -F : '/lpfc/ {print $1}' < /proc/interrupts)

# Check to ensure the proc irq subsystem supports SMP affinity
shopt -s nullglob
smp_files=/proc/irq/*/smp_affinity
smp_files=$(echo $smp_files)
shopt -u nullglob
if [[ -z  "$smp_files" ]]
then
    exit 0
fi

shopt -s nullglob
lpfc_logs=/sys/class/scsi_host/*/lpfc_fcp_io_sched
lpfc_logs=$(echo $lpfc_logs)
shopt -u nullglob
if [[ -z  "$lpfc_logs" ]]
then
    exit 0
fi

shopt -s nullglob
msi_files=/sys/class/scsi_host/host*/lpfc_use_msi
msi_files=($msi_files)
shopt -u nullglob
if [[ -z  "$msi_files" ]]
then
    exit 0
fi
use_msi=$(cat ${msi_files[0]})
if (( use_msi != 2 ))
then
    exit 0
fi

start=0
cpu=0

# For all lpfc scsi_host's
for ii in $lpfc_logs
do
    dir=${ii%/*}
    host=${dir##*/}
    cd $dir
    sli4=$(grep sli-4 < fwrev)
    if [[ -z "$sli4" ]]
    then
#	This path is for SLI3 HBA instances
#
	vcnt=2
	nvcnt=$vcnt
	skip=0
	[[ $style == hba ]] && cpu=0
	for vv in $vectors
	do
#	    Skip vectors until we get to the ones that
#           correspond to this SCSI Host.
#
	    if (( skip == start ))
	    then
		cd /proc/irq/$vv
		if (( vcnt == 2 ))
		then
		    echo "SCSI $host SLI3 SlowPath vector $vv mapped to CPU0"
		    echo ${cpumask[0]} > smp_affinity
		else
                    if (( cpu >= 0 && cpu <= 31 ))
                    then
		        echo \
                  "SCSI $host SLI3 FastPath vector $vv mapped to CPU$cpu"
		        echo ${cpumask[cpu]} > smp_affinity
                    fi
		    cpu=$((cpu + 1))
		    (( cpu == numcpu )) && cpu=0
		fi
		vcnt=$((vcnt - 1))
		if (( vcnt <= 0 ))
		then
		    start=$((start + nvcnt))
		    break
		fi
	    else
		skip=$((skip + 1))
	    fi
	done
    else
#	This path is for SLI4 HBA instances
#
	[[ -e lpfc_fcp_io_channel ]] && \
                fn=lpfc_fcp_io_channel || \
                fn=lpfc_fcp_eq_count
        vcnt=$(< $fn)
	nvcnt=$vcnt
#	Turn on I/O scheduling by CPU
	echo 1 > lpfc_fcp_io_sched
	skip=0
	[[ "$style" == hba ]] && cpu=0
	for vv in $vectors
	do
#	    Skip vectors until we get to the ones that
#	    correspond to this SCSI Host.
#
	    if (( skip == start ))
	    then
		cd /proc/irq/$vv
                if (( cpu >= 0 && cpu <= 31 ))
                then
		    echo "SCSI $host SLI4 vector $vv mapped to CPU$cpu"
		    echo ${cpumask[cpu]} > smp_affinity
                fi
		cpu=$((cpu + 1))
		(( cpu == numcpu )) && cpu=0
		vcnt=$((vcnt - 1))
		if (( vcnt <= 0 ))
		then
		    start=$((start + nvcnt))
		    break
		fi
	    else
		skip=$((skip + 1))
	    fi
	done
    fi
done

