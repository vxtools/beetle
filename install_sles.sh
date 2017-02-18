#!/bin/bash

source .config

function printh {
echo "$(date) : $@"
}

# Configure the repo
#
printh "Installing the custom repo....."
zypper addrepo -G ${PWD}/opt/repos/vx_sles12_x86_64 $YCR

# Install the required packages
#
printh "Installing the required utilities....."
$ZYPP sysfsutils lsscsi sysstat java libaio-devel glibc-devel zlib-devel sg3_utils net-tools wget

# Install and Configure multipath
#
printh "Install and configure multipath....."
$ZYPP multipath-tools kpartx 
cp -r $MPSRC $MPDIR
systemctl enable multipathd
systemctl start multipathd

# Installation of FIO
#
printh "Installing FIO....."
$ZYPP fio 

# Configure the required udev rules.
#
printh "Copying Schedule rules file....."
cp -pr $UDEVSRC $UDEVDIR
udevadm control --reload ; udevadm trigger

# Cleanup
#
printh "INSTALLATION COMPLETED...... CLEANING UP ...."

zypper removerepo $YCR
