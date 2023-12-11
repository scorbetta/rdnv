`timescale 1ns/100ps

`define WIDTH 16

module ootbtb;
    // Connections
    logic               clk;
    logic               rstn;
    logic               read_event;
    logic [`WIDTH-1:0]  random_in;
    logic               value_change;
    logic [`WIDTH-1:0]  data_out;
    
    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (2),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0),
        .MAX_SIM_TIME   (1e3)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (), // Unused
        .USER_RSTN  (rstn)
    );

    // DUT
    DELTA_REG #(
        .DATA_WIDTH (`WIDTH),
        .HAS_RESET  (1)
    )
    DUT (
        .CLK            (clk),
        .RSTN           (rstn),
        .READ_EVENT     (read_event),
        .VALUE_IN       (random_in),
        .VALUE_CHANGE   (value_change),
        .VALUE_OUT      (data_out)
    );

    // Stimuli
    initial begin
        random_in <= {`WIDTH{1'b0}};
        read_event <= 1'b0;
        @(posedge rstn);
        repeat(4) @(posedge clk);

        // Write value
        random_in <= 32;
        repeat(10) @(posedge clk);

        // Write another value
        random_in <= 15;
        repeat(20) @(posedge clk);

        // Reset state
        read_event <= 1'b1;
        @(posedge clk);
        read_event <= 1'b0;

        @(posedge clk);
        $finish;
    end
endmodule
