class axi4s_seq_item #(int DATA_WIDTH = 64) extends uvm_sequence_item;
    // Length of the stream
    rand int stream_len;
    // Data queue
    rand bit [DATA_WIDTH-1:0] stream_data [];
    // Leading and trail space, in cycles
    rand int pre_wait;
    rand int post_wait;

    `uvm_object_utils_begin(axi4s_seq_item#(DATA_WIDTH))
        `uvm_field_array_int(stream_data, UVM_ALL_ON)
        `uvm_field_int(stream_len, UVM_ALL_ON)
        `uvm_field_int(pre_wait, UVM_ALL_ON)
        `uvm_field_int(post_wait, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4s_seq_item");
        super.new(name);
    endfunction

    // Length constraints
    constraint size_c {
        stream_data.size() == stream_len;
        solve stream_len before stream_data;
    };

    // Maximum stream constraint
    constraint max_len_c {
        stream_len inside {[1:128]};
    };

    // Bounded waits
    constraint pre_wait_c {
        pre_wait inside {[1:10]};
    };

    constraint post_wait_c {
        post_wait inside {[1:10]};
    };
endclass
