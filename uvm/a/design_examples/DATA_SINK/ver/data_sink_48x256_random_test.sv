class data_sink_48x256_random_test extends uvm_test;
    data_sink_env#(48,256) env;
    axi4s_seq#(48) seq;

    `uvm_component_utils(data_sink_48x256_random_test)

    function new(string name = "data_sink_48x256_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = data_sink_env#(48,256)::type_id::create("env", this);
        seq = axi4s_seq#(48)::type_id::create("seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
