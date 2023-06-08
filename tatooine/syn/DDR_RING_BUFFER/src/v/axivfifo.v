`timescale 1ns/100ps
//`define AXI3

// Adapted from the design by Dan Gisselquist, Ph.D., Gisselquist Technology, with modifications by
// Simone Corbetta, Ph. D. Nuclear Instruments
module AXIVFIFO #(
    parameter C_AXI_ID_WIDTH    = 1,
    parameter C_AXI_ADDR_WIDTH  = 32,
    parameter C_AXI_DATA_WIDTH  = 32,
    // LGMAXBURST determines the size of the maximum AXI burst, beware of the differences in AXI3 
    // and AXI4, plus the 4KiB constraint
`ifdef	AXI3
    parameter GMAXBURST         = 4,
`else
    parameter LGMAXBURST        = 8,
`endif
    // LGFIFO: This is the (log-based-2) size of the internal FIFO. High throughput transfers are
    // accomplished by first storing data into a FIFO, then once a full burst size is available 
    // bursting that data over the bus. In order to be able to keep receiving data while bursting
    // it out, the FIFO size must be at least twice the size of the maximum burst size
    parameter LGFIFO            = LGMAXBURST + 1,
    // Beware of the wolf
    parameter EXTERNAL_READ_ITF = 0
)
(
    // Clock and reset
    input                           S_AXI_ACLK,
    input                           S_AXI_ARESETN,
    // AXI4 Stream input interface
    input                           S_AXIS_TVALID,
    output                          S_AXIS_TREADY,
    input    [C_AXI_DATA_WIDTH-1:0] S_AXIS_TDATA,
    // AXI4 Stream output interface
    output                          M_AXIS_TVALID,
    input                           M_AXIS_TREADY,
    output   [C_AXI_DATA_WIDTH-1:0] M_AXIS_TDATA,
    // AXI4 Full DMA interface
    output                          M_AXI_AWVALID,
    input                           M_AXI_AWREADY,
    output   [C_AXI_ID_WIDTH-1:0]   M_AXI_AWID,
    output   [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
`ifdef	AXI3
    output [3:0]			        M_AXI_AWLEN,
`else
    output [7:0]			        M_AXI_AWLEN,
`endif
    output [2:0]                    M_AXI_AWSIZE,
    output [1:0]                    M_AXI_AWBURST,
`ifdef	AXI3
    output [1:0]			        M_AXI_AWLOCK,
`else
    output	                        M_AXI_AWLOCK,
`endif
    output [3:0]                    M_AXI_AWCACHE,
    output [2:0]                    M_AXI_AWPROT,
    output [3:0]                    M_AXI_AWQOS,
    output                          M_AXI_WVALID,
    input                           M_AXI_WREADY,
`ifdef	AXI3
    output [C_AXI_ID_WIDTH-1:0]	    M_AXI_WID,
`endif
    output [C_AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
    output [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output                          M_AXI_WLAST,
    input                           M_AXI_BVALID,
    output                          M_AXI_BREADY,
    input[C_AXI_ID_WIDTH-1:0]       M_AXI_BID,
    input [1:0]                     M_AXI_BRESP,
    output                          M_AXI_ARVALID,
    input                           M_AXI_ARREADY,
    output [C_AXI_ID_WIDTH-1:0]     M_AXI_ARID,
    output [C_AXI_ADDR_WIDTH-1:0]   M_AXI_ARADDR,
`ifdef	AXI3
    output [3:0]			        M_AXI_ARLEN,
`else
    output [7:0]			        M_AXI_ARLEN,
`endif
    output [2:0]                    M_AXI_ARSIZE,
    output [1:0]                    M_AXI_ARBURST,
`ifdef	AXI3
    output [1:0]			        M_AXI_ARLOCK,
`else
    output	                        M_AXI_ARLOCK,
