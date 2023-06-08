// An AXI4 Stream Master transasction is determined by the number of beats
class axi4s_master_seq_item#(int DATA_WIDTH = 64) extends axi4s_seq_item#(DATA_WIDTH);
    // Stream length, in number of beats
    rand int stream_len;
    // Stram data
    rand bit [DATA_WIDTH-1:0] stream_data [];

    `uvm_object_utils_begin(axi4s_master_seq_item#(DATA_WIDTH))
        `uvm_field_int(stream_len, UVM_ALL_ON)
        `uvm_field_array_int(stream_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4s_master_seq_item");
        super.new(name);
    endfunction

    // Length constraints
    constraint size_c {
        stream_data.size() == stream_len;
        solve stream_len before stream_data;
    };

    // Maximum stream constraint for bounded simulation
    constraint max_len_c {
        stream_len inside {[1:512]};
    };
endclass
