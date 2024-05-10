`default_nettype none

// Adapted w/ modifications by Simone Corbetta PhD from the design of Dan Gisselquist, Ph.D.,
// Gisselquist Technology
module AXIVFIFO #(
    parameter AXI_ID_WIDTH    = 1,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_DATA_WIDTH  = 32,
    // LGMAXBURST determines the size of the maximum AXI burst
    parameter LGMAXBURST        = 8,
    // Beware of the wolf
    parameter EXTERNAL_READ_ITF = 0
)
(
    // Clock and reset
    input wire                                                  CLK,
    input wire                                                  RSTN,
    // AXI4 Stream input interface
    input wire                                                  S_AXIS_TVALID,
    output wire                                                 S_AXIS_TREADY,
    input wire [AXI_DATA_WIDTH-1:0]                             S_AXIS_TDATA,
    // AXI4 Stream output interface
    output wire                                                 M_AXIS_TVALID,
    input wire                                                  M_AXIS_TREADY,
    output wire [AXI_DATA_WIDTH-1:0]                            M_AXIS_TDATA,
    // AXI4 Full DMA interface
    output wire                                                 M_AXI_AWVALID,
    input wire                                                  M_AXI_AWREADY,
    output wire [AXI_ID_WIDTH-1:0]                              M_AXI_AWID,
    output wire [AXI_ADDR_WIDTH-1:0]                            M_AXI_AWADDR,
    output wire [7:0]			                                M_AXI_AWLEN,
    output wire [2:0]                                           M_AXI_AWSIZE,
    output wire [1:0]                                           M_AXI_AWBURST,
    output	                                                    M_AXI_AWLOCK,
    output wire [3:0]                                           M_AXI_AWCACHE,
    output wire [2:0]                                           M_AXI_AWPROT,
    output wire [3:0]                                           M_AXI_AWQOS,
    output wire                                                 M_AXI_WVALID,
    input wire                                                  M_AXI_WREADY,
    output wire [AXI_ID_WIDTH-1:0]	                            M_AXI_WID,
    output wire [AXI_DATA_WIDTH-1:0]                            M_AXI_WDATA,
    output wire [AXI_DATA_WIDTH/8-1:0]                          M_AXI_WSTRB,
    output wire                                                 M_AXI_WLAST,
    input wire                                                  M_AXI_BVALID,
    output wire                                                 M_AXI_BREADY,
    input [AXI_ID_WIDTH-1:0]                                    M_AXI_BID,
    input wire [1:0]                                            M_AXI_BRESP,
    output wire                                                 M_AXI_ARVALID,
    input wire                                                  M_AXI_ARREADY,
    output wire [AXI_ID_WIDTH-1:0]                              M_AXI_ARID,
    output wire [AXI_ADDR_WIDTH-1:0]                            M_AXI_ARADDR,
    output wire [7:0]			                                M_AXI_ARLEN,
    output wire [2:0]                                           M_AXI_ARSIZE,
    output wire [1:0]                                           M_AXI_ARBURST,
    output	                                                    M_AXI_ARLOCK,
    output wire [3:0]                                           M_AXI_ARCACHE,
    output wire [2:0]                                           M_AXI_ARPROT,
    output wire [3:0]                                           M_AXI_ARQOS,
    input wire                                                  M_AXI_RVALID,
    output wire                                                 M_AXI_RREADY,
    input wire [AXI_ID_WIDTH-1:0]                               M_AXI_RID,
    input wire [AXI_DATA_WIDTH-1:0]                             M_AXI_RDATA,
    input wire                                                  M_AXI_RLAST,
    input wire [1:0]                                            M_AXI_RRESP,
    // Miscellanea
    input wire                                                  i_reset,
    output wire                                                 o_overflow,
    output wire                                                 o_mm2s_full,
    output wire                                                 o_empty,
    output wire [AXI_ADDR_WIDTH-($clog2(AXI_DATA_WIDTH)-3):0]   o_fill,
    output wire [LGMAXBURST+1:0]                                ififo_fill_o,
    output wire                                                 ififo_full_o,
    output wire [LGMAXBURST+1:0]                                ofifo_fill_o,
    output wire                                                 DATA_LOSS,
    output wire [AXI_ADDR_WIDTH-1:0]                            wptr,
    output wire [AXI_ADDR_WIDTH-1:0]                            rptr,
    input wire [31:0]                                           RING_BUFFER_LEN,
    input wire [31:0]                                           AXI_BASE_ADDR,
    input wire [31:0]                                           AXI_ADDR_MASK,
    output wire                                                 EOB,
    output wire [31:0]                                          WRITE_OFFSET
);

    // Derived constants
    localparam ADDRLSB  = $clog2(AXI_DATA_WIDTH) - 3;
    localparam MAXBURST = 1 << LGMAXBURST;
    localparam BURSTAW  = AXI_ADDR_WIDTH - LGMAXBURST - ADDRLSB;

    // Connetions
    reg                             soft_reset;
    reg                             vfifo_empty;
    reg                             vfifo_full;
    wire                            reset_fifo;
    reg [AXI_ADDR_WIDTH-ADDRLSB:0]  vfifo_fill;
    reg [BURSTAW:0]                 mem_data_available_w;
    reg [BURSTAW:0]                 writes_outstanding;
    reg [BURSTAW:0]                 mem_space_available_w;
    reg [BURSTAW:0]                 reads_outstanding;
    reg                             s_last_stalled;
    reg [AXI_DATA_WIDTH-1:0]        s_last_tdata;
    wire                            read_from_fifo;
    wire                            ififo_full;
    wire                            ififo_empty;
    wire [AXI_DATA_WIDTH-1:0]       ififo_data;
    wire [LGMAXBURST+1:0]           ififo_fill;
    reg                             start_write;
    reg                             phantom_write;
    reg                             axi_awvalid;
    reg                             axi_wvalid;
    reg                             axi_wlast;
    reg                             writes_idle;
    reg [AXI_ADDR_WIDTH-1:0]        axi_awaddr;
    reg [LGMAXBURST:0]              writes_pending;
    reg                             start_read;
    reg                             phantom_read;
    reg                             reads_idle;
    reg                             axi_arvalid;
    reg [AXI_ADDR_WIDTH-1:0]        axi_araddr;
    reg [LGMAXBURST+1:0]            ofifo_space_available;
    wire                            write_to_fifo;
    wire                            ofifo_empty;
    wire                            ofifo_full;
    wire[LGMAXBURST+1:0]            ofifo_fill;
    reg                             eob;
    reg                             data_loss;
    reg [31:0]                      writes_counter;
    reg [31:0]                      reads_counter;
    reg                             overflow;

        
    // Writes and Reads always happen at the size of a burst. Thus, comparing the number of Writes
    // and Reads against the length of the buffer is enough to tell whether a data loss has been
    // already experienced or not. The information will be latched until next soft reset, required
    // to re-establish the nominal operations
    always @(posedge CLK) begin
        if(reset_fifo) begin
            data_loss <= 1'b0;
        end
        else if(!data_loss && mem_data_available_w > RING_BUFFER_LEN) begin
            data_loss <= 1'b1;
        end
    end

    always @(posedge CLK) begin
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

    // This is how we reset the FIFO without resetting the rest of the AXI bus.  On a reset request,
    // we raise the soft_reset flag and reset all of our internal FIFOs.  We also stop issuing bus
    // commands.  Once all outstanding bus commands come to a halt, then we release from reset and
    // start operating as a FIFO.
    always @(posedge CLK) begin
        if(!RSTN) begin
            soft_reset <= 0;
        end
        else if(i_reset) begin
            soft_reset <= 1;
        end
        else if(writes_idle && reads_idle) begin
            soft_reset <= 0;
        end
    end

    assign reset_fifo = soft_reset || !RSTN;

    // Calculating the fill of the virtual FIFO, and the associated full/empty flags that go with it
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            // In  EXTERNAL_READ_ITF  mode we lose the concept of VFIFO filling, since we cannot 
            // intercept Reads to the buffer. So that, conventionally, we show the buffer empty to 
            // the external world
            assign vfifo_fill   = 0;
            assign vfifo_empty  = 1;
            assign vfifo_full   = 0;
        end
        else begin
            always @(posedge CLK)
            if(!RSTN || soft_reset)
            begin
                vfifo_fill <= 0;
                vfifo_empty <= 1;
                vfifo_full <= 0;
            end
            else begin
                case({ S_AXIS_TVALID && S_AXIS_TREADY, M_AXIS_TVALID && M_AXIS_TREADY })
                    2'b10: begin
                        vfifo_fill <= vfifo_fill + 1;
                        vfifo_empty <= 0;
                        vfifo_full <= (&vfifo_fill[AXI_ADDR_WIDTH-ADDRLSB-1:0]);
                    end

                    2'b01: begin
                        vfifo_fill <= vfifo_fill - 1;
                        vfifo_full <= 0;
                        vfifo_empty <= (vfifo_fill <= 1);
                    end
            
                    default: begin
                        vfifo_fill <= vfifo_fill;
                        vfifo_full <= vfifo_full;
                        vfifo_empty <= vfifo_empty;
                    end
                endcase
            end
        end
    endgenerate

    // Determining when the write half is idle is required to know when to come out of soft reset.
    // The first step is to count the number of bursts that remain outstanding
    always @(posedge CLK) begin
        if(!RSTN) begin
            writes_outstanding <= 0;
        end
        else begin
            case({ phantom_write, M_AXI_BVALID && M_AXI_BREADY })
                2'b01: begin
                    writes_outstanding <= writes_outstanding - 1;
                end

                2'b10: begin
                    writes_outstanding <= writes_outstanding + 1;
                end

                default: begin 
                    writes_outstanding <= writes_outstanding;
                end
            endcase
        end
    end

    // The second step is to use this counter to determine if we are idle.  If WVALID is ever high,
    // or start_write goes high, then we are obviously not idle.  Otherwise, we become idle when the
    // number of writes outstanding transitions to (or equals) zero.
    always @(posedge CLK) begin
        if(!RSTN) begin
            writes_idle <= 1'b1;
        end
        else begin
            if (start_write || M_AXI_WVALID) begin
                writes_idle <= 1'b0;
            end
            else begin
                writes_idle <= (writes_outstanding == ((M_AXI_BVALID && M_AXI_BREADY) ? 1'b1 : 1'b0));
            end
        end
    end

    // Count how much space is used in the memory device.  Well, obviously, we can't fill our memory
    // device or we have problems.  To make sure we don't overflow, we count memory usage here.
    // We'll count memory usage in units of bursts of (1<<LGMAXBURST) words of (1<<ADDRLSB) bytes
    // each.  So ... here we count the amount of device memory that hasn't (yet) been committed.
    // This is different from the memory used (which we don't calculate), or the memory which may
    // yet be read--which we'll calculate in a moment.
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            // In  EXTERNAL_READ_ITF  mode we lose the concept of available space in memory, since
            // the Read interface is external
            assign mem_space_available_w = (1 << BURSTAW);
        end
        else begin
            always @(posedge CLK) begin
                if(!RSTN || soft_reset) begin
                    mem_space_available_w <= (1<<BURSTAW);
                end
                else begin
                    case({ phantom_write, M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST })
                        2'b01: begin
                            mem_space_available_w <= mem_space_available_w + 1;
                        end
                        
                        2'b10: begin
                            mem_space_available_w <= mem_space_available_w - 1;
                        end

                        default: begin 
                            mem_space_available_w <= mem_space_available_w;
                        end
                    endcase
                end
            end
        end
    endgenerate

    // Determining when the read half is idle. Count the number of read bursts that we've committed
    // to. This includes bursts that have ARVALID but haven't been accepted, as well as any the
    // downstream device will yet return an RLAST for.
    always @(posedge CLK) begin
        if(!RSTN) begin
            reads_outstanding <= 0;
        end
        else begin
            case({ phantom_read, M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST })
                2'b01: begin
                    reads_outstanding <= reads_outstanding - 1;
                end

                2'b10: begin
                    reads_outstanding <= reads_outstanding + 1;
                end

                default: begin
                    reads_outstanding <= reads_outstanding;
                end
            endcase
        end
    end

    // Now, using the reads_outstanding counter, we can check whether or not we are idle (and can
    // exit a reset) of if instead there are more bursts outstanding to wait for. By registering
    // this counter, we can keep the soft_reset release simpler. At least this way, it doesn't need
    // to check two counters for zero.
    always @(posedge CLK) begin
        if(!RSTN) begin
            reads_idle <= 1'b1;
        end
        else begin
            if(start_read || M_AXI_ARVALID) begin
                reads_idle <= 1'b0;
            end
            else begin
                reads_idle <= (reads_outstanding == ((M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) ? 1'b1 : 1'b0));
            end
        end
    end

    // Count how much data is in the memory device that we can read out.  In AXI, after you issue
    // a write, you can't depend upon that data being present on the device and available for a read
    // until the associated BVALID is returned.  Therefore we don't count any memory as available to
    // be read until BVALID comes back.  Once a read command is issued, the memory is again no
    // longer available to be read.  Note also that we are counting bursts here.  A second
    // conversion below converts this count to bytes.
    always @(posedge CLK) begin
        if(!RSTN || soft_reset) begin
            mem_data_available_w <= 0;
        end
        else begin
            case({ M_AXI_BVALID, phantom_read })
                2'b10: begin
                    mem_data_available_w <= mem_data_available_w + 1;
                end

                2'b01: begin
                    mem_data_available_w <= mem_data_available_w - 1;
                end

                default: begin
                    mem_data_available_w <= mem_data_available_w;
                end
            endcase
        end
    end

    // Incoming stream overflow detection.  The overflow flag is set if ever an incoming value
    // violates the stream protocol and changes while stalled.  Internally, however, the overflow
    // flag is ignored.  It's provided for your information.
    always @(posedge CLK) begin
        if(!RSTN) begin
            s_last_stalled <= 0;
        end
        else begin
            s_last_stalled <= S_AXIS_TVALID && !S_AXIS_TREADY;
        end
    end

    always @(posedge CLK) begin
        if(S_AXIS_TVALID) begin
            s_last_tdata <= S_AXIS_TDATA;
        end
    end

    always @(posedge CLK) begin
        if(!RSTN || soft_reset) begin
            overflow <= 1'b0;
        end
        else if (s_last_stalled) begin
            if(!S_AXIS_TVALID) begin
                overflow <= 1;
            end

            if(S_AXIS_TDATA != s_last_tdata) begin
                overflow <= 1;
            end
        end
    end

    assign	read_from_fifo= (M_AXI_WVALID && M_AXI_WREADY);

    SIMPLE_FIFO #(
        .BW                 (AXI_DATA_WIDTH),
        .LGFLEN             (LGMAXBURST+1),
        .OPT_ASYNC_READ     (1'b1),
        .OPT_WRITE_ON_FULL  (1'b0),
        .OPT_READ_ON_EMPTY  (1'b0)
    )
    ififo (
        .i_clk      (CLK),
        .i_reset    (reset_fifo),
        .i_wr       (S_AXIS_TVALID && S_AXIS_TREADY),
        .i_data     (S_AXIS_TDATA),
        .o_full     (ififo_full),
        .o_fill     (ififo_fill),
        .i_rd       (read_from_fifo),
        .o_data     (ififo_data),
        .o_empty    (ififo_empty)
    );

    // start_write: determining when to issue a write burst
    always @(*) begin
        start_write = 0;

        if(ififo_fill >= (1<<LGMAXBURST)) begin
            start_write = 1;
        end

        if(vfifo_full || soft_reset || phantom_write) begin
            start_write = 0;
        end

        if(mem_space_available_w == 0) begin
            start_write = 0;
        end

        if(M_AXI_WVALID && (!M_AXI_WREADY || !M_AXI_WLAST)) begin
            start_write = 0;
        end

        if(M_AXI_AWVALID && !M_AXI_AWREADY) begin
            start_write = 0;
        end
    end

    // Register the start write signal into AWVALID and phantom write.  phantom_write contains the
    // start signal, but immediately clears on the next clock cycle.  This allows us some time to
    // calculate the data for the next burst which and if AWVALID remains high and not yet accepted.
    always @(posedge CLK) begin
        if(!RSTN) begin
            phantom_write <= 0;
        end
        else begin
            phantom_write <= start_write;
        end
    end

    // Set AWVALID to start_write if every the channel isn't stalled.  Incidentally, start_write is
    // guaranteed to be zero if the channel is stalled, since that signal is used by other things as
    // well.
    always @(posedge CLK) begin
        if(!RSTN) begin
            axi_awvalid <= 0;
        end
        else if(!M_AXI_AWVALID || M_AXI_AWREADY) begin
            axi_awvalid <= start_write;
        end
    end

    // Write address.  We insist on alignment.  On every accepted burst, we step forward by one
    // burst length.  On reset, we reset the address at our first opportunity.
    always @(posedge CLK) begin
        if(!RSTN) begin
            axi_awaddr <= 0;
        end
        else begin
            // Alignment!
            axi_awaddr[LGMAXBURST+ADDRLSB-1:0] <= 0;

            if((!M_AXI_AWVALID || M_AXI_AWREADY) && soft_reset) begin
                axi_awaddr <= 0;
            end
            else if(M_AXI_AWVALID && M_AXI_AWREADY) begin
                axi_awaddr[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_awaddr[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];
            end
        end
    end  
    

    // Write data channel valid
    always @(posedge CLK) begin
        if(!RSTN) begin
            axi_wvalid <= 0;
        end
        else if(start_write) begin
            axi_wvalid <= 1;
        end
        else if(!M_AXI_WVALID || M_AXI_WREADY) begin
            axi_wvalid <= M_AXI_WVALID && !M_AXI_WLAST;
        end
    end

    // WLAST generation.  On the beginning of any burst, start a counter of the number of items in
    // it.  Once the counter gets to 1, set WLAST.
    always @(posedge CLK) begin
        if(!RSTN) begin
            writes_pending <= 0;
        end
        else if(start_write) begin
            writes_pending <= MAXBURST;
        end
        else if(M_AXI_WVALID && M_AXI_WREADY) begin
            writes_pending <= writes_pending -1;
        end
    end

    always @(posedge CLK) begin
        if(start_write) begin
            axi_wlast <= (LGMAXBURST == 0);
        end
        else if(!M_AXI_WVALID || M_AXI_WREADY) begin
            axi_wlast <= (writes_pending == 1 + (M_AXI_WVALID ? 1:0));
        end
    end

    // How much FIFO space is available?  One we issue a read command, the FIFO space isn't
    // available any more.  That way we can determine when a second read can be issued--even before
    // the first has returned--while also guaranteeing that there's always room in the outgoing FIFO
    // for anything that might return.  Remember: NEVER generate backpressure in a bus master
    always @(posedge CLK) begin
        if(reset_fifo) begin
            ofifo_space_available <= (1<<(LGMAXBURST+1));
        end
        else begin
            case({phantom_read, M_AXIS_TVALID && M_AXIS_TREADY})
                2'b10: begin
                    ofifo_space_available <= ofifo_space_available - MAXBURST;
                end

                2'b01: begin
                    ofifo_space_available <= ofifo_space_available + 1;
                end

                2'b11: begin
                    ofifo_space_available <= ofifo_space_available - MAXBURST + 1;
                end

                default: begin
                    ofifo_space_available <= ofifo_space_available;
                end
            endcase
        end
    end

    // Determine when to start a next read-from-memory-to-FIFO burst
    generate
        if(EXTERNAL_READ_ITF == 1) begin
            assign start_read = 1'b0;
        end
        else begin
            always @(*) begin
                start_read = 1;

                // We can't read yet if we don't have space available.
                // Note the comparison is carefully chosen to make certain
                // it doesn't use all ofifo_space_available bits, but rather
                // only the number of bits between (LGMAXBURST+1) and
                // LGMAXBURST--nominally a single bit.
                if(ofifo_space_available < MAXBURST) begin
                    start_read = 0;
                end

                // If there's no memory available for us to read from, then
                // we can't start a read yet.
                if(!M_AXI_BVALID && mem_data_available_w == 0) begin
                    start_read = 0;
                end

                // Don't start anything while waiting on a reset.  Likewise,
                // insist on a minimum one clock between read burst issuances.
                if(soft_reset || phantom_read) begin
                    start_read = 0;
                end

                // We can't start a read request if the AR* channel is stalled
                if(M_AXI_ARVALID && !M_AXI_ARREADY) begin
                    start_read = 0;
                end
            end
        end
    endgenerate
        
    // Set phantom_read and ARVALID
    always @(posedge CLK) begin
        if(!RSTN) begin
            phantom_read <= 0;
        end
        else begin
            phantom_read <= start_read;
        end
    end

    always @(posedge CLK) begin
        if(!RSTN) begin
            axi_arvalid <= 0;
        end
        else if (!M_AXI_ARVALID || M_AXI_ARREADY) begin
            axi_arvalid <= start_read;
        end
    end

    // Calculate the next ARADDR
    always @(posedge CLK) begin
        if (!RSTN) begin
            axi_araddr <= 0;
        end
        else begin
            axi_araddr[LGMAXBURST+ADDRLSB-1:0] <= 0;

            if(M_AXI_ARVALID && M_AXI_ARREADY) begin
                axi_araddr[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] <= (axi_araddr[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB] + 1) & AXI_ADDR_MASK[AXI_ADDR_WIDTH-1:LGMAXBURST+ADDRLSB];
            end

            if((!M_AXI_ARVALID || M_AXI_ARREADY) && soft_reset) begin
                axi_araddr <= 0;
            end
        end
    end


    // We basically just stuff the data read from memory back into our
    // outgoing FIFO here.  The logic is quite straightforward.
    assign write_to_fifo = M_AXI_RVALID && M_AXI_RREADY;

    SIMPLE_FIFO #(
        .BW                 (AXI_DATA_WIDTH),
        .LGFLEN             (LGMAXBURST+1),
        .OPT_ASYNC_READ     (1'b1),
        .OPT_WRITE_ON_FULL  (1'b0),
        .OPT_READ_ON_EMPTY  (1'b0)
    )
    ofifo (
        .i_clk      (CLK),
        .i_reset    (reset_fifo),
        .i_wr       (write_to_fifo),
        .i_data     (M_AXI_RDATA),
        .o_full     (ofifo_full),
        .o_fill     (ofifo_fill),
		.i_rd       (M_AXIS_TVALID && M_AXIS_TREADY),
        .o_data     (M_AXIS_TDATA),
        .o_empty    (ofifo_empty)
    );

    // Generate a pulse every time the burst ends
    always @(posedge CLK) begin
        if(!RSTN) begin
            eob <= 1'b0;
        end
        else begin
            eob <= 1'b0;
            
            if(!eob && M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST) begin
                eob <= 1'b1;
            end
        end
    end
    
    // Pinout
    assign DATA_LOSS        = data_loss;
    assign wptr             = AXI_BASE_ADDR + axi_awaddr;
    assign rptr             = AXI_BASE_ADDR + axi_araddr;
    assign EOB              = eob;
    assign o_fill           = vfifo_fill;
    assign o_empty          = vfifo_empty;
    assign S_AXIS_TREADY    = !reset_fifo && !ififo_full && !vfifo_full;
    assign ififo_full_o     = ififo_full;
    assign WRITE_OFFSET     = axi_awaddr;
    assign M_AXI_AWVALID    = axi_awvalid;
    assign M_AXI_AWID       = 0;
    assign M_AXI_AWADDR     = AXI_BASE_ADDR + axi_awaddr;
    assign M_AXI_AWLEN      = MAXBURST-1;
    assign M_AXI_AWSIZE     = ADDRLSB[2:0];
    assign M_AXI_AWBURST    = 2'b01;
    assign M_AXI_AWLOCK     = 0;
    assign M_AXI_AWCACHE    = 0;
    assign M_AXI_AWPROT     = 0;
    assign M_AXI_AWQOS      = 0;
    assign M_AXI_WVALID     = axi_wvalid;
    assign M_AXI_WDATA      = ififo_data;
    assign M_AXI_WLAST      = axi_wlast;
    assign M_AXI_WSTRB      = -1;
    assign M_AXI_BREADY     = 1;
    assign M_AXI_ARVALID    = axi_arvalid;
    assign M_AXI_ARID       = 0;
    assign M_AXI_ARADDR     = AXI_BASE_ADDR + axi_araddr;
    assign M_AXI_ARLEN      = MAXBURST-1;
    assign M_AXI_ARSIZE     = ADDRLSB[2:0];
    assign M_AXI_ARBURST    = 2'b01;
    assign M_AXI_ARLOCK     = 0;
    assign M_AXI_ARCACHE    = 0;
    assign M_AXI_ARPROT     = 0;
    assign M_AXI_ARQOS      = 0;
    assign M_AXI_RREADY     = 1;
	assign M_AXIS_TVALID    = !ofifo_empty;
    assign o_mm2s_full      = |ofifo_fill[LGMAXBURST+1:LGMAXBURST];
    assign ififo_fill_o     = ififo_fill;
    assign ofifo_fill_o     = ofifo_fill;
    assign o_overflow       = overflow;
endmodule

`default_nettype wire
