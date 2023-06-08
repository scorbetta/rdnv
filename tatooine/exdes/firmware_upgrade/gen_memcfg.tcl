# Generate a memory configuration file containing the Golden Image and the Firmware Upgrade Image
set GOLDEN_IMAGE "./golden_image/project_1.runs/impl_1/FPGA_TOP.bit"
set FWU_IMAGE "./fwu_image/project_1.runs/impl_1/FPGA_TOP.bit"
set OUTPUT_CFG_FILE "./multi_boot_image.mcs"

# Assumptions:
#   SPI works x4
#   Golden Image starts at address 0x00000000
#   Firmware Upgrade image starts at address 0x02000000
write_cfgmem -force -format mcs -size 64 -interface SPIx4 -loadbit "up 0x00000000 $GOLDEN_IMAGE up 0x02000000 $FWU_IMAGE" -checksum -file $OUTPUT_CFG_FILE

# Exit
exit
