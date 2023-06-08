class ddr_ring_buffer_scoreboard #(int DATA_WIDTH = 32, int RAM_DEPTH = 128) extends uvm_scoreboard;
    // Receives transactions from the driver
    uvm_tlm_analysis_fifo#(axi4s_seq_item#(DATA_WIDTH)) driver_ap_fifo;
    uvm_analysis_export#(axi4s_seq_item#(DATA_WIDTH)) driver_ap;
    // In-fight transaction
    axi4s_seq_item#(DATA_WIDTH) txn;

    `uvm_component_utils(ddr_ring_buffer_scoreboard#(DATA_WIDTH,RAM_DEPTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);

        // Get access to the internal signals of the DUT
        uvm_config_db#(virtual ddr_ring_buffer_whitebox_if#(DATA_WIDTH,RAM_DEPTH))::get(null, "*", "dut_ver_if", ver_if);

        num_errors = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver_ap_fifo = new("driver_ap_fifo", this);
        driver_ap = new("driver_ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver_ap.connect(driver_ap_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            // Get transaction from driver
            driver_ap_fifo.get(txn);
        end
    endtask
endclass
