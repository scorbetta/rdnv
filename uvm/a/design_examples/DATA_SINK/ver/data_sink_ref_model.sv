class data_sink_ref_model #(int DATA_WIDTH = 32, int RAM_DEPTH = 128);
    // The RAM
    bit [DATA_WIDTH-1:0] ram [RAM_DEPTH];
    // Write pointer
    int row;

    function new();
        ram = '{default: {DATA_WIDTH{1'b0}}};
        row = 0;
    endfunction

    // Update the reference model status every new transaction
    function void update(axi4s_seq_item#(DATA_WIDTH) new_txn);
        for(int idx = 0; idx < new_txn.stream_len; idx++) begin
            ram[row] = new_txn.stream_data[idx];
            row = (row + 1) % RAM_DEPTH;
        end
    endfunction

    // Reset internals
    function void reset();
        ram = '{default: {DATA_WIDTH{1'b0}}};
        row = 0;
    endfunction
endclass
