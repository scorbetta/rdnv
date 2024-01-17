`default_nettype none

// Fixed-point adder
module FIXED_POINT_ADD
#(
    // The width of the input values
    parameter WIDTH     = 8,
    // Number of bits reserved to the fractional part. Also, the position of the binary point from
    // LSB. Must be strictly positive
    parameter FRAC_BITS = 3
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // Input operand
    input wire signed [WIDTH-1:0]   VALUE_A_IN,
    input wire signed [WIDTH-1:0]   VALUE_B_IN,
    input wire                      VALID_IN,
    // Outputs
    output wire signed [WIDTH-1:0]  VALUE_OUT,
    output wire                     VALID_OUT,
    output wire                     OVERFLOW
);

    reg signed [WIDTH-1:0]  value_out;
    reg                     valid_out;
    wire                    overflow;
    wire                    value_a_sign;
    wire                    value_b_sign;
    wire                    value_out_sign;

    always @(posedge CLK) begin
        if(!RSTN) begin
            valid_out <= 1'b0;
            value_out <= 0;
        end
        else begin
            valid_out <= 1'b0;

            if(VALID_IN) begin
                value_out <= VALUE_A_IN + VALUE_B_IN;
                valid_out <= 1'b1;
            end
        end
    end

    // Overflow occurs when input operands have same sign, but result has different
    assign value_a_sign     = VALUE_A_IN[WIDTH-1];
    assign value_b_sign     = VALUE_B_IN[WIDTH-1];
    assign value_out_sign   = VALUE_OUT[WIDTH-1];
    assign overflow         = (value_a_sign & value_b_sign & ~value_out_sign) | (~value_a_sign & ~value_b_sign & value_out_sign);

    // Pinout
    assign VALUE_OUT    = value_out;
    assign VALID_OUT    = valid_out;
    assign OVERFLOW     = overflow;
endmodule

`default_nettype wire
