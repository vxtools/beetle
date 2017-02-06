#!/bin/bash

source .config

function printh {
echo "$(date) : $@"
}

[[ ! -d /opt/beetle ]] && { echo "beetle was not installed on /opt directory. please reinstall on /opt and retry..." ; exit 255 ;}

# Configure the repo
#
printh "Copying the custom yum repository....."
cp -pr $REPOSRC $REPODIR

# Install the required packages
#
printh "Installing the required utilities....."
$YUM sysfsutils lsscsi sysstat java libaio-devel zlib-devel ipmitool sg3_utils net-tools wget

# Install and Configure multipath
#
printh "Install and configure multipath....."
$YUM device-mapper-multipath
cp -r $MPSRC $MPDIR
systemctl enable multipathd
systemctl start multipathd

# Installation of FIO
#
printh "Installing FIO....."
$YUM fio 

# Configure the required udev rules.
#
printh "Copying Schedule rules file....."
cp -pr $UDEVSRC $UDEVDIR
udevadm control --reload ; udevadm trigger

# Cleanup
#
printh "INSTALLATION COMPLETED...... CLEANING UP ...."

rm $REPODIR/$(basename $REPOSRC)
