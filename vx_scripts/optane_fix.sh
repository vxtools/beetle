#/bin/bash

cp -pr /config/current/vxd.cfg /tmp/vxd_bkup.cfg
sed -i '730,770s/driveWBW = 2240/driveWBW = 1540/g ; 730,770s/rebuildWBW = 2240/rebuildWBW = 1100/g' /config/current/vxd.cfg
diff /config/current/vxd.cfg /tmp/vxd_bkup.cfg
