`timescale 1ns/100ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import axi4_pkg::*;
import ddr_ring_buffer_ver_pkg::*;

module ddr_ring_buffer_uvm_tb;
    // Signals
    logic           clk;
    logic           rst;
    logic           rstn;

    axi4s_if #(
        .DATA_WIDTH (64)
    )
    ififo_axi_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    axi4s_if #(
        .DATA_WIDTH (64)
    )
    ofifo_axi_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    axi4f_if #(
        .DATA_WIDTH (64),
        .ADDR_WIDTH (16),
        .ID_WIDTH   (4)
    )
    ddr_ctrl_axi_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );
    
    ddr_ring_buffer_out_if #(
        .AXI_ADDR_WIDTH     (16),
        .AXI_DATA_WIDTH     (64),
        .STAGE_FIFOS_DEPTH  (512)
    )
    dut_out_if ();

    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (5),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (rst),
        .USER_RSTN  (rstn)
    );
    
    // DUT
    DDR_RING_BUFFER #(
        .AXI_ID_WIDTH       (4),
        .AXI_ADDR_WIDTH     (16),
        .AXI_DATA_WIDTH     (64),
        .DRAIN_BURST_LEN    (256),
        .STAGE_FIFOS_DEPTH  (512),
        .EXTERNAL_READ_ITF  (0)
    )
    DDR_RING_BUFFER (
        .S_AXI_ACLK         (clk),
        .S_AXI_ARESETN      (rstn),
        .IFIFO_AXI_PORT     (ififo_axi_port),
        .OFIFO_AXI_PORT     (ofifo_axi_port),
        .DDR_CTRL_AXI_PORT  (ddr_ctrl_axi_port),
        .SOFT_RSTN          (1'b1),
        .MM2S_FULL          (dut_out_if.mm2s_full),
        .EMPTY              (dut_out_if.empty),
        .CORE_FILL          (dut_out_if.core_fill),
        .IFIFO_FILL         (dut_out_if.ififo_fill),
        .IFIFO_FULL         (dut_out_if.ififo_full),
        .OFIFO_FILL         (dut_out_if.ofifo_fill),
        .DATA_LOSS          (dut_out_if.data_loss),
        .RING_BUFFER_WPTR   (dut_out_if.ring_buffer_wptr),
        .RING_BUFFER_RPTR   (dut_out_if.ring_buffer_rptr),
        .WRITE_OFFSET       (dut_out_if.write_offset),
        .AXI_BASE_ADDR      (dut_out_if.axi_base_addr),
        .RING_BUFFER_LEN    (dut_out_if.ring_buffer_len),
        .AXI_ADDR_MASK      (dut_out_if.axi_addr_mask),
        .CLEAR_EOB          (1'b0),
        .DDR_EOB            (dut_out_if.ddr_eob)
    );

    // Simulate DDR controller plus DDR memory
    axi_ram #(
        .DATA_WIDTH         (64),
        .ADDR_WIDTH         (16),
        .STRB_WIDTH         (64/8),
        .ID_WIDTH           (4),
        .PIPELINE_OUTPUT    (1)
    )
    DDR_RAM (
        .clk            (clk),
        .rst            (rst),
        .s_axi_awid     (ddr_ctrl_axi_port.awid),
        .s_axi_awaddr   (ddr_ctrl_axi_port.awaddr),
        .s_axi_awlen    (ddr_ctrl_axi_port.awlen),
        .s_axi_awsize   (ddr_ctrl_axi_port.awsize),
        .s_axi_awburst  (ddr_ctrl_axi_port.awburst),
        .s_axi_awlock   (ddr_ctrl_axi_port.awlock),
        .s_axi_awcache  (ddr_ctrl_axi_port.awcache),
        .s_axi_awprot   (ddr_ctrl_axi_port.awprot),
        .s_axi_awvalid  (ddr_ctrl_axi_port.awvalid),
        .s_axi_awready  (ddr_ctrl_axi_port.awready),
        .s_axi_wdata    (ddr_ctrl_axi_port.wdata),
        .s_axi_wstrb    (ddr_ctrl_axi_port.wstrb),
        .s_axi_wlast    (ddr_ctrl_axi_port.wlast),
        .s_axi_wvalid   (ddr_ctrl_axi_port.wvalid),
        .s_axi_wready   (ddr_ctrl_axi_port.wready),
        .s_axi_bid      (ddr_ctrl_axi_port.bid),
        .s_axi_bresp    (ddr_ctrl_axi_port.bresp),
        .s_axi_bvalid   (ddr_ctrl_axi_port.bvalid),
        .s_axi_bready   (ddr_ctrl_axi_port.bready),
        .s_axi_arid     (ddr_ctrl_axi_port.arid),
        .s_axi_araddr   (ddr_ctrl_axi_port.araddr),
        .s_axi_arlen    (ddr_ctrl_axi_port.arlen),
        .s_axi_arsize   (ddr_ctrl_axi_port.arsize),
        .s_axi_arburst  (ddr_ctrl_axi_port.arburst),
        .s_axi_arlock   (ddr_ctrl_axi_port.arlock),
        .s_axi_arcache  (ddr_ctrl_axi_port.arcache),
        .s_axi_arprot   (ddr_ctrl_axi_port.arprot),
        .s_axi_arvalid  (ddr_ctrl_axi_port.arvalid),
        .s_axi_arready  (ddr_ctrl_axi_port.arready),
        .s_axi_rid      (ddr_ctrl_axi_port.rid),
        .s_axi_rdata    (ddr_ctrl_axi_port.rdata),
        .s_axi_rresp    (ddr_ctrl_axi_port.rresp),
        .s_axi_rlast    (ddr_ctrl_axi_port.rlast),
        .s_axi_rvalid   (ddr_ctrl_axi_port.rvalid),
        .s_axi_rready   (ddr_ctrl_axi_port.rready)
    );

    // Static configuration
    assign dut_out_if.axi_base_addr     = 32'h00000000;
    assign dut_out_if.ring_buffer_len   = 32'd4;
    assign dut_out_if.axi_addr_mask     = 32'h00001fff;

    // UVM
    initial begin
        // Setup
        uvm_config_db#(virtual axi4s_if#(64))::set(null, "uvm_test_top.env.ififo_agent.driver", "vif", ififo_axi_port);
        uvm_config_db#(virtual axi4s_if#(64))::set(null, "uvm_test_top.env.ofifo_agent.driver", "vif", ofifo_axi_port);
        uvm_config_db#(virtual ddr_ring_buffer_out_if#(16,64,512))::set(null, "uvm_test_top.env.sb", "dut_vif", dut_out_if);

        // Run test
        run_test();
    end

    // Bounded simulation
    initial begin
        repeat(1e4) @(posedge clk);
        $finish();
    end    
endmodule
