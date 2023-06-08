import axi4s_agent_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

class data_gen_environment extends uvm_env;
    `uvm_component_utils(data_gen_environment)
    axi4s_master_agent master_agent;
    //adder_4_bit_ref_model ref_model;
    //adder_4_bit_coverage#(adder_4_bit_transaction) coverage;
    //adder_4_bit_scoreboard  sb;
       
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master_agent = axi4s_master_agent::type_id::create("master_agent", this);
        //ref_model = adder_4_bit_ref_model::type_id::create("ref_model", this);
        //coverage = adder_4_bit_coverage#(adder_4_bit_transaction)::type_id::create("coverage", this);
        //sb = adder_4_bit_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //agent.driver.drv2rm_port.connect(ref_model.rm_export);
        //adder_4_bit_agnt.monitor.mon2sb_port.connect(sb.mon2sb_export);
        //ref_model.rm2sb_port.connect(coverage.analysis_export);
        //ref_model.rm2sb_port.connect(sb.rm2sb_export);
    endfunction
endclass
