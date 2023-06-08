class ddr_ring_buffer_random_test extends uvm_test;
    ddr_ring_buffer_env env;
    axi4s_master_seq#(64) ififo_seq;
    axi4s_slave_seq#(64) ofifo_seq;
    axi4s_master_seq_item_cfg ififo_cfg;

    `uvm_component_utils(ddr_ring_buffer_random_test)

    function new(string name = "ddr_ring_buffer_random_test", uvm_component parent = null);
        super.new(name, parent);

        // Master interface draining the OFIFO does not use TLAST
        uvm_resource_db#(bit)::set("uvm_test_top.env.ofifo_agent.driver", "DISABLE_TLAST", 1'b1);

        // Create configuration for IFIFO transactions
        ififo_cfg = new();
        ififo_cfg.stream_len_min = 256;
        ififo_cfg.stream_len_max = 256;
        uvm_config_db#(axi4s_master_seq_item_cfg)::set(null, "uvm_test_top.env.ififo_agent.seqr.ififo_seq", "cfg", ififo_cfg);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ddr_ring_buffer_env::type_id::create("env", this);
        ififo_seq = axi4s_master_seq#(64)::type_id::create("ififo_seq");
        ofifo_seq = axi4s_slave_seq#(64)::type_id::create("ofifo_seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        fork
            ififo_seq.start(env.ififo_agent.seqr);
            ofifo_seq.start(env.ofifo_agent.seqr);
        join

        phase.drop_objection(this);
    endtask
endclass
