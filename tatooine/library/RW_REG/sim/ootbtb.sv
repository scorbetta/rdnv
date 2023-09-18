`timescale 1ns/100ps

`define WIDTH 16

module ootbtb;
    // Connections
    logic               clk;
    logic               rstn;
    logic               wen;
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
        .USER_RST   (), // Unused
        .USER_RSTN  (rstn)
    );

    // DUT
    RW_REG #(
        .DATA_WIDTH (`WIDTH),
        .HAS_RESET  (1)
    )
    DUT (
        .CLK        (clk),
        .RSTN       (rstn),
        .WEN        (wen),
        .VALUE_IN   (random_in),
        .VALUE_OUT  (data_out)
    );

    // Stimuli
    initial begin
        wen <= 1'b0;
        random_in <= {`WIDTH{1'b0}};
        @(posedge rstn);
        repeat(4) @(posedge clk);

        for(int test = 1; test <= 10; test++) begin
            @(posedge clk);
            wen <= 1'b1;
            random_in <= $urandom;
        end

        @(posedge clk);
        wen <= 1'b0;

        repeat(10) @(posedge clk);
        $finish;
    end
endmodule
