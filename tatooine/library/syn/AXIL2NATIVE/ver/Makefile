# COCOTB configuration
TOPLEVEL = $(shell dirname $(PWD) | xargs basename)
FLAVOR = v
COV = 0

# DUT configuration
EXTRA_ARGS += -GDATA_WIDTH=32 -GADDR_WIDTH=16

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
