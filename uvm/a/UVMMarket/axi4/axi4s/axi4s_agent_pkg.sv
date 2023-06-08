package axi4s_agent_pkg;
    // AXI4 includes
    import axi4_pkg::*;

    // UVM includes
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Agent includes
    `include "components/axi4s_seq_item.sv"
    `include "components/axi4s_seq.sv"
    `include "components/axi4s_seqr.sv"
    `include "components/axi4s_master_driver.sv"
    `include "components/axi4s_monitor.sv"
    `include "components/axi4s_master_agent.sv"
endpackage
