#!/bin/bash

# Utility to check Golden Image

# Log file for debug
LOGFILE=fpga_reboot_silver.log

echo -n "" > $LOGFILE

# BRAM Write/Read tests
for tdx in $( seq 1 1 4 )
do
    addr_dec=$(( $tdx * 4 ))
    addr_hex=$( printf '0x%08x' $addr_dec )
    data_hex=$( printf '0x%08x' $RANDOM )
    sudo ./reg_rw /dev/xdma0_user $addr_hex w | tee -a $LOGFILE
    sudo ./reg_rw /dev/xdma0_user $addr_hex w $data_hex | tee -a $LOGFILE
    sudo ./reg_rw /dev/xdma0_user $addr_hex w | tee -a $LOGFILE
done

# GPIO tests. According to the image taken the results vary
sudo ./reg_rw /dev/xdma0_user 0x10000 w 0x0 | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10008 w | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10000 w 0x1 | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10008 w | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10000 w 0x2 | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10008 w | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10000 w 0x3 | tee -a $LOGFILE
sudo ./reg_rw /dev/xdma0_user 0x10008 w | tee -a $LOGFILE
