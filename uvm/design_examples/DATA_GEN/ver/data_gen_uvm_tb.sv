`include "uvm_macros.svh"
import uvm_pkg::*;
import axi4_pkg::*;

module data_gen_uvm_tb;
    bit clk;
    bit rstn;

    axi4s_if #(
        .DATA_WIDTH (32)
    )
    data_port (
        .aclk       (clk),
        .aresetn    (rstn)
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
    DATA_GEN DUT (
        .ACLK       (clk),
        .ARESETN    (rstn),
        .CFG_VALID  (cfg_valid),
        .CFG_DATA   (cfg_data),
        .START      (start),
        .AXIS_PORT  (data_port)
    );

    // Make a simple Slave
    always_ff @(posedge clk) begin
        if(!rstn) begin
            data_port.tready <= 1'b0;
        end
        else begin
            data_port.tready <= 1'b0;
            
            if(data_port.tvalid && !data_port.tready) begin
                data_port.tready <= 1'b1;
            end
        end
    end

    // UVM configuration section
    initial begin
        // Add the  data_port  interface to the database
        uvm_config_db#(virtual axi4s_if#(.DATA_WIDTH(32)))::set(uvm_root::get(), "*", "dut_vif_in", data_port);
    end

    // UVM test run section
    initial begin
        run_test("data_gen_random_test");
    end

    // Max simulation time
    initial begin
        repeat(1e3) @(posedge clk);
        $finish;
    end
endmodule
