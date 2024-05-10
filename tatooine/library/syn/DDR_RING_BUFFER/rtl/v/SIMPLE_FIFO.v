`default_nettype none

// Adapted with modifications by Simone Corbetta PhD from the design by Dan Gisselquist, Ph.D.,
// Gisselquist Technology
module SIMPLE_FIFO #(
    parameter BW                = 8,
    parameter LGFLEN            = 4,
    parameter OPT_ASYNC_READ    = 1'b1,
    parameter OPT_WRITE_ON_FULL = 1'b0,
    parameter OPT_READ_ON_EMPTY = 1'b0
)
(
    input wire              i_clk,
    input wire              i_reset,
    // Write interface
    input wire              i_wr,
    input wire [(BW-1):0]   i_data,
    output wire             o_full,
    output wire [LGFLEN:0]  o_fill,
    // Read interface
    input wire              i_rd,
    output wire [(BW-1):0]  o_data,
    output wire             o_empty
);

    localparam FLEN = (1 << LGFLEN);
    reg                 r_full;
    reg                 r_empty;
    reg [(BW-1):0]      mem [FLEN];
    reg [LGFLEN:0]      wr_addr;
    reg [LGFLEN:0]      rd_addr;
    wire [LGFLEN-1:0]   rd_next;
    wire                w_wr;
    wire                w_rd;
    reg                 bypass_valid;
    reg [BW-1:0]        bypass_data;
    reg [BW-1:0]        rd_data;
    reg [LGFLEN:0]      fill;
    wire [BW-1:0]       data;

    assign w_wr = (i_wr & ~o_full);
    assign w_rd = (i_rd & ~o_empty);

    // Write half
    always @(posedge i_clk) begin
        if(i_reset) begin
            fill <= 0;
        end
        else begin
            case({ w_wr, w_rd })
                2'b01: fill <= fill - 1;
                2'b10: fill <= fill + 1;
                default: fill <= wr_addr - rd_addr;
            endcase
        end
    end

    // r_full, o_full
    always @(posedge i_clk) begin
        if(i_reset) begin
            r_full <= 0;
        end
        else begin
            case({ w_wr, w_rd})
                2'b01: r_full <= 1'b0;
                2'b10: r_full <= (fill == { 1'b0, {(LGFLEN){1'b1}} });
                default: r_full <= (fill == { 1'b1, {(LGFLEN){1'b0}} });
            endcase
        end
    end

    assign  o_full = (i_rd && OPT_WRITE_ON_FULL) ? 1'b0 : r_full;

    // wr_addr, the write address pointer
    always @(posedge i_clk) begin
        if(i_reset) begin
            wr_addr <= 0;
        end
        else if (w_wr) begin
            wr_addr <= wr_addr + 1'b1;
        end
    end

    // Write to memory
    always @(posedge i_clk) begin
        if (w_wr) begin
            mem[wr_addr[(LGFLEN-1):0]] <= i_data;
        end
    end

    // Read half
    always @(posedge i_clk) begin
        if(i_reset) begin
            rd_addr <= 0;
        end
        else if (w_rd) begin
            rd_addr <= rd_addr + 1;
        end
    end

    assign rd_next = rd_addr[LGFLEN-1:0] + 1;

    // r_empty, o_empty
    always @(posedge i_clk) begin
        if (i_reset) begin
            r_empty <= 1'b1;
        end
        else begin
            case ({ w_wr, w_rd })
                2'b01: r_empty <= (fill <= 1);
                2'b10: r_empty <= 1'b0;
                default: begin end
            endcase
        end
    end

    assign  o_empty = (OPT_READ_ON_EMPTY && i_wr) ? 1'b0 : r_empty;

    // Read from the FIFO
    generate
        if (OPT_ASYNC_READ && OPT_READ_ON_EMPTY) begin
            always @(*) begin
                data = mem[rd_addr[LGFLEN-1:0]];
                if (r_empty) begin
                    data = i_data;
                end
            end
        end
        else if (OPT_ASYNC_READ) begin
            assign data = mem[rd_addr[LGFLEN-1:0]];
        end
        else begin
            // Memory read, bypassing it if we must
            always @(posedge i_clk) begin
                if (i_reset) begin
                    bypass_valid <= 0;
                end
                else if (r_empty || i_rd) begin
                    bypass_valid <= i_wr && (r_empty || (i_rd && fill == 1));
                end
            end

            always @(posedge i_clk) begin
                if (r_empty || i_rd) begin
                    bypass_data <= i_data;
                end
            end

            always @(posedge i_clk) begin
                if (w_rd) begin
                    rd_data <= mem[rd_next];
                end
            end

            always @(*) begin
                if (OPT_READ_ON_EMPTY && r_empty) begin
                    data = i_data;
                end
                else if (bypass_valid) begin
                    data = bypass_data;
                end
                else begin
                    data = rd_data;
                end
            end
        end
    endgenerate

    // Pinout
    assign o_fill   = fill;
    assign o_data   = data;
endmodule

`default_nettype wire
