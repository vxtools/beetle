#!/bin/bash

ODIR=/tmp/conf

[[ ! -d $ODIR ]] && mkdir -p $ODIR 

vxcli eg list |awk '/^[0-9]/ {print $2}' |while read E; do vxcli eg show $E > ${ODIR}/$E.eg; done

vxcli initiator list > ${ODIR}/ini.lst

vxcli volume list > ${ODIR}/list.vol
