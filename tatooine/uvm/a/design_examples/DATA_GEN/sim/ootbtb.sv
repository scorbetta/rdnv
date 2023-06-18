`timescale 1ns/100ps

module ootbtb;
    logic           clk;
    logic           rstn;
    logic           cfg_valid;
    logic [31:0]    cfg_data;
    logic           start;

    axi4s_if #(
        .DATA_WIDTH (32)
    )
    data_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    DATA_GEN DUT (
        .ACLK       (clk),
        .ARESETN    (rstn),
        .CFG_VALID  (cfg_valid),
        .CFG_DATA   (cfg_data),
        .START      (start),
        .AXIS_PORT  (data_port)
    );

    always_ff @(posedge clk) begin
        if(!rstn) begin
            data_port.tready <= 1'b0;
        end
        else begin
            data_port.tready <= 1'b0;
            
            if(data_port.tvalid && !data_port.tready) begin
                data_port.tready <= 1'b1;
            end
        end
    end

    initial begin
        clk = 1'b0;
        forever begin
            #3.0 clk = ~clk;
        end
    end

    initial begin
        rstn = 1'b0;
        repeat(10) @(posedge clk);
        rstn = 1'b1;
    end

    initial begin
        cfg_valid <= 1'b0;
        cfg_data <= 32'd0;
        start <= 1'b0;
        @(posedge rstn);
        repeat(10) @(posedge clk);

        cfg_valid <= 1'b1;
        cfg_data <= 32'd16;
        @(posedge clk);
        cfg_valid <= 1'b0;

        @(posedge clk);
        start <= 1'b1;
        repeat(4) @(posedge clk);
        start <= 1'b0;

        repeat(1e3) @(posedge clk);
        $finish;
    end
endmodule
