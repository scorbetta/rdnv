class axi4s_slave_seq_item #(int DATA_WIDTH = 64) extends axi4s_seq_item#(DATA_WIDTH);
    // When 1'b1 TREADY is asserted before TVALID, otherwise TREADY waits for the rising-edge on
    // TVALID  
    rand bit tready_before_tvalid;
    // TREADY deassert period, in number of cycles
    rand int tready_clear_period;
    // TREADY deassert length, in number of cycles
    rand int tready_clear_length;

    `uvm_object_utils_begin(axi4s_slave_seq_item#(DATA_WIDTH))
        `uvm_field_int(tready_before_tvalid, UVM_ALL_ON)
        `uvm_field_int(tready_clear_period, UVM_ALL_ON)
        `uvm_field_int(tready_clear_length, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4s_slave_seq_item");
        super.new(name);
    endfunction

    // Bounded periond and clearance length
    constraint tready_low_c {
        tready_clear_period inside { [0:20] };
        tready_clear_length inside { [1:10] };
    };
endclass
