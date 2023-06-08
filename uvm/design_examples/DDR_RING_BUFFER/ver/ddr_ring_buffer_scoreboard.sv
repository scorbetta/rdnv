class ddr_ring_buffer_scoreboard extends uvm_scoreboard;
    // Receives transactions from the drivers
    uvm_tlm_analysis_fifo#(axi4s_master_seq_item#(64)) ap_fifo;
    uvm_analysis_export#(axi4s_master_seq_item#(64)) ap;
    // In-fight transactions
    axi4s_master_seq_item#(64) ififo_txn;
    // Get access to the DUT output pins
    virtual ddr_ring_buffer_out_if#(16,64,512) dut_out_if;

    `uvm_component_utils(ddr_ring_buffer_scoreboard)

    function new (string name, uvm_component parent);
        super.new(name, parent);
        if(!uvm_config_db#(virtual ddr_ring_buffer_out_if#(16,64,512))::get(this, "", "dut_vif", dut_out_if)) begin
            `uvm_fatal("NO_DUT_VIF", { "DUT virtual interface must be set for: ", get_full_name(), ".dut_vif" });
        end
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_fifo = new("ap_fifo", this);
        ap = new("ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap.connect(ap_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        forever begin
            // Get transaction from Master and Slave drivers
            ap_fifo.get(ififo_txn);
        end
        phase.drop_objection(this);
    endtask
endclass
