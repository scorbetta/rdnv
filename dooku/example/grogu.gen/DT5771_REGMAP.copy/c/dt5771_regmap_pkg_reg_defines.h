#pragma once

// Array registers are defined only once

// DT5771_DDR_CTRL_CONFIG @+0x0
typedef union DT5771_DDR_CTRL_CONFIG_reg_tag {
    struct {
        uint32_t axi_addr_width : 9; // @[8:0]
        uint32_t axi_data_width : 12; // @[20:9]
        uint32_t drain_burst_len : 11; // @[31:21]
    } fields;
    uint32_t value;
} DT5771_DDR_CTRL_CONFIG_reg_t;

// DT5771_RING_BUFFER_WPTR @+0x4
typedef union DT5771_RING_BUFFER_WPTR_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_RING_BUFFER_WPTR_reg_t;

// DT5771_PRE_TRIGGER_BUFFER_STATUS @+0x8
typedef union DT5771_PRE_TRIGGER_BUFFER_STATUS_reg_tag {
    struct {
        uint32_t data_count : 11; // @[10:0]
        uint32_t full : 1; // @[11:11]
        uint32_t pfull : 1; // @[12:12]
        uint32_t empty : 1; // @[13:13]
        uint32_t pempty : 1; // @[14:14]
        uint32_t rsv : 17; // @[31:15]
    } fields;
    uint32_t value;
} DT5771_PRE_TRIGGER_BUFFER_STATUS_reg_t;

// DT5771_PIPE_FIFO_FILL_STATS @+0xc
typedef union DT5771_PIPE_FIFO_FILL_STATS_reg_tag {
    struct {
        uint32_t ring_buffer_ififo_full_seen : 1; // @[0:0]
        uint32_t ring_buffer_ififo_max_fill : 10; // @[10:1]
        uint32_t pre_trigger_buffer_full_seen : 1; // @[11:11]
        uint32_t pre_trigger_buffer_max_fill : 11; // @[22:12]
        uint32_t rsv : 9; // @[31:23]
    } fields;
    uint32_t value;
} DT5771_PIPE_FIFO_FILL_STATS_reg_t;

// DT5771_EOS_IRQ_COUNTER @+0x10
typedef union DT5771_EOS_IRQ_COUNTER_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_EOS_IRQ_COUNTER_reg_t;

// DT5771_EOB_IRQ_COUNTER @+0x14
typedef union DT5771_EOB_IRQ_COUNTER_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_EOB_IRQ_COUNTER_reg_t;

// DT5771_PIPE_FIFO_STATUS @+0x18
typedef union DT5771_PIPE_FIFO_STATUS_reg_tag {
    struct {
        uint32_t pre_trigger_buffer_occupancy : 16; // @[15:0]
        uint32_t ring_buffer_ififo_occupancy : 16; // @[31:16]
    } fields;
    uint32_t value;
} DT5771_PIPE_FIFO_STATUS_reg_t;

// DT5771_RING_BUFFER_WRITE_OFFSET @+0x1c
typedef union DT5771_RING_BUFFER_WRITE_OFFSET_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_RING_BUFFER_WRITE_OFFSET_reg_t;

// DT5771_PRE_TRIGGER_WRITE_OVERFLOW_COUNTER @+0x20
typedef union DT5771_PRE_TRIGGER_WRITE_OVERFLOW_COUNTER_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_PRE_TRIGGER_WRITE_OVERFLOW_COUNTER_reg_t;

// DT5771_AD9642_RDATA @+0x24
typedef union DT5771_AD9642_RDATA_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_AD9642_RDATA_reg_t;

// DT5771_LMH6518_RDATA @+0x28
typedef union DT5771_LMH6518_RDATA_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_LMH6518_RDATA_reg_t;

// DT5771_DMA_BUFFER_BASE_ADDR @+0x2c
typedef union DT5771_DMA_BUFFER_BASE_ADDR_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_DMA_BUFFER_BASE_ADDR_reg_t;

// DT5771_DMA_BUFFER_LEN @+0x30
typedef union DT5771_DMA_BUFFER_LEN_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_DMA_BUFFER_LEN_reg_t;

