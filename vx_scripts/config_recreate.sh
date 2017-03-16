#!/usr/bin/bash
#
# Usage : ./config_recreate.sh
# The information collected through collect_config.sh is used to create the config.
# collect_config.sh creates the configuration backup in /tmp/conf directory
#
# Contact vxtools@vexata.com for any comments/suggestions
####################################################################################

CONF=/tmp/conf

[[ ! -d $CONF ]] && { echo "ERROR: Unable to find config backup.... Exiting "; exit 255; }

for i in eg vg ig pg volume
do 
e=$(vxcli $i list | awk '/^[0-9]/ {t+=1}END{print t}')
t=$((t+e))
done

[[ $t -gt 1 ]] && { echo "ERROR: Some Config already exists.. Exiting.. Expected: 1, Recieved: $t"; exit 255; }

vxcli eg list |awk '/^[0-9]/ {t+=1}END{print t}'

cd $CONF

# Create volume, will truncate the decimals
cat list.vol | xargs -L1 vxcli volume create

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
	# Skip IG creation if already exists
	vxcli ig show $i  >/dev/null 2>&1
	[[ $? -ne 0 ]] && vxcli ig create $i ${IG[@]}

	PG=($(awk '/^PG Info/{flag=1;next}/^$/{flag=0}flag' $e | grep -A10 '  Members:'| xargs |awk -F: '{print $NF}'|sed 's/,/ /g'))
	p=$(awk '/^PG Info/{flag=1;next}/^$/{flag=0}flag' $e | awk '/Name:/ {print $NF}')
	# Skip PG creation if already exists
	vxcli pg show $p  >/dev/null 2>&1
	[[ $? -ne 0 ]] && vxcli pg create $p ${PG[@]}


	VG=($(awk '/VolId/{flag=1;next}/^$/{flag=0}flag' $e | awk '!/----/ {print $NF}'|xargs))
	v=$(grep -A2 '^VG Info:' $e | awk '/Name:/ {print $NF}')
	vxcli vg create $v ${VG[@]}

vxcli eg create $(basename $e .eg)  $v:$i:$p
done

b=/tmp/conf_$(date +%m%d%Y_%H%M%S)

# Renaming the config backup to avoid accidental reuse 
# If you are Sure to use a old config, rename the appropriate /tmp/conf_MMDDYY_HHMMSS file to /tmp/conf

echo "Moving Config Backup from $CONF to $b "
mv $CONF $b

cd -
