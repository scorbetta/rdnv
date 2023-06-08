class axi4s_slave_seq_item_cfg extends uvm_object;
    bit tready_before_tvalid;
    int tready_clear_period;
    int tready_clear_length;

    `uvm_object_utils(axi4s_slave_seq_item_cfg)

    function new(string name = "axi4s_slaver_seq_item_cfg");
        super.new(name);
        stream_len_min = 0;
        stream_len_max = 512;
    endfunction
endclass
