`timescale 1ns/100ps

module READY_VALID_FILTER_WITH_REN
#(
    parameter DATA_WIDTH    = 64
)
(
    input                   CLK,
    input                   RSTN,
    input [DATA_WIDTH-1:0]  DATA_IN,
    input                   LAST_IN,
    input                   VALID_IN,
    input                   READY_IN,
    output [DATA_WIDTH-1:0] DATA_OUT,
    output                  LAST_OUT,
    output                  VALID_OUT,
    output                  RD_EN,
    output [31:0]           RD_ADDR
);

    // Internal signals
    logic                   buffer_en;
    logic [DATA_WIDTH-1:0]  buffer_data;
    logic                   buffer_valid;
    logic                   buffer_last;
    logic                   out_en;
    logic [DATA_WIDTH-1:0]  data_mux;
    logic                   valid_mux;
    logic                   buffer_sel;
    logic [31:0]            rd_addr;
    logic                   rd_en;
    logic                   valid_out;
    logic                   next;
    logic [DATA_WIDTH-1:0]  data_in;
    logic                   valid_in;
    logic                   in_en;

    typedef enum { ERROR, STALL, FILL, FW } state_t;
    state_t                 curr_state;
    state_t                 next_state;

    // The data buffer
    REGISTER_PIPELINE #(
        .DATA_WIDTH     (DATA_WIDTH),
        .RESET_VALUE    ({DATA_WIDTH{1'b0}}),
        .NUM_STAGES     (1)
    )
    DATA_BUFFER (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (buffer_en),
        .DATA_IN    (data_in),
        .DATA_OUT   (buffer_data)
    );

    // The valid buffer
    REGISTER_PIPELINE #(
        .DATA_WIDTH     (1),
        .RESET_VALUE    (1'b0),
        .NUM_STAGES     (1)
    )
    VALID_BUFFER (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (buffer_en),
        .DATA_IN    (valid_in),
        .DATA_OUT   (buffer_valid)
    );

    // The last buffer
    REGISTER_PIPELINE #(
        .DATA_WIDTH     (1),
        .RESET_VALUE    (1'b0),
        .NUM_STAGES     (1)
    )
    LAST_BUFFER (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (buffer_en),
        .DATA_IN    (last_in),
        .DATA_OUT   (buffer_last)
    );

    // The output data register
    REGISTER #(
        .DATA_WIDTH     (DATA_WIDTH),
        .RESET_VALUE    ({DATA_WIDTH{1'b0}})
    )
    DATA_OUT_REG (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (out_en),
        .DATA_IN    (data_mux),
        .DATA_OUT   (DATA_OUT)
    );

    // The output valid register
    REGISTER #(
        .DATA_WIDTH     (1),
        .RESET_VALUE    (1'b0)
    )
    VALID_OUT_REG (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .CE         (out_en),
        .DATA_IN    (valid_mux),
        .DATA_OUT   (valid_out)
    );

    // The internal muxes
    always_comb begin
        case(buffer_sel)
            1'b0 : begin
                data_mux = data_in;
                valid_mux = valid_in;
            end

            1'b1 : begin
                data_mux = buffer_data;
                valid_mux = buffer_valid;
            end
        endcase
    end

    always_comb begin
        case(in_en)
            1'b0 : begin
                data_in = data_in;
                valid_in = valid_in;
            end

            1'b1 : begin
                data_in = DATA_IN;
                valid_in = VALID_IN;
            end
        endcase
    end

    // The Pearl

    // Next-state compute logic
    always_comb begin
        case(curr_state)
            FW : begin
                next_state = READY_IN ? FW : FILL;
            end

            FILL : begin
                next_state = READY_IN ? FILL : STALL;
            end

            STALL : begin
                next_state = READY_IN ? FILL : STALL;
            end

            ERROR : begin
                next_state = ERROR;
            end

            default : begin
                next_state = ERROR;
            end
        endcase
    end

    // Next-state update logic
    always_ff @(posedge CLK) begin
        if(!RSTN) begin
            curr_state <= FW;
        end
        else begin
            curr_state <= next_state;
        end
    end

    // Output logic (Moore's outputs depend only on the current state, Mealy's ones depend on the
    // input as well)
    always_comb begin
        case(curr_state)
            FW : begin
                rd_en = 1'b1;
                buffer_en = ~READY_IN;
                buffer_sel = 1'b0;
                out_en = READY_IN;
                next = 1'b1;
                in_en = 1'b1;
            end

            FILL : begin
                rd_en = READY_IN;
                buffer_en = READY_IN;
                buffer_sel = 1'b1;
                out_en = READY_IN;
                next = READY_IN;
                in_en = 1'b1;
            end

            STALL : begin
                rd_en = 1'b0;
                buffer_en = READY_IN;
                buffer_sel = 1'b1;
                out_en = READY_IN;
                next = 1'b0;
                in_en = 1'b0;
            end

            default : begin
                rd_en = 1'b0;
                buffer_en = 1'b0;
                buffer_sel = 1'b0;
                out_en = 1'b0;
            end
        endcase
    end

    // Address is incremented every time  ready_in  and  valid_out  are both asserted
    always_ff @(posedge CLK) begin
        if(!RSTN) begin
            rd_addr <= 0;
        end
        else if(next) begin
            rd_addr <= rd_addr + 4;
        end
    end

    // Pinout
    assign RD_EN        = rd_en;
    assign RD_ADDR      = rd_addr;
    assign VALID_OUT    = valid_out;
endmodule