// DT5771_DMA_BUFFER_ADDR_MASK @+0x34
typedef union DT5771_DMA_BUFFER_ADDR_MASK_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_DMA_BUFFER_ADDR_MASK_reg_t;

// DT5771_RING_BUFFER_CFG @+0x38
typedef union DT5771_RING_BUFFER_CFG_reg_tag {
    struct {
        uint32_t trigger : 1; // @[0:0]
        uint32_t clear_irq : 1; // @[1:1]
        uint32_t mode_selector : 2; // @[3:2]
        uint32_t rsv : 28; // @[31:4]
    } fields;
    uint32_t value;
} DT5771_RING_BUFFER_CFG_reg_t;

// DT5771_RING_BUFFER_STREAM_CONFIG @+0x3c
typedef union DT5771_RING_BUFFER_STREAM_CONFIG_reg_tag {
    struct {
        uint32_t in_stream_en : 1; // @[0:0]
        uint32_t soft_rstn : 1; // @[1:1]
        uint32_t pre_trigger_len : 10; // @[11:2]
        uint32_t post_trigger_len : 20; // @[31:12]
    } fields;
    uint32_t value;
} DT5771_RING_BUFFER_STREAM_CONFIG_reg_t;

// DT5771_DATAGEN_CONFIG @+0x40
typedef union DT5771_DATAGEN_CONFIG_reg_tag {
    struct {
        uint32_t datagen_en : 1; // @[0:0]
        uint32_t datagen_sel : 2; // @[2:1]
        uint32_t rsv : 29; // @[31:3]
    } fields;
    uint32_t value;
} DT5771_DATAGEN_CONFIG_reg_t;

// DT5771_FAN_CONTROLLER_CONFIG @+0x44
typedef union DT5771_FAN_CONTROLLER_CONFIG_reg_tag {
    struct {
        uint32_t fan_tick : 1; // @[0:0]
        uint32_t rsv : 31; // @[31:1]
    } fields;
    uint32_t value;
} DT5771_FAN_CONTROLLER_CONFIG_reg_t;

// DT5771_BOARD_MANAGER_CONFIG @+0x48
typedef union DT5771_BOARD_MANAGER_CONFIG_reg_tag {
    struct {
        uint32_t jswitch : 3; // @[2:0]
        uint32_t intkilln : 1; // @[3:3]
        uint32_t recovery : 1; // @[4:4]
        uint32_t rsv : 27; // @[31:5]
    } fields;
    uint32_t value;
} DT5771_BOARD_MANAGER_CONFIG_reg_t;

// DT5771_AD9642_CFG @+0x4c
typedef union DT5771_AD9642_CFG_reg_tag {
    struct {
        uint32_t CMD_RNW : 1; // @[0:0]
        uint32_t CMD_LEN : 2; // @[2:1]
        uint32_t CMD_ADDR : 13; // @[15:3]
        uint32_t ENABLE : 1; // @[16:16]
        uint32_t RSV : 15; // @[31:17]
    } fields;
    uint32_t value;
} DT5771_AD9642_CFG_reg_t;

// DT5771_AD9642_WDATA @+0x50
typedef union DT5771_AD9642_WDATA_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_AD9642_WDATA_reg_t;

// DT5771_LMH6518_CFG @+0x54
typedef union DT5771_LMH6518_CFG_reg_tag {
    struct {
        uint32_t CMD_RNW : 1; // @[0:0]
        uint32_t CMD_LEN : 2; // @[2:1]
        uint32_t CMD_ADDR : 13; // @[15:3]
        uint32_t ENABLE : 1; // @[16:16]
        uint32_t RSV : 15; // @[31:17]
    } fields;
    uint32_t value;
} DT5771_LMH6518_CFG_reg_t;

// DT5771_LMH6518_WDATA @+0x58
typedef union DT5771_LMH6518_WDATA_reg_tag {
    struct {
        uint32_t data : 32; // @[31:0]
    } fields;
    uint32_t value;
} DT5771_LMH6518_WDATA_reg_t;
