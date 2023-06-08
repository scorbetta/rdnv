// The AXI4 Stream Master pin whiggling driver
class axi4s_master_driver #(int DATA_WIDTH = 32) extends uvm_driver #(axi4s_seq_item#(DATA_WIDTH));
    // The virtual interface
    virtual axi4s_if#(DATA_WIDTH) vif;
    // The analysis port is fed with generated transactions
    uvm_analysis_port#(axi4s_seq_item#(DATA_WIDTH)) ap;

    `uvm_component_utils(axi4s_master_driver#(DATA_WIDTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4s_if#(DATA_WIDTH))::get(this, "", "dut_vif_in", vif)) begin
            `uvm_fatal("NO_VIF", { "virtual interface must be set for: ", get_full_name(), ".vif" });
        end
        ap = new("axi4s_master_driver_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            // Get new transaction from sequencer
            seq_item_port.get_next_item(req);
            `uvm_info(get_full_name(), $sformatf("Transaction received"), UVM_LOW);
            req.print();

            // Drive pins
            drive(req);
            ap.write(req);

            // Mark the item as done
            seq_item_port.item_done();
            seq_item_port.put(req);
        end
    endtask

    virtual task drive(axi4s_seq_item#(DATA_WIDTH) txn);
        // Wait out of reset
        vif.tvalid <= 1'b0;
        vif.tlast <= 1'b0;
        vif.tdata <= {DATA_WIDTH{1'b0}};

        while(vif.aresetn == 1'b0) begin
            @(posedge vif.aclk);
        end

        // Leading wait
        repeat(txn.pre_wait) @(posedge vif.aclk);

        for(int beat = 0; beat < txn.stream_len; beat++) begin
            // Send data item
            vif.tvalid <= 1'b1;
            vif.tlast <= (beat == (txn.stream_len - 1));
            vif.tdata <= txn.stream_data[beat];

            // Wait for ack from Slave
            do begin
                @(posedge vif.aclk);
            end while(!vif.tready);
        end

        vif.tvalid <= 1'b0;
        vif.tlast <= 1'b0;
        vif.tdata <= {DATA_WIDTH{1'b0}};

        // Trail wait
        repeat(txn.post_wait) @(posedge vif.aclk);
    endtask
endclass
