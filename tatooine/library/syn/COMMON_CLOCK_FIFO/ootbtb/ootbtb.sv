`timescale 1ns/100ps

// FIFO configuration
`define FIFO_DEPTH 256
`define DATA_WIDTH 64
`define FWFT_SHOWAHEAD 1'b0
`define PROG_FULL_THRESHOLD 252
`define PROG_EMPTY_THRESHOLD 4

// This module compares the outputs of the SystemVerilog implementation (stored beneath the
//  ../src/sv/  folder) and the reference VHDL one (copied over here to overcome simulation of two
// modules with same name)
module ootbtb;
    // Connections
    logic                   sync_rst;
    logic                   clk;
    logic                   we;
    logic [`DATA_WIDTH-1:0] din;
    logic                   full_sv;
    logic                   prog_full_sv;
    logic                   valid_sv;
    logic                   re;
    logic [`DATA_WIDTH-1:0] dout_sv;
    logic                   empty_sv;
    logic                   prog_empty_sv;
    logic [31:0]            data_count_sv;
    logic                   full_golden;
    logic                   prog_full_golden;
    logic                   valid_golden;
    logic [`DATA_WIDTH-1:0] dout_golden;
    logic                   empty_golden;
    logic                   prog_empty_golden;
    logic [31:0]            data_count_golden;
    logic                   sim_ready = 1'b0; // Time-0 initialization required here
    logic                   sim_ready_early;
    logic                   soft_reset;

    typedef enum { UNDERFLOW, OVERFLOW, WRITES_THEN_READS } phase_t;
    phase_t phase;
   
    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (2),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (sync_rst),
        .USER_RSTN  ()
    );

    // SystemVerilog DUT
    COMMON_CLOCK_FIFO #(
        .FIFO_DEPTH     (`FIFO_DEPTH),
        .DATA_WIDTH     (`DATA_WIDTH),
        .FWFT_SHOWAHEAD	(`FWFT_SHOWAHEAD)
    )
    COMMON_CLOCK_FIFO_SV (
        .SYNC_RST               (sync_rst | soft_reset),
        .CLK                    (clk),
        .WE                     (we),
        .DIN                    (din),
        .FULL                   (full_sv),
        .PROG_FULL              (prog_full_sv),
        .VALID                  (valid_sv),
        .RE                     (re),
        .DOUT                   (dout_sv),
        .EMPTY                  (empty_sv),
        .PROG_EMPTY             (prog_empty_sv),
        .DATA_COUNT             (data_count_sv),
        .PROG_FULL_THRESHOLD    (`PROG_FULL_THRESHOLD),
        .PROG_EMPTY_THRESHOLD	(`PROG_EMPTY_THRESHOLD)
    );

    // VHDL DUT
    COMMON_CLOCK_FIFO_GOLDEN #(
        .Fifo_depth             (`FIFO_DEPTH),
        .data_width             (`DATA_WIDTH),
        .FWFT_ShowAhead         (`FWFT_SHOWAHEAD),
        .Prog_Full_ThresHold    (`PROG_FULL_THRESHOLD),
        .Prog_Empty_ThresHold   (`PROG_EMPTY_THRESHOLD)
    )
    COMMON_CLOCK_FIFO_GOLDEN (
        .Async_rst  (1'b0),
        .Sync_rst   (sync_rst | soft_reset),
        .clk        (clk),
        .we         (we),
        .din        (din),
        .full       (full_golden),
        .prog_full  (prog_full_golden),
        .valid      (valid_golden),
        .re         (re),
        .dout       (dout_golden),
        .empty      (empty_golden),
        .prog_empty (prog_empty_golden),
        .data_count (data_count_golden)
    );

    // The golden design contains a bug:  full  and  prog_full  are not cleared out of reset,
    // instead the are with a single-cycle delay. The SystemVerilog implementation fixed this bug,
    // but then we be sure to perform checks once these are properly cleared. The  sim_ready  signal
    // is a strobe for such reason
    always_ff @(posedge clk) begin
        if(sync_rst | soft_reset) begin
            sim_ready <= 1'b0;
            sim_ready_early <= 1'b0;
        end
        else if(!sync_rst && !sim_ready_early && !prog_full_golden && !full_golden) begin
            sim_ready_early <= 1'b1;
        end
        else if(sim_ready_early) begin
            sim_ready <= 1'b1;
        end
    end

    task test_writes_then_reads(integer num_iters);
        phase <= WRITES_THEN_READS;

	repeat(num_iters) begin
	    repeat(1 + $urandom % 4) @(posedge clk);
            we <= 1'b1;
	    din <= { $urandom, $urandom };
	    @(posedge clk);
	    we <= 1'b0;
	end

	re <= 1'b1;
	repeat(num_iters) @(posedge clk);
        re <= 1'b0;
    endtask

    task test_overflow();
        phase <= OVERFLOW;

        soft_reset <= 1'b1;
        repeat(4) @(posedge clk);
        soft_reset <= 1'b0;
        @(posedge sim_ready);

        // Fill in FIFOs
        repeat(1 + $urandom % 4) @(posedge clk);
        for(int idx = 1; idx <= `FIFO_DEPTH; idx++) begin
	    @(posedge clk);
            we <= 1'b1;
	    din <= { $urandom, $urandom };
        end

        // Write w/ overflow
        for(int idx = 1; idx <= 10; idx++) begin
	    @(posedge clk);
            we <= 1'b1;
	    din <= { $urandom, $urandom };
        end
	
        @(posedge clk);
	we <= 1'b0;
    endtask

    task test_underflow();
        phase <= UNDERFLOW;

        // Reuse result from  test_overflow()  test, meaning that we expect the FIFOs to be full at
        // this point
        for(int idx = 1; idx <= `FIFO_DEPTH; idx++) begin
            @(posedge clk);
            re <= 1'b0;
        end

        // Read w/ underflow
        for(int idx = 1; idx <= 10; idx++) begin
            @(posedge clk);
            re <= 1'b1;
        end

        @(posedge clk);
        re <= 1'b0;
    endtask

    // Control end of simulation
    initial begin
	we <= 1'b0;
	re <= 1'b0;
        soft_reset <= 1'b0;
        @(negedge sync_rst);

        // Writes then Reads
        test_writes_then_reads(150);
        repeat(25) @(posedge clk);

        // Overflow
        test_overflow();
        repeat(25) @(posedge clk);

        // Underflow
        test_underflow();
        repeat(25) @(posedge clk);

	$finish;
    end

    // Cycle-wise output checks. Internal nodes are more difficult to verify due to Xilinx' limited
    // support to multi-language across-boundary references
    default clocking cb @(posedge clk); endclocking
    assert property ( disable iff (!sim_ready) data_count_golden == data_count_sv );
    assert property ( disable iff (!sim_ready) full_golden == full_sv );
    assert property ( disable iff (!sim_ready) prog_full_golden == prog_full_sv );
    assert property ( disable iff (!sim_ready) valid_golden == valid_sv );
    assert property ( disable iff (!sim_ready) empty_golden == empty_sv );
    assert property ( disable iff (!sim_ready) prog_empty_golden == prog_empty_sv );
    assert property ( disable iff (!sim_ready) data_count_golden == data_count_sv );

    //  dout  does not get a reset value so we check data only after a Read request
    assert property ( disable iff (!sim_ready) (valid_golden && valid_sv) |-> (dout_golden == dout_sv) );
endmodule
