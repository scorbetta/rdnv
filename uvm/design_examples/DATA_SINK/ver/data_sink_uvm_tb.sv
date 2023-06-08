`include "uvm_macros.svh"
import uvm_pkg::*;
import axi4_pkg::*;
import data_sink_ver_pkg::*;

module data_sink_uvm_tb;
    // Connections
    bit         clk;
    bit         rstn;
    bit [31:0]  cfg_data;
    bit         cfg_valid;
    bit         start;

    // DUT AXI4 Stream Slave interface
    axi4s_if #(
        .DATA_WIDTH (48)
    )
    data_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    // Binding is a way in SystemVerilog of creating an instance of a module inside of another one
    // without requiring access to the module to which you are binding

    // Bind whitebox interface to DUT's internals probe interface will create an instance of the
    //  data_sink_whitebox_if  interface within the  DUT  design module. The port mapping provided
    // will then close the loop by allowing us to acess DUT internals without modifying the DUT
    // design itself!
    //
    //   bind <design_module> <external_module> <instantiation_name> <design_module_variables>
    bind DUT data_sink_whitebox_if #(
        .DATA_WIDTH (48),
        .RAM_DEPTH  (256)
    )
    ver_if (
        .row    (DUT.row),
        .ram    (DUT.ram)
    );

    // Protocol checkers from ARM
    Axi4StreamPC #(
        .DATA_WIDTH_BYTES   (6),
        .MAXWAITS           (16), // Maximum number of cycles between VALID -> READY high before a warning is generated
        .RecommendOn        (1'b1),
        .RecMaxWaitOn       (1'b1)
    )
    AXI4S_PC (
        .ACLK       (clk),
        .ARESETn    (rstn),
        .TDATA      (data_port.tdata),
        .TLAST      (data_port.tlast),
        .TVALID     (data_port.tvalid),
        .TREADY     (data_port.tready)
    );

    // Clock and reset
    initial begin
        clk = 0;
        forever begin
            #2.0 clk = ~clk;
        end
    end

    initial begin
        rstn = 1'b0;
        repeat(10) @(posedge clk);
        rstn = 1'b1;
    end

    // DUT
    DATA_SINK #(
        .DATA_WIDTH (48),
        .RAM_DEPTH  (256)
    )
    DUT (
        .ACLK       (clk),
        .ARESETN    (rstn),
        .AXIS_PORT  (data_port)
    );

    // UVM setup
    initial begin
        // Add the  data_port  interface to the database
        uvm_config_db#(virtual axi4s_if#(48))::set(null, "*", "dut_vif_in", data_port);
        // Set whitebox interface
        uvm_config_db#(virtual data_sink_whitebox_if#(48,256))::set(null, "*", "dut_ver_if", DUT.ver_if);
        // Test name comes from command line
        run_test();
    end

    // Max simulation time
    initial begin
        repeat(1e3) @(posedge clk);
        $finish;
    end
endmodule