`endif
    output [3:0]                    M_AXI_ARCACHE,
    output [2:0]                    M_AXI_ARPROT,
    output [3:0]                    M_AXI_ARQOS,
    input                           M_AXI_RVALID,
    output                          M_AXI_RREADY,
    input [C_AXI_ID_WIDTH-1:0]      M_AXI_RID,
    input [C_AXI_DATA_WIDTH-1:0]    M_AXI_RDATA,
    input                           M_AXI_RLAST,
    input [1:0]                     M_AXI_RRESP,
    // Miscellanea
    input                           i_reset,
    output                          o_overflow,
    output                          o_mm2s_full,
    output                          o_empty,
    output [C_AXI_ADDR_WIDTH-($clog2(C_AXI_DATA_WIDTH)-3):0] o_fill,
    output [LGFIFO:0]               ififo_fill_o,
    output                          ififo_full_o,
    output [LGFIFO:0]               ofifo_fill_o,
    output                          DATA_LOSS,
    output [C_AXI_ADDR_WIDTH-1:0]   wptr,
    output [C_AXI_ADDR_WIDTH-1:0]   rptr,
    input [31:0]                    RING_BUFFER_LEN,
    input [31:0]                    AXI_BASE_ADDR,
    input [31:0]                    AXI_ADDR_MASK,
    output                          EOB,
    output [31:0]                   WRITE_OFFSET
);

    // Derived constants
    localparam ADDRLSB  = $clog2(C_AXI_DATA_WIDTH) - 3;
    localparam MAXBURST = 1 << LGMAXBURST;
    localparam BURSTAW  = C_AXI_ADDR_WIDTH - LGMAXBURST-ADDRLSB;
    // Connetions
    reg                soft_reset, vfifo_empty, vfifo_full;
    wire                reset_fifo;
    reg    [C_AXI_ADDR_WIDTH-ADDRLSB:0]    vfifo_fill;
    reg    [BURSTAW:0]        mem_data_available_w,
                    writes_outstanding;
    reg    [BURSTAW:0]        mem_space_available_w,
                    reads_outstanding;
    reg                s_last_stalled;
    reg    [C_AXI_DATA_WIDTH-1:0]    s_last_tdata;
    wire                read_from_fifo, ififo_full, ififo_empty;
    wire    [C_AXI_DATA_WIDTH-1:0]    ififo_data;
    wire    [LGFIFO:0]        ififo_fill;

    reg                start_write, phantom_write,
                    axi_awvalid, axi_wvalid, axi_wlast,
                    writes_idle;
    reg    [C_AXI_ADDR_WIDTH-1:0]    axi_awaddr;
    reg    [LGMAXBURST:0]        writes_pending;

    reg                start_read, phantom_read, reads_idle,
                    axi_arvalid;
    reg    [C_AXI_ADDR_WIDTH-1:0]    axi_araddr;
    reg    [LGFIFO:0]    ofifo_space_available;
    wire            write_to_fifo, ofifo_empty, ofifo_full;
    wire    [LGFIFO:0]    ofifo_fill;
    reg eob;   

        reg data_loss;
        reg [31:0] writes_counter;
        reg [31:0] reads_counter;

        assign DATA_LOSS = data_loss;
        
        wire m_axis_tvalid;
    wire [C_AXI_DATA_WIDTH-1:0] m_axis_tdata;
        assign M_AXIS_TVALID = m_axis_tvalid;
        assign M_AXIS_TDATA = m_axis_tdata;
        //assign wptr = axi_awaddr;
        assign wptr = AXI_BASE_ADDR + axi_awaddr;
        //assign rptr = axi_araddr;
        assign rptr = AXI_BASE_ADDR + axi_araddr;
        
        // Writes and Reads always happen at the size of a burst. Thus,
        // comparing the number of Writes and Reads against the length of the
        // buffer is enough to tell whether a data loss has been already
        // experienced or not. The information will be latched until next soft
        // reset, required to re-establish the nominal operations
        always @(posedge S_AXI_ACLK) begin
            if(reset_fifo) begin
                data_loss <= 1'b0;
            end
            else if(!data_loss && mem_data_available_w > RING_BUFFER_LEN) begin
                data_loss <= 1'b1;
            end
        end

        always @(posedge S_AXI_ACLK) begin
            if(reset_fifo) begin
                writes_counter <= 0;
                reads_counter <= 0;
            end
            else begin
                if(M_AXI_BVALID & M_AXI_BREADY) begin
                    writes_counter <= writes_counter + 1;
                end

                if(phantom_read) begin
                    reads_counter <= reads_counter + 1;
                end
            end
        end

    ////////////////////////////////////////////////////////////////////////
    //
    // Global FIFO signal handling
    // {{{
    ////////////////////////////////////////////////////////////////////////
    //
    //

    //
    // A soft reset
    // {{{
    // This is how we reset the FIFO without resetting the rest of the AXI
    // bus.  On a reset request, we raise the soft_reset flag and reset all
    // of our internal FIFOs.  We also stop issuing bus commands.  Once all
    // outstanding bus commands come to a halt, then we release from reset
    // and start operating as a FIFO.
    initial    soft_reset = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        soft_reset <= 0;
    else if (i_reset)
        soft_reset <= 1;
    else if (writes_idle && reads_idle)
        soft_reset <= 0;

    assign    reset_fifo = soft_reset || !S_AXI_ARESETN;
    // }}}

    //
    // Calculating the fill of the virtual FIFO, and the associated
    // full/empty flags that go with it
    // {{{
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            // In  EXTERNAL_READ_ITF  mode we lose the concept of VFIFO filling, since we cannot 
            // intercept Reads to the buffer. So that, conventionally, we show the buffer empty to 
            // the external world
            assign vfifo_fill = 0;
            assign vfifo_empty = 1;
            assign vfifo_full = 0;
        end
        else begin
            initial    vfifo_fill  = 0;
            initial    vfifo_empty = 1;
            initial    vfifo_full  = 0;

            always @(posedge S_AXI_ACLK)
            if (!S_AXI_ARESETN || soft_reset)
            begin
                vfifo_fill  <= 0;
                vfifo_empty <= 1;
                vfifo_full  <= 0;
            end else case({ S_AXIS_TVALID && S_AXIS_TREADY,
                    M_AXIS_TVALID && M_AXIS_TREADY })
            2'b10:    begin
                vfifo_fill  <= vfifo_fill + 1;
                vfifo_empty <= 0;
                vfifo_full  <= (&vfifo_fill[C_AXI_ADDR_WIDTH-ADDRLSB-1:0]);
                end
            2'b01:    begin
                vfifo_fill <= vfifo_fill - 1;
                vfifo_full <= 0;
                vfifo_empty<= (vfifo_fill <= 1);
                end
            default: begin end
            endcase        
        end
    endgenerate

    always @(*)
        o_fill = vfifo_fill;

    always @(*)
        o_empty = vfifo_empty;
    // }}}

    // Determining when the write half is idle
    // {{{
    // This is required to know when to come out of soft reset.
    //
    // The first step is to count the number of bursts that remain
    // outstanding
    initial    writes_outstanding = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        writes_outstanding <= 0;
    else case({ phantom_write,M_AXI_BVALID && M_AXI_BREADY})
    2'b01: writes_outstanding <= writes_outstanding - 1;
    2'b10: writes_outstanding <= writes_outstanding + 1;
    default: begin end
    endcase

    // The second step is to use this counter to determine if we are idle.
    // If WVALID is ever high, or start_write goes high, then we are
    // obviously not idle.  Otherwise, we become idle when the number of
    // writes outstanding transitions to (or equals) zero.
    initial    writes_idle = 1;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        writes_idle <= 1;
    else if (start_write || M_AXI_WVALID)
        writes_idle <= 0;
    else
        writes_idle <= (writes_outstanding
                == ((M_AXI_BVALID && M_AXI_BREADY) ? 1:0));
    // }}}

    // Count how much space is used in the memory device
    // {{{
    // Well, obviously, we can't fill our memory device or we have problems.
    // To make sure we don't overflow, we count memory usage here.  We'll
    // count memory usage in units of bursts of (1<<LGMAXBURST) words of
    // (1<<ADDRLSB) bytes each.  So ... here we count the amount of device
    // memory that hasn't (yet) been committed.  This is different from the
    // memory used (which we don't calculate), or the memory which may yet
    // be read--which we'll calculate in a moment.
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            // In  EXTERNAL_READ_ITF  mode we lose the concept of available space in memory, since
            // the Read interface is external
            assign mem_space_available_w = (1 << BURSTAW);
        end
        else begin
            initial    mem_space_available_w = (1<<BURSTAW);
            always @(posedge S_AXI_ACLK)
            if (!S_AXI_ARESETN || soft_reset)
                mem_space_available_w <= (1<<BURSTAW);
            else case({ phantom_write,M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST })
            2'b01: mem_space_available_w <= mem_space_available_w + 1;
            2'b10: mem_space_available_w <= mem_space_available_w - 1;
            default: begin end
            endcase
        end
    endgenerate
    // }}}

    // Determining when the read half is idle
    // {{{
    // Count the number of read bursts that we've committed to.  This
    // includes bursts that have ARVALID but haven't been accepted, as well
    // as any the downstream device will yet return an RLAST for.
    initial    reads_outstanding = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        reads_outstanding <= 0;
    else case({ phantom_read,M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST})
    2'b01: reads_outstanding <= reads_outstanding - 1;
    2'b10: reads_outstanding <= reads_outstanding + 1;
    default: begin end
    endcase

    // Now, using the reads_outstanding counter, we can check whether or not
    // we are idle (and can exit a reset) of if instead there are more
    // bursts outstanding to wait for.
    //
    // By registering this counter, we can keep the soft_reset release
    // simpler.  At least this way, it doesn't need to check two counters
    // for zero.
    initial    reads_idle = 1;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        reads_idle <= 1;
    else if (start_read || M_AXI_ARVALID)
        reads_idle <= 0;
    else
        reads_idle <= (reads_outstanding
        == ((M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) ? 1:0));
    // }}}

    // Count how much data is in the memory device that we can read out
    // {{{
    // In AXI, after you issue a write, you can't depend upon that data
    // being present on the device and available for a read until the
    // associated BVALID is returned.  Therefore we don't count any memory
    // as available to be read until BVALID comes back.  Once a read
    // command is issued, the memory is again no longer available to be
    // read.  Note also that we are counting bursts here.  A second
    // conversion below converts this count to bytes.
    initial    mem_data_available_w = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN || soft_reset)
        mem_data_available_w <= 0;
    else case({ M_AXI_BVALID, phantom_read })
    2'b10: mem_data_available_w <= mem_data_available_w + 1;
    2'b01: mem_data_available_w <= mem_data_available_w - 1;
    default: begin end
    endcase
    // }}}

    //
    // Incoming stream overflow detection
    // {{{
    // The overflow flag is set if ever an incoming value violates the
    // stream protocol and changes while stalled.  Internally, however,
    // the overflow flag is ignored.  It's provided for your information.
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        s_last_stalled <= 0;
    else
        s_last_stalled <= S_AXIS_TVALID && !S_AXIS_TREADY;

    always @(posedge S_AXI_ACLK)
    if (S_AXIS_TVALID)
        s_last_tdata <= S_AXIS_TDATA;

    initial    o_overflow = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN || soft_reset)
        o_overflow <= 0;
    else if (s_last_stalled)
    begin
        if (!S_AXIS_TVALID)
            o_overflow <= 1;
        if (S_AXIS_TDATA != s_last_tdata)
            o_overflow <= 1;
    end
    // }}}
    // }}}

    ////////////////////////////////////////////////////////////////////////
    //
    // Incoming FIFO
    // {{{
    // Incoming data stream info the FIFO
    //
    ////////////////////////////////////////////////////////////////////////
    //
    //
    assign    S_AXIS_TREADY = !reset_fifo && !ififo_full && !vfifo_full;
	//assign	read_from_fifo= (!skd_valid || (M_AXI_WVALID && M_AXI_WREADY));
    assign	read_from_fifo= (M_AXI_WVALID && M_AXI_WREADY);
    
    assign ififo_full_o = ififo_full;

    sfifo #(.BW(C_AXI_DATA_WIDTH), .LGFLEN(LGFIFO))
    ififo(S_AXI_ACLK, reset_fifo,
        S_AXIS_TVALID && S_AXIS_TREADY,
            S_AXIS_TDATA, ififo_full, ififo_fill,
        read_from_fifo, ififo_data, ififo_empty);
/*         COMMON_CLOCK_FIFO #(
            .Fifo_depth             (1<<LGFIFO),
            .data_width             (C_AXI_DATA_WIDTH),
            .FWFT_ShowAhead         (1'b1),
            .Prog_Full_ThresHold    (1<<LGFIFO-1),
            .Prog_Empty_ThresHold   (1)
        )
        ififo (
            .Async_rst  (1'b0),
            .Sync_rst   (reset_fifo),
            .clk        (S_AXI_ACLK),
            .we         (S_AXIS_TVALID & S_AXIS_TREADY),
            .din        (S_AXIS_TDATA),
            .full       (ififo_full),
            .prog_full  (), // Unused
            .valid      (), // Unused w/ the show-ahead configuration
            .re         (read_from_fifo),
            .dout       (ififo_data),
            .empty      (ififo_empty),
            .prog_empty (), // Unused
            .data_count (ififo_fill)
        ); */

/* 	//
	// We need a quick 1-element buffer here in order to keep the soft
	// reset, which resets the FIFO pointer, from adjusting any FIFO data.
	// {{{
	// Here's the rule: we need to fill the buffer before it ever gets
	// used.  Then, once used, it should be able to maintain 100%
	// throughput.
	initial	skd_valid = 0;
	always @(posedge S_AXI_ACLK)
	if (reset_fifo)
		skd_valid <= 0;
	else if (!ififo_empty)
		skd_valid <= 1;
	else if (M_AXI_WVALID && M_AXI_WREADY)
		skd_valid <= 0;

	always @(posedge S_AXI_ACLK)
	if (!M_AXI_WVALID || M_AXI_WREADY)
	begin
		if (!skd_valid || M_AXI_WREADY)
			skd_data <= ififo_data;
	end
	// }}}
	// }}}
 */


    ////////////////////////////////////////////////////////////////////////
    //
    // AXI write processing
    // {{{
    // Write data from our FIFO onto the bus
    //
    ////////////////////////////////////////////////////////////////////////
    //
    //

    // start_write: determining when to issue a write burst
    // {{{
    always @(*)
    begin
        start_write = 0;

        if (ififo_fill >= (1<<LGMAXBURST))
            start_write = 1;
        if (vfifo_full || soft_reset || phantom_write)
            start_write = 0;
        if (mem_space_available_w == 0)
            start_write = 0;

        if (M_AXI_WVALID && (!M_AXI_WREADY || !M_AXI_WLAST))
            start_write = 0;
        if (M_AXI_AWVALID && !M_AXI_AWREADY)
            start_write = 0;
    end
    // }}}

    // Register the start write signal into AWVALID and phantom write
    // {{{
    // phantom_write contains the start signal, but immediately clears
    // on the next clock cycle.  This allows us some time to calculate
    // the data for the next burst which and if AWVALID remains high and
    // not yet accepted.
    initial    phantom_write = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        phantom_write <= 0;
    else
        phantom_write <= start_write;

    // Set AWVALID to start_write if every the channel isn't stalled.
    // Incidentally, start_write is guaranteed to be zero if the channel
    // is stalled, since that signal is used by other things as well.
    initial    axi_awvalid = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_awvalid <= 0;
    else if (!M_AXI_AWVALID || M_AXI_AWREADY)
        axi_awvalid <= start_write;
    // }}}

    // Write address
    // {{{
    // We insist on alignment.  On every accepted burst, we step forward by
    // one burst length.  On reset, we reset the address at our first
    // opportunity.
    initial    axi_awaddr = 0;
    always @(posedge S_AXI_ACLK)
    begin
        if (M_AXI_AWVALID && M_AXI_AWREADY)
            axi_awaddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_awaddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];

        if ((!M_AXI_AWVALID || M_AXI_AWREADY) && soft_reset)
            axi_awaddr <= 0;

        if (!S_AXI_ARESETN)
            axi_awaddr <= 0;

        axi_awaddr[LGMAXBURST+ADDRLSB-1:0] <= 0;
    end  
    
    assign WRITE_OFFSET = axi_awaddr;
    // }}}

    // Write data channel valid
    // {{{
    initial    axi_wvalid = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_wvalid <= 0;
    else if (start_write)
        axi_wvalid <= 1;
    else if (!M_AXI_WVALID || M_AXI_WREADY)
        axi_wvalid <= M_AXI_WVALID && !M_AXI_WLAST;
    // }}}

    // WLAST generation
    // {{{
    // On the beginning of any burst, start a counter of the number of items
    // in it.  Once the counter gets to 1, set WLAST.
    initial    writes_pending = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        writes_pending <= 0;
    else if (start_write)
        writes_pending <= MAXBURST;
    else if (M_AXI_WVALID && M_AXI_WREADY)
        writes_pending <= writes_pending -1;

    always @(posedge S_AXI_ACLK)
    if (start_write)
        axi_wlast <= (LGMAXBURST == 0);
    else if (!M_AXI_WVALID || M_AXI_WREADY)
        axi_wlast <= (writes_pending == 1 + (M_AXI_WVALID ? 1:0));
    // }}}

    // Bus assignments based upon the above
    // {{{
    assign    M_AXI_AWVALID = axi_awvalid;
    assign    M_AXI_AWID    = 0;
    //assign    M_AXI_AWADDR  = AXI_BASE_ADDR + axi_awaddr[$clog2(RING_BUFFER_SIZE)-1:0];
    assign    M_AXI_AWADDR  = AXI_BASE_ADDR + axi_awaddr;
    assign    M_AXI_AWLEN   = MAXBURST-1;
    assign    M_AXI_AWSIZE  = ADDRLSB[2:0];
    assign    M_AXI_AWBURST = 2'b01;
    assign    M_AXI_AWLOCK  = 0;
    assign    M_AXI_AWCACHE = 0;
    assign    M_AXI_AWPROT  = 0;
    assign    M_AXI_AWQOS   = 0;

    assign    M_AXI_WVALID = axi_wvalid;
	//assign	M_AXI_WDATA  = skd_data;
    assign	M_AXI_WDATA  = ififo_data;
`ifdef	AXI3
	assign	M_AXI_WID    = 0;
