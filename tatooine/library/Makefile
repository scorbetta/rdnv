# Modules for which a  ver/  folder exists
VER_SUBDIRS := $(shell find . -name ver -type d)

# Modules for which a  lec/  folder exists
LEC_SUBDIRS := $(shell find . -name lec -type d)

# List of available targets for  ver/  Makefiles
VER_TARGETS := sim json purge cov-report

# List of available targets for  lec/  Makefiles
LEC_TARGETS := lec purge

# Overwrite this to 1 in case coverage is all you need!
WAVES ?= 0

default: help
help:
	@echo "---- Welcome to Tatooine! ------------"
	@echo "Available actions"
	@echo ""

$(VER_TARGETS): $(VER_SUBDIRS)
$(VER_SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS) WAVES=$(WAVES)

$(LEC_TARGETS): $(LEC_SUBDIRS)
$(LEC_SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: help $(VER_SUBDIRS) $(LEC_SUBDIRS) $(VER_TARGETS) $(LEC_TARGETS)
