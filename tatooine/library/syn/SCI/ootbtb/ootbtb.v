`timescale 1ns/100ps

`define ADDR_WIDTH      4
`define DATA_WIDTH      8
`define NUM_SLAVES      4
`define NUM_MEM_WORDS   (2 ** `ADDR_WIDTH)
`define NUM_TESTS       100

// Testing single-Master/multiple-Slaves configuration
module ootbtb;
    genvar                                  gdx;
    reg                                     clk;
    reg                                     rstn;
    reg                                     req_in;
    reg                                     wnr_in;
    reg [`ADDR_WIDTH-1:0]                   addr_in;
    reg [`NUM_SLAVES-1:0]                   csn_in;
    reg [`DATA_WIDTH-1:0]                   data_in;
    wire                                    ack_out;
    wire [`DATA_WIDTH-1:0]                  data_out;
    wire [`NUM_SLAVES-1:0]                  sci_csn;
    wire                                    sci_req;
    wire                                    sci_resp;
    wire                                    sci_ack;
    wire [`NUM_SLAVES-1:0]                  ni_wreq;
    wire [`NUM_SLAVES*`ADDR_WIDTH-1:0]      ni_waddr;
    wire [`NUM_SLAVES*`DATA_WIDTH-1:0]      ni_wdata;
    reg [`NUM_SLAVES-1:0]                   ni_wack;
    wire [`NUM_SLAVES-1:0]                  ni_rreq;
    wire [`NUM_SLAVES*`ADDR_WIDTH-1:0]      ni_raddr;
    reg [`NUM_SLAVES*`DATA_WIDTH-1:0]       ni_rdata;
    reg [`NUM_SLAVES-1:0]                   ni_rvalid;
    reg [`NUM_MEM_WORDS*`DATA_WIDTH-1:0]    mems [0:`NUM_SLAVES-1];
    integer                                 tdx;
    integer                                 pid;

    // Clock and reset
    initial begin
        clk = 1'b0;
        forever begin
            #2.0 clk = ~clk;
        end
    end

    initial begin
        rstn = 1'b0;
        repeat(4) @(posedge clk);
        rstn = 1'b1;
    end

    // Single Master
    SCI_MASTER #(
        .ADDR_WIDTH         (`ADDR_WIDTH),
        .DATA_WIDTH         (`DATA_WIDTH),
        .NUM_PERIPHERALS    (`NUM_SLAVES)
    )
    SCI_MASTER (
        .CLK        (clk),
        .RSTN       (rstn),
        .REQ        (req_in),
        .WNR        (wnr_in),
        .ADDR       (addr_in),
        .CSN_IN     (csn_in),
        .DATA_IN    (data_in),
        .ACK        (ack_out),
        .DATA_OUT   (data_out),
        .SCI_CSN    (sci_csn),
        .SCI_REQ    (sci_req),
        .SCI_RESP   (sci_resp),
        .SCI_ACK    (sci_ack)
    );

    // Multiple Slaves
    generate
        for(gdx = 0; gdx < `NUM_SLAVES; gdx = gdx + 1) begin
            // SCI Slave
            SCI_SLAVE #(
                .ADDR_WIDTH (`ADDR_WIDTH),
                .DATA_WIDTH (`DATA_WIDTH)
            )
            SCI_SLAVE (
                .CLK        (clk),
                .RSTN       (rstn),
                .SCI_CSN    (sci_csn[gdx]),
                .SCI_REQ    (sci_req),
                .SCI_RESP   (sci_resp),
                .SCI_ACK    (sci_ack),
                .NI_WREQ    (ni_wreq[gdx]),
                .NI_WADDR   (ni_waddr[gdx*`ADDR_WIDTH+:`ADDR_WIDTH]),
                .NI_WDATA   (ni_wdata[gdx*`DATA_WIDTH+:`DATA_WIDTH]),
                .NI_WACK    (ni_wack[gdx]),
                .NI_RREQ    (ni_rreq[gdx]),
                .NI_RADDR   (ni_raddr[gdx*`ADDR_WIDTH+:`ADDR_WIDTH]),
                .NI_RDATA   (ni_rdata[gdx*`DATA_WIDTH+:`DATA_WIDTH]),
                .NI_RVALID  (ni_rvalid[gdx])
            );

            // Native model attached to the SCI Slave
            always @(posedge clk) begin
                if(!rstn) begin
                    ni_wack[gdx] <= 1'b0;
                    ni_rvalid[gdx] <= 1'b0;
                end
                else begin
                    ni_wack[gdx] <= 1'b0;
                    ni_rvalid[gdx] <= 1'b0;

                    if(ni_wreq[gdx]) begin
                        mems[gdx][ni_waddr[gdx*`ADDR_WIDTH+:`ADDR_WIDTH]*`DATA_WIDTH+:`DATA_WIDTH] <= ni_wdata[gdx*`DATA_WIDTH+:`DATA_WIDTH];
                        ni_wack[gdx] <= 1'b1;
                    end

                    if(ni_rreq[gdx]) begin
                        ni_rdata[gdx*`DATA_WIDTH+:`DATA_WIDTH] <= mems[gdx][ni_raddr[gdx*`ADDR_WIDTH+:`ADDR_WIDTH]*`DATA_WIDTH+:`DATA_WIDTH];
                        ni_rvalid[gdx] <= 1'b1;
                    end
                end
            end
        end
    endgenerate

    //@DBUGinteger sdx;
    //@DBUGinteger rdx;
    //@DBUG
    //@DBUGinitial begin
    //@DBUG    forever begin
    //@DBUG        @(posedge clk) begin
    //@DBUG            for(sdx = 0; sdx < `NUM_SLAVES; sdx = sdx + 1) begin
    //@DBUG                if(ni_wreq[sdx] == 1) begin
    //@DBUG                    @(negedge clk);
    //@DBUG                    $display("---- Write");
    //@DBUG                    $display("%d %x %x", sdx, ni_waddr[(sdx*`ADDR_WIDTH)+:`ADDR_WIDTH], ni_wdata[sdx*`DATA_WIDTH+:`DATA_WIDTH]);
    //@DBUG                    for(rdx = 0; rdx < `NUM_MEM_WORDS; rdx = rdx + 1) begin
    //@DBUG                        $display("%x %x", rdx, mems[sdx][rdx*`DATA_WIDTH+:`DATA_WIDTH]);
    //@DBUG                    end
    //@DBUG                end

    //@DBUG                if(ni_rvalid[sdx] == 1) begin
    //@DBUG                    @(negedge clk);
    //@DBUG                    $display("---- Read");
    //@DBUG                    for(rdx = 0; rdx < `NUM_MEM_WORDS; rdx = rdx + 1) begin
    //@DBUG                        $display("%x %x", rdx, mems[sdx][rdx*`DATA_WIDTH+:`DATA_WIDTH]);
    //@DBUG                    end
    //@DBUG                    $display("%d %x %x", sdx, ni_raddr[(sdx*`ADDR_WIDTH)+:`ADDR_WIDTH], ni_rdata[sdx*`DATA_WIDTH+:`DATA_WIDTH]);
    //@DBUG                end
    //@DBUG            end
    //@DBUG        end
    //@DBUG    end
    //@DBUGend

    // End of simulation
    initial begin
        repeat(1e4) @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("ootbtb.vcd");
        $dumpvars(0, ootbtb);
    end

    // Stimuli
    function automatic [`NUM_SLAVES-1:0] get_csn;
        input integer pid;
        begin
            get_csn = {`NUM_SLAVES{1'b1}};
            get_csn[pid] = 1'b0;
        end
    endfunction

    initial begin
        csn_in <= {`NUM_SLAVES{1'b1}};
        req_in <= 1'b0;
        @(posedge rstn);
        repeat(4) @(posedge clk);

        for(tdx = 0; tdx < `NUM_TESTS; tdx = tdx + 1) begin
            // Random peripheral, address and data
            @(posedge clk);
            pid = $urandom_range(0, `NUM_SLAVES-1);
            data_in <= $random;
            addr_in <= $random;

            // Chip select does not change between Write and Read
            csn_in <= get_csn(pid);
            #1 $display("info: Test #%0d/%0d: pid=%0d,csn_in=0b%b,data_in=0x%x,addr_in=0x%x", tdx+1, `NUM_TESTS, pid, csn_in, data_in, addr_in);

            // Write
            @(posedge clk);
            req_in <= 1'b1;
            wnr_in <= 1'b1;
            @(posedge clk);
            req_in <= 1'b0;
            @(posedge ack_out);

            // Shim delay
            repeat(4) @(posedge clk);

            // Read
            @(posedge clk);
            req_in <= 1'b1;
            wnr_in <= 1'b0;
            @(posedge clk);
            req_in <= 1'b0;
            @(posedge ack_out);

            // Verify data
            @(negedge clk);
            if(data_out != data_in) begin
                $display("erro: Unexpected data readout: 0x%x (expected: 0x%x)", data_out, data_in);
                $display("erro:     pid=%0d,csn_in=0b%b,addr_in=0x%x", pid, csn_in, addr_in);
                $fatal(1);
            end
        end

        // Early finish
        $finish;
    end
endmodule