`endif
    assign    M_AXI_WLAST  = axi_wlast;
    assign    M_AXI_WSTRB  = -1;

    assign    M_AXI_BREADY = 1;
    // }}}
    // }}}

    ////////////////////////////////////////////////////////////////////////
    //
    // AXI read processing
    // {{{
    // Read data into our FIFO
    //
    ////////////////////////////////////////////////////////////////////////
    //
    //

    // How much FIFO space is available?
    // {{{
    // One we issue a read command, the FIFO space isn't available any more.
    // That way we can determine when a second read can be issued--even
    // before the first has returned--while also guaranteeing that there's
    // always room in the outgoing FIFO for anything that might return.
    // Remember: NEVER generate backpressure in a bus master
    initial    ofifo_space_available = (1<<LGFIFO);
    always @(posedge S_AXI_ACLK)
    if (reset_fifo)
        ofifo_space_available <= (1<<LGFIFO);
	else case({phantom_read, M_AXIS_TVALID && M_AXIS_TREADY})
    2'b10:    ofifo_space_available <= ofifo_space_available - MAXBURST;
    2'b01:    ofifo_space_available <= ofifo_space_available + 1;
    2'b11:    ofifo_space_available <= ofifo_space_available - MAXBURST + 1;
    default: begin end
    endcase
    // }}}

    // Determine when to start a next read-from-memory-to-FIFO burst
    // {{{
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            assign start_read = 1'b0;
        end
        else begin
            always @(*)
            begin
                start_read = 1;

                // We can't read yet if we don't have space available.
                // Note the comparison is carefully chosen to make certain
                // it doesn't use all ofifo_space_available bits, but rather
                // only the number of bits between LGFIFO and
                // LGMAXBURST--nominally a single bit.
                if (ofifo_space_available < MAXBURST)    // FIFO space ?
                    start_read = 0;

                // If there's no memory available for us to read from, then
                // we can't start a read yet.
                if (!M_AXI_BVALID && mem_data_available_w == 0)
                    start_read = 0;

                // Don't start anything while waiting on a reset.  Likewise,
                // insist on a minimum one clock between read burst issuances.
                if (soft_reset || phantom_read)
                    start_read = 0;

                // We can't start a read request if the AR* channel is stalled
                if (M_AXI_ARVALID && !M_AXI_ARREADY)
                    start_read = 0;

            end
        end
    endgenerate
        
    // Set phantom_read and ARVALID
    // {{{
    initial    phantom_read = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        phantom_read <= 0;
    else
        phantom_read <= start_read;

    initial    axi_arvalid = 0;
    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_arvalid <= 0;
    else if (!M_AXI_ARVALID || M_AXI_ARREADY)
        axi_arvalid <= start_read;
    // }}}

    // Calculate the next ARADDR
    // {{{
    initial    axi_araddr = 0;
    always @(posedge S_AXI_ACLK)
    begin
        if (M_AXI_ARVALID && M_AXI_ARREADY)
            axi_araddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_araddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];

        if ((!M_AXI_ARVALID || M_AXI_ARREADY) && soft_reset)
            axi_araddr <= 0;

        if (!S_AXI_ARESETN)
            axi_araddr <= 0;

        axi_araddr[LGMAXBURST+ADDRLSB-1:0] <= 0;
    end
    // }}}

    // Assign values to our bus wires
    // {{{
    assign    M_AXI_ARVALID = axi_arvalid;
    assign    M_AXI_ARID    = 0;
    //assign    M_AXI_ARADDR  = AXI_BASE_ADDR + axi_araddr[$clog2(RING_BUFFER_SIZE)-1:0];
    assign    M_AXI_ARADDR  = AXI_BASE_ADDR + axi_araddr;
    assign    M_AXI_ARLEN   = MAXBURST-1;
    assign    M_AXI_ARSIZE  = ADDRLSB[2:0];
    assign    M_AXI_ARBURST = 2'b01;
    assign    M_AXI_ARLOCK  = 0;
    assign    M_AXI_ARCACHE = 0;
    assign    M_AXI_ARPROT  = 0;
    assign    M_AXI_ARQOS   = 0;

    assign    M_AXI_RREADY = 1;
    // }}}
    // }}}

    ////////////////////////////////////////////////////////////////////////
    //
    // Outgoing AXI stream processing
    // {{{
    // Send data out from the MM2S FIFO
    //
    ////////////////////////////////////////////////////////////////////////
    //
    //

    // We basically just stuff the data read from memory back into our
    // outgoing FIFO here.  The logic is quite straightforward.
    assign    write_to_fifo = M_AXI_RVALID && M_AXI_RREADY;
	assign	M_AXIS_TVALID = !ofifo_empty;

	sfifo #(.BW(C_AXI_DATA_WIDTH), .LGFLEN(LGFIFO))
    ofifo(S_AXI_ACLK, reset_fifo,
        write_to_fifo,
            M_AXI_RDATA, ofifo_full, ofifo_fill,
		M_AXIS_TVALID && M_AXIS_TREADY, M_AXIS_TDATA, ofifo_empty);
/*         COMMON_CLOCK_FIFO #(
            .Fifo_depth             (1<<LGFIFO),
            .data_width             (C_AXI_DATA_WIDTH),
            .FWFT_ShowAhead         (1'b1),
            .Prog_Full_ThresHold    (1<<LGFIFO-1),
            .Prog_Empty_ThresHold   (1)
        )
        ofifo (
            .Async_rst  (1'b0),
            .Sync_rst   (reset_fifo),
            .clk        (S_AXI_ACLK),
            .we         (write_to_fifo),
            .din        (M_AXI_RDATA),
            .full       (ofifo_full),
            .prog_full  (), // Unused
            .valid      (), // Unused w/ the show-ahead configuration
            .re         (m_axis_tvalid & M_AXIS_TREADY),
            .dout       (m_axis_tdata),
            .empty      (ofifo_empty),
            .prog_empty (), // Unused
            .data_count (ofifo_fill)
        ); */

    always @(*)
        o_mm2s_full = |ofifo_fill[LGFIFO:LGMAXBURST];
    // }}}

    // Keep Verilator happy
    // {{{
    // Verilator lint_off UNUSED
    wire    unused;
    assign    unused = &{ 1'b0, M_AXI_BID, M_AXI_RID,
            M_AXI_BRESP[0], M_AXI_RRESP[0],
            ififo_empty, ofifo_full, ofifo_fill
            // fifo_full, fifo_fill, fifo_empty,
            };

    // Verilator lint_on UNUSED
    // }}}
                assign ififo_fill_o = ififo_fill;
                assign ofifo_fill_o = ofifo_fill;


    // Generate a pulse every time the burst ends
    always @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            eob <= 1'b0;
        end
        else begin
            eob <= 1'b0;
            
            if(!eob && M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST) begin
                eob <= 1'b1;
            end
        end
    end
    
    assign EOB = eob;
endmodule