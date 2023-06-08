
 PARAMETER VERSION = 2.2.0


BEGIN OS
 PARAMETER OS_NAME = standalone
 PARAMETER OS_VER = 7.6
 PARAMETER PROC_INSTANCE = UBLAZE_HIER_microblaze_0
 PARAMETER stdin = UBLAZE_HIER_axi_uartlite_0
 PARAMETER stdout = UBLAZE_HIER_axi_uartlite_0
END


BEGIN PROCESSOR
 PARAMETER DRIVER_NAME = cpu
 PARAMETER DRIVER_VER = 2.14
 PARAMETER HW_INSTANCE = UBLAZE_HIER_microblaze_0
END


BEGIN DRIVER
 PARAMETER DRIVER_NAME = intc
 PARAMETER DRIVER_VER = 3.13
 PARAMETER HW_INSTANCE = UBLAZE_HIER_microblaze_0_axi_intc
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 4.7
 PARAMETER HW_INSTANCE = UBLAZE_HIER_microblaze_0_local_memory_dlmb_bram_if_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 4.7
 PARAMETER HW_INSTANCE = UBLAZE_HIER_microblaze_0_local_memory_ilmb_bram_if_cntlr
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = bram
 PARAMETER DRIVER_VER = 4.7
 PARAMETER HW_INSTANCE = axi_bram_ctrl_1
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = spi
 PARAMETER DRIVER_VER = 4.8
 PARAMETER HW_INSTANCE = axi_quad_spi_0
END

BEGIN DRIVER
 PARAMETER DRIVER_NAME = uartlite
 PARAMETER DRIVER_VER = 3.6
 PARAMETER HW_INSTANCE = UBLAZE_HIER_axi_uartlite_0
END


