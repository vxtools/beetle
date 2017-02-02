#!/bin/bash

SFILE=opt/emulex/elx-lpfc-vector-map.conf
SDIR=opt/emulex/lpfc
MDIR=/etc/modprobe.d/

# Copying the lpfc startup files with recommended settings.
cp -pr $SFILE $MDIR
cp -pr $SDIR $MDIR
