`default_nettype none

module SCI_SLAVE #(
    parameter ADDR_WIDTH    = 8,
    parameter DATA_WIDTH    = 8
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // SCI interface
    input wire                      SCI_CSN,
    input wire                      SCI_REQ,
    output wire                     SCI_RESP,
    output wire                     SCI_ACK,
    // Native interface
    output wire                     NI_WREQ,
    output wire [ADDR_WIDTH-1:0]    NI_WADDR,
    output wire [DATA_WIDTH-1:0]    NI_WDATA,
    input wire                      NI_WACK,
    output wire                     NI_RREQ,
    output wire [ADDR_WIDTH-1:0]    NI_RADDR,
    input wire [DATA_WIDTH-1:0]     NI_RDATA,
    input wire                      NI_RVALID
);

    localparam IDLE             = 3'b000;
    localparam SCI_ADDR_PHASE   = 3'b001;
    localparam SCI_DATA_PHASE   = 3'b010;
    localparam NI_WDATA_PHASE   = 3'b100;
    localparam NI_RDATA_PHASE   = 3'b101;

    reg [2:0]                       curr_state;
    reg                             sci_req;
    reg                             sci_csn;
    wire                            open_req;
    wire                            count_rstn;
    wire                            sci_resp_enable;
    wire                            sci_ack_enable;
    wire                            sci_ack;
    reg                             wnr;
    wire                            addr_count_en;
    wire [$clog2(ADDR_WIDTH)-1:0]   addr_count;
    wire                            data_count_en;
    wire [$clog2(DATA_WIDTH)-1:0]   data_count;
    wire [ADDR_WIDTH-1:0]           reg_addr;
    wire [DATA_WIDTH-1:0]           reg_wdata;
    reg                             ni_wreq;
    reg                             ni_rreq;
    wire                            rdata_shift;

    // Resample internally
    always @(posedge CLK) begin
        sci_req <= SCI_REQ;
    end

    always @(posedge CLK) begin
        sci_csn <= SCI_CSN;
    end

    // Detect request open (Master-triggered)
    EDGE_DETECTOR NEW_REQ_DETECTOR (
        .CLK            (CLK),
        .SAMPLE_IN      (sci_csn),
        .RISE_EDGE_OUT  (), // Unused
        .FALL_EDGE_OUT  (open_req)
    );

    // Reset counters any time a new request arrives
    assign count_rstn = ~open_req | ni_rreq;

    // Control engine
    always @(posedge CLK) begin
        if(!RSTN) begin
            curr_state <= IDLE;
        end
        else begin
            case(curr_state)
                IDLE : begin
                    if(open_req) begin
                        wnr <= sci_req;
                        curr_state <= SCI_ADDR_PHASE;
                    end
                end

                SCI_ADDR_PHASE : begin
                    if(addr_count == ADDR_WIDTH-1) begin
                        if(wnr) begin
                            curr_state <= SCI_DATA_PHASE;
                        end
                        else begin
                            curr_state <= NI_RDATA_PHASE;
                        end
                    end
                end

                SCI_DATA_PHASE : begin
                    if(data_count == DATA_WIDTH-1) begin
                        if(wnr) begin
                            curr_state <= NI_WDATA_PHASE;
                        end
                        else begin
                            curr_state <= IDLE;
                        end
                    end
                end

                NI_WDATA_PHASE : begin
                    if(NI_WACK) begin
                        curr_state <= IDLE;
                    end
                end

                NI_RDATA_PHASE : begin
                    if(NI_RVALID) begin
                        curr_state <= SCI_DATA_PHASE;
                    end
                end

                default : begin
                end
            endcase
        end
    end

    // Receive addresses bits
    COUNTER #(
        .WIDTH  ($clog2(ADDR_WIDTH))
    )
    ADDR_COUNTER (
        .CLK        (CLK),
        .RSTN       (count_rstn),
        .EN         (addr_count_en),
        .VALUE      (addr_count),
        .OVERFLOW   () // Unused
    );

    assign addr_count_en = (curr_state == SCI_ADDR_PHASE) ? 1'b1 : 1'b0;

    SIPO_BUFFER #(
        .DEPTH  (ADDR_WIDTH)
    )
    ADDRESS_BUFFER (
        .CLK    (CLK),
        .SIN    (sci_req),
        .EN     (addr_count_en),
        .POUT   (reg_addr)
    );

    // Counter is shared between Write/REQ and Read/RESP phases
    COUNTER #(
        .WIDTH  ($clog2(DATA_WIDTH))
    )
    DATA_COUNTER (
        .CLK        (CLK),
        .RSTN       (count_rstn),
        .EN         (data_count_en),
        .VALUE      (data_count),
        .OVERFLOW   () // Unused
    );

    assign data_count_en = (curr_state == SCI_DATA_PHASE) ? 1'b1 : 1'b0;

    // Receive data bits
    SIPO_BUFFER #(
        .DEPTH  (DATA_WIDTH)
    )
    WDATA_BUFFER (
        .CLK    (CLK),
        .SIN    (sci_req),
        .EN     (data_count_en),
        .POUT   (reg_wdata)
    );

    // Write to local regmap
    always @(posedge CLK) begin
        if(!RSTN) begin
            ni_wreq <= 1'b0;
        end
        else begin
            ni_wreq <= 1'b0;

            if(wnr && (curr_state == SCI_DATA_PHASE) && (data_count == DATA_WIDTH-1)) begin
                ni_wreq <= 1'b1;
            end
        end
    end

    assign NI_WREQ  = ni_wreq;
    assign NI_WADDR = reg_addr;
    assign NI_WDATA = reg_wdata;

    // Latch data from local regmap
    PISO_BUFFER #(
        .DEPTH  (DATA_WIDTH)
    )
    RDATA_BUFFER (
        .CLK        (CLK),
        .PIN        (NI_RDATA),
        .LOAD_IN    (NI_RVALID),
        .SHIFT_OUT  (rdata_shift),
        .SOUT       (SCI_RESP)
    );

    assign rdata_shift = ((curr_state == SCI_DATA_PHASE) && !wnr) ? 1'b1 : 1'b0;

    always @(posedge CLK) begin
        if(!RSTN) begin
            ni_rreq <= 1'b0;
        end
        else begin
            ni_rreq <= 1'b0;

            if(!wnr && (curr_state == SCI_ADDR_PHASE) && (addr_count == ADDR_WIDTH-1)) begin
                ni_rreq <= 1'b1;
            end
        end
    end

    assign NI_RREQ  = ni_rreq;
    assign NI_RADDR = reg_addr;
    assign SCI_ACK  = (((curr_state == NI_WDATA_PHASE) && NI_WACK) || rdata_shift) ? 1'b1 : 1'b0;
endmodule

`default_nettype wire
