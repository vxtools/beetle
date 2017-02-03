# Beetle - Overview 
Beetle is a GitHub repository bundled with custom linux repos and handy scripts, targeted to simplify initial configurations of linux hosts during POCs.

The main purpose of this tool is to streamline some of the unexpected scenarios we often encounter when we walk in to the remote POC datacenters with unique policies and perceptions. As is unexpected things will always be there, hope we could enhance this tool and address them as much as possible using this tool. 

One of those scenarios is walking in to the lab or datacenter with no access to the internet or yum/zypper repositories. Beetle can be downloaded locally to your laptop or external media from GitHub and port it as needed. The custom linux repositories included in beetle covers all the required linux packages required during POC.

This package also includes the `custom multipath configuration` file and recommended `performance optimization settings` file. These are installed in the client hosts through install scripts. 

In addition, we had an opportunity to develop some useful shortcuts (unix functions to sound boring) over period of time to help with some of the frequently performed tasks. These shortcuts do assume some non-minimal packages are installed on the Linux hosts. These are bundled with the custom repos and install script will take care of them.

Also a simple bash script is included, to perform the `basic storage provisioning` on a vexata array.

Last but not least some sample(handy) `work profiles for FIO and VDBENCH` tool are included in bettle.

# How to use it
## Download the git repository
Run on any Linux host with access to github:
```
git clone https://github.com/vxtools/beetle.git /opt/beetle
```

Note: As of now, please download this git repo on /opt in the Linux test machine. There is a dependency on custom repos for this. Will update this as and when we find an altenative.

## Supported OS 
- CentOS/Redhat/OEL/Fedora (version 7)
- SLES12
Note: Support to other OSes can be added on an as-needed basis.

## Run the Install script.
Identify the Linux distro that you are working on and run respective install scripts:

###### CentOS/Redhat/OEL/Fedora (version 7)
```
# ./install_linux.sh
```
###### SLES 12
```
# ./install_sles.sh
```

# What it does

- Configures the custom repos
- Installs all the required packages
- Install device-mapper and configures with vexata specific settings
- Installs udev rules optmized for vexata array
- Cleans up the custom repo

## Vexata Array provisioning script
File location: `vx_scripts/configure_vexata_array.sh`  
Please note that this `script needs to be run from array`.

- Copy the file to the array
``` 
# scp /opt/beetle/configure_vexata_array.sh root@<array-name>:/root/
```

- Update the `HOSTS` list variable in the script to reflect all the linux host names.
```
HOSTS=("host1" "host2") # Replace this with linux hosts assosiated with this setup
```

- If possible enable ssh password less loging from array to linux host. If its not an option for some reason, just type the host password when prompted. 
```
# /root/configure_vexata_array.sh [No. of Volumes] [Each Volume Size in GiB]
```

## Handy shortcuts
Following are the list of handy shortcuts available to help with some routine tasks.
These are not imported by default. It need to explicitly sourced on each linux host to use them.

```
# source /opt/beetle/.test_env
```

###### List of available shortcuts

```
# vhelp
          vdblist                 : Create sd list for vdbench profiles
          fiolist                 : List device to be used with FIO command.
          wwnlist                 : WWN List of all FC ports
               ws                 : Status check of FC ports
            dlist                 : list the dm-X devices in one line
           sdlist                 : list the sdX devices in one line
          lstune                  : Lists the values of all frequently tuned settings for devices.
         tune_all                 : Set the recommended values to all frequently tuned settings for devices.
      tune_random                 : Set the requested value to enable/disable entrophy on all vexata volumes(default
    tune_affinity                 : Set the requested affinity value to all vexata volumes (default
          tune_nr                 : Increase / decrease the nr_requests on all vexata volumes (default
       tune_sched                 : set I/O scheduler on all vexata volumes (default
       rescan_all                 : Rescan all scsi devices asoosiated with FC
            rmdev                 : Remove stale device entries
         mpconfig                 : List the effective multipath configuration.
               vc                 : List the number of SD volumes and DM volumes.
               dl                 : list all dm-X devices with new-line. Usefull to pass on to test tools.
          devlist                 : list all dm-X devices with full path name in single line. Usefull to pass on to test tools.
              ver                 : Display the current OS version.
           hbaver                 : Display HBA version installed on the system,
 check_interrupts                 : Check interrupt values on the system
         chdev_to                 : Change timeout for SD devices
         lsdev_to                 : List timeout for SD devices
```

You may view individual shortcut code by using `type`
```
# type vc
vc is a function
vc () 
{ 
    echo "Vexata SDs : $(lsscsi |grep Vexata|wc -l)";
    tf=$(multipath -ll);
    echo "Vexata DMs : $(echo "$tf" | grep Vexata |wc -l)";
    echo "$tf" | awk '/Vexata/ {print $3}' | while read mp; do
        echo "$mp : $(echo "$tf" | sed -n '/'${mp}'/,/^mpath/p' | awk '/^  \|-|^  `/ {print $0}' | wc -l)";
    done
}

```

# Contact

Feel free to reach out to kishore@vexata.com for any questions. Appreciate any feedback or suggestions to make this tool more useful.
