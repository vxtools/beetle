#!/bin/bash

source .config

function printh {
echo -e "$(date) : $@"
}

[[ ! -d /opt/beetle ]] && { echo "beetle was not installed on /opt directory. please reinstall on /opt and retry..." ; exit 255 ;}

# Configure the repo
#
printh "Copying the custom yum repository....."
cp -pr $REPOSRC $REPODIR

# Install the required packages
#
printh "Installing the required utilities....."
$YUM sysfsutils lsscsi sysstat java libaio-devel zlib-devel ipmitool sg3_utils net-tools wget pciutils > $YLOG

# Install and Configure multipath
#
printh "Checking for multipath install...."
mstatus=$(rpm -qa |grep multipath|wc -l)
if [[ $mstatus -eq 0 ]] 
then
printh "Install and configure multipath....."
$YUM device-mapper-multipath >> $YLOG
cp -r $MPSRC $MPDIR
systemctl enable multipathd
systemctl start multipathd
else
[[ -f /etc/multipath.conf ]] &&  { sed -i '/^devices/ r $MPMOD' /etc/multipath.conf  ; }
printh "Identified old multipath.conf, inserted Vexata Strings...."
fi

# Installation of FIO
#
printh "Installing FIO....."
$YUM fio  >> $YLOG

# Configure the required udev rules.
#
printh "Copying Schedule rules file....."
cp -pr $UDEVSRC $UDEVDIR
udevadm control --reload ; udevadm trigger

# Cleanup
#
printh "INSTALLATION COMPLETED, logfile : $YLOG ...... CLEANING UP ...."

rm $REPODIR/$(basename $REPOSRC)
