`timescale 1ns/100ps

`define WIDTH 16

module ootbtb;
    // Connections
    logic               clk;
    logic               rstn;
    logic [`WIDTH-1:0]  random_in;
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
        .USER_RST   (),
        .USER_RSTN  (rstn)
    );

    // DUT
    REGISTER #(
        .DATA_WIDTH (16)
    )
    DUT (
        .CLK        (clk),
        .RSTN       (rstn),
        .DATA_IN    (random_in),
        .DATA_OUT   (data_out)
    );

    // Stimuli
    initial begin
        random_in <= {`WIDTH{1'b0}};
        @(posedge rstn);
        repeat(4) @(posedge clk);

        for(int test = 1; test <= 10; test++) begin
            @(posedge clk);
            random_in <= $urandom;
            @(posedge clk);
            assert (data_out == random_in) else $fatal(1, "ootbtb error");
        end
    end
endmodule
