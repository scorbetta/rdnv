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
    output wire                     VALID_OUT,
    output wire                     OVERFLOW
);

    reg signed [2*WIDTH-1:0]    a_times_b;
    reg                         mul_valid;
    wire                        overflow;
    wire                        value_a_sign;
    wire                        value_b_sign;
    wire                        value_out_sign;

    always @(posedge CLK) begin
        if(!RSTN) begin
            a_times_b <= 0;
            mul_valid <= 1'b0;
        end
        else begin
            mul_valid <= 1'b0;

            if(VALID_IN) begin
                // Rebase to the proper base
                a_times_b <= VALUE_A_IN * VALUE_B_IN;
                mul_valid <= 1'b1;
            end
        end
    end

    // Overflow in multiplication never actually occurs, since we are reserving twice the number of
    // bits of the operands for the result. Still, we consider overflow that case when the sign of
    // the result is different than the expected, similar to what it's done with the addition
    assign value_a_sign     = VALUE_A_IN[WIDTH-1];
    assign value_b_sign     = VALUE_B_IN[WIDTH-1];
    assign value_out_sign   = VALUE_OUT[WIDTH-1];
    assign overflow         = (~value_a_sign & ~value_b_sign & value_out_sign) | (~value_a_sign & value_b_sign & ~value_out_sign) | (value_a_sign & ~value_b_sign & ~value_out_sign) | (value_a_sign & value_b_sign & value_out_sign);

    // Pinout
    assign VALUE_OUT    = a_times_b[FRAC_BITS +: WIDTH];
    assign VALID_OUT    = mul_valid;
    assign OVERFLOW     = overflow;
endmodule

`default_nettype wire
