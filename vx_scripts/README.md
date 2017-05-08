### USAGE : # ./configure_vexata_array \<volcount\> \<volsize in GiB\>

Example-1:
```
# ./configure_vexata_array 8 256 # Creates 8 volumes of size 256 GiB each
```

To Create multiple EGs (say higher than max volumed per EG, rerun the script multiple times

Example-2:
```
# ./configure_vexata_array 4 100 # Creates additional 4 volumes of size 100 GiB each
```
