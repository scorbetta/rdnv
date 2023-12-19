# COCOTB configuration
TOPLEVEL = $(shell dirname $(CURDIR) | xargs basename)
FLAVOR = sv

# DUT configuration
EXTRA_ARGS += -GFIFO_DEPTH=16 -GDATA_WIDTH=16 -GFWFT_SHOWAHEAD=0
EXTRA_ARGS += -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
include $(TATOOINE_ROOT)/scripts/Makefile.dooku
