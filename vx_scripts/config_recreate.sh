#!/usr/bin/bash

[[ ! -d /tmp/conf ]] && { echo "ERROR: Unable to find config backup.... Exiting "; exit 255; }

for i in eg vg ig pg volume
do 
e=$(vxcli $i list | awk '/^[0-9]/ {t+=1}END{print t}')
t=$((t+e))
done

[[ $t -gt 1 ]] && { echo "ERROR: Some Config already exists.. Exiting.. Expected: 1, Recieved: $t"; exit 255; }

vxcli eg list |awk '/^[0-9]/ {t+=1}END{print t}'

cd /tmp/conf

# Create volume, will truncate the decimals
awk '/^[0-9]/ {print $2,$3}' /tmp/conf/list.vol | sed 's/..G$/ GiB/g; s/..T$/ TiB/g; s/..M$/ MiB/g' | xargs -L1 vxcli volume create

for e in *.eg
do
IG=($(awk '/IniId/{flag=1;next}/^$/{flag=0}flag' $e | awk '!/----/ {print $NF}'|xargs))
# Add initiators if not auto-detected
for j in ${IG[@]}
do
	T_ID=($(vxcli initiator list |awk -v VAR=$j '{if($2==VAR) print $2}'))
	[[ -z ${T_ID[@]} ]] && vxcli initiator add $j $(echo $j|awk -F- '{print $NF}'|sed 's/.\{2\}/&:/g' | sed 's/:$//g')
done
i=$(awk '/^IG Info/{flag=1;next}/^$/{flag=0}flag' $e | awk '/Name:/ {print $NF}')
vxcli ig create $i ${IG[@]}

PG=($(awk '/^PG Info/{flag=1;next}/^$/{flag=0}flag' $e | grep -A10 '  Members:'| xargs |awk -F: '{print $NF}'|sed 's/,/ /g'))
p=$(awk '/^PG Info/{flag=1;next}/^$/{flag=0}flag' $e | awk '/Name:/ {print $NF}')
# Skip pg creation if PG exists
vxcli pg show $p  >/dev/null 2>&1
[[ $? -ne 0 ]] && vxcli pg create $p ${PG[@]}


VG=($(awk '/VolId/{flag=1;next}/^$/{flag=0}flag' $e | awk '!/----/ {print $NF}'|xargs))
v=$(grep -A2 '^VG Info:' $e | awk '/Name:/ {print $NF}')
vxcli vg create $v ${VG[@]}

vxcli eg create $e $v:$i:$p
done

cd -
