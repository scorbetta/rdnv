// A generic AXI4 Stream monitor object
class axi4s_monitor extends uvm_monitor;
    // Interface reference
    virtual axi4s_if vif;
    // Side-channel
    uvm_analysis_port #(axi4s_seq_item) side_channel;
    // In-flight transaction
    axi4s_seq_item in_flight_txn;

    `uvm_component_utils(axi4s_monitor)

    function new (string name, uvm_component parent);
        super.new(name, parent);
        in_flight_txn = new();
        side_channel = new("side_channel", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4s_if)::get(this, "", "dut_vif_in", vif)) begin
            `uvm_fatal("NOVIF", { "virtual interface must be set for: ", get_full_name(), ".vif" });
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        //forever begin
        //    // Get in-flight transaction
        //    //@(posedge vif.aclk);
        //    //in_flight_txn.tvalid = vif.tvalid;
        //    //in_flight_txn.tdata = vif.tdata;
        //    //in_flight_txn.tlast = vif.tlast;
        //    `uvm_info(get_full_name(), $sformatf("Transaction from monitor"), UVM_LOW);
        //    in_flight_txn.print();
        //    // Send in-flight transaction out
        //    side_channel.write(in_flight_txn);
        //end
    endtask
endclass
