# Modules for which a  ver/  folder exists
VER_SUBDIRS := $(shell find . -name ver -type d)

# Modules for which a  lec/  folder exists
LEC_SUBDIRS := $(shell find . -name lec -type d)

# List of available targets for  ver/  Makefiles
VER_TARGETS := all json purge

# List of available targets for  lec/  Makefiles
LEC_TARGETS := all purge

default: help
help:
	@echo "---- Welcome to Tatooine! ------------"
	@echo "Available actions"
	@echo ""

$(VER_TARGETS): $(VER_SUBDIRS)
$(VER_SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(LEC_TARGETS): $(LEC_SUBDIRS)
$(LEC_SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: help $(VER_SUBDIRS) $(LEC_SUBDIRS) $(VER_TARGETS) $(LEC_TARGETS)
