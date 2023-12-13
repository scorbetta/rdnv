// A simple and reusable free-running counter
module COUNTER #(
    parameter WIDTH = 64
)
(
    input               CLK,
    input               RSTN,
    input               EN,
    output [WIDTH-1:0]  VALUE,
    output              OVERFLOW
);

    logic [WIDTH-1:0]   value;
    logic               overflow;

    always_ff @(posedge CLK) begin
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
