# COCOTB configuration
TOPLEVEL = $(shell dirname $(CURDIR) | xargs basename)
FLAVOR = v

# DUT configuration
EXTRA_ARGS += -GWIDTH=16 -GFRAC_BITS=13 -GNUM_INPUTS=16 -GHAS_EXT_BIAS=0
EXTRA_ARGS += -Wno-WIDTHEXPAND

# Include ORGANA Makefiles
include $(TATOOINE_ROOT)/scripts/Makefile.cocotb
include $(TATOOINE_ROOT)/scripts/Makefile.dooku
