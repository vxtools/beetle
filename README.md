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

## Additional lpfc settings
For inbox drivers, please run the following commands to distribute the interrupts across all cores effeciently. Since irqbalance is a system level setting, this is not included in the install script.
```
# systemctl stop irqbalance 
# systemctl disable irqbalance 
# cp -pr /opt/beetle/opt/emulex/elx-lpfc-vector-map.conf /etc/modprobe.d/
# cp -pr /opt/beetle/opt/emulex/lpfc/lpfc_vector_map.sh /etc/modprobe.d/lpfc
# cp –pr /opt/beetle/opt/emulex/lpfc/lpfc_configure_oas.sh /etc/modprobe.d/lpfc
```
If you are able to install the latest driver from [Broadcom Website](https://www.broadcom.com/support/download-search
), you may just run following command to increase the `lpfc_fcp_imax` value.
```
# sed -i "s/lpfc $CMD/lpfc lpfc_fcp_imax=200000 $CMD/g" /etc/modprobe.d/elx-lpfc-vector-map.conf 
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

Now the **fun part begins**, let us make sure the volumes provisioned are visible to hosts:

* Login to individual Linux host and run rescan
```
# rescan-scsi-bus.sh
```

* Make sure multipath identifies vexata paths correctly.
```
# source /opt/beetle/.test_env
# vc
Vexata SDs : 224
Vexata DMs : 7
dm-10 : 32
dm-9 : 32
dm-8 : 32
dm-7 : 32
dm-6 : 32
dm-12 : 32
dm-11 : 32
```

* If you don't see the expected device count for `Vexata SDs`. Make sure all fiber channel ports are online on linux host
```
# ws
host11 0x10000090fa9277ec Online 16 Gbit
host12 0x10000090fa9277ed Online 16 Gbit
```

*  Make sure all FC ports are online on Vexata Array.
```
[root@bolt41-ioc0 ~]$  vxcli sa portlist

Num SA Ports =  16

PortNum   Node/Ioc/Port  Type  WWN                       IniCnt  VolCnt  RefCnt  State
--------------------------------------------------------------------------------------------
00        0/0/0          FC    10:00:3c:91:2b:00:75:00       20      24       2  Online
01        0/0/1          FC    10:00:3c:91:2b:00:75:01       20      24       2  Online
02        0/0/2          FC    10:00:3c:91:2b:00:75:02       20      24       2  Online
03        0/0/3          FC    10:00:3c:91:2b:00:75:03       20      24       2  Online
04        0/0/4          FC    10:00:3c:91:2b:00:75:04       20      24       2  Online
05        0/0/5          FC    10:00:3c:91:2b:00:75:05       20      24       2  Online
06        0/0/6          FC    10:00:3c:91:2b:00:75:06       20      24       2  Online
07        0/0/7          FC    10:00:3c:91:2b:00:75:07       20      24       2  Online
08        0/1/0          FC    10:00:3c:91:2b:00:75:08       20      24       2  Online
09        0/1/1          FC    10:00:3c:91:2b:00:75:09       20      24       2  Online
10        0/1/2          FC    10:00:3c:91:2b:00:75:0a       20      24       2  Online
11        0/1/3          FC    10:00:3c:91:2b:00:75:0b       20      24       2  Online
12        0/1/4          FC    10:00:3c:91:2b:00:75:0c       20      24       2  Online
13        0/1/5          FC    10:00:3c:91:2b:00:75:0d       20      24       2  Online
14        0/1/6          FC    10:00:3c:91:2b:00:75:0e       20      24       2  Online
15        0/1/7          FC    10:00:3c:91:2b:00:75:0f       20      24       2  Online
```

* Login to SAN FC switch or contact the SAN administrator to make sure all ports are logged in properly to the switch.

###### Brocade Switch
```
# switchshow
```
###### Cisco Switch
```
# show fcns database vsan 1
```

* If no obvious issues are found from above steps, please refer to **Linux best practices guide** to try all other rescaning options.

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
