// Generated by PeakRDL-regblock starting from JINJA templated  MY_MODULE_TEMPLATE.sv  file
`timescale 1ns/100ps

`include "DT5771_REGMAP.svh"

module DT5771_REGMAP (
    // Clock and reset
    input ACLK,
    input ARESETN,
    // AXI interface
    axi4l_if.slave AXIL,
    // Register bundles
    input dt5771_regmap_pkg::dt5771_address_map__in_t hwif_in,
    output dt5771_regmap_pkg::dt5771_address_map__out_t hwif_out
);

    logic regpool_ren;
    logic [15:0] regpool_raddr;
    logic [31:0] regpool_rdata;
    logic regpool_rvalid;
    logic regpool_wen;
    logic regpool_wen_resampled;
    logic [15:0] regpool_waddr;
    logic [31:0] regpool_wdata;

    // AXI4 Lite to Native bridge
    AXIL2NATIVE #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (16)
    )
    AXIL2NATIVE_0 (
        .AXI_ACLK       (ACLK),
        .AXI_ARESETN    (ARESETN),
        .AXI_AWADDR     (AXIL.awaddr),
        .AXI_AWPROT     (AXIL.awprot),
        .AXI_AWVALID    (AXIL.awvalid),
        .AXI_AWREADY    (AXIL.awready),
        .AXI_WDATA      (AXIL.wdata),
        .AXI_WSTRB      (AXIL.wstrb),
        .AXI_WVALID     (AXIL.wvalid),
        .AXI_WREADY     (AXIL.wready),
        .AXI_BRESP      (AXIL.bresp),
        .AXI_BVALID     (AXIL.bvalid),
        .AXI_BREADY     (AXIL.bready),
        .AXI_ARADDR     (AXIL.araddr),
        .AXI_ARPROT     (AXIL.arprot),
        .AXI_ARVALID    (AXIL.arvalid),
        .AXI_ARREADY    (AXIL.arready),
        .AXI_RDATA      (AXIL.rdata),
        .AXI_RRESP      (AXIL.rresp),
        .AXI_RVALID     (AXIL.rvalid),
        .AXI_RREADY     (AXIL.rready),
        .WEN            (regpool_wen),
        .WADDR          (regpool_waddr),
        .WDATA          (regpool_wdata),
        .WACK           (), // Unused
        .REN            (regpool_ren),
        .RADDR          (regpool_raddr),
        .RDATA          (regpool_rdata),
        .RVALID         (regpool_rvalid)
    );

    // Instantiate registers and declare their own signals. From a Software perspective, i.e. access
    // via the AXI4 Lite interface, Configuration registers are Write-only and Debug registers are
    // Read-only
    // DDR_CTRL_CONFIG: The configuration of the DDR controller
    logic [31:0] ddr_ctrl_config_value_in;
    logic [31:0] ddr_ctrl_config_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    DDR_CTRL_CONFIG_REG (
        .CLK        (ACLK),
        .VALUE_IN   (ddr_ctrl_config_value_in),
        .VALUE_OUT  (ddr_ctrl_config_value_out)
    );
        
    // RING_BUFFER_WPTR: The current DDR Write pointer
    logic [31:0] ring_buffer_wptr_value_in;
    logic [31:0] ring_buffer_wptr_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    RING_BUFFER_WPTR_REG (
        .CLK        (ACLK),
        .VALUE_IN   (ring_buffer_wptr_value_in),
        .VALUE_OUT  (ring_buffer_wptr_value_out)
    );
        
    // PRE_TRIGGER_BUFFER_STATUS: Status of the pre-trigger buffer
    logic [31:0] pre_trigger_buffer_status_value_in;
    logic [31:0] pre_trigger_buffer_status_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    PRE_TRIGGER_BUFFER_STATUS_REG (
        .CLK        (ACLK),
        .VALUE_IN   (pre_trigger_buffer_status_value_in),
        .VALUE_OUT  (pre_trigger_buffer_status_value_out)
    );
        
    // PIPE_FIFO_FILL_STATS: Filling statistics of the FIFOs lying on the main pipeline
    logic [31:0] pipe_fifo_fill_stats_value_in;
    logic [31:0] pipe_fifo_fill_stats_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    PIPE_FIFO_FILL_STATS_REG (
        .CLK        (ACLK),
        .VALUE_IN   (pipe_fifo_fill_stats_value_in),
        .VALUE_OUT  (pipe_fifo_fill_stats_value_out)
    );
        
    // EOS_IRQ_COUNTER: Number of edges over EOS signal
    logic [31:0] eos_irq_counter_value_in;
    logic [31:0] eos_irq_counter_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    EOS_IRQ_COUNTER_REG (
        .CLK        (ACLK),
        .VALUE_IN   (eos_irq_counter_value_in),
        .VALUE_OUT  (eos_irq_counter_value_out)
    );
        
    // EOB_IRQ_COUNTER: Number of edges over EOB signal
    logic [31:0] eob_irq_counter_value_in;
    logic [31:0] eob_irq_counter_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    EOB_IRQ_COUNTER_REG (
        .CLK        (ACLK),
        .VALUE_IN   (eob_irq_counter_value_in),
        .VALUE_OUT  (eob_irq_counter_value_out)
    );
        
    // PIPE_FIFO_STATUS: Snapshot of status of FIFOS lying on the main pipeline
    logic [31:0] pipe_fifo_status_value_in;
    logic [31:0] pipe_fifo_status_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    PIPE_FIFO_STATUS_REG (
        .CLK        (ACLK),
        .VALUE_IN   (pipe_fifo_status_value_in),
        .VALUE_OUT  (pipe_fifo_status_value_out)
    );
        
    // RING_BUFFER_WRITE_OFFSET: The current Write offset
    logic [31:0] ring_buffer_write_offset_value_in;
    logic [31:0] ring_buffer_write_offset_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    RING_BUFFER_WRITE_OFFSET_REG (
        .CLK        (ACLK),
        .VALUE_IN   (ring_buffer_write_offset_value_in),
        .VALUE_OUT  (ring_buffer_write_offset_value_out)
    );
        
    // PRE_TRIGGER_WRITE_OVERFLOW_COUNTER: Number of Write overflow pulses
    logic [31:0] pre_trigger_write_overflow_counter_value_in;
    logic [31:0] pre_trigger_write_overflow_counter_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    PRE_TRIGGER_WRITE_OVERFLOW_COUNTER_REG (
        .CLK        (ACLK),
        .VALUE_IN   (pre_trigger_write_overflow_counter_value_in),
        .VALUE_OUT  (pre_trigger_write_overflow_counter_value_out)
    );
        
    // AD9642_RDATA: AD9642 readout data
    logic [31:0] ad9642_rdata_value_in;
    logic [31:0] ad9642_rdata_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    AD9642_RDATA_REG (
        .CLK        (ACLK),
        .VALUE_IN   (ad9642_rdata_value_in),
        .VALUE_OUT  (ad9642_rdata_value_out)
    );
        
    // LMH6518_RDATA: LMH6518 readout data
    logic [31:0] lmh6518_rdata_value_in;
    logic [31:0] lmh6518_rdata_value_out;
    RO_REG #(
        .DATA_WIDTH (32)
    )
    LMH6518_RDATA_REG (
        .CLK        (ACLK),
        .VALUE_IN   (lmh6518_rdata_value_in),
        .VALUE_OUT  (lmh6518_rdata_value_out)
    );
        
    // DMA_BUFFER_BASE_ADDR: The base address of the reserved DMA space in DDR
    logic dma_buffer_base_addr_wreq;
    logic dma_buffer_base_addr_wreq_filtered;
    logic [31:0] dma_buffer_base_addr_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    DMA_BUFFER_BASE_ADDR_REG (
        .CLK    (ACLK),
        .WEN    (dma_buffer_base_addr_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (dma_buffer_base_addr_value_out)
    );
        
    // DMA_BUFFER_LEN: The maximum number of DMA chunks available in the DDR ring buffer
    logic dma_buffer_len_wreq;
    logic dma_buffer_len_wreq_filtered;
    logic [31:0] dma_buffer_len_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    DMA_BUFFER_LEN_REG (
        .CLK    (ACLK),
        .WEN    (dma_buffer_len_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (dma_buffer_len_value_out)
    );
        
    // DMA_BUFFER_ADDR_MASK: The mask is computed from DDR ring buffer specs
    logic dma_buffer_addr_mask_wreq;
    logic dma_buffer_addr_mask_wreq_filtered;
    logic [31:0] dma_buffer_addr_mask_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    DMA_BUFFER_ADDR_MASK_REG (
        .CLK    (ACLK),
        .WEN    (dma_buffer_addr_mask_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (dma_buffer_addr_mask_value_out)
    );
        
    // RING_BUFFER_CFG: Ring buffer configuration
    logic ring_buffer_cfg_wreq;
    logic ring_buffer_cfg_wreq_filtered;
    logic [31:0] ring_buffer_cfg_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    RING_BUFFER_CFG_REG (
        .CLK    (ACLK),
        .WEN    (ring_buffer_cfg_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (ring_buffer_cfg_value_out)
    );
        
    // RING_BUFFER_STREAM_CONFIG: Configuration of the pre-trigger and post-trigger stream length
    logic ring_buffer_stream_config_wreq;
    logic ring_buffer_stream_config_wreq_filtered;
    logic [31:0] ring_buffer_stream_config_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    RING_BUFFER_STREAM_CONFIG_REG (
        .CLK    (ACLK),
        .WEN    (ring_buffer_stream_config_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (ring_buffer_stream_config_value_out)
    );
        
    // DATAGEN_CONFIG: Configuration of the data generation engine
    logic datagen_config_wreq;
    logic datagen_config_wreq_filtered;
    logic [31:0] datagen_config_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    DATAGEN_CONFIG_REG (
        .CLK    (ACLK),
        .WEN    (datagen_config_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (datagen_config_value_out)
    );
        
    // FAN_CONTROLLER_CONFIG: Fan controller engine configuration
    logic fan_controller_config_wreq;
    logic fan_controller_config_wreq_filtered;
    logic [31:0] fan_controller_config_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    FAN_CONTROLLER_CONFIG_REG (
        .CLK    (ACLK),
        .WEN    (fan_controller_config_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (fan_controller_config_value_out)
    );
        
    // BOARD_MANAGER_CONFIG: Board manager configuration
    logic board_manager_config_wreq;
    logic board_manager_config_wreq_filtered;
    logic [31:0] board_manager_config_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    BOARD_MANAGER_CONFIG_REG (
        .CLK    (ACLK),
        .WEN    (board_manager_config_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (board_manager_config_value_out)
    );
        
    // AD9642_CFG: ADC configuration and readout via dedicated SPI interface
    logic ad9642_cfg_wreq;
    logic ad9642_cfg_wreq_filtered;
    logic [31:0] ad9642_cfg_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    AD9642_CFG_REG (
        .CLK    (ACLK),
        .WEN    (ad9642_cfg_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (ad9642_cfg_value_out)
    );
        
    // AD9642_WDATA: AD9642 Write data
    logic ad9642_wdata_wreq;
    logic ad9642_wdata_wreq_filtered;
    logic [31:0] ad9642_wdata_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    AD9642_WDATA_REG (
        .CLK    (ACLK),
        .WEN    (ad9642_wdata_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (ad9642_wdata_value_out)
    );
        
    // LMH6518_CFG: ADC configuration and readout via dedicated SPI interface
    logic lmh6518_cfg_wreq;
    logic lmh6518_cfg_wreq_filtered;
    logic [31:0] lmh6518_cfg_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    LMH6518_CFG_REG (
        .CLK    (ACLK),
        .WEN    (lmh6518_cfg_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (lmh6518_cfg_value_out)
    );
        
    // LMH6518_WDATA: LMH6518 Write data
    logic lmh6518_wdata_wreq;
    logic lmh6518_wdata_wreq_filtered;
    logic [31:0] lmh6518_wdata_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    LMH6518_WDATA_REG (
        .CLK    (ACLK),
        .WEN    (lmh6518_wdata_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (lmh6518_wdata_value_out)
    );
        
    // DMA_TRIGGER: DMA readout trigger status (SciCompiler)
    logic dma_trigger_wreq;
    logic dma_trigger_wreq_filtered;
    logic [31:0] dma_trigger_value_out;
    RW_REG #(
        .DATA_WIDTH (32)
    )
    DMA_TRIGGER_REG (
        .CLK    (ACLK),
        .WEN    (dma_trigger_wreq_filtered),
        .WDATA  (regpool_wdata),
        .RDATA  (dma_trigger_value_out)
    );
        
    // Write decoder
    always_ff @(posedge ACLK) begin
        dma_buffer_base_addr_wreq <= 1'b0;
        dma_buffer_len_wreq <= 1'b0;
        dma_buffer_addr_mask_wreq <= 1'b0;
        ring_buffer_cfg_wreq <= 1'b0;
        ring_buffer_stream_config_wreq <= 1'b0;
        datagen_config_wreq <= 1'b0;
        fan_controller_config_wreq <= 1'b0;
        board_manager_config_wreq <= 1'b0;
        ad9642_cfg_wreq <= 1'b0;
        ad9642_wdata_wreq <= 1'b0;
        lmh6518_cfg_wreq <= 1'b0;
        lmh6518_wdata_wreq <= 1'b0;
        dma_trigger_wreq <= 1'b0;

        case(regpool_waddr)
            `DMA_BUFFER_BASE_ADDR_OFFSET : begin dma_buffer_base_addr_wreq <= 1'b1; end
            `DMA_BUFFER_LEN_OFFSET : begin dma_buffer_len_wreq <= 1'b1; end
            `DMA_BUFFER_ADDR_MASK_OFFSET : begin dma_buffer_addr_mask_wreq <= 1'b1; end
            `RING_BUFFER_CFG_OFFSET : begin ring_buffer_cfg_wreq <= 1'b1; end
            `RING_BUFFER_STREAM_CONFIG_OFFSET : begin ring_buffer_stream_config_wreq <= 1'b1; end
            `DATAGEN_CONFIG_OFFSET : begin datagen_config_wreq <= 1'b1; end
            `FAN_CONTROLLER_CONFIG_OFFSET : begin fan_controller_config_wreq <= 1'b1; end
            `BOARD_MANAGER_CONFIG_OFFSET : begin board_manager_config_wreq <= 1'b1; end
            `AD9642_CFG_OFFSET : begin ad9642_cfg_wreq <= 1'b1; end
            `AD9642_WDATA_OFFSET : begin ad9642_wdata_wreq <= 1'b1; end
            `LMH6518_CFG_OFFSET : begin lmh6518_cfg_wreq <= 1'b1; end
            `LMH6518_WDATA_OFFSET : begin lmh6518_wdata_wreq <= 1'b1; end
            `DMA_TRIGGER_OFFSET : begin dma_trigger_wreq <= 1'b1; end
        endcase
    end

    // Align Write enable to resampled decoder
    always_ff @(posedge ACLK) begin
        regpool_wen_resampled <= regpool_wen;
    end

    // Filter Write enables
    assign dma_buffer_base_addr_wreq_filtered = dma_buffer_base_addr_wreq & regpool_wen_resampled;
    assign dma_buffer_len_wreq_filtered = dma_buffer_len_wreq & regpool_wen_resampled;
    assign dma_buffer_addr_mask_wreq_filtered = dma_buffer_addr_mask_wreq & regpool_wen_resampled;
    assign ring_buffer_cfg_wreq_filtered = ring_buffer_cfg_wreq & regpool_wen_resampled;
    assign ring_buffer_stream_config_wreq_filtered = ring_buffer_stream_config_wreq & regpool_wen_resampled;
    assign datagen_config_wreq_filtered = datagen_config_wreq & regpool_wen_resampled;
    assign fan_controller_config_wreq_filtered = fan_controller_config_wreq & regpool_wen_resampled;
    assign board_manager_config_wreq_filtered = board_manager_config_wreq & regpool_wen_resampled;
    assign ad9642_cfg_wreq_filtered = ad9642_cfg_wreq & regpool_wen_resampled;
    assign ad9642_wdata_wreq_filtered = ad9642_wdata_wreq & regpool_wen_resampled;
    assign lmh6518_cfg_wreq_filtered = lmh6518_cfg_wreq & regpool_wen_resampled;
    assign lmh6518_wdata_wreq_filtered = lmh6518_wdata_wreq & regpool_wen_resampled;
    assign dma_trigger_wreq_filtered = dma_trigger_wreq & regpool_wen_resampled;

    // Create Read strobe from Read request edge
    always_ff @(posedge ACLK) begin
        regpool_rvalid <= regpool_ren;
    end

    // Read decoder
    always_ff @(posedge ACLK) begin
        case(regpool_raddr)
            `DDR_CTRL_CONFIG_OFFSET : begin regpool_rdata <= ddr_ctrl_config_value_out; end
            `RING_BUFFER_WPTR_OFFSET : begin regpool_rdata <= ring_buffer_wptr_value_out; end
            `PRE_TRIGGER_BUFFER_STATUS_OFFSET : begin regpool_rdata <= pre_trigger_buffer_status_value_out; end
            `PIPE_FIFO_FILL_STATS_OFFSET : begin regpool_rdata <= pipe_fifo_fill_stats_value_out; end
            `EOS_IRQ_COUNTER_OFFSET : begin regpool_rdata <= eos_irq_counter_value_out; end
            `EOB_IRQ_COUNTER_OFFSET : begin regpool_rdata <= eob_irq_counter_value_out; end
            `PIPE_FIFO_STATUS_OFFSET : begin regpool_rdata <= pipe_fifo_status_value_out; end
            `RING_BUFFER_WRITE_OFFSET_OFFSET : begin regpool_rdata <= ring_buffer_write_offset_value_out; end
            `PRE_TRIGGER_WRITE_OVERFLOW_COUNTER_OFFSET : begin regpool_rdata <= pre_trigger_write_overflow_counter_value_out; end
            `AD9642_RDATA_OFFSET : begin regpool_rdata <= ad9642_rdata_value_out; end
            `LMH6518_RDATA_OFFSET : begin regpool_rdata <= lmh6518_rdata_value_out; end
            `DMA_BUFFER_BASE_ADDR_OFFSET : begin regpool_rdata <= dma_buffer_base_addr_value_out; end
            `DMA_BUFFER_LEN_OFFSET : begin regpool_rdata <= dma_buffer_len_value_out; end
            `DMA_BUFFER_ADDR_MASK_OFFSET : begin regpool_rdata <= dma_buffer_addr_mask_value_out; end
            `RING_BUFFER_CFG_OFFSET : begin regpool_rdata <= ring_buffer_cfg_value_out; end
            `RING_BUFFER_STREAM_CONFIG_OFFSET : begin regpool_rdata <= ring_buffer_stream_config_value_out; end
            `DATAGEN_CONFIG_OFFSET : begin regpool_rdata <= datagen_config_value_out; end
            `FAN_CONTROLLER_CONFIG_OFFSET : begin regpool_rdata <= fan_controller_config_value_out; end
            `BOARD_MANAGER_CONFIG_OFFSET : begin regpool_rdata <= board_manager_config_value_out; end
            `AD9642_CFG_OFFSET : begin regpool_rdata <= ad9642_cfg_value_out; end
            `AD9642_WDATA_OFFSET : begin regpool_rdata <= ad9642_wdata_value_out; end
            `LMH6518_CFG_OFFSET : begin regpool_rdata <= lmh6518_cfg_value_out; end
            `LMH6518_WDATA_OFFSET : begin regpool_rdata <= lmh6518_wdata_value_out; end
            `DMA_TRIGGER_OFFSET : begin regpool_rdata <= dma_trigger_value_out; end
            default : begin regpool_rdata <= 32'hdeadbeef; end
        endcase
    end
 
    // Compose and decompose CSR structured data. Control registers (those written by the Software
    // and read by the Hardware) are put over the  hwif_out  port; Status registers (those written
    // by the Hardware and read by the Software) are get over the  hwif_in  port
    assign ddr_ctrl_config_value_in = { hwif_in.DDR_CTRL_CONFIG.drain_burst_len.next, hwif_in.DDR_CTRL_CONFIG.axi_data_width.next, hwif_in.DDR_CTRL_CONFIG.axi_addr_width.next };
    assign ring_buffer_wptr_value_in = { hwif_in.RING_BUFFER_WPTR.data.next };
    assign pre_trigger_buffer_status_value_in = { hwif_in.PRE_TRIGGER_BUFFER_STATUS.rsv.next, hwif_in.PRE_TRIGGER_BUFFER_STATUS.pempty.next, hwif_in.PRE_TRIGGER_BUFFER_STATUS.empty.next, hwif_in.PRE_TRIGGER_BUFFER_STATUS.pfull.next, hwif_in.PRE_TRIGGER_BUFFER_STATUS.full.next, hwif_in.PRE_TRIGGER_BUFFER_STATUS.data_count.next };
    assign pipe_fifo_fill_stats_value_in = { hwif_in.PIPE_FIFO_FILL_STATS.rsv.next, hwif_in.PIPE_FIFO_FILL_STATS.pre_trigger_buffer_max_fill.next, hwif_in.PIPE_FIFO_FILL_STATS.pre_trigger_buffer_full_seen.next, hwif_in.PIPE_FIFO_FILL_STATS.ring_buffer_ififo_max_fill.next, hwif_in.PIPE_FIFO_FILL_STATS.ring_buffer_ififo_full_seen.next };
    assign eos_irq_counter_value_in = { hwif_in.EOS_IRQ_COUNTER.data.next };
    assign eob_irq_counter_value_in = { hwif_in.EOB_IRQ_COUNTER.data.next };
    assign pipe_fifo_status_value_in = { hwif_in.PIPE_FIFO_STATUS.ring_buffer_ififo_occupancy.next, hwif_in.PIPE_FIFO_STATUS.pre_trigger_buffer_occupancy.next };
    assign ring_buffer_write_offset_value_in = { hwif_in.RING_BUFFER_WRITE_OFFSET.data.next };
    assign pre_trigger_write_overflow_counter_value_in = { hwif_in.PRE_TRIGGER_WRITE_OVERFLOW_COUNTER.data.next };
    assign ad9642_rdata_value_in = { hwif_in.AD9642_RDATA.data.next };
    assign lmh6518_rdata_value_in = { hwif_in.LMH6518_RDATA.data.next };
    assign { hwif_out.DMA_BUFFER_BASE_ADDR.data.value } = dma_buffer_base_addr_value_out;
    assign { hwif_out.DMA_BUFFER_LEN.data.value } = dma_buffer_len_value_out;
    assign { hwif_out.DMA_BUFFER_ADDR_MASK.data.value } = dma_buffer_addr_mask_value_out;
    assign { hwif_out.RING_BUFFER_CFG.rsv.value, hwif_out.RING_BUFFER_CFG.mode_selector.value, hwif_out.RING_BUFFER_CFG.clear_irq.value, hwif_out.RING_BUFFER_CFG.trigger.value } = ring_buffer_cfg_value_out;
    assign { hwif_out.RING_BUFFER_STREAM_CONFIG.post_trigger_len.value, hwif_out.RING_BUFFER_STREAM_CONFIG.pre_trigger_len.value, hwif_out.RING_BUFFER_STREAM_CONFIG.soft_rstn.value, hwif_out.RING_BUFFER_STREAM_CONFIG.in_stream_en.value } = ring_buffer_stream_config_value_out;
    assign { hwif_out.DATAGEN_CONFIG.rsv.value, hwif_out.DATAGEN_CONFIG.datagen_sel.value, hwif_out.DATAGEN_CONFIG.datagen_en.value } = datagen_config_value_out;
    assign { hwif_out.FAN_CONTROLLER_CONFIG.rsv.value, hwif_out.FAN_CONTROLLER_CONFIG.fan_tick.value } = fan_controller_config_value_out;
    assign { hwif_out.BOARD_MANAGER_CONFIG.rsv.value, hwif_out.BOARD_MANAGER_CONFIG.recovery.value, hwif_out.BOARD_MANAGER_CONFIG.intkilln.value, hwif_out.BOARD_MANAGER_CONFIG.jswitch.value } = board_manager_config_value_out;
    assign { hwif_out.AD9642_CFG.RSV.value, hwif_out.AD9642_CFG.ENABLE.value, hwif_out.AD9642_CFG.CMD_ADDR.value, hwif_out.AD9642_CFG.CMD_LEN.value, hwif_out.AD9642_CFG.CMD_RNW.value } = ad9642_cfg_value_out;
    assign { hwif_out.AD9642_WDATA.data.value } = ad9642_wdata_value_out;
    assign { hwif_out.LMH6518_CFG.RSV.value, hwif_out.LMH6518_CFG.ENABLE.value, hwif_out.LMH6518_CFG.CMD_ADDR.value, hwif_out.LMH6518_CFG.CMD_LEN.value, hwif_out.LMH6518_CFG.CMD_RNW.value } = lmh6518_cfg_value_out;
    assign { hwif_out.LMH6518_WDATA.data.value } = lmh6518_wdata_value_out;
    assign { hwif_out.DMA_TRIGGER.data.value } = dma_trigger_value_out;
endmodule