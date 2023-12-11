`timescale 1ns/100ps

module ootbtb;
    logic           clk;
    logic           rst;
    logic           rstn;
    logic [63:0]    data_in;
    logic           valid_in;
    logic           ready_in;
    logic [63:0]    data_out;
    logic           valid_out;
    logic           rd_en;
    logic [31:0]    rd_addr;
    logic [63:0]    expected_data;
    integer         pre_delay;
    integer         post_delay;

    // Clock and reset wizard
    CLK_WIZARD #(
        .CLK_PERIOD     (10 ),
        .RESET_DELAY    (4  ),
        .INIT_PHASE     (0  )
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk    ),
        .USER_RST   (rst    ),
        .USER_RSTN  (rstn   )
    );

    // DUT
   READY_VALID_FILTER_WITH_REN #(
        .DATA_WIDTH (64)
    )
    DUT (
        .CLK        (clk),
        .RSTN       (rstn),
        .DATA_IN    (data_in),
        .VALID_IN   (valid_in),
        .READY_IN   (ready_in),
        .DATA_OUT   (data_out),
        .VALID_OUT  (valid_out),
        .RD_EN      (rd_en),
        .RD_ADDR    (rd_addr)
    );

    // Phony RAM
    always_ff @(posedge clk) begin
        if(!rstn) begin
            valid_in <= 1'b0;
            data_in <= 0;
        end
        else if(rd_en) begin
            valid_in <= 1'b1;
            data_in <= rd_addr >> 2;
        end
        else begin
            valid_in <= 1'b0;
        end
    end

    // Phony Slave
    initial begin
        ready_in <= 1'b1;
        repeat(10) @(posedge clk);

        // Randomly twiggle  ready_in  for backpressure emulation
        forever begin
            pre_delay = 1 + $urandom % 25;
            post_delay = 1 + $urandom % 25;
            repeat(pre_delay) @(posedge clk);
            ready_in <= 1'b0;
            repeat(post_delay) @(posedge clk);
            ready_in <= 1'b1;
        end
    end

    // Check all data has been accessed in expected order
    always_ff @(posedge clk) begin
        if(!rstn) begin
            expected_data <= 0;
        end
        else if(valid_out && ready_in) begin
            expected_data <= expected_data + 1;
            if(data_out != expected_data) begin
                $display("erro: [%0d] Unexpected data: 0x%016x (expected: 0x%016x)", $time, data_out, expected_data);
            end
        end
    end

    // Close simulation
    initial begin
        repeat(1e6) @(posedge clk);
        $finish;
    end
endmodule
