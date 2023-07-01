`timescale 1ns/100ps

module ootbtb;
    logic   clk;
    logic   rstn;

    axi4s_if #(
        .DATA_WIDTH (32)
    )
    data_port (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    DATA_SINK DUT (
        .ACLK       (clk),
        .ARESETN    (rstn),
        .AXIS_PORT  (data_port)
    );

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
        data_port.tvalid <= 1'b0;
        data_port.tdata <= 32'hffffffff;
        data_port.tlast <= 1'b0;
        @(posedge rstn);
        repeat(10) @(posedge clk);

        repeat(32) begin
            @(posedge clk);
            data_port.tvalid <= 1'b1;
            data_port.tdata <= data_port.tdata + 1;
            data_port.tlast <= (data_port.tdata == 32'd30);
            @(posedge data_port.tready);
        end

        @(posedge clk);
        data_port.tvalid <= 1'b0;
        data_port.tdata <= 32'd0;
        data_port.tlast <= 1'b0;

        repeat(1e3) @(posedge clk);
        $finish;
    end
endmodule
