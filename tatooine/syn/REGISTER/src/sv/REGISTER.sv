`timescale 1ns/100ps

module REGISTER
#(
    parameter DATA_WIDTH    = 1,
    parameter RESET_VALUE   = 1'b0
)
(
    input                   CLK,
    input                   RSTN,
    input                   CE,
    input [DATA_WIDTH-1:0]  DATA_IN,
    output [DATA_WIDTH-1:0] DATA_OUT
);

    logic [DATA_WIDTH-1:0]  data_out;

    always_ff @(posedge CLK) begin
        if(!RSTN) begin
            data_out <= RESET_VALUE;
        end
        else if(CE) begin
            data_out <= DATA_IN;
        end
    end

    assign DATA_OUT = data_out;
endmodule
