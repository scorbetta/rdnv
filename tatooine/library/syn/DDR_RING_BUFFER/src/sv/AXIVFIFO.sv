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
    axi4s_if.slave                  IFIFO_AXI_PORT,
    // AXI4 Stream output interface
    axi4s_if.master                 OFIFO_AXI_PORT,
    // AXI Full DMA interface
`ifdef AXI3
    axi3f_if.master                 DDR_CTRL_AXI_PORT,
`else
    axi4f_if.master                 DDR_CTRL_AXI_PORT,
`endif
    // Miscellanea
    input                           SOFT_RST,
    output                          OVERFLOW,
    output                          MM2S_FULL,
    output                          VFIFO_EMPTY,
    output [C_AXI_ADDR_WIDTH-($clog2(C_AXI_DATA_WIDTH)-3):0] VFIFO_FILL,
    output [LGFIFO:0]               IFIFO_FILL,
    output                          IFIFO_FULL,
    output [LGFIFO:0]               OFIFO_FILL,
    output                          DATA_LOSS,
    output [C_AXI_ADDR_WIDTH-1:0]   WPTR,
    output [C_AXI_ADDR_WIDTH-1:0]   RPTR,
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
    logic                               soft_reset;
    logic                               vfifo_empty;
    logic                               vfifo_full;
    logic                               reset_fifo;
    logic [C_AXI_ADDR_WIDTH-ADDRLSB:0]  vfifo_fill;
    logic [BURSTAW:0]                   mem_data_available_w;
    logic [BURSTAW:0]                   writes_outstanding;
    logic [BURSTAW:0]                   mem_space_available_w;
    logic [BURSTAW:0]                   reads_outstanding;
    logic                               s_last_stalled;
    logic [C_AXI_DATA_WIDTH-1:0]        s_last_tdata;
    logic                               ififo_full;
    logic                               ififo_empty;
    logic [C_AXI_DATA_WIDTH-1:0]        ififo_data;
    logic [LGFIFO:0]                    ififo_fill;
    logic                               start_write;
    logic                               phantom_write;
    logic                               axi_awvalid;
    logic                               axi_wvalid;
    logic                               axi_wlast;
    logic                               writes_idle;
    logic [C_AXI_ADDR_WIDTH-1:0]        axi_awaddr;
    logic [LGMAXBURST:0]                writes_pending;
    logic                               start_read;
    logic                               phantom_read;
    logic                               reads_idle;
    logic                               axi_arvalid;
    logic [C_AXI_ADDR_WIDTH-1:0]        axi_araddr;
    logic [LGFIFO:0]                    ofifo_space_available;
    logic                               write_to_fifo;
    logic                               ofifo_empty;
    logic                               ofifo_full;
    logic [LGFIFO:0]                    ofifo_fill;
    logic                               eob;   
    logic                               data_loss;
    logic                               overflow;

    assign reset_fifo = soft_reset || !S_AXI_ARESETN;

    // Writes and Reads always happen at the size of a burst. Thus, comparing the number of Writes 
    // and Reads against the length of the buffer is enough to tell whether a data loss has been 
    // already experienced or not. The information will be latched until next soft reset, required 
    // to re-establish the nominal operations
    always_ff @(posedge S_AXI_ACLK) begin
        if(reset_fifo) begin
            data_loss <= 1'b0;
        end
        else if(!data_loss && mem_data_available_w > RING_BUFFER_LEN) begin
            data_loss <= 1'b1;
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            soft_reset <= 0;
        end
        else if(SOFT_RST) begin
            soft_reset <= 1;
        end
        else if(writes_idle && reads_idle) begin
            soft_reset <= 0;
        end
    end

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
            always_ff @(posedge S_AXI_ACLK)
            if (!S_AXI_ARESETN || soft_reset)
            begin
                vfifo_fill  <= 0;
                vfifo_empty <= 1;
                vfifo_full  <= 0;
            end else case({ IFIFO_AXI_PORT.tvalid && IFIFO_AXI_PORT.tready, OFIFO_AXI_PORT.tvalid && OFIFO_AXI_PORT.tready })
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

    // Determining when the write half is idle required to know when to come out of soft reset
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            writes_outstanding <= 0;
        end
        else begin
            case({ phantom_write, DDR_CTRL_AXI_PORT.bvalid & DDR_CTRL_AXI_PORT.bready})
                2'b01: writes_outstanding <= writes_outstanding - 1;
                2'b10: writes_outstanding <= writes_outstanding + 1;
                default: writes_outstanding <= writes_outstanding;
            endcase
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            writes_idle <= 1;
        end
        else if(start_write || DDR_CTRL_AXI_PORT.wvalid) begin
            writes_idle <= 0;
        end
        else begin
            writes_idle <= (writes_outstanding == ( (DDR_CTRL_AXI_PORT.bvalid && DDR_CTRL_AXI_PORT.bready) ? 1 : 0) );
        end
    end

    // Count how much space is used in the memory device
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            // In  EXTERNAL_READ_ITF  mode we lose the concept of available space in memory, since
            // the Read interface is external
            assign mem_space_available_w = (1 << BURSTAW);
        end
        else begin
            always_ff @(posedge S_AXI_ACLK) begin
                if(!S_AXI_ARESETN || soft_reset) begin
                    mem_space_available_w <= (1 << BURSTAW);
                end
                else begin
                    case({ phantom_write, DDR_CTRL_AXI_PORT.rvalid & DDR_CTRL_AXI_PORT.rready & DDR_CTRL_AXI_PORT.rlast })
                        2'b01: mem_space_available_w <= mem_space_available_w + 1;
                        2'b10: mem_space_available_w <= mem_space_available_w - 1;
                        default: mem_space_available_w <= mem_space_available_w;
                    endcase
                end
            end
        end
    endgenerate

    // Determining when the read half is idle
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            reads_outstanding <= 0;
        end
        else begin
            case({ phantom_read, DDR_CTRL_AXI_PORT.rvalid & DDR_CTRL_AXI_PORT.rready & DDR_CTRL_AXI_PORT.rlast})
                2'b01: reads_outstanding <= reads_outstanding - 1;
                2'b10: reads_outstanding <= reads_outstanding + 1;
                default: reads_outstanding <= reads_outstanding;
            endcase
        end
    end

    // Now, using the reads_outstanding counter, we can check whether or not we are idle (and can 
    // exit a reset) of if instead there are more bursts outstanding to wait for. By registering this
    // counter, we can keep the soft_reset release simpler. At least this way, it doesn't need to 
    // check two counters for zero
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            reads_idle <= 1;
        end
        else if(start_read || DDR_CTRL_AXI_PORT.arvalid) begin
            reads_idle <= 0;
        end
        else begin
            reads_idle <= (reads_outstanding == ( (DDR_CTRL_AXI_PORT.rvalid && DDR_CTRL_AXI_PORT.rready && DDR_CTRL_AXI_PORT.rlast) ? 1 : 0) );
        end
    end

    // Count how much data is in the memory device that we can read out. In AXI, after you issue a
    // write, you can't depend upon that data being present on the device and available for a read 
    // until the associated BVALID is returned. Therefore we don't count any memory as available to 
    // be read until BVALID comes back. Once a read  command is issued, the memory is again no 
    // longer available to be read.  Note also that we are counting bursts here. A second conversion
    // below converts this count to bytes.
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN || soft_reset) begin
            mem_data_available_w <= 0;
        end
        else begin
            case({ DDR_CTRL_AXI_PORT.bvalid, phantom_read })
                2'b10: mem_data_available_w <= mem_data_available_w + 1;
                2'b01: mem_data_available_w <= mem_data_available_w - 1;
                default: mem_data_available_w <= mem_data_available_w;
            endcase
        end
    end

    // Incoming stream overflow detection. The overflow flag is set if ever an incoming value violates 
    // the stream protocol and changes while stalled. Internally, however, the overflow flag is 
    // ignored. It's provided for your information
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            s_last_stalled <= 0;
        end
        else begin
            s_last_stalled <= IFIFO_AXI_PORT.tvalid & ~IFIFO_AXI_PORT.tready;
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(IFIFO_AXI_PORT.tvalid) begin
            s_last_tdata <= IFIFO_AXI_PORT.tdata;
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN || soft_reset) begin
            overflow <= 0;
        end
        else if(s_last_stalled) begin
            if(!IFIFO_AXI_PORT.tvalid) begin
                overflow <= 1;
            end
        
            if(IFIFO_AXI_PORT.tdata != s_last_tdata) begin
                overflow <= 1;
            end
        end
    end

     SIMPLE_FIFO #(
        .BW                 (C_AXI_DATA_WIDTH),
        .LGFLEN             (LGFIFO),
        .OPT_ASYNC_READ     (1'b1),
        .OPT_WRITE_ON_FULL  (1'b0),
        .OPT_READ_ON_EMPTY  (1'b0)
    )
    IFIFO (
        .i_clk      (S_AXI_ACLK),
        .i_reset    (reset_fifo),
        .i_wr       (IFIFO_AXI_PORT.tvalid & IFIFO_AXI_PORT.tready),
        .i_data     (IFIFO_AXI_PORT.tdata),
        .o_full     (ififo_full),
        .o_fill     (ififo_fill),
        .i_rd       (DDR_CTRL_AXI_PORT.wvalid & DDR_CTRL_AXI_PORT.wready),
        .o_data     (ififo_data),
        .o_empty    (ififo_empty)
    );

    always_comb begin
        start_write = 0;
        if(ififo_fill >= (1 << LGMAXBURST)) begin
            start_write = 1;
        end
        
        if(vfifo_full || soft_reset || phantom_write) begin
            start_write = 0;
        end
        
        if(mem_space_available_w == 0) begin
            start_write = 0;
        end

        if(DDR_CTRL_AXI_PORT.wvalid && (!DDR_CTRL_AXI_PORT.wready || !DDR_CTRL_AXI_PORT.wlast)) begin
            start_write = 0;
        end
        
        if(DDR_CTRL_AXI_PORT.awvalid && !DDR_CTRL_AXI_PORT.awready) begin
            start_write = 0;
        end
    end

    // Register the start write signal into AWVALID and phantom write. phantom_write contains the
    // start signal, but immediately clears on the next clock cycle.  This allows us some time to 
    // calculate the data for the next burst which and if AWVALID remains high and not yet accepted.
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            phantom_write <= 0;
        end
        else begin
            phantom_write <= start_write;
        end
    end

    // Set AWVALID to start_write if every the channel isn't stalled. Incidentally, start_write is 
    // guaranteed to be zero if the channel is stalled, since that signal is used by other things as 
    // well.
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            axi_awvalid <= 0;
        end
        else if (!DDR_CTRL_AXI_PORT.awvalid || DDR_CTRL_AXI_PORT.awready) begin
            axi_awvalid <= start_write;
        end
    end

    // Write address. We insist on alignment. On every accepted burst, we step forward by one burst 
    // length. On reset, we reset the address at our first opportunity
    always_ff @(posedge S_AXI_ACLK) begin
        if(DDR_CTRL_AXI_PORT.awvalid && DDR_CTRL_AXI_PORT.awready) begin
            axi_awaddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_awaddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];
        end

        if((!DDR_CTRL_AXI_PORT.awvalid || DDR_CTRL_AXI_PORT.awready) && soft_reset) begin
            axi_awaddr <= 0;
        end

        if(!S_AXI_ARESETN) begin
            axi_awaddr <= 0;
        end

        axi_awaddr[LGMAXBURST+ADDRLSB-1:0] <= 0;
    end  
    
    // }}}

    // Write data channel valid
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            axi_wvalid <= 0;
        end
        else if(start_write) begin
            axi_wvalid <= 1;
        end
        else if (!DDR_CTRL_AXI_PORT.wvalid || DDR_CTRL_AXI_PORT.wready) begin
            axi_wvalid <= DDR_CTRL_AXI_PORT.wvalid && !DDR_CTRL_AXI_PORT.wlast;
        end
    end

    // WLAST generation. On the beginning of any burst, start a counter of the number of items in it.
    // Once the counter gets to 1, set WLAST.
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            writes_pending <= 0;
        end
        else if(start_write) begin
            writes_pending <= MAXBURST;
        end
        else if(DDR_CTRL_AXI_PORT.wvalid && DDR_CTRL_AXI_PORT.wready) begin
            writes_pending <= writes_pending -1;
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(start_write) begin
            axi_wlast <= (LGMAXBURST == 0);
        end
        else if(!DDR_CTRL_AXI_PORT.wvalid || DDR_CTRL_AXI_PORT.wready) begin
            axi_wlast <= (writes_pending == 1 + (DDR_CTRL_AXI_PORT.wvalid ? 1:0));
        end
    end

    // How much FIFO space is available? One we issue a read command, the FIFO space isn't available 
    // any more. That way we can determine when a second read can be issued--even before the first 
    // has returned--while also guaranteeing that there's always room in the outgoing FIFO for 
    // anything that might return. Remember: NEVER generate backpressure in a bus master
    always_ff @(posedge S_AXI_ACLK) begin
        if(reset_fifo) begin
            ofifo_space_available <= (1<<LGFIFO);
        end
        else begin
            case({phantom_read, OFIFO_AXI_PORT.tvalid && OFIFO_AXI_PORT.tready})
                2'b10: ofifo_space_available <= ofifo_space_available - MAXBURST;
                2'b01: ofifo_space_available <= ofifo_space_available + 1;
                2'b11: ofifo_space_available <= ofifo_space_available - MAXBURST + 1;
                default: ofifo_space_available <= ofifo_space_available;
            endcase
        end
    end

    // Determine when to start a next read-from-memory-to-FIFO burst
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            assign start_read = 1'b0;
        end
        else begin
            always_comb begin
                start_read = 1;

                // We can't read yet if we don't have space available.
                // Note the comparison is carefully chosen to make certain
                // it doesn't use all ofifo_space_available bits, but rather
                // only the number of bits between LGFIFO and
                // LGMAXBURST--nominally a single bit.
                if (ofifo_space_available < MAXBURST) begin
                    start_read = 0;
                end

                // If there's no memory available for us to read from, then
                // we can't start a read yet.
                if (!DDR_CTRL_AXI_PORT.bvalid && mem_data_available_w == 0) begin
                    start_read = 0;
                end

                // Don't start anything while waiting on a reset.  Likewise,
                // insist on a minimum one clock between read burst issuances.
                if (soft_reset || phantom_read) begin
                    start_read = 0;
                end

                // We can't start a read request if the AR* channel is stalled
                if (DDR_CTRL_AXI_PORT.arvalid && !DDR_CTRL_AXI_PORT.arready) begin
                    start_read = 0;
                end
            end
        end
    endgenerate
        
    // Set phantom_read and ARVALID
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            phantom_read <= 0;
        end
        else begin
            phantom_read <= start_read;
        end
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            axi_arvalid <= 0;
        end
        else if(!DDR_CTRL_AXI_PORT.arvalid || DDR_CTRL_AXI_PORT.arready) begin
            axi_arvalid <= start_read;
        end
    end

    // Calculate the next ARADDR
    always_ff @(posedge S_AXI_ACLK) begin
        if(DDR_CTRL_AXI_PORT.arvalid && DDR_CTRL_AXI_PORT.arready) begin
            axi_araddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_araddr[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[C_AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];
        end

        if((!DDR_CTRL_AXI_PORT.arvalid || DDR_CTRL_AXI_PORT.arready) && soft_reset) begin
            axi_araddr <= 0;
        end

        if(!S_AXI_ARESETN) begin
            axi_araddr <= 0;
        end

        axi_araddr[LGMAXBURST+ADDRLSB-1:0] <= 0;
    end

    // We basically just stuff the data read from memory back into our outgoing FIFO here. The logic
    // is quite straightforward
    assign write_to_fifo = DDR_CTRL_AXI_PORT.rvalid && DDR_CTRL_AXI_PORT.rready;

 	SIMPLE_FIFO #(
        .BW                 (C_AXI_DATA_WIDTH),
        .LGFLEN             (LGFIFO),
        .OPT_ASYNC_READ     (1'b1),
        .OPT_WRITE_ON_FULL  (1'b0),
        .OPT_READ_ON_EMPTY  (1'b0)
    )
    OFIFO (
        .i_clk      (S_AXI_ACLK),
        .i_reset    (reset_fifo),
        .i_wr       (write_to_fifo),
        .i_data     (DDR_CTRL_AXI_PORT.rdata),
        .o_full     (ofifo_full),
        .o_fill     (ofifo_fill),
		.i_rd       (OFIFO_AXI_PORT.tvalid & OFIFO_AXI_PORT.tready),
        .o_data     (OFIFO_AXI_PORT.tdata),
        .o_empty    (ofifo_empty)
    );

    // Generate a pulse every time the burst ends
    always_ff @(posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            eob <= 1'b0;
        end
        else begin
            eob <= 1'b0;
            
            if(!eob && DDR_CTRL_AXI_PORT.wvalid && DDR_CTRL_AXI_PORT.wready && DDR_CTRL_AXI_PORT.wlast) begin
                eob <= 1'b1;
            end
        end
    end
    
    
    // Pinout
    assign DATA_LOSS                    = data_loss;
    assign EOB                          = eob;
    assign VFIFO_FILL                   = vfifo_fill;
    assign VFIFO_EMPTY                  = vfifo_empty;
    assign WRITE_OFFSET                 = axi_awaddr;
    assign DDR_CTRL_AXI_PORT.awvalid    = axi_awvalid;
    assign DDR_CTRL_AXI_PORT.awid       = 0;
    assign DDR_CTRL_AXI_PORT.awaddr     = AXI_BASE_ADDR + axi_awaddr;
    assign DDR_CTRL_AXI_PORT.awlen      = MAXBURST-1;
    assign DDR_CTRL_AXI_PORT.awsize     = ADDRLSB[2:0];
    assign DDR_CTRL_AXI_PORT.awburst    = 2'b01;
    assign DDR_CTRL_AXI_PORT.awlock     = 0;
    assign DDR_CTRL_AXI_PORT.awcache    = 0;
    assign DDR_CTRL_AXI_PORT.awprot     = 0;
    assign DDR_CTRL_AXI_PORT.awqos      = 0;
    assign DDR_CTRL_AXI_PORT.wvalid     = axi_wvalid;
    assign DDR_CTRL_AXI_PORT.wdata      = ififo_data;
`ifdef	AXI3        
	assign DDR_CTRL_AXI_PORT.wid        = 0;
