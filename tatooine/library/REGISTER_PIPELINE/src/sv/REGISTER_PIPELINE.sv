`timescale 1ns/100ps

module REGISTER_PIPELINE
#(
    parameter DATA_WIDTH    = 1,
    parameter RESET_VALUE   = 1'b0,
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
    REGISTER #(
        .DATA_WIDTH     (DATA_WIDTH),
        .RESET_VALUE    (RESET_VALUE)
    )
    PIPE_STAGE (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (CE),
        .DATA_IN    (pipe_data_in[0]),
        .DATA_OUT   (pipe_data_out[0])
    );

    assign pipe_data_in[0] = DATA_IN;

    // Configurable number of stages
    generate
        for(genvar pdx = 1; pdx < NUM_STAGES; pdx++) begin
            REGISTER #(
                .DATA_WIDTH     (DATA_WIDTH),
                .RESET_VALUE    (RESET_VALUE)
            )
            PIPE_STAGE (
                .CLK        (CLK),
                .RSTN       (RSTN),
                .CE         (CE),
                .DATA_IN    (pipe_data_in[pdx]),
                .DATA_OUT   (pipe_data_out[pdx])
            );

            assign pipe_data_in[pdx] = pipe_data_out[pdx-1];
        end
    endgenerate

    // Footer
    assign DATA_OUT = pipe_data_out[NUM_STAGES-1];
endmodule
