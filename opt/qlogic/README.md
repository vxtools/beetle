
This package will reload the qla2xxx driver with multiple vectors enabled and a max queue value of 16 per port.

After loading the module, a script rebalances the interrupts across all vectors.

Pre req : Disable irqbalance on the system

```
systemctl stop irqbalance
systemctl disable irqbalance
```
## How to Install. 

1. Download the tar file:
```
# wget https://github.com/vxtools/beetle/raw/master/opt/qlogic/qla_autoload.tar
```

2. Extract the package with following flags.

```
# tar xvfP qla_autoload.tar 
```

P - will disable striping /'s from file names.

3. This will extract following two files in the host where the tar command was executed.

```
# tar tvfP /root/qla_autoload.tar
-rw-r--r-- root/root       167 2017-03-22 19:51 /lib/modprobe.d/qla_autoload.conf
-rwxr-xr-x root/root       317 2017-03-22 20:05 /etc/qla2x_rebalance.sh
```

4. Unload the qla2xxx module

```
# multipath -F # Flushes all multipath devices
# sleep 60 
# rmmod qla2xxx
# modprobe qla2xxx
```

Output of the modprobe will look like below. Depending on the number of cores in the system, the output could change.

```
install ql2xmaxqueues=16 ql2xmultique_tag=1 /sbin/modprobe --ignore-install qla2xxx ql2xmaxqueues=16 ql2xmultique_tag=1 $CMDLINE_OPTS; /etc/qla2x_rebalance.sh
insmod /lib/modules/3.10.0-327.el7.x86_64/kernel/drivers/scsi/qla2xxx/qla2xxx.ko ql2xmaxqueues=16 ql2xmultique_tag=1
Setting IRQ 35 to mask 2
Setting IRQ 36 to mask 4
Setting IRQ 37 to mask 10
Setting IRQ 38 to mask 40
Setting IRQ 39 to mask 100
Setting IRQ 40 to mask 400
Setting IRQ 41 to mask 1000
Setting IRQ 42 to mask 4000
Setting IRQ 43 to mask 10000
Setting IRQ 44 to mask 40000
Setting IRQ 45 to mask 100000
Setting IRQ 46 to mask 400000
Setting IRQ 47 to mask 1000000
Setting IRQ 48 to mask 4000000
Setting IRQ 49 to mask 10000000
Setting IRQ 86 to mask 40000000
Setting IRQ 87 to mask 100000000
Setting IRQ 88 to mask 4
Setting IRQ 89 to mask 10
Setting IRQ 90 to mask 40
Setting IRQ 91 to mask 100
Setting IRQ 92 to mask 400
Setting IRQ 93 to mask 1000
Setting IRQ 94 to mask 4000
Setting IRQ 95 to mask 10000
Setting IRQ 96 to mask 40000
Setting IRQ 98 to mask 100000
Setting IRQ 99 to mask 400000
Setting IRQ 100 to mask 1000000
Setting IRQ 101 to mask 4000000
Setting IRQ 102 to mask 10000000
Setting IRQ 103 to mask 40000000
Setting IRQ 104 to mask 100000000
Setting IRQ 105 to mask 4
Setting IRQ 106 to mask 10
Setting IRQ 107 to mask 40
Setting IRQ 108 to mask 100
Setting IRQ 109 to mask 400
Setting IRQ 110 to mask 1000
Setting IRQ 111 to mask 4000
Setting IRQ 112 to mask 10000
Setting IRQ 113 to mask 40000
Setting IRQ 114 to mask 100000
Setting IRQ 115 to mask 400000
Setting IRQ 116 to mask 1000000
Setting IRQ 117 to mask 4000000
Setting IRQ 118 to mask 10000000
Setting IRQ 119 to mask 40000000
Setting IRQ 120 to mask 100000000
Setting IRQ 121 to mask 4
Setting IRQ 122 to mask 10
Setting IRQ 123 to mask 40
```

## How to verify the settings are applied.
```
# cat /sys/module/qla2xxx/parameters/ql2xmaxqueues
16
# cat /sys/module/qla2xxx/parameters/ql2xmultique_tag
1
# grep qla2xxx /proc/interrupts |wc -l
64
```

## How to back off the changes.

1. Remove the files from the system
```
# rm -rf /lib/modprobe.d/qla_autoload.conf
# rm -rf /etc/qla2x_rebalance.sh
```
2. Reload the qlogic driver.
```
# multipath -F # Flushes all multipath devices
# sleep 10 
# rmmod qla2xxx
# modprobe qla2xxx
```
