#!/bin/bash

###########################################################################
#
# lpfc_configure_oas.sh
#
# This script is provided by Emulex is used to configure Optimized Acccess
# Storage (OAS) luns specified by the OAS configuration file on boot or
# after driver load.
#
# The script will look for the oas configuration file (oas.config) in either
# the /etc/lpfc or /usr/sbin/lpfc directores.  The path and name of the
# configuration file can be specified as the first parameter to the script.
#
# Usage: 
#        lpfc_configure_oas.sh [-f oas_config_file] [-v] [-c] [-h]
#
###########################################################################

#
# Arrays for oas information
#

declare -a port_wwpns
declare -a vport_wwpns
declare -a target_wwpns
declare -a luns
declare -a scsi_hosts

# 
# Global read only varaibles
#

SCRIPT_NAME=$(basename $0)
OAS_CONFIG_FILE="oas.conf"
OAS_CONFIG_DIR="/usr/sbin/lpfc"

#
# Support Functions
#

usage() 
{

	echo 
	echo "lpfc_configure_oas.sh [-f oas_config_file] [-v] [-c] [-h]"
	echo 
	echo "  Configures luns specified by the $OAS_CONFIG_FILE for Optimized Access Storage.  The"
	echo "location for the configuration file is $OAS_CONFIG_DIR."
	echo 
	echo "-f oas_config_file : path to configuration file to use instead of the default file"
	echo "-v : enables verbose mode of the script"
	echo "-c : verifies the configuration file without applying the configuration"
	echo "-h : displays the usage of the script"
	echo
	return 0

}

trace() 
{

	if [ ! -z $LOG_UTILITY ]
	then
		$LOG_UTILITY "$SCRIPT_NAME : $1"
	fi
	return 0

}

