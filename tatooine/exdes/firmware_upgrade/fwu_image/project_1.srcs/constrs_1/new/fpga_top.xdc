# PCIe reference clock
create_clock -period 10.000 -name PCIE_REFCLK [get_ports PCIE_REFCLK_P]
set_property PACKAGE_PIN AB5 [get_ports PCIE_REFCLK_N]
set_property PACKAGE_PIN AB6 [get_ports PCIE_REFCLK_P]

# PCIe dedicated reset pin
set_property PACKAGE_PIN K22 [get_ports PCIE_RSTN]
set_false_path -from [get_ports PCIE_RSTN]
set_property PULLUP true [get_ports PCIE_RSTN]
set_property IOSTANDARD LVCMOS18 [get_ports PCIE_RSTN]

# PCIe data pins (Rx)
set_property PACKAGE_PIN AB2 [ get_ports {PCIE_RXP[0]} ]
set_property PACKAGE_PIN AB1 [ get_ports {PCIE_RXN[0]} ]
set_property PACKAGE_PIN AD2 [ get_ports {PCIE_RXP[1]} ]
set_property PACKAGE_PIN AD1 [ get_ports {PCIE_RXN[1]} ]
set_property PACKAGE_PIN AF2 [ get_ports {PCIE_RXP[2]} ]
set_property PACKAGE_PIN AF1 [ get_ports {PCIE_RXN[2]} ]
set_property PACKAGE_PIN AH2 [ get_ports {PCIE_RXP[3]} ]
set_property PACKAGE_PIN AH1 [ get_ports {PCIE_RXN[3]} ]
set_property PACKAGE_PIN AJ4 [ get_ports {PCIE_RXP[4]} ]
set_property PACKAGE_PIN AJ3 [ get_ports {PCIE_RXN[4]} ]
set_property PACKAGE_PIN AK2 [ get_ports {PCIE_RXP[5]} ]
set_property PACKAGE_PIN AK1 [ get_ports {PCIE_RXN[5]} ]
set_property PACKAGE_PIN AM2 [ get_ports {PCIE_RXP[6]} ]
set_property PACKAGE_PIN AM1 [ get_ports {PCIE_RXN[6]} ]
set_property PACKAGE_PIN AP2 [ get_ports {PCIE_RXP[7]} ]
set_property PACKAGE_PIN AP1 [ get_ports {PCIE_RXN[7]} ]

# PCIe data pins (Tx)
set_property PACKAGE_PIN AC4 [ get_ports {PCIE_TXP[0]} ]
set_property PACKAGE_PIN AC3 [ get_ports {PCIE_TXN[0]} ]
set_property PACKAGE_PIN AE4 [ get_ports {PCIE_TXP[1]} ]
set_property PACKAGE_PIN AE3 [ get_ports {PCIE_TXN[1]} ]
set_property PACKAGE_PIN AG4 [ get_ports {PCIE_TXP[2]} ]
set_property PACKAGE_PIN AG3 [ get_ports {PCIE_TXN[2]} ]
set_property PACKAGE_PIN AH6 [ get_ports {PCIE_TXP[3]} ]
set_property PACKAGE_PIN AH5 [ get_ports {PCIE_TXN[3]} ]
set_property PACKAGE_PIN AK6 [ get_ports {PCIE_TXP[4]} ]
set_property PACKAGE_PIN AK5 [ get_ports {PCIE_TXN[4]} ]
set_property PACKAGE_PIN AL4 [ get_ports {PCIE_TXP[5]} ]
set_property PACKAGE_PIN AL3 [ get_ports {PCIE_TXN[5]} ]
set_property PACKAGE_PIN AM6 [ get_ports {PCIE_TXP[6]} ]
set_property PACKAGE_PIN AM5 [ get_ports {PCIE_TXN[6]} ]
set_property PACKAGE_PIN AN4 [ get_ports {PCIE_TXP[7]} ]
set_property PACKAGE_PIN AN3 [ get_ports {PCIE_TXN[7]} ]

# UART pins
set_property PACKAGE_PIN AK8 [ get_ports UART_RX ]
set_property IOSTANDARD LVCMOS18 [get_ports UART_RX]
set_property PACKAGE_PIN AL8 [ get_ports UART_TX ]
set_property IOSTANDARD LVCMOS18 [get_ports UART_TX]

# Bitstream constraints
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [ current_design ]

# Miscellanea
set_false_path -to [get_pins -hier *sync_reg[0]/D]