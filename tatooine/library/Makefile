.PHONY: list clean help

# Select DUT
DUT ?= AXIL2NATIVE

default: help
help:
	@echo "---- Welcome to Tatooine! ------------"
	@echo "Available actions"
	@echo ""

ver:
	$(MAKE) -C syn/$(DUT)/ver

lec:
	$(MAKE) -C syn/$(DUT)/lec

clean:
	$(MAKE) purge -C syn/$(DUT)/ver
	$(MAKE) purge -C syn/$(DUT)/lec
