class ddr_ring_buffer_random_test extends uvm_test;
    ddr_ring_buffer_env#(64,2<<16) env;
    axi4s_seq#(64) seq;

    `uvm_component_utils(ddr_ring_buffer_random_test)

    function new(string name = "ddr_ring_buffer_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ddr_ring_buffer_env#(64,2<<16)::type_id::create("env", this);
        seq = axi4s_seq#(64)::type_id::create("seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
