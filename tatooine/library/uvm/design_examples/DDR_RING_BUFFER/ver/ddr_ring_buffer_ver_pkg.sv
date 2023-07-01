package ddr_ring_buffer_ver_pkg;
    // AXI4 includes
    import axi4_pkg::*;
    import axi4s_agent_pkg::*;

    // UVM includes
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Verification includes
    `include "ddr_ring_buffer_scoreboard.sv"
    `include "ddr_ring_buffer_env.sv"

    // Tests includes
    `include "ddr_ring_buffer_random_test.sv"
endpackage

// DUT-specific output interface
`include "ddr_ring_buffer_out_if.sv"
