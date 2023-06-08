`timescale 1ns/100ps

module PARAMETRIC_MUX #(
    // Input and output data width
    parameter   DATA_WIDTH = 1,
    // Number of inputs
    parameter   NUM_INPUTS = 2
)
(
    input [DATA_WIDTH-1:0]          BUS_IN [NUM_INPUTS],
    input [$clog2(NUM_INPUTS)-1:0]  SEL_IN,
    output [DATA_WIDTH-1:0]         BUS_OUT
);

    logic [DATA_WIDTH-1:0]  bus_out;

    assign bus_out = BUS_IN[SEL_IN];

    assign BUS_OUT = bus_out;
endmodule
