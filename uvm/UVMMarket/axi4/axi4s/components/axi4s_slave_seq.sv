// The default sequence for the AXI4 Stream components. By inheriting from this class the user can
// specify sequences with non-default constraints. In this way, the AXI4S* components can be reused
// and yet the user project environment can have its own peculiarities
class axi4s_slave_seq#(int DATA_WIDTH = 32) extends uvm_sequence#(axi4s_slave_seq_item#(DATA_WIDTH));
    `uvm_object_utils(axi4s_slave_seq#(DATA_WIDTH));

    function new(string name = "axi4s_slave_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Create request object
        req = axi4s_slave_seq_item#(DATA_WIDTH)::type_id::create("req");
        assert(req.randomize());  
        req.print();

        // Wait for grant from the sequencer
        start_item(req);
        finish_item(req);

        // Wait for item to be done
        get_response(rsp);
        rsp.print();
    endtask
endclass
