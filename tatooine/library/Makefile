.PHONY: sim

# Select DUT
DUT ?= AXIL2NATIVE

ver:
	$(MAKE) -C syn/$(DUT)/ver

sim:
	$(MAKE) -C syn/$(DUT)/sim

clean:
	$(MAKE) purge -C syn/$(DUT)/ver
	$(MAKE) purge -C syn/$(DUT)/sim
	find . -name __pycache__ -exec rm -fR {} +
