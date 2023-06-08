# PHONY targets
.PHONY: all sim elab comp clean waves

# Prefix for change of hierarchy. Do *not* modify this line!
PREFIX != pwd | sed "s@\/@\\\/@g"

# Libraries
STD_LIBS = unisims_ver unimacro_ver secureip
ALL_LIBS = $(STD_LIBS) $(USER_LIBS)
LIBS = $(patsubst %, -L %, $(ALL_LIBS))

# Include folders for Verilog and SystemVerilog
STD_INCLUDES = 
ALL_INCLUDES = $(STD_INCLUDES) $(USER_INCLUDES)
INCLUDES = $(patsubst %, --include %, $(ALL_INCLUDES))

# Files to query compilation lists
IN_FILES = rtl_sources.list ver_sources.list sim_sources.list

# Prepend absolute path to files that are relative, leave others as is
SRCS_SV != grep -sh "^[$$/].*\.sv$$" $(IN_FILES) ; grep -sh "^[^$$/].*\.sv$$" $(IN_FILES) | sed "s@^@$(PREFIX)/@g"
SRCS_V != grep -sh "^[$$/].*\.v$$" $(IN_FILES) ; grep -sh "^[^$$/].*\.v$$" $(IN_FILES) | sed "s@^@$(PREFIX)/@g"
SRCS_VHD != grep -sh "^[$$/].*\.vhd$$" $(IN_FILES) ; grep -sh "^[^$$/].*\.vhd$$" $(IN_FILES) | sed "s@^@$(PREFIX)/@g"

# SystemVerilog compilation setup
SV_COMP_OPTS = --sv --nolog --incr $(INCLUDES) $(LIBS)
SV_CMD_LINE := xvlog --sv $(SV_COMP_OPTS) $(SRCS_SV)

# Verilog compilation setup
V_COMP_OPTS = --nolog --incr $(INCLUDES) $(LIBS)
V_CMD_LINE := xvlog $(V_COMP_OPTS) $(SRCS_V)

# VHDL compilation setup
VHD_COMP_OPTS = --nolog --2008
VHD_CMD_LINE := xvhdl $(VHD_COMP_OPTS) $(SRCS_VHD)

# Elaboration setup
ELAB_OPTS = --nolog --debug all --timescale 1ns/100ps $(LIBS)
ELAB_CMD_LINE := xelab $(ELAB_OPTS) --snapshot xsim.snapshot $(TOP)

# Simulation setup
SIM_OPTS = --nolog --sv_seed $(shell date +%N) --testplusarg UVM_TESTNAME=$(UVM_TESTNAME)
SIM_CMD_LINE := xsim $(SIM_OPTS) --tclbatch $(SCRIPTS_DIR)/xsim.in xsim.snapshot

# Colored output
BLUE = \033[0;34m
RED = \033[0;31m
DEFAULT = \033[0m

# Prepare commands to execute

# Default target is to run 'em all
all: sim

elab: .elab.timestamp

comp: .comp_v.timestamp .comp_sv.timestamp .comp_vhd.timestamp

sim: elab
	@echo
	@echo "$(BLUE)sim: $(SIM_CMD_LINE)$(DEFAULT)"
	eval $(SIM_CMD_LINE)

.elab.timestamp: .comp_v.timestamp .comp_sv.timestamp .comp_vhd.timestamp
	@echo
	@echo "$(BLUE)elab: $(ELAB_CMD_LINE)$(DEFAULT)"
	eval $(ELAB_CMD_LINE)
	@touch .elab.timestamp

ifneq ($(SRCS_V),)
.comp_v.timestamp: $(SRCS_V)
	@echo
	@echo "$(BLUE)comp: $(V_CMD_LINE)$(DEFAULT)"
	eval $(V_CMD_LINE)
	@touch .comp_v.timestamp
else
.comp_v.timestamp: $(SRCS_V)
	@touch .comp_v.timestamp
endif

ifneq ($(SRCS_SV),)
.comp_sv.timestamp: $(SRCS_SV)
	@echo
	@echo "$(BLUE)comp: $(SV_CMD_LINE)$(DEFAULT)"
	eval $(SV_CMD_LINE)
	@touch .comp_sv.timestamp
else
.comp_sv.timestamp: $(SRCS_SV)
	@touch .comp_sv.timestamp
endif

ifneq ($(SRCS_VHD),)
.comp_vhd.timestamp: $(SRCS_VHD)
	@echo
	@echo "$(BLUE)comp: $(VHD_CMD_LINE)$(DEFAULT)"
	eval $(VHD_CMD_LINE)
	@touch .comp_vhd.timestamp
else
.comp_vhd.timestamp:
	@touch .comp_vhd.timestamp
endif

waves: xsim.snapshot.wdb
	xsim -g xsim.snapshot.wdb -t load_waves.tcl

clean:
	rm -rf *.jou *.log *.pb *.wdb xsim.dir xsim.covdb
	rm -rf .*.timestamp .Xil
