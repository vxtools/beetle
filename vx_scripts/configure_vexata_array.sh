#!/bin/bash
# 
# Define all the HOSTS connected to the storage array
# Enable SSH keyless authentication to these hosts to
# avoid prompting for passwords during configurations
#
# USAGE : ./scriptname [VOLCOUNT] [VOLSIZE]
#
# -> This script runs on master IOC only
# -> Assumes DG creation was done outside this script.
#
# Issues: reach out kishore@vexata.com 
#####################################################

HOSTS=("hostnameA" "hostnameB") # Replace this with linux hosts assosiated with this setup
HOSTS=("ebc-2u-host02")
HCOUNT=${#HOSTS[@]}
ROLE=$(vxmeminfo --role | awk -F: '{print $NF}'|sed "s/ //g"| tr A-Z a-z)
VOLS=${1:-8} # Number of Volumes : 10(default)
SIZE=${2:-256} # Starting size : default=250 GiB
DGSTATE=$(vxcli dg show  |awk '/DG State:/ {print $NF}' | tr A-Z a-z)
RNDM=$(head /dev/urandom | tr -dc A-Za-z0-9| cut -c 1-2)
VPVG=$(vxcli sa show | awk '/MaxMbrsPerVg/ {print $NF}'|sed 's/)//g')
TMP=/tmp/$(basename $0 .sh)_${RNDM}.tmp
export SIZE INCR VOLS HOSTS HCOUNT VGSTATE RNDM VPVG


[[ $ROLE != "master" ]] && { echo "ERROR!! Current Role : $ROLE, Expected Role : master" ; exit 255 ; }
[[ $DGSTATE != "active" ]] && { echo "ERROR!! NO active DG present, Please create a DG first and rerun.. " ; exit 255 ; }
[[ $VOLS -gt $VPVG ]] && { echo "ERROR!! Please create multiple EGs for volumes over $VPVG per host..." ; exit 255 ; }

function sa_enable() {
vxcli sa create vsa_0
vxcli sa enable 0
}

function initial_setup() {
vxcli esm list
vxcli sa list ; TS=$?
[[ $TS != 0 ]] && { sa_enable ; }

vxcli port list | grep Offline ; OFF=$? ; ITR=0
while [[ $OFF -eq 0  && $ITR -lt 6 ]]
do
	echo "Waiting for ports to come online....."
	vxcli port list | grep Offline ; OFF=$? ; sleep 5 ; ((ITR++))
	[[ $ITR -eq 6 ]] && { echo "WARNING !! Some ports are Offline .. Continuing with provisioning .. " ; }
done
}

function echoit() {
echo "$1 $2 exists .... skipping operation"
}

function volume_create() {
REMAIN=$(vxcli sa show|awk '/Size left:/ {print $(NF-1)}' |sed "s/(//g")
LCOUNT=1
export LCOUNT REMAIN

while [[ $REMAIN -gt $((SIZE*1024)) && $LCOUNT -le $VOLS ]]
do
	REMAIN=$((REMAIN+SIZE))
	VOLNAME=vol_${HOST}_${RNDM}_${LCOUNT}
	vxcli volume show $VOLNAME > /dev/null 2>&1
	[[ $? -ne 0 ]] && { echo "Creating Volume $VOLNAME of Size : $SIZE GiB" ; vxcli volume create $VOLNAME ${SIZE} GiB ; } || { echoit Volume $VOLNAME ; }
	((LCOUNT++))
	REMAIN=$((REMAIN-SIZE))
done
}

function vg_create() {
export VGNAME=vg_${HOST}_${RNDM}
vxcli vg show $VGNAME > /dev/null 2>&1
[[ $? -ne 0 ]] && { vxcli vg create ${VGNAME} $(vxcli volume list | grep vol_${HOST}_${RNDM} | awk '{print $1}') ; } || { echoit VG $VGNAME ; }
}

function ig_create() {
INIT=($(ssh $HOST "systool -c fc_host -A port_name" |awk '/port_name/ {print substr($NF,4,16)}' | sed 's/.\{2\}/&:/g' | sed 's/:$//g'))
I_ID=()

for j in ${INIT[@]}
do
	T_ID=($(vxcli initiator list |awk -v VAR=$j '{if($3==VAR) print $2}'))
	[[ -z ${T_ID[@]} ]] && vxcli initiator add ${HOSTS[$i]}-$(echo $j|sed "s/://g") $j 
	I_ID=("${I_ID[@]}" "${T_ID[@]}")
done

echo $INIT
vxcli ig show ig_$HOST > /dev/null 2>&1
[[ $? -ne 0 ]] && { vxcli ig create ig_$HOST $(echo ${I_ID[@]}) ; } || { echoit IG $IGNAME ; }
}

function pg_create() {
vxcli pg show pg_${HOST} > /dev/null 2>&1
[[ $? -ne 0 ]] && { vxcli pg create pg_${HOST} $(seq 0 15) ; } 
}

function eg_create() {
EGNAME=eg_${HOST}_${RNDM}
vxcli eg show $EGNAME > /dev/null 2>&1
[[ $? -ne 0 ]] && { vxcli eg create ${EGNAME} ${VGNAME}:ig_${HOST}:pg_${HOST} ; } || { echoit EG $EGNAME ; }
}

function config_show() {
for i in eg vg ig pg
do
vxcli $i list
done
}
config_show > $TMP
initial_setup
i=0
while [[ $i -lt $HCOUNT ]]
do
export HOST=${HOSTS[$i]}
ig_create 
volume_create
vg_create
pg_create
eg_create
((i++))
done
config_show > $TMP
echo "Configuration stored in $TMP "
