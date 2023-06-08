// Generated by PeakRDL-regblock starting from JINJA templated  my_package_template.sv  file
`timescale 1ns/100ps

package dt5771_regmap_pkg;
    typedef struct {
        logic [8:0] next;
    } CSR_S_DDR_CTRL_CONFIG__axi_addr_width__in_t;

    typedef struct {
        logic [11:0] next;
    } CSR_S_DDR_CTRL_CONFIG__axi_data_width__in_t;

    typedef struct {
        logic [10:0] next;
    } CSR_S_DDR_CTRL_CONFIG__drain_burst_len__in_t;

    typedef struct {
        CSR_S_DDR_CTRL_CONFIG__axi_addr_width__in_t axi_addr_width;
        CSR_S_DDR_CTRL_CONFIG__axi_data_width__in_t axi_data_width;
        CSR_S_DDR_CTRL_CONFIG__drain_burst_len__in_t drain_burst_len;
    } __CSR_S_DDR_CTRL_CONFIG__in_t;

    typedef struct {
        logic [31:0] next;
    } CSR_S_GPREG__data__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_010241b3__in_t;

    typedef struct {
        logic [10:0] next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__data_count__in_t;

    typedef struct {
        logic next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__full__in_t;

    typedef struct {
        logic next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__pfull__in_t;

    typedef struct {
        logic next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__empty__in_t;

    typedef struct {
        logic next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__pempty__in_t;

    typedef struct {
        logic [16:0] next;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__rsv__in_t;

    typedef struct {
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__data_count__in_t data_count;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__full__in_t full;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__pfull__in_t pfull;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__empty__in_t empty;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__pempty__in_t pempty;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__rsv__in_t rsv;
    } __CSR_S_PRE_TRIGGER_BUFFER_STATUS__in_t;

    typedef struct {
        logic next;
    } CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_full_seen__in_t;

    typedef struct {
        logic [9:0] next;
    } CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_max_fill__in_t;

    typedef struct {
        logic next;
    } CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_full_seen__in_t;

    typedef struct {
        logic [10:0] next;
    } CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_max_fill__in_t;

    typedef struct {
        logic [8:0] next;
    } CSR_S_PIPE_FIFO_FILL_STATS__rsv__in_t;

    typedef struct {
        CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_full_seen__in_t ring_buffer_ififo_full_seen;
        CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_max_fill__in_t ring_buffer_ififo_max_fill;
        CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_full_seen__in_t pre_trigger_buffer_full_seen;
        CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_max_fill__in_t pre_trigger_buffer_max_fill;
        CSR_S_PIPE_FIFO_FILL_STATS__rsv__in_t rsv;
    } __CSR_S_PIPE_FIFO_FILL_STATS__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_9698c27f__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_0c009a9a__in_t;

    typedef struct {
        logic [15:0] next;
    } CSR_S_PIPE_FIFO_STATUS__pre_trigger_buffer_occupancy__in_t;

    typedef struct {
        logic [15:0] next;
    } CSR_S_PIPE_FIFO_STATUS__ring_buffer_ififo_occupancy__in_t;

    typedef struct {
        CSR_S_PIPE_FIFO_STATUS__pre_trigger_buffer_occupancy__in_t pre_trigger_buffer_occupancy;
        CSR_S_PIPE_FIFO_STATUS__ring_buffer_ififo_occupancy__in_t ring_buffer_ififo_occupancy;
    } __CSR_S_PIPE_FIFO_STATUS__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_ee0b9709__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_f53fa901__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_d2beafd7__in_t;

    typedef struct {
        CSR_S_GPREG__data__in_t data;
    } __CSR_S_GPREG_desc_3a9fc9a1__in_t;

    typedef struct {
        __CSR_S_DDR_CTRL_CONFIG__in_t DDR_CTRL_CONFIG;
        __CSR_S_GPREG_desc_010241b3__in_t RING_BUFFER_WPTR;
        __CSR_S_PRE_TRIGGER_BUFFER_STATUS__in_t PRE_TRIGGER_BUFFER_STATUS;
        __CSR_S_PIPE_FIFO_FILL_STATS__in_t PIPE_FIFO_FILL_STATS;
        __CSR_S_GPREG_desc_9698c27f__in_t EOS_IRQ_COUNTER;
        __CSR_S_GPREG_desc_0c009a9a__in_t EOB_IRQ_COUNTER;
        __CSR_S_PIPE_FIFO_STATUS__in_t PIPE_FIFO_STATUS;
        __CSR_S_GPREG_desc_ee0b9709__in_t RING_BUFFER_WRITE_OFFSET;
        __CSR_S_GPREG_desc_f53fa901__in_t PRE_TRIGGER_WRITE_OVERFLOW_COUNTER;
        __CSR_S_GPREG_desc_d2beafd7__in_t AD9642_RDATA;
        __CSR_S_GPREG_desc_3a9fc9a1__in_t LMH6518_RDATA;
    } dt5771_address_map__in_t;

    typedef struct {
        logic [8:0] value;
    } CSR_S_DDR_CTRL_CONFIG__axi_addr_width__out_t;

    typedef struct {
        logic [11:0] value;
    } CSR_S_DDR_CTRL_CONFIG__axi_data_width__out_t;

    typedef struct {
        logic [10:0] value;
    } CSR_S_DDR_CTRL_CONFIG__drain_burst_len__out_t;

    typedef struct {
        CSR_S_DDR_CTRL_CONFIG__axi_addr_width__out_t axi_addr_width;
        CSR_S_DDR_CTRL_CONFIG__axi_data_width__out_t axi_data_width;
        CSR_S_DDR_CTRL_CONFIG__drain_burst_len__out_t drain_burst_len;
    } __CSR_S_DDR_CTRL_CONFIG__out_t;

    typedef struct {
        logic [31:0] value;
    } CSR_S_GPREG__data__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_010241b3__out_t;

    typedef struct {
        logic [10:0] value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__data_count__out_t;

    typedef struct {
        logic value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__full__out_t;

    typedef struct {
        logic value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__pfull__out_t;

    typedef struct {
        logic value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__empty__out_t;

    typedef struct {
        logic value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__pempty__out_t;

    typedef struct {
        logic [16:0] value;
    } CSR_S_PRE_TRIGGER_BUFFER_STATUS__rsv__out_t;

    typedef struct {
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__data_count__out_t data_count;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__full__out_t full;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__pfull__out_t pfull;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__empty__out_t empty;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__pempty__out_t pempty;
        CSR_S_PRE_TRIGGER_BUFFER_STATUS__rsv__out_t rsv;
    } __CSR_S_PRE_TRIGGER_BUFFER_STATUS__out_t;

    typedef struct {
        logic value;
    } CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_full_seen__out_t;

    typedef struct {
        logic [9:0] value;
    } CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_max_fill__out_t;

    typedef struct {
        logic value;
    } CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_full_seen__out_t;

    typedef struct {
        logic [10:0] value;
    } CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_max_fill__out_t;

    typedef struct {
        logic [8:0] value;
    } CSR_S_PIPE_FIFO_FILL_STATS__rsv__out_t;

    typedef struct {
        CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_full_seen__out_t ring_buffer_ififo_full_seen;
        CSR_S_PIPE_FIFO_FILL_STATS__ring_buffer_ififo_max_fill__out_t ring_buffer_ififo_max_fill;
        CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_full_seen__out_t pre_trigger_buffer_full_seen;
        CSR_S_PIPE_FIFO_FILL_STATS__pre_trigger_buffer_max_fill__out_t pre_trigger_buffer_max_fill;
        CSR_S_PIPE_FIFO_FILL_STATS__rsv__out_t rsv;
    } __CSR_S_PIPE_FIFO_FILL_STATS__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_9698c27f__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_0c009a9a__out_t;

    typedef struct {
        logic [15:0] value;
    } CSR_S_PIPE_FIFO_STATUS__pre_trigger_buffer_occupancy__out_t;

    typedef struct {
        logic [15:0] value;
    } CSR_S_PIPE_FIFO_STATUS__ring_buffer_ififo_occupancy__out_t;

    typedef struct {
        CSR_S_PIPE_FIFO_STATUS__pre_trigger_buffer_occupancy__out_t pre_trigger_buffer_occupancy;
        CSR_S_PIPE_FIFO_STATUS__ring_buffer_ififo_occupancy__out_t ring_buffer_ififo_occupancy;
    } __CSR_S_PIPE_FIFO_STATUS__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_ee0b9709__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_f53fa901__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_d2beafd7__out_t;

    typedef struct {
        CSR_S_GPREG__data__out_t data;
    } __CSR_S_GPREG_desc_3a9fc9a1__out_t;

    typedef struct {
        logic [31:0] value;
    } CSR_C_GPREG__data__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_f05fd524__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_197ebead__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_a3c0cc5f__out_t;

    typedef struct {
        logic value;
    } CSR_C_RING_BUFFER_CFG__trigger__out_t;

    typedef struct {
        logic value;
    } CSR_C_RING_BUFFER_CFG__clear_irq__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_C_RING_BUFFER_CFG__mode_selector__out_t;

    typedef struct {
        logic [27:0] value;
    } CSR_C_RING_BUFFER_CFG__rsv__out_t;

    typedef struct {
        CSR_C_RING_BUFFER_CFG__trigger__out_t trigger;
        CSR_C_RING_BUFFER_CFG__clear_irq__out_t clear_irq;
        CSR_C_RING_BUFFER_CFG__mode_selector__out_t mode_selector;
        CSR_C_RING_BUFFER_CFG__rsv__out_t rsv;
    } __CSR_C_RING_BUFFER_CFG__out_t;

    typedef struct {
        logic value;
    } CSR_C_RING_BUFFER_STREAM_CONFIG__in_stream_en__out_t;

    typedef struct {
        logic value;
    } CSR_C_RING_BUFFER_STREAM_CONFIG__soft_rstn__out_t;

    typedef struct {
        logic [9:0] value;
    } CSR_C_RING_BUFFER_STREAM_CONFIG__pre_trigger_len__out_t;

    typedef struct {
        logic [19:0] value;
    } CSR_C_RING_BUFFER_STREAM_CONFIG__post_trigger_len__out_t;

    typedef struct {
        CSR_C_RING_BUFFER_STREAM_CONFIG__in_stream_en__out_t in_stream_en;
        CSR_C_RING_BUFFER_STREAM_CONFIG__soft_rstn__out_t soft_rstn;
        CSR_C_RING_BUFFER_STREAM_CONFIG__pre_trigger_len__out_t pre_trigger_len;
        CSR_C_RING_BUFFER_STREAM_CONFIG__post_trigger_len__out_t post_trigger_len;
    } __CSR_C_RING_BUFFER_STREAM_CONFIG__out_t;

    typedef struct {
        logic value;
    } CSR_C_DATAGEN_CONFIG__datagen_en__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_C_DATAGEN_CONFIG__datagen_sel__out_t;

    typedef struct {
        logic [28:0] value;
    } CSR_C_DATAGEN_CONFIG__rsv__out_t;

    typedef struct {
        CSR_C_DATAGEN_CONFIG__datagen_en__out_t datagen_en;
        CSR_C_DATAGEN_CONFIG__datagen_sel__out_t datagen_sel;
        CSR_C_DATAGEN_CONFIG__rsv__out_t rsv;
    } __CSR_C_DATAGEN_CONFIG__out_t;

    typedef struct {
        logic value;
    } CSR_C_FAN_CONTROLLER_CONFIG__fan_tick__out_t;

    typedef struct {
        logic [30:0] value;
    } CSR_C_FAN_CONTROLLER_CONFIG__rsv__out_t;

    typedef struct {
        CSR_C_FAN_CONTROLLER_CONFIG__fan_tick__out_t fan_tick;
        CSR_C_FAN_CONTROLLER_CONFIG__rsv__out_t rsv;
    } __CSR_C_FAN_CONTROLLER_CONFIG__out_t;

    typedef struct {
        logic [2:0] value;
    } CSR_C_BOARD_MANAGER_CONFIG__jswitch__out_t;

    typedef struct {
        logic value;
    } CSR_C_BOARD_MANAGER_CONFIG__intkilln__out_t;

    typedef struct {
        logic value;
    } CSR_C_BOARD_MANAGER_CONFIG__recovery__out_t;

    typedef struct {
        logic [26:0] value;
    } CSR_C_BOARD_MANAGER_CONFIG__rsv__out_t;

    typedef struct {
        CSR_C_BOARD_MANAGER_CONFIG__jswitch__out_t jswitch;
        CSR_C_BOARD_MANAGER_CONFIG__intkilln__out_t intkilln;
        CSR_C_BOARD_MANAGER_CONFIG__recovery__out_t recovery;
        CSR_C_BOARD_MANAGER_CONFIG__rsv__out_t rsv;
    } __CSR_C_BOARD_MANAGER_CONFIG__out_t;

    typedef struct {
        logic value;
    } CSR_C_ADC_SPI_CONFIG__CMD_RNW__out_t;

    typedef struct {
        logic [1:0] value;
    } CSR_C_ADC_SPI_CONFIG__CMD_LEN__out_t;

    typedef struct {
        logic [12:0] value;
    } CSR_C_ADC_SPI_CONFIG__CMD_ADDR__out_t;

    typedef struct {
        logic value;
    } CSR_C_ADC_SPI_CONFIG__ENABLE__out_t;

    typedef struct {
        logic [14:0] value;
    } CSR_C_ADC_SPI_CONFIG__RSV__out_t;

    typedef struct {
        CSR_C_ADC_SPI_CONFIG__CMD_RNW__out_t CMD_RNW;
        CSR_C_ADC_SPI_CONFIG__CMD_LEN__out_t CMD_LEN;
        CSR_C_ADC_SPI_CONFIG__CMD_ADDR__out_t CMD_ADDR;
        CSR_C_ADC_SPI_CONFIG__ENABLE__out_t ENABLE;
        CSR_C_ADC_SPI_CONFIG__RSV__out_t RSV;
    } __CSR_C_ADC_SPI_CONFIG__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_4e05e9b0__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_a6984a69__out_t;

    typedef struct {
        CSR_C_GPREG__data__out_t data;
    } __CSR_C_GPREG_desc_4833da00__out_t;

    typedef struct {
        __CSR_S_DDR_CTRL_CONFIG__out_t DDR_CTRL_CONFIG;
        __CSR_S_GPREG_desc_010241b3__out_t RING_BUFFER_WPTR;
        __CSR_S_PRE_TRIGGER_BUFFER_STATUS__out_t PRE_TRIGGER_BUFFER_STATUS;
        __CSR_S_PIPE_FIFO_FILL_STATS__out_t PIPE_FIFO_FILL_STATS;
        __CSR_S_GPREG_desc_9698c27f__out_t EOS_IRQ_COUNTER;
        __CSR_S_GPREG_desc_0c009a9a__out_t EOB_IRQ_COUNTER;
        __CSR_S_PIPE_FIFO_STATUS__out_t PIPE_FIFO_STATUS;
        __CSR_S_GPREG_desc_ee0b9709__out_t RING_BUFFER_WRITE_OFFSET;
        __CSR_S_GPREG_desc_f53fa901__out_t PRE_TRIGGER_WRITE_OVERFLOW_COUNTER;
        __CSR_S_GPREG_desc_d2beafd7__out_t AD9642_RDATA;
        __CSR_S_GPREG_desc_3a9fc9a1__out_t LMH6518_RDATA;
        __CSR_C_GPREG_desc_f05fd524__out_t DMA_BUFFER_BASE_ADDR;
        __CSR_C_GPREG_desc_197ebead__out_t DMA_BUFFER_LEN;
        __CSR_C_GPREG_desc_a3c0cc5f__out_t DMA_BUFFER_ADDR_MASK;
        __CSR_C_RING_BUFFER_CFG__out_t RING_BUFFER_CFG;
        __CSR_C_RING_BUFFER_STREAM_CONFIG__out_t RING_BUFFER_STREAM_CONFIG;
        __CSR_C_DATAGEN_CONFIG__out_t DATAGEN_CONFIG;
        __CSR_C_FAN_CONTROLLER_CONFIG__out_t FAN_CONTROLLER_CONFIG;
        __CSR_C_BOARD_MANAGER_CONFIG__out_t BOARD_MANAGER_CONFIG;
        __CSR_C_ADC_SPI_CONFIG__out_t AD9642_CFG;
        __CSR_C_GPREG_desc_4e05e9b0__out_t AD9642_WDATA;
        __CSR_C_ADC_SPI_CONFIG__out_t LMH6518_CFG;
        __CSR_C_GPREG_desc_a6984a69__out_t LMH6518_WDATA;
        __CSR_C_GPREG_desc_4833da00__out_t DMA_TRIGGER;
    } dt5771_address_map__out_t;
endpackage