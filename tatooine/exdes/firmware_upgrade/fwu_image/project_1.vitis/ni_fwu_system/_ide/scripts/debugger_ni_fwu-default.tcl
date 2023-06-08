# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/ni_fwu_system/_ide/scripts/debugger_ni_fwu-default.tcl
# 
# 
# Usage with xsct:
# In an external shell use the below command and launch symbol server.
# symbol_server -S -s tcp::1534
# To debug using xsct, launch xsct and run below command
# source /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/ni_fwu_system/_ide/scripts/debugger_ni_fwu-default.tcl
# 
connect -path [list tcp::1534 tcp:pciedev-linux:3121]
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/FPGA_TOP/export/FPGA_TOP/hw/FPGA_TOP.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow /home/utente/projects/ni-cores/exdes/firmware_upgrade/fwu_image/project_1.vitis/ni_fwu/Release/ni_fwu.elf
bpadd -addr &main
