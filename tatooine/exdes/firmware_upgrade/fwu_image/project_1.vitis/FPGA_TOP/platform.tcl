# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/FPGA_TOP/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/FPGA_TOP/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {FPGA_TOP}\
-hw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}\
-out {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis}

platform write
domain create -name {standalone_UBLAZE_HIER_microblaze_0} -display-name {standalone_UBLAZE_HIER_microblaze_0} -os {standalone} -proc {UBLAZE_HIER_microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {FPGA_TOP}
platform generate -quick
bsp reload
catch {bsp regenerate}
platform generate
bsp reload
catch {bsp regenerate}
catch {bsp regenerate}
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
catch {bsp regenerate}
platform generate -domains standalone_UBLAZE_HIER_microblaze_0 
platform generate -domains standalone_UBLAZE_HIER_microblaze_0 
platform clean
platform generate
platform generate -domains standalone_UBLAZE_HIER_microblaze_0 
platform generate -domains standalone_UBLAZE_HIER_microblaze_0 
platform generate
platform active {FPGA_TOP}
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
catch {bsp regenerate}
catch {bsp regenerate}
platform generate -domains standalone_UBLAZE_HIER_microblaze_0 
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
catch {bsp regenerate}
platform clean
catch {bsp regenerate}
platform generate
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
platform clean
catch {bsp regenerate}
platform generate
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
platform clean
platform generate
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
platform clean
platform generate
platform generate
platform active {FPGA_TOP}
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
catch {bsp regenerate}
platform clean
platform generate
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
bsp reload
catch {bsp regenerate}
platform clean
catch {bsp regenerate}
platform generate
platform active {FPGA_TOP}
platform config -updatehw {/home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/FPGA_TOP.xsa}
platform clean
bsp reload
catch {bsp regenerate}
platform generate
platform active {FPGA_TOP}
bsp reload
bsp reload
