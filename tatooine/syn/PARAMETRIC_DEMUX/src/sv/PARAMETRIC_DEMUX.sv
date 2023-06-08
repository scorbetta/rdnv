`timescale 1ns/100ps

module PARAMETRIC_DEMUX #(
    // Input and output data width
    parameter   DATA_WIDTH = 1,
    // Number of outputs
    parameter   NUM_OUTPUTS = 2
)
(
    input [DATA_WIDTH-1:0]          BUS_IN,
    input [$clog2(NUM_OUTPUTS)-1:0] SEL_IN,
    output [DATA_WIDTH-1:0]         BUS_OUT [NUM_OUTPUTS]
);

    logic [DATA_WIDTH-1:0]  bus_out [NUM_OUTPUTS];

    // Unselected outputs will not change
    always_comb begin
        for(integer sel = 0; sel < NUM_OUTPUTS; sel++) begin
            if(sel == SEL_IN) begin
                bus_out[sel] = BUS_IN;
            end
        end
    end

    assign BUS_OUT = bus_out;
endmodule
