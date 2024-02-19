`default_nettype none

// Serial-in/Parallel-out buffer
module SIPO_BUFFER
#(
    parameter DEPTH = 8
)
(
    input wire              CLK,
    input wire              SIN,
    input wire              EN,
    output wire [DEPTH-1:0] POUT
);

    reg [DEPTH-1:0] data;

    // Shift toward right, serial data is shifted in LSB first
    always @(posedge CLK) begin
        if(EN) begin
            data <= { SIN, data[DEPTH-1:1] };
        end
    end

    // Parallel out!
    assign POUT = data;
endmodule

`default_nettype wire
