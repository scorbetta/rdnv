class axi4s_slave_agent #(int DATA_WIDTH = 32) extends uvm_agent;
    axi4s_slave_driver#(DATA_WIDTH) driver;
    generic_seqr#(axi4s_slave_seq_item#(DATA_WIDTH)) seqr;

    `uvm_component_utils(axi4s_slave_agent#(DATA_WIDTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = axi4s_slave_driver#(DATA_WIDTH)::type_id::create("driver", this);
        seqr = generic_seqr#(axi4s_slave_seq_item#(DATA_WIDTH))::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass
