.PHONY: sim

# Select DUT
DUT ?= AXIL2NATIVE

# Select design flavor
TOPLEVEL_LANG ?= verilog

sim:
	$(MAKE) -C syn/$(DUT)/ver TOPLEVEL_LANG=$(TOPLEVEL_LANG)

clean:
	$(MAKE) purge -C syn/$(DUT)/ver TOPLEVEL_LANG=$(TOPLEVEL_LANG)
