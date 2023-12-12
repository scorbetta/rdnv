`timescale 1ns/100ps

`define OUT_WIDTH 16

module ootbtb;
    // Connections
    logic                   clk;
    logic                   rst;
    logic [`OUT_WIDTH-1:0]  random_out;
    integer                 fid;
    
    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (2),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (rst),
        .USER_RSTN  ()
    );

    // DUT
    random_gaussian #(
        .OUT_WIDTH  (`OUT_WIDTH)
    )
    DUT (
        .clk    (clk),
        .reset  (rst),
        .random (random_out)
    );

    // Save to file
    initial begin
        fid = $fopen("gaussian_data.csv", "w");
        forever begin
            @(posedge clk) begin
                if(!rst) begin
                    $fwrite(fid, "%d\n", $signed(random_out));
                end
            end
        end
    end
    
    final begin
        $fclose(fid);
    end
    
    // Control end of simulation
    initial begin
        @(negedge rst);
        repeat(1e5) @(posedge clk);
        $finish;
    end
endmodule
