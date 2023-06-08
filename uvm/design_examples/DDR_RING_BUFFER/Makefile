# Top-level name. This is also the assumed  .prj  file for Vivado to work
TOP = ddr_ring_buffer_uvm_tb

# Test selection
UVM_TESTNAME = ddr_ring_buffer_random_test

# Additional libraries (other than  unisims_ver, unimacro_ver, secureip  )
USER_LIBS = uvm

# Include folders for Verilog and SystemVerilog
USER_INCLUDES = 

# Additional user-defined options to the merged compilation/elaboration steps
ELAB_USER_OPTS = --define DATA_WIDTH=64 --define ADDR_WIDTH=16 --define DRAIN_BURST_LEN=256

# Import rules
include ${ROOT}/scripts/Makefile
