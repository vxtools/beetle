#!/bin/bash

ODIR=/tmp/conf

[[ ! -d $ODIR ]] && mkdir -p $ODIR 

vxcli eg list |awk '/^[0-9]/ {print $2}' |while read E; do vxcli eg show $E > ${ODIR}/$E.eg; done

vxcli initiator list > ${ODIR}/ini.lst
vxcli dg show > ${ODIR}/dgshow.lst
vxcli sa show > ${ODIR}/sashow.lst

vxcli volume list|awk '/^[0-9]/ {print $1}' | xargs -L1 vxcli volume show |awk -F: '/Id:|Configured Size:|   Name:/ {print $NF}'  | paste - - -  | sed 's/(//g;s/)//g' | awk '{print $2, $(NF-1), $NF}' > ${ODIR}/list.vol