`endif      
    assign DDR_CTRL_AXI_PORT.wlast      = axi_wlast;
    assign DDR_CTRL_AXI_PORT.wstrb      = {C_AXI_DATA_WIDTH/8{1'b1}};
    assign DDR_CTRL_AXI_PORT.bready     = 1;
    assign DDR_CTRL_AXI_PORT.arvalid    = axi_arvalid;
    assign DDR_CTRL_AXI_PORT.arid       = 0;
    assign DDR_CTRL_AXI_PORT.araddr     = AXI_BASE_ADDR + axi_araddr;
    assign DDR_CTRL_AXI_PORT.arlen      = MAXBURST-1;
    assign DDR_CTRL_AXI_PORT.arsize     = ADDRLSB[2:0];
    assign DDR_CTRL_AXI_PORT.arburst    = 2'b01;
    assign DDR_CTRL_AXI_PORT.arlock     = 0;
    assign DDR_CTRL_AXI_PORT.arcache    = 0;
    assign DDR_CTRL_AXI_PORT.arprot     = 0;
    assign DDR_CTRL_AXI_PORT.arqos      = 0;
    assign DDR_CTRL_AXI_PORT.rready     = 1;
	assign OFIFO_AXI_PORT.tvalid        = !ofifo_empty;
    assign MM2S_FULL                    = |ofifo_fill[LGFIFO:LGMAXBURST];
    assign IFIFO_FILL                   = ififo_fill;
    assign IFIFO_FULL                   = ififo_full;
    assign OFIFO_FILL                   = ofifo_fill;
    assign OVERFLOW                     = overflow;
    assign WPTR                         = AXI_BASE_ADDR + axi_awaddr;
    assign RPTR                         = AXI_BASE_ADDR + axi_araddr;        
    assign IFIFO_AXI_PORT.tready        = !reset_fifo && !ififo_full && !vfifo_full;
endmodule
