class axi4s_master_seq_item_cfg extends uvm_object;
    // Minimum stream length
    int stream_len_min;
    // Maximum stream length
    int stream_len_max;

    `uvm_object_utils(axi4s_master_seq_item_cfg)

    function new(string name = "axi4s_master_seq_item_cfg");
        super.new(name);
        stream_len_min = 0;
        stream_len_max = 512;
    endfunction
endclass
