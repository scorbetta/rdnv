`default_nettype none

// This module controls Read transactions to peripherals that act RAM-like, i.e. accepting Read
// request (for instance through a Read enable signal) and generating Read data back strobed by an
// acknowledge signal (e.g., a Read valid). The controller counts number of Read requests sent and
// Read responses received separately, so that the forward path and the backward path can be timed
// independently, i.e. registers can be added on their path to help timing without taking care of
// the asymmetry. This leads to a latency insensitive design
module READ_ENGINE
#(
    parameter DATA_WIDTH    = 64,
    parameter ADDR_WIDTH    = 32
)
(
    // CLock and reset
    input wire                      CLK,
    input wire                      RSTN,
    // Read request controller interface
    input wire                      READ_START,
    input wire [ADDR_WIDTH-1:0]     RADDR_START,
    input wire [31:0]               READ_LENGTH,
    output wire                     RREQ_COUNT_DONE,
    // Read response controller interface
    output wire                     RVALID_COPY,
    output wire [DATA_WIDTH-1:0]    RDATA_COPY,
    output wire                     RVALID_COUNT_DONE,
    // Peripheral interface
    output wire                     RREQ,
    output wire [ADDR_WIDTH-1:0]    RADDR,
    input wire                      RVALID,
    input wire [DATA_WIDTH-1:0]     RDATA
);

    // Signals
    wire [31:0]             rreq_counter;
    reg                     read_start_seen;
    reg [31:0]              read_length;
    reg [31:0]              read_length_minus_one;
    wire                    rreq_count_done;
    wire                    counter_rstn;
    wire [31:0]             rvalid_counter;
    wire                    rvalid_count_done;
    reg                     rreq;
    reg [ADDR_WIDTH-1:0]    raddr;
    
    // Count number of requests
    COUNTER #(
        .WIDTH  (32)
    )
    RREQ_COUNTER (
        .CLK        (CLK),
        .RSTN       (counter_rstn),
        .EN         (rreq),
        .VALUE      (rreq_counter),
        .OVERFLOW   () // Unused
    );
    
    // Controller to generate a number of read requests
    always @(posedge CLK) begin
        if(!RSTN) begin
            read_start_seen <= 1'b0;
            rreq <= 1'b0;
        end
        else begin
            rreq <= 1'b0;
            
            if(READ_START && !read_start_seen) begin
                read_start_seen <= 1'b1;
                read_length <= READ_LENGTH;
                read_length_minus_one <= READ_LENGTH - 1;
                rreq <= 1'b1;
            end
            else if(read_start_seen && rreq_counter < read_length_minus_one) begin
                rreq <= 1'b1;
            end
            else if(read_start_seen && rreq_counter == read_length_minus_one) begin
                rreq <= 1'b0;
                read_start_seen <= 1'b0;
            end
        end
    end

    // Controller to generat correct addresses
    always @(posedge CLK) begin
        if(!RSTN) begin
            raddr <= 0;
        end
        else if(READ_START && !read_start_seen) begin
            raddr <= RADDR_START;
        end
        else if(read_start_seen) begin
            raddr <= raddr + 1;
        end
    end
    
    assign rreq_count_done = (rreq_counter == read_length);

    // Count number of responses
    COUNTER #(
        .WIDTH  (32)
    )
    RVALID_COUNTER (
        .CLK        (CLK),
        .RSTN       (counter_rstn),
        .EN         (RVALID),
        .VALUE      (rvalid_counter),
        .OVERFLOW   () // Unused
    );
    
    assign rvalid_count_done = (rvalid_counter == read_length);

    // Reset counters every time a new request is accepted
    assign counter_rstn = ~(READ_START & ~read_start_seen);
       
    // Pinout
    assign RREQ_COUNT_DONE      = rreq_count_done;
    assign RVALID_COUNT_DONE    = rvalid_count_done;
    assign RVALID_COPY          = RVALID;
    assign RDATA_COPY           = RDATA;
    assign RREQ                 = rreq;
    assign RADDR                = raddr;
endmodule

`default_nettype wire
