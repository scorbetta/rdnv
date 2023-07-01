// SystemVerilog porting of the original VHDL design
module FWFT_SHOWAHEAD_LOGIC #(
    parameter DATA_WIDTH = 8
)
(
    input                   RD_CLK,
    input                   SYNC_RST,
    input                   RD_EN,
    input                   FIFO_EMPTY,
    input [DATA_WIDTH-1:0]  RAM_DOUT,
    output [DATA_WIDTH-1:0] FIFO_DOUT,
    output                  USER_EMPTY,
    output                  EMPTY_INT,
    output                  USER_VALID,
    output                  RAM_RE,
    output                  STAGE1_VALID,
    output                  STAGE2_VALID
);  

    logic [DATA_WIDTH-1:0]  data_reg;
    logic                   preloadstage1;
    logic                   preloadstage2;
    logic                   ram_valid_i;
    logic                   read_data_valid_i;
    logic                   ram_regout_en;
    logic                   ram_rd_en;
    logic                   empty_s;
    logic                   empty_i;
    logic                   empty_i_duplicate;
    //@@attribute syn_preserve  : string;
    //@@attribute syn_preserve of empty_i                       : signal is "true";
    //@@attribute syn_preserve of read_data_valid_i     : signal is "true";
    //@@attribute syn_preserve of empty_i_duplicate     : signal is "true";
        
    assign preloadstage1 = (~ram_valid_i | preloadstage2) & ~FIFO_EMPTY;
    assign preloadstage2 = ram_valid_i & (~read_data_valid_i | RD_EN);
    assign ram_regout_en = preloadstage2;
    assign ram_rd_en = (RD_EN & ~FIFO_EMPTY) | preloadstage1;
    assign empty_s = (~ram_valid_i & ~read_data_valid_i) | (~ram_valid_i & RD_EN);
    
    always_ff @(posedge RD_CLK) begin
        if(SYNC_RST) begin
            ram_valid_i <= 1'b0;
            read_data_valid_i <= 1'b0;
            empty_i <= 1'b1;
            data_reg <= {DATA_WIDTH{1'b0}};
            empty_i_duplicate <= 1'b1;
        end
        else begin
            if(ram_regout_en) begin
                data_reg <= RAM_DOUT;
            end
                
            if(ram_rd_en) begin
                ram_valid_i <= 1'b1;
            end
            else begin
                if(ram_regout_en) begin
                    ram_valid_i <= 1'b0;
                end
                else begin
                    ram_valid_i <= ram_valid_i;
                end
            end
            
            read_data_valid_i <= ram_valid_i | (read_data_valid_i & ~RD_EN);
            empty_i <= empty_s;
            empty_i_duplicate <= empty_s;
        end
    end

    // Pinout
    assign USER_VALID   = read_data_valid_i;
    assign USER_EMPTY   = empty_i;
    assign EMPTY_INT    = empty_i_duplicate;
    assign RAM_RE       = ram_rd_en;
    assign FIFO_DOUT    = data_reg; 
    assign STAGE1_VALID = ram_valid_i; 
    assign STAGE2_VALID = read_data_valid_i;
endmodule
