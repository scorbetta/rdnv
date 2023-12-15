# COCOTB configuration
TOPLEVEL = $(shell dirname $(CURDIR) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -GDATA_WIDTH=8 -GHAS_RESET=1

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
include $(TATOOINE_ROOT)/scripts/Makefile.dooku
