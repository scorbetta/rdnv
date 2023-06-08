class ddr_ring_buffer_env #(int DATA_WIDTH = 64, int RAM_DEPTH = 128) extends uvm_env;
    axi4s_master_agent#(DATA_WIDTH) ififo_agent;
    ddr_ring_buffer_scoreboard#(DATA_WIDTH,RAM_DEPTH) sb;
       
    `uvm_component_utils(ddr_ring_buffer_env#(DATA_WIDTH,RAM_DEPTH))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi4s_master_agent#(DATA_WIDTH)::type_id::create("agent", this);
        sb = ddr_ring_buffer_scoreboard#(DATA_WIDTH,RAM_DEPTH)::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.driver.ap.connect(sb.driver_ap);
    endfunction
endclass
