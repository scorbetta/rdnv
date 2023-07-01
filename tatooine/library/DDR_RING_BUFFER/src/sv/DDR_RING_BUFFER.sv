`timescale 1ns/100ps
//`define AXI3

// This module provides a mechanism to manage a portion of DDR memory as a ring
// buffer. Writes and reads are managed like in a FIFO in a transparent way
module DDR_RING_BUFFER #(
    parameter AXI_ID_WIDTH      = 1,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_DATA_WIDTH    = 32,
    parameter DRAIN_BURST_LEN   = 128,
    parameter STAGE_FIFOS_DEPTH = 256,
    parameter EXTERNAL_READ_ITF = 0
)
(
    input	                                                S_AXI_ACLK,
    input	                                                S_AXI_ARESETN,
    // AXI4 Stream Write interface
    axi4s_if.slave                                          IFIFO_AXI_PORT,
    // AXI4 Stream Read interface
    axi4s_if.master                                         OFIFO_AXI_PORT,
    // DDR MIG interface
`ifdef AXI3
    axi3f_if.master                                         DDR_CTRL_AXI_PORT,
`else
    axi4f_if.master                                         DDR_CTRL_AXI_PORT,
`endif
    // Configuration
    input [31:0]                                            RING_BUFFER_LEN,
    input [31:0]                                            AXI_BASE_ADDR,
    input [31:0]                                            AXI_ADDR_MASK,
    // Miscellanea
    input				                                    SOFT_RSTN,
    output				                                    MM2S_FULL,
    output				                                    EMPTY,
    output [AXI_ADDR_WIDTH-($clog2(AXI_DATA_WIDTH)-3):0]    CORE_FILL,
    output [$clog2(STAGE_FIFOS_DEPTH):0]                    IFIFO_FILL,
    output                                                  IFIFO_FULL,
    output [$clog2(STAGE_FIFOS_DEPTH):0]                    OFIFO_FILL,
    output                                                  DATA_LOSS,
    output [AXI_ADDR_WIDTH-1:0]                             RING_BUFFER_WPTR,
    output [AXI_ADDR_WIDTH-1:0]                             RING_BUFFER_RPTR,
    output [31:0]                                           WRITE_OFFSET,
    input                                                   CLEAR_EOB,
    output                                                  DDR_EOB
);

    logic           eob;
    logic           eob_r1;
    logic           eob_stretched;

    // AXI Virtual FIFO core decouples in a smart way user stream from DDR
    // stream. There is no requirement on the rate of data at the input FIFO
    // interface, since DDR engine will drain data at fixed bursts. The core
    // works as follows.
    //
    // An input FIFO receives data through the Stream interface and data is
    // eventually drained to the DDR memory through the FUll interface.
    //
    // DDR access happens in fixed bursts determined by the two parameters
    //  C_AXI_DATA_WIDTH  and  LGMAXBURST  . When the input FIFO contains
    //  2^LGMAXBURST  entries a DDR Write burst is initiated; in total
    //  2^LGMAXBURST*(C_AXI_DATA_WIDTH/4)  Bytes are written.
    //
    // The output FIFO is then used to stage data from the DDR, ready for the
    // user. Data is drained from the DDR into the output FIFO if there is space
    // in the FIFO and after a Write response.
    //
    // The Write and Read addresses will wrap according to the  RING_BUFFER_LEN
    // parameter. This determines the number of slots in the DDR buffer. Slots
    // have the size of a burst. So that, the dedicated DDR range for the ring
    // buffer contains exaclty 
    //      RING_BUFFER_LEN * (2^LGMAXBURST * (C_AXI_DATA_WIDTH/4))
    // Bytes.
    AXIVFIFO #(
        // AXI bus configuration
        .C_AXI_ID_WIDTH     (AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH   (AXI_DATA_WIDTH),
        // Determines when the data will be pushed to DDR
        .LGMAXBURST         ($clog2(DRAIN_BURST_LEN)),
        // Depth of the input and output FIFOs
        .LGFIFO             ($clog2(STAGE_FIFOS_DEPTH)),
        .EXTERNAL_READ_ITF  (EXTERNAL_READ_ITF)
    )
    AXIVFIFO_CORE (
        // Clock and reset
        .S_AXI_ACLK         (S_AXI_ACLK),
        .S_AXI_ARESETN      (S_AXI_ARESETN),
        // Input FIFO interface
        .IFIFO_AXI_PORT     (IFIFO_AXI_PORT),
        // Output FIFO interface
        .OFIFO_AXI_PORT     (OFIFO_AXI_PORT),
        // DDR interface
        .DDR_CTRL_AXI_PORT  (DDR_CTRL_AXI_PORT),
        .RING_BUFFER_LEN    (RING_BUFFER_LEN),
        .AXI_BASE_ADDR      (AXI_BASE_ADDR),        
        .AXI_ADDR_MASK      (AXI_ADDR_MASK),
        .SOFT_RST           (~SOFT_RSTN),
        .OVERFLOW           (), // Unused
        .MM2S_FULL          (MM2S_FULL),
        .VFIFO_EMPTY        (EMPTY),
        .VFIFO_FILL         (CORE_FILL),
        .IFIFO_FILL         (IFIFO_FILL),
        .IFIFO_FULL         (IFIFO_FULL),
        .OFIFO_FILL         (OFIFO_FILL),
        .DATA_LOSS          (DATA_LOSS),
        .WPTR               (RING_BUFFER_WPTR),
        .RPTR               (RING_BUFFER_RPTR),
        .EOB                (eob),
        .WRITE_OFFSET       (WRITE_OFFSET)
    );
    
    // Safely detect a rising edge over the End-of-Burst signal from the DDR FIFO logic
    always_ff @(posedge S_AXI_ACLK) begin
        eob_r1 <= eob;
    end  
    
    // Stretch the End-of-burst signal upon detecting a rising edge from the DDR FIFO logic
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN || CLEAR_EOB) begin
            eob_stretched <= 1'b0;
        end
        else if(eob && !eob_r1 && !eob_stretched) begin
            eob_stretched <= 1'b1;
        end
    end
    
    // Pinout
    assign DDR_EOB = eob_stretched;
endmodule
