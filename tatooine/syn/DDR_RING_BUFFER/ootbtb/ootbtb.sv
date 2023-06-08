`timescale 1ns/100ps

// Uncomment the following line to test AXI3 interface instead of AXI4
//`define AXI3

module ootbtb;
    // Signals
    logic           clk;
    logic           rst;
    logic           rstn;
    logic           datagen_en;
    logic           eob;
    logic           soft_rstn;
    logic           clear_irq;
    logic [31:0]    ring_buffer_base_addr;
    logic [31:0]    ring_buffer_len;
    logic [31:0]    ring_buffer_addr_mask;
    logic [9:0]     ring_buffer_ififo_fill;
    logic           ring_buffer_ififo_full;
    logic [9:0]     ring_buffer_ofifo_fill;
    logic           ring_buffer_data_loss;
    logic [31:0]    ring_buffer_wptr;
    logic [31:0]    write_offset;
    logic           ram_wen;
    logic [9:0]     ram_waddr;
    logic [63:0]    ram_wdata;
    logic [7:0]     ram_wstrb;
    logic           ram_ren;
    logic [9:0]     ram_raddr;
    logic           ram_rvalid;
    logic [63:0]    ram_rdata;
    logic [31:0]    base_addr;
    logic [7:0]     num_beats;
    logic [7:0]     beat_counter;
    logic [15:0]    datagen_dout;

    typedef enum { SEND_RESP, WRITE_DATA, IDLE } state_t;
    state_t curr_state;

    axi4s_if #(
        .DATA_WIDTH (16)
    )
    axis_data_in (
        .aclk       (clk),
        .aresetn    (rstn)
    );

    axi4s_if #(
        .DATA_WIDTH (16)
    )
    axis_data_out (
        .aclk       (clk),
        .aresetn    (rstn)
    );

`ifdef AXI3
    axi3f_if #(
        .USER_WIDTH (4),
`else
    axi4f_if #(
`endif
        .DATA_WIDTH (16),
        .ADDR_WIDTH (32),
        .ID_WIDTH   (3)
    )
    axif_ddr_ctrl (
        .aclk       (clk),
        .aresetn    (rstn)
    );
    
    // Clock and reset
    CLK_WIZARD #(
        .CLK_PERIOD     (5),
        .RESET_DELAY    (10),
        .INIT_PHASE     (0)
    )
    CLK_WIZARD_0 (
        .USER_CLK   (clk),
        .USER_RST   (rst),
        .USER_RSTN  (rstn)
    );
    
    // DUT
    DDR_RING_BUFFER #(
        .AXI_ID_WIDTH       (3),
        .AXI_ADDR_WIDTH     (32),
        .AXI_DATA_WIDTH     (16),
`ifdef AXI3
        .DRAIN_BURST_LEN    (16),
`else
        .DRAIN_BURST_LEN    (256),
`endif
        .STAGE_FIFOS_DEPTH  (512),
        .EXTERNAL_READ_ITF  (0)
    )
    DDR_RING_BUFFER (
        .S_AXI_ACLK         (clk),
        .S_AXI_ARESETN      (rstn),
        .IFIFO_AXI_PORT     (axis_data_in),
        .OFIFO_AXI_PORT     (axis_data_out),
        .DDR_CTRL_AXI_PORT  (axif_ddr_ctrl),
        .SOFT_RSTN          (soft_rstn),
        .MM2S_FULL          (), // Unused
        .EMPTY              (), //
        .CORE_FILL          (), //
        .IFIFO_FILL         (ring_buffer_ififo_fill),
        .IFIFO_FULL         (ring_buffer_ififo_full),
        .OFIFO_FILL         (ring_buffer_ofifo_fill),
        .DATA_LOSS          (ring_buffer_data_loss),
        .RING_BUFFER_WPTR   (ring_buffer_wptr),
        .RING_BUFFER_RPTR   (), // Unused
        .WRITE_OFFSET       (write_offset),
        .AXI_BASE_ADDR      (ring_buffer_base_addr),
        .RING_BUFFER_LEN    (ring_buffer_len),
        .AXI_ADDR_MASK      (ring_buffer_addr_mask),
        .CLEAR_EOB          (clear_irq),
        .DDR_EOB            (eob)
    );

    // AXI-to-Native layer
    assign axif_ddr_ctrl.awready    = 1'b1;
    assign axif_ddr_ctrl.wready     = 1'b1;

    always_ff @(posedge clk) begin
        if(rst) begin
            axif_ddr_ctrl.bvalid <= 1'b0;
            curr_state <= IDLE;
        end
        else begin
            ram_wen <= 1'b0;

            case(curr_state)
                IDLE : begin
                    if(axif_ddr_ctrl.awvalid && axif_ddr_ctrl.awready) begin
                        base_addr <= axif_ddr_ctrl.awaddr;
                        num_beats <= axif_ddr_ctrl.awlen + 1;
                        beat_counter <= 0;
                        curr_state <= WRITE_DATA;
                    end
                end

                WRITE_DATA : begin
                    if(axif_ddr_ctrl.wvalid && axif_ddr_ctrl.wready) begin
                        ram_wen <= 1'b1;
                        ram_waddr <= base_addr + (beat_counter * 4);
                        beat_counter <= beat_counter + 1;
                        
                        if(axif_ddr_ctrl.wlast) begin
                            axif_ddr_ctrl.bvalid <= 1'b1;
                            axif_ddr_ctrl.bresp <= 2'b00;
                            curr_state <= SEND_RESP;
                        end
                    end
                end

                SEND_RESP : begin
                    if(axif_ddr_ctrl.bvalid && axif_ddr_ctrl.bready) begin
                        axif_ddr_ctrl.bvalid <= 1'b0;
                        curr_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Simulate DDR memory
    SDPRAM #(
        .WIDTH      (64),
        .DEPTH      (1024),
        .ZL_READ    (0)
    )
    RAM (
        .CLK    (clk),
        .RST    (rst),
        .WEN    (ram_wen),
        .WADDR  (ram_waddr),
        .WDATA  (ram_wdata),
        .WSTRB  (ram_wstrb),
        .REN    (ram_ren),
        .RADDR  (ram_raddr),
        .RVALID (ram_rvalid),
        .RDATA  (ram_rdata)
    );

    // Data generator model
    random_uniform #(
        .SEED       (31'h16632afb),
        .OUT_WIDTH  (16)
    )
    DATAGEN_0 (
        .clk    (clk),
        .random (datagen_dout),
        .reset  (rst)
    );

    // TREADY not managed here
    assign axis_data_in.tvalid  = datagen_en;
    assign axis_data_in.tdata   = datagen_dout;
    
    // Apply configuration
    assign ring_buffer_base_addr    = 32'h1a800000;
    assign ring_buffer_len          = 32'd4;
    assign ring_buffer_addr_mask    = 32'h00001fff;

    initial begin
        // Defaults
        datagen_en <= 1'b0;
        soft_rstn <= 1'b1;
        ram_ren <= 1'b0;
        clear_irq <= 1'b0;
                
        // Wait for out-of-reset
        @(posedge rstn);
        repeat(10) @(posedge clk);

        // Free-running to fill the IFIFO buffer...
        datagen_en <= 1'b1;
        while(ring_buffer_ififo_fill <
`ifdef AXI3
        16
`else
        256
`endif /* AXI3 */
        ) begin
            @(posedge clk);
        end

        // ... plus a little extra
        repeat(1e2) @(posedge clk);
        datagen_en <= 1'b0;
        
        // Tail
        repeat(1e3) @(posedge clk);
        $finish();
    end    
endmodule
