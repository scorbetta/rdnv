// Adapted from the design by Dan Gisselquist, Ph.D., Gisselquist Technology, with modifications by
// Simone Corbetta, Ph. D. Nuclear Instruments
module SIMPLE_FIFO #(
    parameter BW                = 8,
    parameter LGFLEN            = 4,
    parameter OPT_ASYNC_READ    = 1'b1,
    parameter OPT_WRITE_ON_FULL = 1'b0,
    parameter OPT_READ_ON_EMPTY = 1'b0
)
(
    input                   i_clk,
    input                   i_reset,
    // Write interface
    input                   i_wr,
    input [(BW-1):0]        i_data,
    output	                o_full,
    output reg [LGFLEN:0]   o_fill,
    // Read interface
    input                   i_rd,
    output reg [(BW-1):0]   o_data,
    output	                o_empty
);

	localparam FLEN = (1 << LGFLEN);
	logic			    r_full;
    logic               r_empty;
	logic [(BW-1):0]	mem [FLEN];
	logic [LGFLEN:0]	wr_addr;
    logic [LGFLEN:0]    rd_addr;
	logic [LGFLEN-1:0]  rd_next;
	logic               w_wr;
	logic               w_rd;
    logic               bypass_valid;
    logic [BW-1:0]      bypass_data;
    logic [BW-1:0]      rd_data;

    assign w_wr = (i_wr & ~o_full);
    assign w_rd = (i_rd & ~o_empty);

	// Write half
	always_ff @(posedge i_clk) begin
        if(i_reset) begin
            o_fill <= 0;
        end
        else begin
            case({ w_wr, w_rd })
                2'b01: o_fill <= o_fill - 1;
                2'b10: o_fill <= o_fill + 1;
                default: o_fill <= wr_addr - rd_addr;
            endcase
        end
    end

	// r_full, o_full
	always_ff @(posedge i_clk) begin
        if(i_reset) begin
            r_full <= 0;
        end
        else begin
            case({ w_wr, w_rd})
                2'b01: r_full <= 1'b0;
                2'b10: r_full <= (o_fill == { 1'b0, {(LGFLEN){1'b1}} });
                default: r_full <= (o_fill == { 1'b1, {(LGFLEN){1'b0}} });
            endcase
        end
    end

	assign	o_full = (i_rd && OPT_WRITE_ON_FULL) ? 1'b0 : r_full;

	// wr_addr, the write address pointer
	always_ff @(posedge i_clk) begin
        if(i_reset) begin
            wr_addr <= 0;
        end
        else if (w_wr) begin
            wr_addr <= wr_addr + 1'b1;
        end
    end

	// Write to memory
	always_ff @(posedge i_clk) begin
        if (w_wr) begin
            mem[wr_addr[(LGFLEN-1):0]] <= i_data;
        end
    end

	// Read half
	always_ff @(posedge i_clk) begin
        if(i_reset) begin
            rd_addr <= 0;
        end
        else if (w_rd) begin
            rd_addr <= rd_addr + 1;
        end
    end

	assign rd_next = rd_addr[LGFLEN-1:0] + 1;

	// r_empty, o_empty
	always_ff @(posedge i_clk) begin
        if (i_reset) begin
            r_empty <= 1'b1;
        end
        else begin
            case ({ w_wr, w_rd })
                2'b01: r_empty <= (o_fill <= 1);
                2'b10: r_empty <= 1'b0;
                default: begin end
            endcase
        end
    end

	assign	o_empty = (OPT_READ_ON_EMPTY && i_wr) ? 1'b0 : r_empty;

	// Read from the FIFO
    generate
        if (OPT_ASYNC_READ && OPT_READ_ON_EMPTY) begin
            // o_data
            always_comb begin
                o_data = mem[rd_addr[LGFLEN-1:0]];
                if (r_empty) begin
                    o_data = i_data;
                end
            end
        end
        else if (OPT_ASYNC_READ) begin
            // o_data
            assign o_data = mem[rd_addr[LGFLEN-1:0]];
        end
        else begin
            // Memory read, bypassing it if we must
            always_ff @(posedge i_clk) begin
                if (i_reset) begin
                    bypass_valid <= 0;
                end
                else if (r_empty || i_rd) begin
                    bypass_valid <= i_wr && (r_empty || (i_rd && o_fill == 1));
                end
            end

            always_ff @(posedge i_clk) begin
                if (r_empty || i_rd) begin
                    bypass_data <= i_data;
                end
            end

            always_ff @(posedge i_clk) begin
                if (w_rd) begin
                    rd_data <= mem[rd_next];
                end
            end

            always_comb begin
                if (OPT_READ_ON_EMPTY && r_empty) begin
                    o_data = i_data;
                end
                else if (bypass_valid) begin
                    o_data = bypass_data;
                end
                else begin
                    o_data = rd_data;
                end
            end
        end
	endgenerate
endmodule