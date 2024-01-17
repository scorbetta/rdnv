`default_nettype none

// Fixed-point accumulator
module FIXED_POINT_ACC
#(
    // The width of the input values
    parameter WIDTH         = 8,
    // Number of bits reserved to the fractional part. Also, the position of the binary point from
    // LSB. Must be strictly positive
    parameter FRAC_BITS     = 3,
    // Number of input operands
    parameter NUM_INPUTS    = 16,
    // When 1'b1, the  EXT_VALUE_IN  port is used as well
    parameter HAS_EXT_BIAS  = 1'b0
)
(
    input wire                                  CLK,
    input wire                                  RSTN,
    // Input operand
    input wire signed [NUM_INPUTS*WIDTH-1:0]    VALUES_IN,
    input wire                                  VALID_IN,
    // External operand (e.g., for bias)
    input wire signed [WIDTH-1:0]               EXT_VALUE_IN,
    // Accumulator
    output wire signed [WIDTH-1:0]              VALUE_OUT,
    output wire                                 VALID_OUT,
    output wire                                 OVERFLOW
);

    // States encoding
    localparam WAIT_LAST    = 0;
    localparam ADD_BIAS     = 1;
    localparam ACCUMULATE   = 2;
    localparam IDLE         = 3;

    // When an external value is used (e.g., for bias), the internal matrices are reshaped
    // accordingly to store the additional entry
    localparam NUM_INPUTS_INT = ( HAS_EXT_BIAS == 1'b1 ? (NUM_INPUTS+1) : NUM_INPUTS );

    reg [$clog2(IDLE)-1:0]              curr_state;
    wire signed [WIDTH-1:0]             acc;
    reg                                 acc_valid;
    reg [$clog2(NUM_INPUTS_INT)-1:0]    counter;
    reg signed [WIDTH-1:0]              adder_in;
    reg                                 adder_enable;
    wire                                adder_valid;
    reg [$clog2(NUM_INPUTS_INT)-1:0]    adder_valid_counter;
    reg                                 adder_valid_counter_reset;
    wire                                adder_overflow;
    reg                                 overflow;

    // Sequentially generate the accumulator value
    always @(posedge CLK) begin
        if(!RSTN) begin
            counter <= 0;
            adder_enable <= 1'b0;
            acc_valid <= 1'b0;
            adder_valid_counter_reset <= 1'b1;
            curr_state <= IDLE;
        end
        else begin
            adder_valid_counter_reset <= 1'b1;
            adder_enable <= 1'b0;
            acc_valid <= 1'b0;

            case(curr_state)
                IDLE : begin
                    if(VALID_IN) begin
                        counter <= 0;
                        adder_valid_counter_reset <= 1'b0;
                        curr_state <= ACCUMULATE;
                    end
                end

                ACCUMULATE : begin
                    counter <= counter + 1;
                    adder_in <= VALUES_IN[counter*WIDTH +: WIDTH];
                    adder_enable <= 1'b1;

                    if(counter == NUM_INPUTS-1 && !HAS_EXT_BIAS) begin
                        curr_state <= WAIT_LAST;
                    end
                    else if(counter == NUM_INPUTS-1 && HAS_EXT_BIAS) begin
                        curr_state <= ADD_BIAS;
                    end
                end

                ADD_BIAS : begin
                    adder_in <= EXT_VALUE_IN;
                    adder_enable <= 1'b1;
                    curr_state <= WAIT_LAST;
                end

                WAIT_LAST : begin
                    if(adder_valid_counter == NUM_INPUTS_INT-1) begin
                        acc_valid <= 1'b1;
                        curr_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Shared adder
    FIXED_POINT_ADD #(
        .WIDTH      (WIDTH),
        .FRAC_BITS  (FRAC_BITS)
    )
    ADDER (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .VALUE_A_IN (acc),
        .VALUE_B_IN (adder_in),
        .VALID_IN   (adder_enable),
        .VALUE_OUT  (acc),
        .VALID_OUT  (adder_valid),
        .OVERFLOW   (adder_overflow)
    );

    // Count number of valid operations by the adder
    always @(posedge CLK) begin
        if(!RSTN | !adder_valid_counter_reset) begin
            adder_valid_counter <= 0;
        end
        else if(adder_valid) begin
            adder_valid_counter <= adder_valid_counter + 1;
        end
    end

    // Overflow is sticky
    always @(posedge CLK) begin
        if(!RSTN | VALID_IN) begin
            overflow <= 1'b0;
        end
        else if(adder_valid && adder_overflow) begin
            overflow <= 1'b1;
        end
    end

    // Pinout
    assign VALUE_OUT    = acc;
    assign VALID_OUT    = acc_valid;
    assign OVERFLOW     = overflow;
endmodule

`default_nettype wire
