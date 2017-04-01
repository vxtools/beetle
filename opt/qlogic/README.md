# Introduction.
This procedure modifies two qla2xxx driver parameters allowing for multiple vectors to be enabled and a max queue value of 16 per port.

```
ql2xmaxqueues:Enables MQ settings Default is 1 for single queue. Set it to number of queues in MQ mode. (int)
ql2xmultique_tag:Enables CPU affinity settings for the driver Default is 0 for no affinity of request and response IO. Set it to 1 to turn on the cpu affinity. (int)
```

A script is included to rebalance the interrupts across all vectors.

These modifications may be necessary to prevent soft lockup errors in high IOPS environments.

## Prerequisites.

Disable irqbalance on the system

```
systemctl stop irqbalance
systemctl disable irqbalance
```

## How to Install. 

1. Download the tar file:
   ```
   # wget https://github.com/vxtools/beetle/raw/master/opt/qlogic/qla_autoload.tar
   ```

2. Extract the package with the following flags.

   ```
   # tar xvfP qla_autoload.tar 
   ```

   P - will disable striping /'s from file names.  

3. This will result in the following two files being extracted on the host:

   ```
   # tar tvfP /root/qla_autoload.tar
   -rw-r--r-- root/root       167 2017-03-22 19:51 /lib/modprobe.d/qla_autoload.conf
   -rwxr-xr-x root/root       317 2017-03-22 20:05 /etc/qla2x_rebalance.sh
   ```

4. Implement modifications: 

   *NOTE:  If your system is booting from SAN, please follow step: i. Persistent implementation.* 
   
   1. Persistent implementation
   
      *These modifications will persist across system reboots.*
      
      ```
      # Backup the current RAMDISK
      # cp -pr /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.orig
      # Create new RAMDISK with updated qla params
      # dracut -f
      # reboot
      ```

   1. Temporary implementation
   
      *These modifications will **not** persist across a reboot.  Disregard this step if your environment boots from SAN.*

      Unload the qla2xxx module

      ```
      # multipath -F # Flushes all multipath devices
      # sleep 60 
      # rmmod qla2xxx
      # modprobe qla2xxx
      ```

      Output of the modprobe will look like below. Depending on the number of cores in the system, the output could change.

      ```
      Setting IRQ 49 to mask 1
      Setting IRQ 50 to mask 3
      Setting IRQ 51 to mask 5
      Setting IRQ 52 to mask 7
      Setting IRQ 53 to mask 9
      Setting IRQ 54 to mask 11
      <truncated>
      Setting IRQ 164 to mask 133
      Setting IRQ 165 to mask 135
      Setting IRQ 166 to mask 137
      Setting IRQ 167 to mask 139
      Setting IRQ 168 to mask 141
      Setting IRQ 169 to mask 143
      ```

## Verify the settings were successfully implemented.
```
# cat /sys/module/qla2xxx/parameters/ql2xmaxqueues
16
# cat /sys/module/qla2xxx/parameters/ql2xmultique_tag
1
# grep qla2xxx /proc/interrupts |wc -l
64
```

## Revert Modifications.

Only use the following steps if the changes made by the procedure above are no longer needed:

1. Remove these files from the system
   ```
   # rm -rf /lib/modprobe.d/qla_autoload.conf
   # rm -rf /etc/qla2x_rebalance.sh
   ```

2. Revert implementation
   1. If changes were implemented persistently:
   
      ```
      # dracut -f 
      # reboot 
      ```
   1. If changes were implemented temporarily:

      ```
      # multipath -F # Flushes all multipath devices
      # sleep 10 
      # rmmod qla2xxx
      # modprobe qla2xxx
      ```
