// Single-clock, true dual-port RAM with Byte-enable and Read-first policy
module TDPRAM #(
    // Row width [bit]
    parameter   WIDTH = 64,
    // Number of rows
    parameter   DEPTH = 512
)
(
    // Clock and reset
    input                       CLK,
    input                       RST,
    // Port-A interface
    input [$clog2(DEPTH)-1:0]   PORTA_ADDR,
    input                       PORTA_REN,
    output                      PORTA_RVALID,
    output [WIDTH-1:0]          PORTA_RDATA,
    input                       PORTA_WEN,
    input [WIDTH-1:0]           PORTA_WDATA,
    input [(WIDTH/8)-1:0]       PORTA_WSTRB,
    // Port-B interface
    input [$clog2(DEPTH)-1:0]   PORTB_ADDR,
    input                       PORTB_REN,
    output                      PORTB_RVALID,
    output [WIDTH-1:0]          PORTB_RDATA,
    input                       PORTB_WEN,
    input [WIDTH-1:0]           PORTB_WDATA,
    input [(WIDTH/8)-1:0]       PORTB_WSTRB
);

    // Connections
    logic [WIDTH-1:0]   ram [DEPTH];
    logic [WIDTH-1:0]   porta_rdata;
    logic [WIDTH-1:0]   portb_rdata;
    logic               porta_rvalid;
    logic               portb_rvalid;

    // Port-A operation
    always_ff @(posedge CLK) begin
        if (PORTA_REN) begin
            porta_rdata <= ram[PORTA_ADDR];
        end
    end

    always_ff @(posedge CLK) begin
        if (PORTA_WEN) begin
            for(int bdx = 0; bdx < (WIDTH/8); bdx++) begin
                if(PORTA_WSTRB[bdx]) begin
                    ram[PORTA_ADDR][bdx*8 +: 8] <= PORTA_WDATA[bdx*8 +: 8];
                end
            end
        end
    end

    always_ff @(posedge CLK) begin
        if(RST) begin
            porta_rvalid <= 1'b0;
        end
        else begin
            porta_rvalid <= PORTA_REN;
        end
    end

    // Port-B operation
    always_ff @(posedge CLK) begin
        if (PORTB_REN) begin
            portb_rdata <= ram[PORTB_ADDR];
        end
    end

    always_ff @(posedge CLK) begin
        if (PORTB_WEN) begin
            for(int bdx = 0; bdx < (WIDTH/8); bdx++) begin
                if(PORTB_WSTRB[bdx]) begin
                    ram[PORTB_ADDR][bdx*8 +: 8] <= PORTB_WDATA[bdx*8 +: 8];
                end
            end
        end
    end

    always_ff @(posedge CLK) begin
        if(RST) begin
            portb_rvalid <= 1'b0;
        end
        else begin
            portb_rvalid <= PORTB_REN;
        end
    end

    // Pinout assignements
    assign PORTA_RVALID = porta_rvalid;
    assign PORTA_RDATA  = porta_rdata;
    assign PORTB_RVALID = portb_rvalid;
    assign PORTB_RDATA  = portb_rdata;

    /* synthesis translate_off */
    initial begin
        for(int row = 0; row < DEPTH; row++) begin
            ram[row] = {WIDTH{1'b0}};
        end
    end
    /* synthesis translate_on */
endmodule
