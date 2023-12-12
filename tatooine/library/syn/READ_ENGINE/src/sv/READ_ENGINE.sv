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
    input                   CLK,
    input                   RSTN,
    // Read request controller interface
    input                   READ_START,
    input [ADDR_WIDTH-1:0]  RADDR_START,
    input [31:0]            READ_LENGTH,
    output                  RREQ_COUNT_DONE,
    // Read response controller interface
    output                  RVALID_COPY,
    output [DATA_WIDTH-1:0] RDATA_COPY,
    output                  RVALID_COUNT_DONE,
    // Peripheral interface
    output                  RREQ,
    output [ADDR_WIDTH-1:0] RADDR,
    input                   RVALID,
    input [DATA_WIDTH-1:0]  RDATA
);

    // Signals
    logic [31:0]            rreq_counter;
    logic                   read_start_seen;
    logic [31:0]            read_length;
    logic [31:0]            read_length_minus_one;
    logic                   rreq_count_done;
    logic                   counter_rstn;
    logic [31:0]            rvalid_counter;
    logic                   rvalid_count_done;
    logic                   rreq;
    logic [ADDR_WIDTH-1:0]  raddr;
    
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
    always_ff @(posedge CLK) begin
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
    always_ff @(posedge CLK) begin
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
