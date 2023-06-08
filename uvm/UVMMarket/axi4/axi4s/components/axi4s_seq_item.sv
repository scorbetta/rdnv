// The base sequence item of an AXI4 Stream transaction
class axi4s_seq_item#(int DATA_WIDTH = 64) extends uvm_sequence_item;
    `uvm_object_utils(axi4s_seq_item#(DATA_WIDTH))

    function new(string name = "axi4s_seq_item");
        super.new(name);
    endfunction
endclass
