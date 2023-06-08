# Constraints for multi-boot
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [ current_design ]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h02000000 [ current_design ]
set_property BITSTREAM.CONFIG.TIMER_CFG 32'h01ffffff [ current_design ]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT Disable [ current_design ]