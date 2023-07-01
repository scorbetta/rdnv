// The default sequence for the AXI4 Stream components. By inheriting from this class the user can
// specify sequences with non-default constraints. In this way, the AXI4S* components can be reused
// and yet the user project environment can have its own peculiarities
class axi4s_master_seq#(int DATA_WIDTH = 32) extends uvm_sequence#(axi4s_master_seq_item#(DATA_WIDTH));
    // The local transaction configurator
    axi4s_master_seq_item_cfg seq_item_cfg;

    `uvm_object_utils(axi4s_master_seq#(DATA_WIDTH));

    function new(string name = "axi4s_master_seq");
        super.new(name);
    endfunction

    virtual task body();
        // Create request object
        req = axi4s_master_seq_item#(DATA_WIDTH)::type_id::create("req");

        // Apply constraints from config, if any
        if(uvm_config_db#(axi4s_master_seq_item_cfg)::get(get_sequencer(), get_name(), "cfg", seq_item_cfg)) begin
            `uvm_warning("CONFIG", { "Configuration object found for ", get_full_name() });
            assert(req.randomize() with {
                stream_len inside { [seq_item_cfg.stream_len_min:seq_item_cfg.stream_len_max] };
            });
        end
        else begin
            assert(req.randomize());
        end

        // Print transaction
        req.print();

        // Wait for grant from the sequencer
        start_item(req);
        finish_item(req);

        // Wait for item to be done
        get_response(rsp);
        rsp.print();
    endtask
endclass
