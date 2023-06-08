// The default sequencer for the AXI4 Stream components
class axi4s_slave_seqr#(int DATA_WIDTH = 32) extends uvm_sequencer#(axi4s_slave_seq_item#(DATA_WIDTH));
    `uvm_component_utils(axi4s_slave_seqr#(DATA_WIDTH))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
