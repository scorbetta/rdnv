interface ddr_ring_buffer_out_if
#(
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_DATA_WIDTH    = 32,
    parameter STAGE_FIFOS_DEPTH = 256
);

    // Non-standard signals to monitor from the DUT interface
    logic [31:0]                                        ring_buffer_len;
    logic [31:0]                                        axi_base_addr;
    logic [31:0]                                        axi_addr_mask;
    logic       			                soft_rstn;
    logic 				                mm2s_full;
    logic 				                empty;
    logic [AXI_ADDR_WIDTH-($clog2(AXI_DATA_WIDTH)-3):0] core_fill;
    logic [$clog2(STAGE_FIFOS_DEPTH):0]                 ififo_fill;
    logic                                               ififo_full;
    logic [$clog2(STAGE_FIFOS_DEPTH):0]                 ofifo_fill;
    logic                                               data_loss;
    logic [AXI_ADDR_WIDTH-1:0]                          ring_buffer_wptr;
    logic [AXI_ADDR_WIDTH-1:0]                          ring_buffer_rptr;
    logic [31:0]                                        write_offset;
    logic                                               clear_eob;
    logic                                               ddr_eob;
endinterface
