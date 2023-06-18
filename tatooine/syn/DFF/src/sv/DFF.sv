`timescale 1ns/100ps

// A reusable D-type flop model
module DFF
(
    input   CLK,
    input   RSTN,
    input   D,
    output  Q
);

    logic q;

    always_ff @(posedge CLK) begin
        if(!RSTN) begin
            q <= 1'b0;
        end
        else begin
            q <= D;
        end
    end

    assign Q = q;
endmodule
