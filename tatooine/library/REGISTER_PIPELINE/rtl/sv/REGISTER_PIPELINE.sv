`timescale 1ns/100ps

// A simple straight pipe of registers (RW_REG), aka a shift register. This can be used to help
// timing closure in congestioned designs. However, be aware that in FPGA designs shift registers
// are likely to be implemented in a single LUT, unless the compiler is told not to do so. When
// a shift register is implemented within a LUT the space spreading that helps timing closure is
// lost
module REGISTER_PIPELINE
#(
    parameter DATA_WIDTH    = 1,
    parameter NUM_STAGES    = 1
)
(
    input                   CLK,
    input                   RSTN,
    input                   CE,
    input [DATA_WIDTH-1:0]  DATA_IN,
    output [DATA_WIDTH-1:0] DATA_OUT
);

    // Internal connections
    logic [DATA_WIDTH-1:0]  pipe_data_in [NUM_STAGES];
    logic [DATA_WIDTH-1:0]  pipe_data_out [NUM_STAGES];

    // Header always present
    RW_REG #(
        .DATA_WIDTH (DATA_WIDTH),
        .HAS_RESET  (1)
    )
    PIPE_STAGE (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .WEN        (CE),
        .VALUE_IN   (pipe_data_in[0]),
        .VALUE_OUT  (pipe_data_out[0])
    );

    assign pipe_data_in[0] = DATA_IN;

    // Configurable number of stages
    generate
        for(genvar pdx = 1; pdx < NUM_STAGES; pdx++) begin
            RW_REG #(
                .DATA_WIDTH (DATA_WIDTH),
                .HAS_RESET  (1)
            )
            PIPE_STAGE (
                .CLK        (CLK),
                .RSTN       (RSTN),
                .WEN        (CE),
                .VALUE_IN   (pipe_data_in[pdx]),
                .VALUE_OUT  (pipe_data_out[pdx])
            );

            assign pipe_data_in[pdx] = pipe_data_out[pdx-1];
        end
    endgenerate

    // Footer
    assign DATA_OUT = pipe_data_out[NUM_STAGES-1];
endmodule
