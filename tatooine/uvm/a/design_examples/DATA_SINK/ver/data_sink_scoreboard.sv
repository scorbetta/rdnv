class data_sink_scoreboard #(int DATA_WIDTH = 32, int RAM_DEPTH = 128) extends uvm_scoreboard;
    // Receives transactions from the driver
    uvm_tlm_analysis_fifo#(axi4s_seq_item#(DATA_WIDTH)) driver_ap_fifo;
    uvm_analysis_export#(axi4s_seq_item#(DATA_WIDTH)) driver_ap;
    // In-fight transaction
    axi4s_seq_item#(DATA_WIDTH) txn;
    // Reference model
    data_sink_ref_model#(DATA_WIDTH,RAM_DEPTH) ref_model;
    // Gain access to the internal signals of the DUT
    virtual data_sink_whitebox_if#(DATA_WIDTH,RAM_DEPTH) ver_if;
    int num_errors;

    `uvm_component_utils(data_sink_scoreboard#(DATA_WIDTH,RAM_DEPTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);

        // Get access to the internal signals of the DUT
        uvm_config_db#(virtual data_sink_whitebox_if#(DATA_WIDTH,RAM_DEPTH))::get(null, "*", "dut_ver_if", ver_if);

        num_errors = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver_ap_fifo = new("driver_ap_fifo", this);
        driver_ap = new("driver_ap", this);
        ref_model = new();
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

            // Update reference model
            ref_model.update(txn);

            // Compare DUT to reference model and count errors
            verify(txn);
        end
    endtask

    function void verify(axi4s_seq_item#(DATA_WIDTH) txn);
        // ABV: Check Write pointer
        assert(ref_model.row == ver_if.row)
        else begin
            num_errors++;
            `uvm_error("VERIFY", $sformatf("Unexpected row: %0d (expected: %0d)", ver_if.row, ref_model.row));
        end

        // ABV: Check new RAM contents
        for(int row = 0; row < RAM_DEPTH; row++) begin
            assert(ref_model.ram[row] === ver_if.ram[row])
            else begin
                num_errors++;
                `uvm_error("VERIFY", $sformatf("Unexpected data @%0d: 0x%08h (expected: 0x%08h)", row, ver_if.ram[row], ref_model.ram[row]));
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        if(num_errors == 0) begin
            `uvm_info(get_full_name(), "test: PASS", UVM_LOW);
        end
        else begin
            `uvm_fatal(get_full_name(), "test: FAIL");
        end
    endfunction
endclass
