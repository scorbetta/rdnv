`default_nettype none

// This module provides a mechanism to manage a portion of DDR memory as a ring buffer. Writes and
// reads are managed like in a FIFO in a transparent way. Adapted w/ modifications by Simone
// Corbetta PhD from the design of Dan Gisselquist, Ph.D., Gisselquist Technology
module DDR_RING_BUFFER #(
    parameter AXI_ID_WIDTH      = 1,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter DATA_WIDTH        = 32,
    parameter DRAIN_BURST_LEN   = 128,
    parameter EXTERNAL_READ_ITF = 0
)
(
    input wire                                              CLK,
    input wire                                              RSTN,
    input wire                                              IFIFO_AXI_PORT_TVALID,
    output wire                                             IFIFO_AXI_PORT_TREADY,
    input wire [DATA_WIDTH-1:0]                             IFIFO_AXI_PORT_TDATA,
    output wire                                             OFIFO_AXI_PORT_TVALID,
    input wire                                              OFIFO_AXI_PORT_TREADY,
    output wire [DATA_WIDTH-1:0]                            OFIFO_AXI_PORT_TDATA,
    output wire                                             DDR_CTRL_AXI_PORT_AWVALID,
    input wire                                              DDR_CTRL_AXI_PORT_AWREADY,
    output wire [AXI_ID_WIDTH-1:0]                          DDR_CTRL_AXI_PORT_AWID,
    output wire [AXI_ADDR_WIDTH-1:0]                        DDR_CTRL_AXI_PORT_AWADDR,
    output wire [7:0]                                       DDR_CTRL_AXI_PORT_AWLEN,
    output wire [2:0]                                       DDR_CTRL_AXI_PORT_AWSIZE,
    output wire [1:0]                                       DDR_CTRL_AXI_PORT_AWBURST,
    output wire                                             DDR_CTRL_AXI_PORT_AWLOCK,
    output wire [3:0]                                       DDR_CTRL_AXI_PORT_AWCACHE,
    output wire [2:0]                                       DDR_CTRL_AXI_PORT_AWPROT,
    output wire [3:0]                                       DDR_CTRL_AXI_PORT_AWQOS,
    output wire                                             DDR_CTRL_AXI_PORT_WVALID,
    input wire                                              DDR_CTRL_AXI_PORT_WREADY,
    output wire [AXI_ID_WIDTH-1:0]                          DDR_CTRL_AXI_PORT_WID,
    output wire [DATA_WIDTH-1:0]                            DDR_CTRL_AXI_PORT_WDATA,
    output wire [DATA_WIDTH/8-1:0]                          DDR_CTRL_AXI_PORT_WSTRB,
    output wire                                             DDR_CTRL_AXI_PORT_WLAST,
    input wire                                              DDR_CTRL_AXI_PORT_BVALID,
    output wire                                             DDR_CTRL_AXI_PORT_BREADY,
    input wire [AXI_ID_WIDTH-1:0]                           DDR_CTRL_AXI_PORT_BID,
    input wire [1:0]                                        DDR_CTRL_AXI_PORT_BRESP,
    output wire                                             DDR_CTRL_AXI_PORT_ARVALID,
    input wire                                              DDR_CTRL_AXI_PORT_ARREADY,
    output wire [AXI_ID_WIDTH-1:0]                          DDR_CTRL_AXI_PORT_ARID,
    output wire [AXI_ADDR_WIDTH-1:0]                        DDR_CTRL_AXI_PORT_ARADDR,
    output wire [7:0]                                       DDR_CTRL_AXI_PORT_ARLEN,
    output wire [2:0]                                       DDR_CTRL_AXI_PORT_ARSIZE,
    output wire [1:0]                                       DDR_CTRL_AXI_PORT_ARBURST,
    output wire                                             DDR_CTRL_AXI_PORT_ARLOCK,
    output wire [3:0]                                       DDR_CTRL_AXI_PORT_ARCACHE,
    output wire [2:0]                                       DDR_CTRL_AXI_PORT_ARPROT,
    output wire [3:0]                                       DDR_CTRL_AXI_PORT_ARQOS,
    input wire                                              DDR_CTRL_AXI_PORT_RVALID,
    output wire                                             DDR_CTRL_AXI_PORT_RREADY,
    input wire [AXI_ID_WIDTH-1:0]                           DDR_CTRL_AXI_PORT_RID,
    input wire [DATA_WIDTH-1:0]                             DDR_CTRL_AXI_PORT_RDATA,
    input wire                                              DDR_CTRL_AXI_PORT_RLAST,
    input wire [1:0]                                        DDR_CTRL_AXI_PORT_RRESP,
    input wire [31:0]                                       RING_BUFFER_LEN,
    input wire [31:0]                                       AXI_BASE_ADDR,
    input wire [31:0]                                       AXI_ADDR_MASK,
    input wire                                              SOFT_RSTN,
    output wire                                             MM2S_FULL,
    output wire                                             EMPTY,
    output wire [AXI_ADDR_WIDTH-($clog2(DATA_WIDTH)-3):0]   CORE_FILL,
    output wire [$clog2(DRAIN_BURST_LEN*2):0]               IFIFO_FILL,
    output wire                                             IFIFO_FULL,
    output wire [$clog2(DRAIN_BURST_LEN*2):0]               OFIFO_FILL,
    output wire                                             DATA_LOSS,
    output wire [AXI_ADDR_WIDTH-1:0]                        RING_BUFFER_WPTR,
    output wire [AXI_ADDR_WIDTH-1:0]                        RING_BUFFER_RPTR,
    output wire [31:0]                                      WRITE_OFFSET,
    input wire                                              CLEAR_EOB,
    output wire                                             DDR_EOB
);

    wire    eob;
    reg     eob_r1;
    reg     eob_stretched;

    // AXI Virtual FIFO core decouples in a smart way user stream from DDR
    // stream. There is no requirement on the rate of data at the input FIFO
    // interface, since DDR engine will drain data at fixed bursts. The core
    // works as follows.
    //
    // An input FIFO receives data through the Stream interface and data is
    // eventually drained to the DDR memory through the FUll interface.
    //
    // DDR access happens in fixed bursts determined by the two parameters
    //  AXI_DATA_WIDTH  and  LGMAXBURST  . When the input FIFO contains
    //  2^LGMAXBURST  entries a DDR Write burst is initiated; in total
    //  2^LGMAXBURST*(AXI_DATA_WIDTH/4)  Bytes are written.
    //
    // The output FIFO is then used to stage data from the DDR, ready for the
    // user. Data is drained from the DDR into the output FIFO if there is space
    // in the FIFO and after a Write response.
    //
    // The Write and Read addresses will wrap according to the  RING_BUFFER_LEN
    // parameter. This determines the number of slots in the DDR buffer. Slots
    // have the size of a burst. So that, the dedicated DDR range for the ring
    // buffer contains exaclty 
    //      RING_BUFFER_LEN * (2^LGMAXBURST * (AXI_DATA_WIDTH/4))
    // Bytes.
    AXIVFIFO #(
        .AXI_ID_WIDTH       (AXI_ID_WIDTH),
        .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH     (DATA_WIDTH),
        .LGMAXBURST         ($clog2(DRAIN_BURST_LEN)),
        .EXTERNAL_READ_ITF  (EXTERNAL_READ_ITF)
    )
    AXIVFIFO_CORE (
        .CLK                (CLK),
        .RSTN               (RSTN),
        .S_AXIS_TVALID      (IFIFO_AXI_PORT_TVALID),
        .S_AXIS_TREADY      (IFIFO_AXI_PORT_TREADY),
        .S_AXIS_TDATA       (IFIFO_AXI_PORT_TDATA),
        .M_AXIS_TVALID      (OFIFO_AXI_PORT_TVALID),
        .M_AXIS_TREADY      (OFIFO_AXI_PORT_TREADY),
        .M_AXIS_TDATA       (OFIFO_AXI_PORT_TDATA),
        .M_AXI_AWVALID      (DDR_CTRL_AXI_PORT_AWVALID),
        .M_AXI_AWREADY      (DDR_CTRL_AXI_PORT_AWREADY),
        .M_AXI_AWID         (DDR_CTRL_AXI_PORT_AWID),
        .M_AXI_AWADDR       (DDR_CTRL_AXI_PORT_AWADDR),
        .M_AXI_AWLEN        (DDR_CTRL_AXI_PORT_AWLEN),
        .M_AXI_AWSIZE       (DDR_CTRL_AXI_PORT_AWSIZE),
        .M_AXI_AWBURST      (DDR_CTRL_AXI_PORT_AWBURST),
        .M_AXI_AWLOCK       (DDR_CTRL_AXI_PORT_AWLOCK),
        .M_AXI_AWCACHE      (DDR_CTRL_AXI_PORT_AWCACHE),
        .M_AXI_AWPROT       (DDR_CTRL_AXI_PORT_AWPROT),
        .M_AXI_AWQOS        (DDR_CTRL_AXI_PORT_AWQOS),
        .M_AXI_WVALID       (DDR_CTRL_AXI_PORT_WVALID),
        .M_AXI_WREADY       (DDR_CTRL_AXI_PORT_WREADY),
        .M_AXI_WID          (DDR_CTRL_AXI_PORT_WID),
        .M_AXI_WDATA        (DDR_CTRL_AXI_PORT_WDATA),
        .M_AXI_WSTRB        (DDR_CTRL_AXI_PORT_WSTRB),
        .M_AXI_WLAST        (DDR_CTRL_AXI_PORT_WLAST),
        .M_AXI_BVALID       (DDR_CTRL_AXI_PORT_BVALID),
        .M_AXI_BREADY       (DDR_CTRL_AXI_PORT_BREADY),
        .M_AXI_BID          (DDR_CTRL_AXI_PORT_BID),
        .M_AXI_BRESP        (DDR_CTRL_AXI_PORT_BRESP),
        .M_AXI_ARVALID      (DDR_CTRL_AXI_PORT_ARVALID),
        .M_AXI_ARREADY      (DDR_CTRL_AXI_PORT_ARREADY),
        .M_AXI_ARID         (DDR_CTRL_AXI_PORT_ARID),
        .M_AXI_ARADDR       (DDR_CTRL_AXI_PORT_ARADDR),
        .M_AXI_ARLEN        (DDR_CTRL_AXI_PORT_ARLEN),
        .M_AXI_ARSIZE       (DDR_CTRL_AXI_PORT_ARSIZE),
        .M_AXI_ARBURST      (DDR_CTRL_AXI_PORT_ARBURST),
        .M_AXI_ARLOCK       (DDR_CTRL_AXI_PORT_ARLOCK),
        .M_AXI_ARCACHE      (DDR_CTRL_AXI_PORT_ARCACHE),
        .M_AXI_ARPROT       (DDR_CTRL_AXI_PORT_ARPROT),
        .M_AXI_ARQOS        (DDR_CTRL_AXI_PORT_ARQOS),
        .M_AXI_RVALID       (DDR_CTRL_AXI_PORT_RVALID),
        .M_AXI_RREADY       (DDR_CTRL_AXI_PORT_RREADY),
        .M_AXI_RID          (DDR_CTRL_AXI_PORT_RID),
        .M_AXI_RDATA        (DDR_CTRL_AXI_PORT_RDATA),
        .M_AXI_RLAST        (DDR_CTRL_AXI_PORT_RLAST),
        .M_AXI_RRESP        (DDR_CTRL_AXI_PORT_RRESP),
        .i_reset            (~SOFT_RSTN),
        .o_overflow         (), // Unused
        .o_mm2s_full        (MM2S_FULL),
        .o_empty            (EMPTY),
        .o_fill             (CORE_FILL),
        .ififo_fill_o       (IFIFO_FILL),
        .ififo_full_o       (IFIFO_FULL),
        .ofifo_fill_o       (OFIFO_FILL),
        .DATA_LOSS          (DATA_LOSS),
        .wptr               (RING_BUFFER_WPTR),
        .rptr               (RING_BUFFER_RPTR),
        .RING_BUFFER_LEN    (RING_BUFFER_LEN),
        .AXI_BASE_ADDR      (AXI_BASE_ADDR),
        .AXI_ADDR_MASK      (AXI_ADDR_MASK),
        .EOB                (eob),
        .WRITE_OFFSET       (WRITE_OFFSET)
    );

    // Safely detect a rising edge over the End-of-Burst signal from the DDR FIFO logic
    always @(posedge CLK) begin
        eob_r1 <= eob;
    end  
    
    // Stretch the End-of-burst signal upon detecting a rising edge from the DDR FIFO logic
    always @(posedge CLK) begin
        if(!RSTN || CLEAR_EOB) begin
            eob_stretched <= 1'b0;
        end
        else if(eob && !eob_r1 && !eob_stretched) begin
            eob_stretched <= 1'b1;
        end
    end
    
    // Pinout
    assign DDR_EOB = eob_stretched;
endmodule

`default_nettype wire
