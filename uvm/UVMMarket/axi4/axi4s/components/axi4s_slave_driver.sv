// The AXI4 Stream Slave pin whiggling driver
class axi4s_slave_driver#(int DATA_WIDTH = 32) extends uvm_driver#(axi4s_slave_seq_item#(DATA_WIDTH));
    // The virtual interface
    virtual axi4s_if#(DATA_WIDTH) vif;
    // TLAST is optional
    bit disable_tlast;

    `uvm_component_utils(axi4s_slave_driver#(DATA_WIDTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4s_if#(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", { "virtual interface must be set for: ", get_full_name(), ".vif" });
        end

        // By default, TLAST is enabled, unless otherwise specified via configuration
        disable_tlast = 1'b0;
        if(uvm_resource_db#(bit)::read_by_name(get_full_name(), "DISABLE_TLAST", disable_tlast)) begin
            `uvm_warning("CONFIG", { "TLAST is being disabled for ", get_full_name() });
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            // Get new transaction from sequencer
            seq_item_port.get_next_item(req);
            `uvm_info(get_full_name(), $sformatf("Transaction received"), UVM_LOW);
            req.print();

            // Drive pins
            drive(req);

            // Mark the item as done
            seq_item_port.item_done();
            seq_item_port.put(req);
        end
    endtask

    virtual task drive(axi4s_slave_seq_item#(DATA_WIDTH) txn);
        // Wait out of reset
        vif.tready <= 1'b0;

        while(vif.aresetn == 1'b0) begin
            @(posedge vif.aclk);
        end

        // Ready/Valid relationship
        if(txn.tready_before_tvalid) begin
            vif.tready <= 1'b1;
        end
        else begin
            vif.tready <= 1'b0;
            @(posedge vif.tvalid);
            @(posedge vif.aclk);
            vif.tready <= 1'b1;
        end

        // When TLAST is disable, the agent runs over an endless cycle of clearance/assertion
        if(disable_tlast) begin
            forever begin
                repeat(txn.tready_clear_period) @(posedge vif.aclk);
                vif.tready <= 1'b0;
                repeat(txn.tready_clear_length) @(posedge vif.aclk);
                vif.tready <= 1'b1;
            end
        end
        else begin
            do begin
                repeat(txn.tready_clear_period) @(posedge vif.aclk);
                vif.tready <= 1'b0;
                repeat(txn.tready_clear_length) @(posedge vif.aclk);
                vif.tready <= 1'b1;
            end while(!(vif.tvalid & vif.tready & vif.tlast));
        end

        // Shall never past this point when TLAST is disabled
        vif.tready <= 1'b0;
    endtask
endclass
