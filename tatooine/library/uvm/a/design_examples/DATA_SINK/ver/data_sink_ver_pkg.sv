package data_sink_ver_pkg;
    // AXI4 includes
    import axi4_pkg::*;
    import axi4s_agent_pkg::*;

    // UVM includes
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Verification includes
    `include "data_sink_ref_model.sv"
    `include "data_sink_scoreboard.sv"
    `include "data_sink_env.sv"

    // Tests includes
    `include "data_sink_48x256_random_test.sv"
endpackage

// Whitebox interface to DUT's internals
`include "data_sink_whitebox_if.sv"
