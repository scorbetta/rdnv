`default_nettype none

// Scalable Configuration Interface
module SCI_MASTER
#(
    parameter ADDR_WIDTH        = 4,
    parameter DATA_WIDTH        = 8,
    parameter NUM_PERIPHERALS   = 2
)
(
    input wire                          CLK,
    input wire                          RSTN,
    // Request interface
    input wire                          REQ,
    input wire                          WNR,
    input wire [ADDR_WIDTH-1:0]         ADDR,
    input wire [NUM_PERIPHERALS-1:0]    CSN_IN,
    input wire [DATA_WIDTH-1:0]         DATA_IN,
    output wire                         ACK,
    output wire [DATA_WIDTH-1:0]        DATA_OUT,
    // Serial interface
    output wire [NUM_PERIPHERALS-1:0]   SCI_CSN,
    output wire                         SCI_REQ,
    input wire                          SCI_RESP,
    input wire                          SCI_ACK
);

    localparam IDLE         = 2'b00;
    localparam ADDR_PHASE   = 2'b01;
    localparam COUNT_DATA   = 2'b10;
    localparam WAIT_DATA    = 2'b11;

    reg [1:0]                       curr_state;
    wire                            new_req;
    wire                            wdata_shift;
    wire                            wdata;
    wire                            addr_shift;
    wire                            addr;
    reg                             sci_resp_q;
    reg                             sci_ack_q;
    wire                            count_rstn;
    wire                            addr_count_en;
    wire [$clog2(ADDR_WIDTH)-1:0]   addr_count;
    wire                            data_count_en;
    wire [$clog2(DATA_WIDTH)-1:0]   data_count;
    reg                             sci_req;
    reg [NUM_PERIPHERALS-1:0]       sci_csn;
    wire                            sci_ack_q_rise;
    wire                            sci_ack_q_fall;
    reg                             ack;
    wire                            sci_ack_qq_rise;
    wire                            sci_ack_qq_fall;

    // Detect new request
    EDGE_DETECTOR NEW_REQ_DETECTOR (
        .CLK            (CLK),
        .SAMPLE_IN      (REQ),
        .RISE_EDGE_OUT  (new_req),
        .FALL_EDGE_OUT  () // Unused
    );

    // Detect transaction closure by the Slave: rising edge over  SCI_ACK  during a Write, and
    // falling edge during a Read
    EDGE_DETECTOR ACK_Q_EDGE_DETECTOR (
        .CLK            (CLK),
        .SAMPLE_IN      (sci_ack_q),
        .RISE_EDGE_OUT  (sci_ack_q_rise),
        .FALL_EDGE_OUT  (sci_ack_q_fall)
    );

    // Latch address and data
    PISO_BUFFER #(
        .DEPTH  (ADDR_WIDTH)
    )
    ADDR_BUFFER (
        .CLK        (CLK),
        .PIN        (ADDR),
        .LOAD_IN    (REQ),
        .SHIFT_OUT  (addr_shift),
        .SOUT       (addr)
    );

    PISO_BUFFER #(
        .DEPTH  (DATA_WIDTH)
    )
    WDATA_BUFFER (
        .CLK        (CLK),
        .PIN        (DATA_IN),
        .LOAD_IN    (REQ),
        .SHIFT_OUT  (wdata_shift),
        .SOUT       (wdata)
    );

    SIPO_BUFFER #(
        .DEPTH  (DATA_WIDTH)
    )
    RDATA_BUFFER (
        .CLK    (CLK),
        .SIN    (sci_resp_q),
        .EN     (sci_ack_q),
        .POUT   (DATA_OUT)
    );

    // Control engine
    always @(posedge CLK) begin
        if(!RSTN) begin
            curr_state <= IDLE;
        end
        else begin
            case(curr_state)
                IDLE : begin
                    if(new_req) begin
                        curr_state <= ADDR_PHASE;
                    end
                end

                ADDR_PHASE : begin
                    if(addr_count == ADDR_WIDTH-1) begin
                        if(WNR) begin
                            curr_state <= COUNT_DATA;
                        end
                        else begin
                            curr_state <= WAIT_DATA;
                        end
                    end
                end

                COUNT_DATA : begin
                    if(data_count == DATA_WIDTH-1) begin
                        curr_state <= IDLE;
                    end
                end

                WAIT_DATA : begin
                    if(sci_ack_q_rise) begin
                        curr_state <= COUNT_DATA;
                    end
                end

                default : begin
                end
            endcase
        end
    end

    assign count_rstn = ~new_req;

    // Chip-select is kept alive throughout the entire transfer
    always @(posedge CLK) begin
        if(!RSTN) begin
            sci_csn <= {NUM_PERIPHERALS{1'b1}};
        end
        else if(new_req) begin
            sci_csn <= CSN_IN;
        end
        else if((!WNR && sci_ack_q_fall) || (WNR && sci_ack_q_rise)) begin
            sci_csn <= {NUM_PERIPHERALS{1'b1}};
        end
    end

    assign SCI_CSN = sci_csn;

    // Send address bits
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

    assign addr_count_en    = (curr_state == ADDR_PHASE) ? 1'b1 : 1'b0;
    assign addr_shift       = (curr_state == ADDR_PHASE) ? 1'b1 : 1'b0;

    // Send data bits
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

    assign data_count_en    = (curr_state == COUNT_DATA) ? 1'b1 : 1'b0;
    assign wdata_shift      = (curr_state == COUNT_DATA) ? 1'b1 : 1'b0;

    // Mux request, address and data
    always @(posedge CLK) begin
        case(curr_state)
            IDLE : begin
                sci_req <= WNR;
            end

            ADDR_PHASE :begin
                sci_req <= addr;
            end

            COUNT_DATA :begin
                sci_req <= wdata;
            end

            default : begin
                sci_req <= 1'b0;
            end
        endcase
    end

    assign SCI_REQ = sci_req;

    // Resample data from tri-state buffers
    always @(posedge CLK) begin
        if(!RSTN) begin
            sci_ack_q <= 1'b0;
            sci_resp_q <= 1'b0;
        end
        else begin
            sci_ack_q <= SCI_ACK;
            sci_resp_q <= SCI_RESP;
        end
    end

    // Local ack
    assign ACK = (~WNR & sci_ack_q_fall) | (WNR & sci_ack_q_rise);
endmodule

`default_nettype wire