verify_oas_is_configurable() 
{

        scsi_host_dir="/sys/class/scsi_host"

	trace "Checking to see if the OAS is configurable."

        # check to see if any scsi host directory exists

        if [ ! -e $scsi_host_dir ]
        then
		trace "Scsi host directory not available."
                return 0
        fi

	# Check to see if the scsi host directory is empty

        if [ ! "$(ls -A $scsi_host_dir)" ]
        then
		trace "Scsi host directory empty."
                return 0
        fi

	# Check to see if any scsi host has a oas enabled file

        for SCSI_HOST in $scsi_host_dir/*
        do
                oas_file="$SCSI_HOST/lpfc_xlane_supported"
		if [ -e $oas_file ]
		then
			read file_state < $oas_file
			if [ "$file_state" == "1" ]
			then
                		oas_file="$SCSI_HOST/$lpfc_enable_oas_fname"
				if [ -e $oas_file ]
				then
					read file_state < $oas_file
					if [ "$file_state" == "1" ]
					then
						trace "Configurable OAS host found."
						return 1
					fi
				fi
			fi
		fi
        done

	trace "No scsi hosts are OAS configurable."
        return 0

}

get_oas_config_file_path()
{

	#
	# If the OAS config path has been set, verify the file is there
	#

	if [ ! -z $OAS_CONFIG_PATH  ]
	then
		if [ -e $OAS_CONFIG_PATH ]
		then 
			return 1
		fi

		trace "$OAS_CONFIG_PATH not found."
		return 2
	fi

	#
	# Check to see if oas config is in the default directory.
	#

	OAS_CONFIG_PATH="$OAS_CONFIG_DIR/$OAS_CONFIG_FILE"
	if [ -e $OAS_CONFIG_PATH ]
	then
		return 1
	fi

	#
	# File not found, return an error
	#

	trace "$OAS_CONFIG_FILE not found."

	OAS_CONFIG_PATH=""
	return 0

}

verify_hex_value() 
{

        # Set string passed to local variable and convert to upper case


        temp_str=$1

        # Initialize local variables

        str_len=${#temp_str}
        str_index=0
        char_chk=""

        # Verify the token has leading 0x

        char_chk=${temp_str:0:1}
        if [ "0" != "$char_chk" ]
        then
                return 0
        fi
        char_chk=${temp_str:1:1}
        if [ "x" != "$char_chk" ] && [ "X" != "$char_chk" ]
        then
                return 0
        fi

        # Verify the remaining part of the token are valid hexadecimal values

        str_index=2
        while [ $str_index -lt $str_len ]
        do
                char_chk=${temp_str:$str_index:1}
                let str_index++
                case $char_chk in
                        "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" )
                        ;;
                        "A" | "B" | "C" | "D" | "E" | "F" )
                        ;;
                        "a" | "b" | "c" | "d" | "e" | "f" )
                        ;;
                        *)
                        return 0
                        ;;
                esac
        done

        # return the next character that should be checked in this string

        return 1

}

process_config_line() 
{

        #if no parameters are passed, the line was empty

        if [ $# -eq 0 ]
        then
                return 0
        fi

        # the first parameter passed should be the token "oaslun:"

        if [ "$1" != "oaslun:" ]
        then
		trace "Configuration line does not contain the expected starting delimiter oaslun:, ignoring line"
                return 0
        fi

        # The number of parameters should be 5.  If not, return error

        if [ $# -ne 5 ]
        then
		trace "Configuration line contains more elements than expected."
                return -1
        fi

        # Second parameter should be the port's wwpn.  Verify parameter 2 is a valid hexadecimal value

        verify_hex_value $2
        if [ $? -ne 1 ]
        then
		trace "The port's wwpn ($2) in the configuration line does not a valid hexadecimal value."
                return -1
        fi
        port_wwpns[$SETTABLE_OAS_LUNS]=$2

        # Third parameter should be the vport's wwpn. Verify parameter 3 is a valid hexadecimal value

        verify_hex_value $3
        if [ $? -ne 1 ]
        then
		trace "The vport's wwpn ($3) in the configuration line does not a valid hexadecimal value."
                return -1
        fi
        vport_wwpns[$SETTABLE_OAS_LUNS]=$3

        # Fourth parameter should be the target's wwpn.  Verify parameter 4 is a valid hexadecimal value

        verify_hex_value $4
        if [ $? -ne 1 ]
        then
		trace "The target's wwpn ($4) in the configuration line does not a valid hexadecimal value."
                return -1
        fi
        target_wwpns[$SETTABLE_OAS_LUNS]=$4

        # Firth parameter should be the lun.  Verify parameter 5 is a valid hexadecimal value

        verify_hex_value $5
        if [ $? -ne 1 ]
        then
		trace "The lun ($5) in the configuration line does not a valid hexadecimal value."
                return -1
        fi
        luns[$SETTABLE_OAS_LUNS]=$5

	trace "Configuration line contains port wwpn=$2, vport wwpn=$3, target wwpn=$4, lun=$5."

	# Line successfully parsed, incremented the number of valid OAS configurations detected

	let OAS_LUNS++

	# If we are our maximum, return a status indicating to not process any further luns

	if [ $OAS_LUNS -eq $MAX_OAS_LUNS ]
	then
		trace "The maximum number of supported oas luns ($MAX_OAS_LUNS) has been obtained."
		return 2
	fi

	# Return sucess

        return 1
}

locate_scsi_host() 
{


        fc_host_dir="/sys/class/fc_host"

        # check to see if fc hosts are available

        if [ ! -e $fc_host_dir ]
        then
		trace "The fc hosts directory not present in the system."
                return 0
        fi

	# check to see if fc host d

        if [ ! "$(ls -A $fc_host_dir)" ]
        then
		trace "No fc hosts present in the system."
                return 0
        fi

        for HOST in $fc_host_dir/*
        do
                port_name_file="$HOST/port_name"
                read wwpn < $port_name_file
		if [ "$wwpn" == "${port_wwpns[$SETTABLE_OAS_LUNS]}" ]
                then

			# host found, save in scsi_hosts array

			trace "Found scsi_host ${HOST:19} for wwpn $wwpn."
                        scsi_hosts[$SETTABLE_OAS_LUNS]=${HOST:19}
                        return 1
                fi
        done

	trace "Host identified by wwpn ${port_wwpns[$SETTABLE_OAS_LUNS]} was not found on the system."
        return 0

}

scsi_host_oas_configurable() 
{

	# Find the scsi host for the specified wwpn
	
	locate_scsi_host
	if [ $? -ne 1 ]
	then
		return 0
	fi

	# Check to see scsi host is available

	scsi_host="/sys/class/scsi_host/${scsi_hosts[$SETTABLE_OAS_LUNS]}"
	if [ ! -e $scsi_host ]
	then
		trace "The scsi host ${scsi_hosts[$SETTABLE_OAS_LUNS]} not found."
		return 0
	fi

	# check to see if oas is enabled for port

	if [ ! -e $scsi_host/$lpfc_enable_oas_fname ]
	then
		trace "The $lpfc_enable_oas_fname file was not found for scsi host ${scsi_hosts[$SETTABLE_OAS_LUNS]}."
		return 0
	fi
	read oas_enabled < $scsi_host/$lpfc_enable_oas_fname
	if [ $oas_enabled == "0" ]
	then
		trace "OAS not enabled ($lpfc_enable_oas_fname = 0) for scsi host ${scsi_hosts[$SETTABLE_OAS_LUNS]}."
		return 0
	fi
	
	return 1

}

config_oas_lun() 
{

	index=$1
	scsi_host="/sys/class/scsi_host/${scsi_hosts[$index]}"

	trace "Configuring OAS lun."

	# check to see if scsi host is available

	if [ ! -e $scsi_host ]
	then
		trace "Scsi host ${scsi_hosts[$index]} not found."
		return 0
	fi

	# check to see if oas is enabled for driver/port

	if [ ! -e $scsi_host/$lpfc_enable_oas_fname ]
	then
		trace "File $lpfc_enable_oas_fname for scsi host ${scsi_hosts[$index]} not found."
		return 0
	fi
	read oas_enabled < $scsi_host/$lpfc_enable_oas_fname
	if [ $oas_enabled == "0" ]
	then
		trace "OAS not enabled ($lpfc_enable_oas_fname = 0) for scsi host ${scsi_hosts[$index]}."
		return 0
	fi

	# enable the lun at index for OAS
	
	echo ${vport_wwpns[$index]} > $scsi_host/lpfc_xlane_vpt
	echo ${target_wwpns[$index]} > $scsi_host/lpfc_xlane_tgt
	echo 1 > $scsi_host/lpfc_xlane_lun_state
	echo ${luns[$index]} > $scsi_host/lpfc_xlane_lun
	
	trace "Configured OAS lun for scsi host ${scsi_hosts[$index]}."
	return 1

}

process_config_file() 
{

	return_status=1
	line_no=0

	# read and process the config file

	trace "Reading entries in configuration file $OAS_CONFIG_PATH."

	while read LINE
	do

		let line_no++
		trace "Processing configuration line $line_no - $LINE."

		# Validate the entries in the line.  

		process_config_line $LINE
		call_status=$?

		# Verify the function was able to parse the line successfully

		if [ $call_status -ne 0 ] && [ $call_status -ne 1 ] && [ $call_status -ne 2 ]
		then
			trace "Error detected in configuration file, aborting processing the config file."
			return_status=0
			break
		fi

		# If the line was successfully processed, determine if it can be applied

		if [ $call_status -eq 1 ] || [ $call_status -eq 2 ]
		then

			# Find the scsi host for the specified wwpn and verify oas is supported and enabled
	
			scsi_host_oas_configurable

			# If the scsi host was found and OAS enabled, increment the SETTABLE_OAS_LUN count.

			if [ $? -eq 1 ]
			then
				let SETTABLE_OAS_LUNS++
			else
				trace "lpfc_configure_oas.sh : The scsi_host was not found or is not oas enabled, ignoring configuration."
			fi

			# If the maximum number of oas luns has been detected, abort loop

			if [ $call_status -eq 2 ]
			then
				break
			fi
		fi 

	done < $OAS_CONFIG_PATH

	trace "Reading of entries in configuration file $OAS_CONFIG_PATH is complete."

	# Indicate the file was process successfully

	return $return_status

}

#
# Start of Main
#

# Initialize variables which can be updated by parameters

lpfc_enable_oas_fname=lpfc_EnableXLane
OAS_CONFIG_PATH=
VERIFY_CONFIG_FILE=0
LOG_UTILITY=

# Process any parameters passed to the script

while getopts "hf:vc" OPTIONS	
do 
	case $OPTIONS in
		h)
		  if [ -t 1 ]
		  then
		  	  # a terminal is associated with stdout out (file descriptor 1), display usage information

		  	 usage
		  fi
		  exit 0
		  ;;
		f)
		  OAS_CONFIG_PATH=$OPTARG
		  ;;
		v)
		  if [ -t 1 ]
		  then
		  	  # a terminal is associated with stdout out (file descriptor 1), change log utility to echo

			  LOG_UTILITY="echo"
		  elif [ -x /usr/bin/logger ]
		  then 
		  	  # no terminal is associated with stdout out (file descriptor 1), send logs to message file

			  LOG_UTILITY="logger"
		  fi
		  ;;
		c)
		  VERIFY_CONFIG_FILE=1
		  ;;
		*) 
		  if [ -t 1 ]
		  then
		  	  # a terminal is associated with stdout out (file descriptor 1), inform the user of the issue

		  	  echo "lpfc_configure_oas.sh : Invalid parameter specified. Use the -h option to determine valid parameters."

		  fi
		  exit -1
		  ;;
	esac
done

# Initialize variables for tracking OAS luns

MAX_OAS_LUNS=48
OAS_LUNS=0
SETTABLE_OAS_LUNS=0

# Determine location of oas config file.

get_oas_config_file_path
call_status=$?
if [ $call_status -ne 1 ]
then
	if [ $call_status -ne 0 ]
	then
		exit -1
	else
		exit 0
	fi
fi

# Process the oas config file.

process_config_file
call_status=$?
if [ $call_status -ne 1 ] || [ $VERIFY_CONFIG_FILE -eq 1 ]
then 
	if [ $call_status -ne 1  ]
	then
		exit -1
	else
		exit 0
	fi
fi

# Verify a driver that supports OAS is loaded and at least one port can be configured for OAS.

verify_oas_is_configurable
if [ $? -ne 1 ]
then 
	exit 0
fi

# Apply the OAS configurations to the physical port(s)

array_index=0
while [ $array_index -lt $SETTABLE_OAS_LUNS ]
do
	config_oas_lun array_index
	let array_index++
done

# Exit script

exit 0
