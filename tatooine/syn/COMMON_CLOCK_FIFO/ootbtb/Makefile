# PHONY targets
.PHONY: all sim elab comp clean waves

# Prefix for change of hierarchy. Do *not* modify this line!
SED_PREFIX = \.\.\/

# RTL and simulation files
SRCS_SV != grep -E "\.sv$$" rtl_sources.list | sed "s/^/$(SED_PREFIX)/" ; grep -E "\.sv$$" ootbtb_sources.list
SRCS_V != grep -E "\.v$$" rtl_sources.list | sed 's/^/$(SED_PREFIX)/' ; grep -E "\.v$$" ootbtb_sources.list
SRCS_VHDL != grep -E "\.vhd$$" rtl_sources.list | sed "s/^/$(SED_PREFIX)/g"; grep -E "\.vhd$$" ootbtb_sources.list

# Options
LIBS=-L uvm -L axi4stream_vip_v1_1_10 -L smartconnect_v1_0 -L axi_protocol_checker_v2_0_3 -L axi_vip_v1_1_3 -L xilinx_vip -L axi_infrastructure_v1_1_0 -L unisims_ver -L unimacro_ver -L secureip
VLOG_COMP_OPTS = --nolog --incr --include ../src/includes --include ../ $(LIBS)
VHDL_COMP_OPTS = --nolog --2008
ELAB_OPTS = --nolog --debug all --timescale 1ns/100ps $(LIBS)
SIM_OPTS = --nolog

# Top-level name
TOP = ootbtb
SEED != date +%N

# Colored output
BLUE = \033[0;34m
RED = \033[0;31m
DEFAULT = \033[0m

# Prepare commands to execute
V_CMD_LINE := xvlog $(VLOG_COMP_OPTS) $(SRCS_V)
SV_CMD_LINE := xvlog --sv $(VLOG_COMP_OPTS) $(SRCS_SV)
VHDL_CMD_LINE := xvhdl $(VHDL_COMP_OPTS) $(SRCS_VHDL)
ELAB_CMD_LINE := xelab $(ELAB_OPTS) --snapshot xsim.snapshot $(TOP)
SIM_CMD_LINE := xsim $(SIM_OPTS) --sv_seed $(SEED) --tclbatch xsim.in xsim.snapshot

# Default target is to run 'em all
all: sim

elab: .elab.timestamp

comp: .comp_v.timestamp .comp_sv.timestamp .comp_vhdl.timestamp

sim: elab
	@echo
	@echo "$(BLUE)sim: $(SIM_CMD_LINE)$(DEFAULT)"
	eval $(SIM_CMD_LINE)

.elab.timestamp: .comp_v.timestamp .comp_sv.timestamp .comp_vhdl.timestamp
	@echo
	@echo "$(BLUE)elab: $(ELAB_CMD_LINE)$(DEFAULT)"
	eval $(ELAB_CMD_LINE)
	touch .elab.timestamp

ifneq ($(SRCS_V),)
.comp_v.timestamp: $(SRCS_V)
	@echo
	@echo "$(BLUE)comp: $(V_CMD_LINE)$(DEFAULT)"
	eval $(V_CMD_LINE)
	touch .comp_v.timestamp
else
.comp_v.timestamp: $(SRCS_V)
	touch .comp_v.timestamp
endif

ifneq ($(SRCS_SV),)
.comp_sv.timestamp: $(SRCS_SV)
	@echo
	@echo "$(BLUE)comp: $(SV_CMD_LINE)$(DEFAULT)"
	@echo "$(BLUE)comp: $(SRCS_VHDL)$(DEFAULT)"
	eval $(SV_CMD_LINE)
	touch .comp_sv.timestamp
else
.comp_sv.timestamp: $(SRCS_SV)
	touch .comp_sv.timestamp
endif

ifneq ($(SRCS_VHDL),)
.comp_vhdl.timestamp: $(SRCS_VHDL)
	@echo
	@echo "$(BLUE)comp: $(VHDL_CMD_LINE)$(DEFAULT)"
	eval $(VHDL_CMD_LINE)
	touch .comp_vhdl.timestamp
else
.comp_vhdl.timestamp:
	touch .comp_vhdl.timestamp
endif

waves: xsim.snapshot.wdb
	xsim -g xsim.snapshot.wdb -t load_waves.tcl

clean:
	rm -rf *.jou *.log *.pb *.wdb xsim.dir
	rm -rf .*.timestamp .Xil
