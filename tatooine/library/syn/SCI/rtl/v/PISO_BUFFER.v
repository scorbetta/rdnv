`default_nettype none

// Parallel-in/Serial-out buffer
module PISO_BUFFER
#(
    parameter DEPTH = 8
)
(
    input wire              CLK,
    input wire [DEPTH-1:0]  PIN,
    input wire              LOAD_IN,
    input wire              SHIFT_OUT,
    output wire             SOUT
);

    wire [DEPTH-1:0]    flop_inputs;
    wire [DEPTH:0]      flop_outputs;
    genvar              gdx;

    //  LOAD_IN  is used to load data from the  PIN  word inside the flops
    //  SHIFT_OUT  is used to shift data
    generate
        for(gdx = 0; gdx < DEPTH; gdx = gdx + 1) begin
            D_FF_EN DFFEN (
                .CLK    (CLK),
                .RSTN   (1'b1),
                .D      (flop_inputs[gdx]),
                .EN     (LOAD_IN | SHIFT_OUT),
                .Q      (flop_outputs[gdx])
            );

            assign flop_inputs[gdx] = (LOAD_IN == 1'b1) ? PIN[gdx] : flop_outputs[gdx+1];
        end
    endgenerate

    // Last flop (MSB) has no precedent flop
    assign flop_outputs[DEPTH] = PIN[DEPTH-1];

    // Serial out through LSB
    assign SOUT = flop_outputs[0];
endmodule

`default_nettype wire
