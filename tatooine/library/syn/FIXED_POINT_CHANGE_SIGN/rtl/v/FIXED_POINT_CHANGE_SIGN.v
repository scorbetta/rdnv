`default_nettype none

// Changes the sign of the incoming value to the target one. This can be used in different contexts,
// e.g. to share ALUs for odd-symmetric functions
module FIXED_POINT_CHANGE_SIGN
#(
    // Input data width
    parameter WIDTH         = 8,
    // Number of fractional bits
    parameter FRAC_BITS     = 3
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // 1'b0 -> we want positive, 1'b1 -> we want negative
    input wire                      TARGET_SIGN,
    input wire signed [WIDTH-1:0]   VALUE_IN,
    input wire                      VALID_IN,
    output wire signed [WIDTH-1:0]  VALUE_OUT,
    output wire                     VALID_OUT,
    output wire                     OVERFLOW
);

     reg signed [WIDTH-1:0]     value_out;
     reg                        valid_out;
     wire                       sign;
     wire                       sign_match;
     wire signed [WIDTH-1:0]    value_negated;
     wire signed [WIDTH-1:0]    value_converted;
     wire                       valid_converted;
     wire signed [WIDTH-1:0]    value_b_in;
     wire                       valid_in_filtered;
     wire                       add_overflow;
     reg                        overflow;

    // As usual, the MSB hints about the negative number
    assign sign = VALUE_IN[WIDTH-1];

    // Run 2's complement only when required, this also simplifies mux later
    assign valid_in_filtered    = VALID_IN & ~sign_match;
    assign value_negated        = ~VALUE_IN;
    assign value_b_in           = { {WIDTH-1{1'b0}}, 1'b1 };

    FIXED_POINT_ADD #(
        .WIDTH      (WIDTH),
        .FRAC_BITS  (FRAC_BITS)
    )
    ADDER (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .VALUE_A_IN (value_negated),
        .VALUE_B_IN (value_b_in),
        .VALID_IN   (valid_in_filtered),
        .VALUE_OUT  (value_converted),
        .VALID_OUT  (valid_converted),
        .OVERFLOW   (add_overflow)
    );

    // When sign of incoming value already matches the desired one, discard all computations
    assign sign_match = (sign & TARGET_SIGN) | (!sign & !TARGET_SIGN);

    always @(posedge CLK) begin
        if(!RSTN) begin
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= 1'b0;

            if(VALID_IN && sign_match) begin
                value_out <= VALUE_IN;
                valid_out <= 1'b1;
                overflow <= 1'b0;
            end
            else if(valid_converted) begin
                value_out <= value_converted;
                valid_out <= 1'b1;
                overflow <= add_overflow;
            end
        end
    end

    // Pinout
    assign VALUE_OUT    = value_out;
    assign VALID_OUT    = valid_out;
    assign OVERFLOW     = overflow;
endmodule

`default_nettype wire
