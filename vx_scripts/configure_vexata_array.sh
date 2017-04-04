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
HCOUNT=${#HOSTS[@]}
ROLE=$(vxmeminfo --role | awk -F: '{print $NF}'|sed "s/ //g"| tr A-Z a-z)
VOLS=${1:-8} # Number of Volumes : 10(default)
SIZE=${2:-256} # Starting size : default=250 GiB
DGSTATE=$(vxcli dg show  |awk '/DG State:/ {print $NF}' | tr A-Z a-z)
export SIZE INCR VOLS HOSTS HCOUNT VGSTATE

[[ $ROLE != "master" ]] && { echo "Current Role : $ROLE, Expected Role : master" ; exit 255 ; }
[[ $DGSTATE != "active" ]] && { echo "NO active DG present, Please create a DG first and rerun.. " ; exit 255 ; }

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

function volume_create() {
REMAIN=$(vxcli sa show|awk '/Size left:/ {print $(NF-1)}' |sed "s/(//g")
LCOUNT=1
export LCOUNT REMAIN

while [[ $REMAIN -gt $((SIZE*1024)) && $LCOUNT -le $VOLS ]]
do
	REMAIN=$((REMAIN+SIZE))
	VOLNAME=vol_${HOST}_${LCOUNT}
	echo "Creating Volume $VOLNAME of Size : $SIZE GiB"
	vxcli volume create $VOLNAME ${SIZE} GiB
	((LCOUNT++))
	REMAIN=$((REMAIN-SIZE))
done
}

function vg_create() {
vxcli vg create vg_${HOST} $(vxcli volume list | grep vol_${HOST} | awk '{print $1}')
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

vxcli ig create ig_$HOST $(echo ${I_ID[@]})
}

function pg_create() {
vxcli pg create pg_${HOST} $(seq 0 15)
}

function eg_create() {
vxcli eg create eg_${HOST} vg_${HOST}:ig_${HOST}:pg_${HOST}
}

function config_show() {
for i in eg vg ig pg
do
vxcli $i list
done
}
config_show
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
config_show
