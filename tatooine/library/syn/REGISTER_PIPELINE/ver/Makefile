# COCOTB configuration
TOPLEVEL = $(shell dirname $(PWD) | xargs basename)
FLAVOR = sv

# DUT configuration
EXTRA_ARGS += -GDATA_WIDTH=32 -GNUM_STAGES=4 

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
