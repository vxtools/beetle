#!/usr/bin/bash

fn=$(basename $0 .sh)
ts=$(date +%y%m%d_%H%M)
hn=$(basename $(hostname) .com)
wdir=/tmp/${fn}_${hn}_${ts}
log=${wdir}/collection.log

[[ ! -s $wdir ]] && mkdir -p $wdir

fname_list=('/proc/cpuinfo' '/proc/meminfo' '/etc/multipath.conf' '/proc/interrupts')
dir_list=('/proc/sys' "/etc/udev/rules.d /lib/udev/rules.d")
cmd_list=('lscpu' 'free -m' 'lspci -vvv' 'dmsetup ls --tree' 'sysctl -a' 'dmidecode')

for dir in "${dir_list[@]}"
do
j=$(echo $dir|sed 's/\//_/g;s/ /_/g')
echo "Collecting $dir info" | tee -a $log
tar cvzf ${wdir}/${j}.tgz $dir > $log 2>&1
done

for fname in "${fname_list[@]}"
do
echo "Copying $fname info" | tee -a $log
cp -pr $fname $wdir >> $log 2>&1
done

for cmd in "${cmd_list[@]}"
do
echo "Collecting command output of $cmd"  | tee -a $log
echo $($cmd) >>  ${wdir}/system_cfg.out 2>&1
done

for host_info in scsi_host fc_host
do
	tdir=${wdir}/${host_info}
	[[ ! -d ${tdir} ]] && mkdir -p ${tdir}

	find /sys/devices -name fc_host | while read FN
	do 
	cd $FN
		for i in host*
		do 
			echo "Backing up ${FN} om ${host_info}"
			tar cvzf /${tdir}/${i}.tgz ${i} > $log 2>&1 
		done
	cd - >/dev/null
	done
done

echo "Creating an archive of the hostinfo collected"
tar cvzf ${wdir}.tgz ${wdir} > /dev/null 2>&1
[[ $? -eq 0 ]] && { echo "Archived data to ${wdir}.tgz, deleting ${wdir}...."; rm -rf ${wdir} ; }
