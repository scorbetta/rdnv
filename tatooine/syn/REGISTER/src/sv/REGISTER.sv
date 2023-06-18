`timescale 1ns/100ps

// A register of configurable width made of D-type flops w/ active-low reset
module REGISTER
#(
    parameter DATA_WIDTH = 1
)
(
    input                   CLK,
    input                   RSTN,
    input [DATA_WIDTH-1:0]  DATA_IN,
    output [DATA_WIDTH-1:0] DATA_OUT
);

    // Generate the register the structural way
    generate
        for(genvar gdx = 0; gdx < DATA_WIDTH; gdx++) begin
            DFF DFF (
                .CLK    (CLK),
                .RSTN   (RSTN),
                .D      (DATA_IN[gdx]),
                .Q      (DATA_OUT[gdx])
            );
        end
    endgenerate
endmodule
