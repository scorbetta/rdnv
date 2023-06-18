package axi4s_agent_pkg;
    // AXI4 includes
    import axi4_pkg::*;

    // UVM includes
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Base includes
    `include "components/axi4s_seq_item.sv"
    `include "components/generic_seqr.sv"
    `include "components/axi4s_driver.sv"

    // Master agent includes
    `include "components/axi4s_master_seq_item_cfg.sv"
    `include "components/axi4s_master_seq_item.sv"
    `include "components/axi4s_master_seq.sv"
    `include "components/axi4s_master_driver.sv"
    `include "components/axi4s_master_agent.sv"

    // Slave agent includes
    `include "components/axi4s_slave_seq_item.sv"
    `include "components/axi4s_slave_seq.sv"
    `include "components/axi4s_slave_driver.sv"
    `include "components/axi4s_slave_agent.sv"
endpackage
