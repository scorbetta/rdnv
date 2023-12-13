`default_nettype none

// A simple and reusable free-running counter
module COUNTER #(
    parameter WIDTH = 64
)
(
    input wire              CLK,
    input wire              RSTN,
    input wire              EN,
    output wire [WIDTH-1:0] VALUE,
    output wire             OVERFLOW
);

    reg [WIDTH-1:0] value;
    reg             overflow;

    always @(posedge CLK) begin
        if(RSTN == 1'b0) begin
            value <= 0;
            overflow <= 1'b0;
        end
        else if(EN == 1'b1) begin
            { overflow, value } <= value + 1;
        end
    end

    // Pinouts
    assign VALUE    = value;
    assign OVERFLOW = overflow;
endmodule

`default_nettype wire
