class ddr_ring_buffer_env extends uvm_env;
    // IFIFO is Slave, this will send AXI4 Stream transactions
    axi4s_master_agent#(64) ififo_agent;
    // OFIFO is Master, this will respond to AXI4 Stream transactions
    axi4s_slave_agent#(64) ofifo_agent;
    // Scoreboard
    ddr_ring_buffer_scoreboard sb;
       
    `uvm_component_utils(ddr_ring_buffer_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ififo_agent = axi4s_master_agent#(64)::type_id::create("ififo_agent", this);
        ofifo_agent = axi4s_slave_agent#(64)::type_id::create("ofifo_agent", this);
        sb = ddr_ring_buffer_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ififo_agent.driver.ap.connect(sb.ap);
    endfunction
endclass
