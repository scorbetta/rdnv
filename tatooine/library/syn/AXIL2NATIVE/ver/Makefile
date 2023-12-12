# COCOTB configuration
TOPLEVEL = $(shell dirname $(PWD) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -DDATA_WIDTH=32 -DADDR_WIDTH=16

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
