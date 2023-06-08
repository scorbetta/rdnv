class data_gen_random_test extends uvm_test;
    `uvm_component_utils(data_gen_random_test)
    data_gen_environment env;
    axi4s_master_seq master_seq;

    function new(string name = "data_gen_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = data_gen_environment::type_id::create("env", this);
        master_seq = axi4s_master_seq::type_id::create("master_seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        master_seq.start(env.master_agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
