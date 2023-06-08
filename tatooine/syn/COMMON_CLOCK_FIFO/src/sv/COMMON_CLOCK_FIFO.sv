// SystemVerilog porting of the original VHDL FIFO design. The design has been
// improved, w/ some fixes
module COMMON_CLOCK_FIFO #(
    // Define Fifo Depth. If depth is not specified as power of 2, it is automatically rounded to
    // nearest and greater power of 2.  Minimum depth is 8.
    parameter FIFO_DEPTH            = 8,
    // Data Bus width
    parameter DATA_WIDTH            = 32,
    // FWFT_SHOWAHEAD = 1, first word appears at the output without asserting read enable
    // FWFT_SHOWAHEAD = 0, a standard Fifo will be generated.
    parameter FWFT_SHOWAHEAD        = 0
)
(
    input                   SYNC_RST,
    input                   CLK,
    input                   WE,
    input [DATA_WIDTH-1:0]  DIN,
    output                  FULL,
    output                  PROG_FULL,
    output                  VALID,
    input                   RE,
    output [DATA_WIDTH-1:0] DOUT,
    output                  EMPTY,
    output                  PROG_EMPTY,
    output [31:0]           DATA_COUNT,
    input [31:0]            PROG_FULL_THRESHOLD,
    input [31:0]            PROG_EMPTY_THRESHOLD
);

    // Must be at least 8-deep
    localparam ADDR_WIDTH   = (FIFO_DEPTH < 8) ? $clog2(8) : $clog2(FIFO_DEPTH);

    logic [DATA_WIDTH-1:0]  dual_port_ram [2**ADDR_WIDTH];
    logic                   disable_fifo;
    logic                   we_masked;
    logic                   re_masked;
    logic                   write_allow;
    logic [ADDR_WIDTH:0]    write_pointer;
    logic [ADDR_WIDTH:0]    next_write_pointer;
    logic [ADDR_WIDTH:0]    write_pointer_actual;
    logic                   full_comp1;
    logic                   full_comp0;
    logic                   prog_full_comb;
    logic                   going_full;
    logic                   ram_full_comb;
    logic                   full_i;
    logic                   prog_full_i;
    logic                   read_allow;
    logic [ADDR_WIDTH:0]    read_pointer;
    logic [ADDR_WIDTH:0]    next_read_pointer;
    logic [ADDR_WIDTH:0]    read_pointer_actual;
    logic                   empty_comp1;
    logic                   empty_comp0;
    logic                   prog_empty_comb;
    logic                   going_empty;
    logic                   ram_empty_comb;
    logic                   prog_empty_i;
    logic                   empty_i;
    logic                   valid_i;
    logic [ADDR_WIDTH:0]    diff_pointer;
    logic [ADDR_WIDTH:0]    data_counter;
    logic                   we_porta;
    logic [ADDR_WIDTH-1:0]  addra;
    logic [DATA_WIDTH-1:0]  dina;
    logic                   ce_portb;
    logic [ADDR_WIDTH-1:0]  addrb;
    logic [DATA_WIDTH-1:0]  doutb;
    logic                   empty_int;
    logic [ADDR_WIDTH:0]    user_read_pointer;
    logic [ADDR_WIDTH:0]    user_next_read_pointer;
    logic                   user_read_enable;

    // Reset generation
    assign disable_fifo = SYNC_RST;

    assign we_masked = WE & ~disable_fifo;
    assign re_masked = RE & ~disable_fifo;

    // Write pointer update
    always_ff @(posedge CLK) begin
    	if(SYNC_RST) begin
           write_pointer <= {ADDR_WIDTH+1{1'b0}};
           full_i <= 1'b0;
           prog_full_i <= 1'b0;
        end
        else begin
            if(write_allow) begin
                write_pointer <= next_write_pointer;
            end
            full_i <= ram_full_comb | disable_fifo;
            prog_full_i <= prog_full_comb | disable_fifo;
        end
    end
    
    assign write_allow = we_masked & ~full_i;
    assign next_write_pointer = write_pointer + 1;
    assign we_porta = write_allow;
    
    assign dina = DIN;
    assign addra = write_pointer[ADDR_WIDTH-1:0];

    // Read pointer update
    always_ff @(posedge CLK) begin
        if(SYNC_RST) begin
            read_pointer <= {ADDR_WIDTH+1{1'b0}};
            empty_i <= 1'b1;
            prog_empty_i <= 1'b1;
        end
        else begin
            if(read_allow) begin
                read_pointer <= next_read_pointer;
            end
            empty_i <= ram_empty_comb | disable_fifo;
            prog_empty_i <= prog_empty_comb | disable_fifo;
        end
    end

    assign next_read_pointer = read_pointer + 1;
    assign addrb = read_pointer[ADDR_WIDTH-1:0];
    
    // Data count generation
    always_ff @(posedge CLK) begin
        if(SYNC_RST) begin
            data_counter <= 32'd0;
        end
        else begin
            data_counter <= diff_pointer;
        end
    end
    
    // Full generator
    assign full_comp0 = (write_pointer[ADDR_WIDTH-1:0] == read_pointer[ADDR_WIDTH-1:0]) && (write_pointer[ADDR_WIDTH] != read_pointer[ADDR_WIDTH]);
    assign full_comp1 = (next_write_pointer[ADDR_WIDTH-1:0] == read_pointer[ADDR_WIDTH-1:0]) && (next_write_pointer[ADDR_WIDTH] != read_pointer[ADDR_WIDTH]);
    
    assign going_full = full_comp1 & write_allow;
    assign ram_full_comb = (going_full | full_comp0) & ~read_allow;
    assign prog_full_comb = (diff_pointer >= PROG_FULL_THRESHOLD[ADDR_WIDTH:0]);
    
    // Empty generator
    assign empty_comp0 = (read_pointer[ADDR_WIDTH:0] == write_pointer[ADDR_WIDTH:0]);
    assign empty_comp1 = (next_read_pointer[ADDR_WIDTH:0] == write_pointer[ADDR_WIDTH:0]);
    
    assign going_empty = empty_comp1 & read_allow;
    assign ram_empty_comb = (going_empty | empty_comp0) & ~write_allow;
    assign prog_empty_comb = (diff_pointer <= PROG_EMPTY_THRESHOLD[ADDR_WIDTH:0]);
    
    // Difference between write and read pointer
    assign diff_pointer = write_pointer_actual - read_pointer_actual;
    
    // Optionally insert FWFT_SHOWAHEAD Logic
    generate
        if(FWFT_SHOWAHEAD == 0) begin
            assign write_pointer_actual = write_allow ? next_write_pointer : write_pointer;
            assign read_pointer_actual = read_allow ? next_read_pointer : read_pointer;
            
            always_ff @(posedge CLK) begin
                if(SYNC_RST) begin
                    valid_i <= 1'b0;
                end
                else begin 
                    valid_i <= read_allow;
                end
            end
            
            assign read_allow = re_masked & ~empty_i;
            assign ce_portb = read_allow; 
            assign EMPTY = empty_i;
            assign DOUT = doutb;
        end
        else begin
            assign read_allow = ce_portb & ~empty_i;

            always_ff @(posedge CLK) begin
                if(SYNC_RST) begin
                    user_read_pointer <= {ADDR_WIDTH+1{1'b0}};
                end
                else begin
                    if(user_read_enable) begin
                        user_read_pointer <= user_next_read_pointer;
                    end
                end
            end
            
            assign user_next_read_pointer = user_read_pointer + 1;
            assign user_read_enable = re_masked & ~empty_int;

            assign write_pointer_actual = write_allow ? next_write_pointer : write_pointer;
            assign read_pointer_actual = user_read_enable ? user_next_read_pointer : user_read_pointer;
            
            FWFT_SHOWAHEAD_LOGIC #(
                .DATA_WIDTH (DATA_WIDTH)
            )
            SHOWAHEAD_LOGIC (
                 .RD_CLK        (CLK),
                 .SYNC_RST      (SYNC_RST),
                 .RD_EN         (re_masked),
                 .FIFO_EMPTY    (empty_i),
                 .RAM_DOUT      (doutb),
                 .FIFO_DOUT     (DOUT),
                 .USER_EMPTY    (EMPTY),
                 .EMPTY_INT     (empty_int),
                 .USER_VALID    (valid_i),
                 .RAM_RE        (ce_portb)
            );
        end
    endgenerate
    
    // Single clock dual-port RAM
    always_ff @(posedge CLK) begin
        if(we_porta) begin
            dual_port_ram[addra] <= dina;
        end
    end

    always_ff @(posedge CLK) begin
        if(ce_portb) begin
            doutb <= dual_port_ram[addrb];
        end
    end

    // Pinout
    assign FULL         = full_i;
    assign PROG_FULL    = prog_full_i;
    assign PROG_EMPTY   = prog_empty_i;
    assign VALID        = valid_i;
    assign DATA_COUNT   = 32'd0 | data_counter[ADDR_WIDTH:0];
endmodule
