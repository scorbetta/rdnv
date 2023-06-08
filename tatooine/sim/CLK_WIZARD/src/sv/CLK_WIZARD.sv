`timescale 1ns/100ps

module CLK_WIZARD
#(
    // Clock period [ns]
    parameter   CLK_PERIOD  =   10  ,
    // Number of cycles reset clear is delayed
    parameter   RESET_DELAY =   4   ,
    // Initial phase [ns]
    parameter   INIT_PHASE  =   0   
)
(
    output  USER_CLK    ,
    output  USER_RST    ,
    output  USER_RSTN   
);

    // Internals
    logic   user_clk    ;
    logic   user_rstn   ;
    logic   user_rst    ;

    initial begin
        user_clk <= 1'b0;
        #(INIT_PHASE);

        user_clk <= 1'b1;
        forever begin
            #(CLK_PERIOD / 2) user_clk <= ~user_clk;
        end
    end

    initial begin
        user_rst <= 1'b1;
        repeat(RESET_DELAY) @(posedge user_clk);
        user_rst <= 1'b0;
    end

    assign user_rstn = ~user_rst;

    // Pinouts
    assign USER_CLK = user_clk;
    assign USER_RST = user_rst;
    assign USER_RSTN = user_rstn;
endmodule
