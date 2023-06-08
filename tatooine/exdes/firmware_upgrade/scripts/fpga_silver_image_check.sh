#!/bin/bash

# Utility to check Silver Image

# Colored output using ANSI escape codes
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Expected register values after initialization
SILVER_STATUS_REG="0xf221028e"
SILVER_WATERMARK="0x0d15ea5e"
SILVER_INIT_STATUS="0x01111111"

# Test presence of the Xilinx FPGA node
xilinx_is_present=$( lspci | grep Xilinx )
if [ "$xilinx_is_present" == "" ]
then
    echo -e "${RED}erro: Xilinx PCIe node not found${NC}"
    exit -65
fi

# Check Silver Image has been loaded
retval=$( sudo ./reg_rw /dev/xdma0_user 0x10000 w | grep 'Read 32-bit' | awk '{print $8}' )
if [ "$retval" != $SILVER_STATUS_REG ]
then
    echo -e "${RED}erro: Silver Image not loaded${NC}"
    echo -e "${RED}erro:    ID readout: ${retval}${NC}"
    exit -65
fi

# Check PLL has locked and PCIe link is up
retval=$( sudo ./reg_rw /dev/xdma0_user 0x10008 w | grep 'Read 32-bit' | awk '{print $8}' )
if [ "$retval" != "0x00000003" ]
then
    echo -e "${RED}erro: Neither PLL lock nor PCIe link up are asserted${NC}"
    echo -e "${RED}erro:    GPIO/Ch2 readout: ${retval}${NC}"
    exit -65
fi

# Check initialization
retval=$( sudo ./reg_rw /dev/xdma0_user 0x1c w | grep 'Read 32-bit' | awk '{print $8}' )
if [ "$retval" != $SILVER_WATERMARK ]
then
    echo -e "${RED}erro: Unexpected watermark: ${retval} (expected: $SILVER_WATERMARK)${NC}"
    exit -65
fi

retval=$( sudo ./reg_rw /dev/xdma0_user 0x14 w | grep 'Read 32-bit' | awk '{print $8}' )
if [ "$retval" != $SILVER_INIT_STATUS ]
then
    echo -e "${RED}erro: Unexpected value after initialization: ${retval} (expected: $SILVER_INIT_STATUS)${NC}"
    exit -65
fi

# Write/Read tests on remote BRAM at known offset
for iter in $( seq 1 1 4 )
do
    # Likely read all 0s
    retval_early=$( sudo ./reg_rw /dev/xdma0_user 0x0 w | grep 'Read 32-bit' | awk '{print $8}' )

    # Get random 32-bit value to write
    random_value=$( printf '0x%08x' $SRANDOM )
    sudo ./reg_rw /dev/xdma0_user 0x0 w $random_value

    # Read back
    retval_late=$( sudo ./reg_rw /dev/xdma0_user 0x0 w | grep 'Read 32-bit' | awk '{print $8}' )

    # Verify expected value
    if [ "$retval_late" != "$random_value" ]
    then
        echo -e "${RED}erro: Readout value at iteration $iter does not match written value${NC}"
        exit -65
    fi
done

# All's good
echo -e "${BLUE}info: Silver Image connection test: PASS${NC}"
