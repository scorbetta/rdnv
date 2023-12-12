# COCOTB configuration
TOPLEVEL = $(shell dirname $(PWD) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -DDATA_WIDTH=8 -DHAS_RESET=1

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
