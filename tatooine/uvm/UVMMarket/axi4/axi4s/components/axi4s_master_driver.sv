// The AXI4 Stream Master pin whiggling driver
class axi4s_master_driver#(int DATA_WIDTH = 32) extends uvm_driver#(axi4s_master_seq_item#(DATA_WIDTH));
    // The virtual interface
    virtual axi4s_if#(DATA_WIDTH) vif;
    // The analysis port is fed with generated transactions
    uvm_analysis_port#(axi4s_master_seq_item#(DATA_WIDTH)) ap;
    // TLAST is optional
    bit disable_tlast;

    `uvm_component_utils(axi4s_master_driver#(DATA_WIDTH))

    function new (string name, uvm_component parent);
        super.new(name, parent);

        // By default, TLAST is enabled, unless otherwise specified via configuration
        disable_tlast = 1'b0;
        if(uvm_resource_db#(bit)::read_by_name(get_full_name(), "DISABLE_TLAST", disable_tlast)) begin
            `uvm_warning("CONFIG", { "TLAST is being disabled for ", get_full_name() });
        end
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4s_if#(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", { "Unable to find virtual interface \"vif\" from: ", get_full_name() });
        end
        ap = new("axi4s_master_driver_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            // Get new transaction from sequencer and drive pins
            seq_item_port.get_next_item(req);
            `uvm_info(get_full_name(), $sformatf("Transaction received"), UVM_LOW);
            req.print();
            drive(req);
            seq_item_port.item_done();

            // Once finished, send the transaction to the subscribers
            ap.write(req);
            seq_item_port.put(req);
        end
    endtask

    virtual task drive(axi4s_master_seq_item#(DATA_WIDTH) txn);
        // Wait out of reset
        vif.tvalid <= 1'b0;
        vif.tlast <= 1'b0;
        vif.tdata <= {DATA_WIDTH{1'b0}};

        while(vif.aresetn == 1'b0) begin
            @(posedge vif.aclk);
        end

        for(int beat = 0; beat < txn.stream_len; beat++) begin
            // Send data item
            vif.tvalid <= 1'b1;
            vif.tlast <= ~disable_tlast & (beat == (txn.stream_len - 1));
            vif.tdata <= txn.stream_data[beat];

            // Wait for ack from Slave
            do begin
                @(posedge vif.aclk);
            end while(!vif.tready);
        end

        vif.tvalid <= 1'b0;
        vif.tlast <= 1'b0;
        vif.tdata <= {DATA_WIDTH{1'b0}};
    endtask
endclass
