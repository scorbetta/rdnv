`timescale 1ns/100ps

module ootbtb;
    // Connections
    logic           clk;
    logic           rst;
    logic           rstn;
    logic           read_start;
    logic [31:0]    read_length;
    logic           rvalid_copy;
    logic [63:0]    rdata_copy;
    logic           rreq_count_done;
    logic           rvalid_count_done;
    logic           rreq;
    logic [3:0]     raddr;
    logic           rvalid;
    logic [63:0]    rdata;
    logic           sdpram_wen;
    logic [3:0]     sdpram_waddr;
    logic [63:0]    sdpram_wdata;
    logic [7:0]     sdpram_wstrb;
    logic           sdpram_ren;
    logic [3:0]     sdpram_raddr;
    logic           sdpram_rvalid;
    logic [63:0]    sdpram_rdata;

    // Number of retiming cycles for Read request path
    localparam REQUEST_DELAY = 0;
    // Number of retiming cycles for Read response path
    localparam RESPONSE_DELAY = 0;

    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (2),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (rst),
        .USER_RSTN  (rstn)
    );

    // DUT
    READ_ENGINE #(
        .DATA_WIDTH (64),
        .ADDR_WIDTH (4)
    )
    DUT (
        .CLK                (clk),
        .RSTN               (rstn),
        .READ_START         (read_start),
        .RADDR_START        (4'h0),
        .RREQ_COUNT_DONE    (rreq_count_done),
        .READ_LENGTH        (read_length),
        .RVALID_COPY        (rvalid_copy),
        .RDATA_COPY         (rdata_copy),
        .RVALID_COUNT_DONE  (rvalid_count_done),
        .RREQ               (rreq),
        .RVALID             (rvalid),
        .RADDR              (raddr),
        .RDATA              (rdata)
    );

    // Delay Read request path from  READ_ENGINE  to  SDPRAM  
    generate
        if(REQUEST_DELAY > 0) begin
            REGISTER_PIPELINE #(
                .DATA_WIDTH     (1),
                .RESET_VALUE    (0),
                .NUM_STAGES     (REQUEST_DELAY)
            )
            RREQ_DELAY (
                .CLK        (clk),
                .RSTN       (rstn),
                .CE         (1'b1),
                .DATA_IN    (rreq),
                .DATA_OUT   (sdpram_ren)
            );

            REGISTER_PIPELINE #(
                .DATA_WIDTH     (4),
                .RESET_VALUE    (0),
                .NUM_STAGES     (REQUEST_DELAY)
            )
            RADDR_DELAY (
                .CLK        (clk),
                .RSTN       (rstn),
                .CE         (1'b1),
                .DATA_IN    (raddr),
                .DATA_OUT   (sdpram_raddr)
            );
        end
        else begin
            assign sdpram_ren = rreq;
            assign sdpram_raddr = raddr;
        end
    endgenerate

    // Delay response request path from  SDPRAM  to  READ_ENGINE  
    generate
        if(RESPONSE_DELAY > 0) begin
            REGISTER_PIPELINE #(
                .DATA_WIDTH     (1),
                .RESET_VALUE    (0),
                .NUM_STAGES     (RESPONSE_DELAY)
            )
            RVALID_DELAY (
                .CLK        (clk),
                .RSTN       (rstn),
                .CE         (1'b1),
                .DATA_IN    (sdpram_rvalid),
                .DATA_OUT   (rvalid)
            );

            REGISTER_PIPELINE #(
                .DATA_WIDTH     (64),
                .RESET_VALUE    (0),
                .NUM_STAGES     (RESPONSE_DELAY)
            )
            RDATA_DELAY (
                .CLK        (clk),
                .RSTN       (rstn),
                .CE         (1'b1),
                .DATA_IN    (sdpram_rdata),
                .DATA_OUT   (rdata)
            );
        end
        else begin
            assign rvalid = sdpram_rvalid;
            assign rdata = sdpram_rdata;
        end
    endgenerate

    // Slave peripheral with asymmetric request/response timing paths
    SDPRAM #(
        .WIDTH      (64),
        .DEPTH      (16),
        .ZL_READ    (0)
    )
    RAM (
        .CLK    (clk),
        .RST    (rst),
        .WEN    (sdpram_wen),
        .WADDR  (sdpram_waddr),
        .WDATA  (sdpram_wdata),
        .WSTRB  (sdpram_wstrb),
        .REN    (sdpram_ren),
        .RADDR  (sdpram_raddr),
        .RVALID (sdpram_rvalid),
        .RDATA  (sdpram_rdata)
    );

    // Feed RAM
    initial begin
        sdpram_wen <= 1'b0;

        @(posedge rstn);
        for(int row = 0; row < 16; row++) begin
            @(posedge clk) begin
                sdpram_wen <= 1'b1;
                sdpram_waddr <= row;
                sdpram_wdata <= {4{row[15:0]}};
                sdpram_wstrb <= 8'hff;
            end
        end

        @(posedge clk);
        sdpram_wen <= 1'b0;
    end

    // Read from RAM
    initial begin
        read_start <= 1'b0;
        
        // Wait for Writes to end
        @(posedge sdpram_wen);
        @(negedge sdpram_wen);
        repeat(10) @(posedge clk);

        read_start <= 1'b1;
        read_length <= 32'd8;
        @(posedge clk);
        read_start <= 1'b0;

        repeat(57) @(posedge clk);
        read_start <= 1'b1;
        read_length <= 32'd48;
        repeat(10) @(posedge clk);
        read_start <= 1'b0;
    end

    // Control end of simulation
    initial begin
        @(negedge rst);

        fork
            begin
                // Wait for all data (two tests)
                @(posedge rvalid_count_done);
                $display("info: rvalid_count_done edge detected");
                @(posedge rvalid_count_done);
                $display("info: rvalid_count_done edge detected");
            end

            begin
                repeat(1e4) @(posedge clk);
                $display("info: Maximum simulation time reached");
            end
        join_any

        repeat(10) @(posedge clk);
        $finish;
    end
endmodule
