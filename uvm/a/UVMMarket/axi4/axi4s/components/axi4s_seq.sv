class axi4s_seq#(int DATA_WIDTH = 32) extends uvm_sequence#(axi4s_seq_item#(DATA_WIDTH));
    `uvm_object_utils(axi4s_seq#(DATA_WIDTH));

    function new(string name = "axi4s_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Create request object
        req = axi4s_seq_item#(DATA_WIDTH)::type_id::create("req");
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
