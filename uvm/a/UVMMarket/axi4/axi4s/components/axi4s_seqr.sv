class axi4s_seqr#(int DATA_WIDTH = 32) extends uvm_sequencer#(axi4s_seq_item#(DATA_WIDTH));
    `uvm_component_utils(axi4s_seqr#(DATA_WIDTH))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
