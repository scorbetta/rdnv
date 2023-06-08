#!/bin/bash

# Utility to reboot the FPGA in Firmware Update mode

# Log file for debug
LOGFILE=fpga_reboot_silver.log

# Silver Image physical address in Flash
SILVER_IMAGE_ADDR=0x02000000

# HWICAP base address (offset from 0xc0000000)
HWICAP_BASE_ADDR=0x20000

# Colored output using ANSI escape codes
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Debug mode allows to follow step by step
DEBUG_MODE=0

# Wait for user intervention
function wait_for_input {
    cmd=$1
    if [ $DEBUG_MODE -eq 1 ]
    then
        echo -e "${BLUE}> $cmd${NC}"
        read -r -n1 key
    fi
}

# Send a Read command over PCIe
function pcie_read {
    offset_in=$1
    hwicap_addr=$(( $HWICAP_BASE_ADDR + $offset_in ))
    addr=$( printf '0x%08x' $hwicap_addr )
    cmd="sudo ./reg_rw /dev/xdma0_user $addr w | tee -a $LOGFILE"
    wait_for_input "$cmd"
    eval $cmd
}

# Send a Write command over PCIe
function pcie_write {
    offset_in=$1
    data_in=$2
    hwicap_addr=$(( $HWICAP_BASE_ADDR + $offset_in ))
    addr=$( printf '0x%08x' $hwicap_addr )
    cmd="sudo ./reg_rw /dev/xdma0_user $addr w $data_in | tee -a $LOGFILE"
    wait_for_input "$cmd"
    eval $cmd
}

# Write data to ICAP for IPROG. Taken from the example bitstream in UG570
cfg_data=( 0xffffffff 0xaa995566 0x20000000 0x30020001 $SILVER_IMAGE_ADDR 0x30008001 0x0000000f 0x20000000 )

# Clear log
echo -n "" > $LOGFILE

# Clear FIFOs at first
echo -e "${BLUE}info: Clearing FIFOs${NC}"
pcie_read 0x114
pcie_write 0x10c 0x00000004
pcie_write 0x10c 0x00000000
pcie_read 0x114

# Send data to FIFO
for data in ${cfg_data[@]}
do
    echo -e "${BLUE}info: Sending data $data${NC}"
    pcie_write 0x100 $data
    pcie_read 0x114

    # Flush the FIFO at every command
    pcie_write 0x10c 0x00000001
    pcie_read 0x114
done
