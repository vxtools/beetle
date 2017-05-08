### USAGE : # ./configure_vexata_array \<volcount\> \<volsize in GiB\>

Example-1:
```
# ./configure_vexata_array 8 256 # Creates 8 volumes of size 256 GiB each
```

To Create multiple EGs (say higher than max volumed per EG, rerun the script multiple times

Example-2:
```
# ./configure_vexata_array 32 100 # Creates additional 32 volumes of size 100 GiB each
# ./configure_vexata_array 32 100 # Creates additional 32 volumes of size 100 GiB each
```
Above example creates total of 64 volumes per each host, with 32 volumes per EG and total of 2 EGs per host.

### Usage : ./config_recreate.sh

This script collects the backup of the configuration. 

The information collected through collect_config.sh can be used to re-create the config.

Backup of the configuration is stored in /tmp/conf directory

Example:
```
# ./config_recreate.sh
```
