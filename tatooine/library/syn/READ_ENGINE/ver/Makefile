# COCOTB configuration
TOPLEVEL = $(shell dirname $(PWD) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -GDATA_WIDTH=16 -GADDR_WIDTH=8 --coverage

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
