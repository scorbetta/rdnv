# PHONY targets that are not files
.PHONY: sim elab waves clean

# Include dependencies setup
include ${ROOT}/scripts/Makefile.deps

# Include Makefile utilities
include ${ROOT}/scripts/Makefile.utils

# Libraries
STD_LIBS = unisims_ver unimacro_ver secureip
ALL_LIBS = $(STD_LIBS) $(USER_LIBS)
LIBS = $(patsubst %, -L %, $(ALL_LIBS))

# Include folders for Verilog and SystemVerilog
STD_INCLUDES = 
ALL_INCLUDES = $(STD_INCLUDES) $(USER_INCLUDES)
INCLUDES = $(patsubst %, --include %, $(ALL_INCLUDES))

# Compilation and elaboration steps options
ELAB_OPTS = --nolog --debug all --timescale 1ns/100ps $(LIBS) --prj $(TOP).prj $(ELAB_USER_OPTS)
ELAB_CMD_LINE := xelab $(ELAB_OPTS) --snapshot xsim.snapshot xil_defaultlib.$(TOP)

# Simulation setup
SIM_OPTS = --nolog --sv_seed $(shell date +%N) --testplusarg UVM_TESTNAME=$(UVM_TESTNAME)
SIM_CMD_LINE := xsim $(SIM_OPTS) --tclbatch $(SCRIPTS_DIR)/xsim.in xsim.snapshot

# Open waves
WAVES_CMD_LINE = xsim -g xsim.snapshot.wdb -t load_waves.tcl

# Remove output products
CLEAN_CMD_LINE = rm -rf *.jou *.log *.pb *.wdb xsim.dir xsim.covdb .*.timestamp .Xil *.prj .temp

# Compile, elaborate and simulate
sim: elab
	@echo "$(BLUE)sim: $(SIM_CMD_LINE)$(DEFAULT)"
	@eval $(SIM_CMD_LINE)

# Compile and elaborate only
elab: .elab.timestamp

.elab.timestamp: $(TOP).prj
	@echo "$(BLUE)elab: $(ELAB_CMD_LINE)$(DEFAULT)"
	@eval $(ELAB_CMD_LINE)
	@touch $@

# Create the  .prj  file keeping the ordering of rtl, sim and ver sources
$(TOP).prj: $(IN_FILES_TSTAMP)
	@grep -hvw "^\s*$$" $^ | tr " " "\n" | awk '!visited[$$0]++' > $@
	@sed -i "s@^\(.*\.v\)\$$@verilog xil_defaultlib \1@g" $@
	@sed -i "s@^\(.*\.sv\)\$$@sv xil_defaultlib \1@g" $@
	@sed -i "s@^\(.*\.vhd\)\$$@vhdl2008 xil_defaultlib \1@g" $@

# Create temporary files storing rtl, sim and ver sources
.%.timestamp: %.list
	@sed "s@^\([^$$/].*\)\$$@$(PREFIX)\/\1@g" $< > $@

waves: xsim.snapshot.wdb
	@echo "$(BLUE)waves: $(WAVES_CMD_LINE)$(DEFAULT)"
	@eval $(WAVES_CMD_LINE)

clean:
	@echo "$(BLUE)clean: $(CLEAN_CMD_LINE)$(DEFAULT)"
	@eval $(CLEAN_CMD_LINE)
