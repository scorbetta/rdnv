// The default sequencer is templated with the target transaction type
class generic_seqr#(type item = uvm_sequence_item) extends uvm_sequencer#(item);
    `uvm_component_utils(generic_seqr#(item));

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
