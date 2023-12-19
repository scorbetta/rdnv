`default_nettype none

// Fixed-point multiplier with configurable representation
module FIXED_POINT_MUL
#(
    // The width of the input values consists of integral and fractional part
    parameter WIDTH     = 8,
    // Number of bits reserved to the fractional part. Also, the position of the binary point from
    // LSB. Must be strictly positive
    parameter FRAC_BITS = 3
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // Input operands
    input wire signed [WIDTH-1:0]   VALUE_A_IN,
    input wire signed [WIDTH-1:0]   VALUE_B_IN,
    input wire                      VALID_IN,
    // Output result
    output wire signed [WIDTH-1:0]  VALUE_OUT,
    output wire                     VALID_OUT
);

    reg signed [2*WIDTH-1:0]    a_times_b;
    reg                         mul_valid;

    always @(posedge CLK) begin
        if(!RSTN) begin
            a_times_b <= 0;
            mul_valid <= 1'b0;
        end
        else begin
            mul_valid <= 1'b0;

            if(VALID_IN) begin
                // Rebase to the proper base
                a_times_b <= (VALUE_A_IN * VALUE_B_IN) >> FRAC_BITS;
                mul_valid <= 1'b1;
            end
        end
    end

    // Pinout
    assign VALUE_OUT    = a_times_b[WIDTH-1:0];
    assign VALID_OUT    = mul_valid;
endmodule

`default_nettype wire
