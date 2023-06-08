// Simple Dual Port RAM with configurable zero-latency Reads
module SDPRAM #(
    // Row width [bit]
    parameter   WIDTH   = 64,
    // Number of rows
    parameter   DEPTH   = 512,
    // If enabled, Read data always present at zero-latency
    parameter   ZL_READ = 0
)
(
    input                       CLK,
    input                       RST,
    input                       WEN,
    input [$clog2(DEPTH)-1:0]   WADDR,
    input [WIDTH-1:0]           WDATA,
    input [(WIDTH/8)-1:0]       WSTRB,
    input                       REN,
    input [$clog2(DEPTH)-1:0]   RADDR,
    output                      RVALID,
    output [WIDTH-1:0]          RDATA
);

    // The RAM block
    logic [WIDTH-1:0] ram [DEPTH] = '{ default: {WIDTH{1'b0}} };

    // Internal connections
    logic [WIDTH-1:0]   rdata;
    logic               rvalid;

    // Read interface
    generate
        // One cycle latency operation. Data is strobed with  RVALID  
        if(ZL_READ == 0) begin
            always_ff @(posedge CLK) begin
                if(RST == 1'b1) begin
                    rvalid <= 1'b0;
                end
                else if(REN) begin
                    rvalid <= 1'b1;
                    rdata <= ram[RADDR];
                end
                else begin
                    rvalid <= 1'b0;
                end
            end
        end

        // Zero latency operation. Data is always available, and  RVALID  has no meaning
        if(ZL_READ == 1) begin
            assign rvalid = 1'b0;
            assign rdata = ram[RADDR];
        end
    endgenerate

    // Write interface
    always_ff @(posedge CLK) begin
        if(WEN) begin
            for(integer bdx = 0; bdx < (WIDTH/8); bdx++) begin
                if(WSTRB[bdx] == 1'b1) begin
                    ram[WADDR][(bdx+1)*8-1 -: 8] <= WDATA[(bdx+1)*8-1 -: 8];
                end
            end
        end
    end
 
    // Pinout assignments
    assign RVALID   = rvalid;
    assign RDATA    = rdata;
endmodule
