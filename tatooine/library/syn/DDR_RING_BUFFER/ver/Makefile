# COCOTB configuration
TOPLEVEL = $(shell dirname $(CURDIR) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -GAXI_ID_WIDTH=1 -GAXI_ADDR_WIDTH=6 -GDATA_WIDTH=8 -GDRAIN_BURST_LEN=16 -GEXTERNAL_READ_ITF=0
EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
include $(TATOOINE_ROOT)/scripts/Makefile.dooku
