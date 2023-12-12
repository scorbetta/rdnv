// For each interface, three modes are included: master, slave and monitor. In Master mode, the
// module initiates a transaction; in Slave mode, it responds to transactions; Monitor mode can be
// used to snoop signals as they go (all signals are trated as inputs).

// AXI4 protocol utility package
package axi4_pkg;
    // Bursts are for Full case only
    localparam BURST_FIXED  = 2'b00;
    localparam BURST_INCR   = 2'b01;
    localparam BURST_WRAP   = 2'b10;

    // Responses apply for both Write and Read transactions, Lite and Full cases
    localparam RESP_OKAY    = 2'b00;
    localparam RESP_EXOKAY  = 2'b01;
    localparam RESP_SLVERR  = 2'b10;
    localparam RESP_DECERR  = 2'b11;

    // Randomize class for AXI4 Full access
    class AXI4F_Packet #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 16);
        rand bit [DATA_WIDTH-1:0]   data [];
        rand bit [ADDR_WIDTH-1:0]   base_addr;
        rand bit [7:0]              length;
        rand bit                    rnw;

        constraint c_data_len {
            data.size() == length;
            solve length before data;
        }

        constraint c_addr_align {
            base_addr % (DATA_WIDTH/8) == 0;
        }
    endclass

    // Randomize class for AXI4 Lite access
    class AXI4L_Packet #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 16) extends AXI4F_Packet(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH));
        rand bit [DATA_WIDTH-1:0]   data [];
        rand bit [ADDR_WIDTH-1:0]   base_addr;
        rand bit [7:0]              length;

        constraint c_len {
            length == 1;
        }
    endclass

    // Randomize class for AXI4 Stream access
    class AXI4S_Packet #(parameter DATA_WIDTH = 32, parameter MAX_LENGTH = 0);
        rand bit [DATA_WIDTH-1:0]   data [];
        rand integer                length;

        constraint c_data_len {
            data.size() == length;
            solve length before data;
        }

        constraint c_len {
            if(MAX_LENGTH > 0) length inside {[1:MAX_LENGTH]};
        }
    endclass

    // A class of utilities. A class allows to use parameters and configure different instances
    // within the same verification environment
    class AXI4F_Utils #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 16);
        // AXI4 Full specification states that bursts cannot wrap around 4KiB boundaries, so bursts
        // might be required to split (depending on start address and length of burst)
        static function void split_axi4f_write(
            input logic [ADDR_WIDTH-1:0]    write_base_addr,
            input logic [DATA_WIDTH-1:0]    write_data_list [],
            output logic [ADDR_WIDTH-1:0]   split_base_list [],
            output integer                  split_lens_list []
        );

            // Internal variables
            automatic logic [ADDR_WIDTH-1:0] curr_start_addr;
            automatic logic [ADDR_WIDTH-1:0] curr_end_addr;
            automatic integer idx;
            automatic integer curr_len;

            // Split incoming Write transaction
            curr_start_addr = write_base_addr;
            curr_end_addr = curr_start_addr;
            idx = 0;
            while(idx < write_data_list.size()) begin
                curr_len = 0;

                while((idx < write_data_list.size()) && (curr_start_addr[ADDR_WIDTH-1:12] == curr_end_addr[ADDR_WIDTH-1:12])) begin
                    curr_end_addr += (DATA_WIDTH/8);
                    curr_len++;
                    idx++;
                end

                // Update list of bursts to produce
                split_base_list = new [split_base_list.size()+1](split_base_list);
                split_base_list[split_base_list.size()-1] = curr_start_addr;

                split_lens_list = new [split_lens_list.size()+1](split_lens_list);
                split_lens_list[split_lens_list.size()-1] = curr_len;

                // Update new start address
                curr_start_addr = curr_end_addr;
                curr_end_addr = curr_start_addr;
            end

            $display("utils: Burst splitting for: 0x%08x /%0d", write_base_addr, write_data_list.size());
            for(int adx = 0; adx < split_base_list.size(); adx++) begin
                $display("utils:    Burst #%0d/%0d: 0x%08x /%0d", (adx+1), split_base_list.size(), split_base_list[adx], split_lens_list[adx]);
            end
        endfunction

        static function void split_axi4f_read(
            input logic [ADDR_WIDTH-1:0]    read_base_addr,
            input logic [7:0]               read_len,
            output logic [ADDR_WIDTH-1:0]   split_base_list [],
            output integer                  split_lens_list []
        );

            // Internal variables
            automatic logic [ADDR_WIDTH-1:0] curr_start_addr;
            automatic logic [ADDR_WIDTH-1:0] curr_end_addr;
            automatic integer idx;
            automatic integer curr_len;

            // Split incoming Read transaction
            curr_start_addr = read_base_addr;
            curr_end_addr = curr_start_addr;
            idx = 0;
            while(idx < read_len) begin
                curr_len = 0;

                while((idx < read_len) && (curr_start_addr[ADDR_WIDTH-1:12] == curr_end_addr[ADDR_WIDTH-1:12])) begin
                    curr_end_addr += (DATA_WIDTH/8);
                    curr_len++;
                    idx++;
                end

                // Update list of bursts to produce
                split_base_list = new [split_base_list.size()+1](split_base_list);
                split_base_list[split_base_list.size()-1] = curr_start_addr;

                split_lens_list = new [split_lens_list.size()+1](split_lens_list);
                split_lens_list[split_lens_list.size()-1] = curr_len;

                // Update new start address
                curr_start_addr = curr_end_addr;
                curr_end_addr = curr_start_addr;
            end

            $display("utils: Burst splitting for: 0x%08x /%0d", read_base_addr, read_len);
            for(int adx = 0; adx < split_base_list.size(); adx++) begin
                $display("utils:    Burst #%0d/%0d: 0x%08x /%0d", (adx+1), split_base_list.size(), split_base_list[adx], split_lens_list[adx]);
            end
        endfunction
    endclass
endpackage

// AXI4-Stream interface
interface axi4s_if
#(
    parameter DATA_WIDTH = 64
)
(
    input   aclk,
    input   aresetn
);

    logic                       tvalid;
    logic                       tready;
    logic [DATA_WIDTH-1:0]      tdata;
    logic [(DATA_WIDTH/8)-1:0]  tstrb;
    logic [(DATA_WIDTH/8)-1:0]  tkeep;
    logic                       tlast;

    modport master (
        input   aclk,
        input   aresetn,
        output  tvalid,
        input   tready,
        output  tdata,
        output  tstrb,
        output  tkeep,
        output  tlast
    );

    modport slave (
        input   aclk,
        input   aresetn,
        input   tvalid,
        output  tready,
        input   tdata,
        input   tstrb,
        input   tkeep,
        input   tlast
    );

    modport monitor (
        input   aclk,
        input   aresetn,
        input   tvalid,
        input   tready,
        input   tdata,
        input   tstrb,
        input   tkeep,
        input   tlast
    );
endinterface

// AXI4 Lite interface
interface axi4l_if
#(
    parameter DATA_WIDTH    = 64,
    parameter ADDR_WIDTH    = 16
)
(
    input   aclk,
    input   aresetn
);

    logic [ADDR_WIDTH-1:0]      awaddr;
    logic [2:0]                 awprot;
    logic                       awvalid;
    logic                       awready;
    logic [DATA_WIDTH-1:0]      wdata;
    logic [(DATA_WIDTH/8)-1:0]  wstrb;
    logic                       wvalid;
    logic                       wready;
    logic [1:0]                 bresp;
    logic                       bvalid;
    logic                       bready;
    logic [ADDR_WIDTH-1:0]      araddr;
    logic [2:0]                 arprot;
    logic                       arvalid;
    logic                       arready;
    logic [DATA_WIDTH-1:0]      rdata;
    logic [1:0]                 rresp;
    logic                       rvalid;
    logic                       rready;

    modport master (
        input   aclk,
        input   aresetn,
        output  awaddr,
        output  awprot,
        output  awvalid,
        input   awready,
        output  wdata,
        output  wstrb,
        output  wvalid,
        input   wready,
        input   bresp,
        input   bvalid,
        output  bready,
        output  araddr,
        output  arprot,
        output  arvalid,
        input   arready,
        input   rdata,
        input   rresp,
        input   rvalid,
        output  rready
    );

    modport slave (
        input   aclk,
        input   aresetn,
        input   awaddr,
        input   awprot,
        input   awvalid,
        output  awready,
        input   wdata,
        input   wstrb,
        input   wvalid,
        output  wready,
        output  bresp,
        output  bvalid,
        input   bready,
        input   araddr,
        input   arprot,
        input   arvalid,
        output  arready,
        output  rdata,
        output  rresp,
        output  rvalid,
        input   rready
    );

    modport monitor (
        input  aclk,
        input  aresetn,
        input  awaddr,
        input  awprot,
        input  awvalid,
        input  awready,
        input  wdata,
        input  wstrb,
        input  wvalid,
        input  wready,
        input  bresp,
        input  bvalid,
        input  bready,
        input  araddr,
        input  arprot,
        input  arvalid,
        input  arready,
        input  rdata,
        input  rresp,
        input  rvalid,
        input  rready
    );

    // Zero out all control signals of a Master interface
    task set_master_idle();
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
        arvalid <= 1'b0;
        rready <= 1'b0;
        @(posedge aclk);
    endtask

    // Zero out all control signals of a Slave interface
    task set_slave_idle();
        awready <= 1'b0;
        wready <= 1'b0;
        bvalid <= 1'b0;
        arready <= 1'b0;
        rvalid <= 1'b0;
    endtask

    // Write access
    task write_data(
        input logic [ADDR_WIDTH-1:0]    write_addr,
        input logic [DATA_WIDTH-1:0]    write_data []
    );

        // Write address and Write data channels proceed in parallel
        fork
            begin
                awvalid <= 1'b1;
                awaddr <= write_addr;

                // Wait for address to be sampled
                forever begin
                    @(posedge aclk);
                    if(awvalid && awready) break;
                end

                awvalid <= 1'b0;
            end

            begin
                wvalid <= 1'b1;
                wdata <= write_data[0];
                wstrb <= {DATA_WIDTH/8{1'b1}};

                // Wait for data to be sampled
                forever begin
                    @(posedge aclk);
                    if(wvalid && wready) break;
                end

                wvalid <= 1'b0;
            end

            begin
                forever begin
                    @(posedge aclk);
                    if(bvalid && !bready) bready <= 1'b1;
                    else if(bvalid && bready) break;
                end
            end

            bready <= 1'b0;
        join

        // Shim delay
        @(posedge aclk);
    endtask

    // Read access
    task read_data(
        input logic [ADDR_WIDTH-1:0]    read_addr,
        output logic [DATA_WIDTH-1:0]   read_data []
    );

        // Read address and Read data channels proceed in parallel
        fork
            begin
                arvalid <= 1'b1;
                araddr <= read_addr;

                // Wait for address to be sampled
                forever begin
                    @(posedge aclk);
                    if(arvalid && arready) break;
                end

                arvalid <= 1'b0;
            end

            begin
                rready <= 1'b1;

                // Wait for data to be sampled
                forever begin
                    @(posedge aclk);
                    if(rvalid && rready) break;
                end

                read_data = new [1](read_data);
                read_data[0] = rdata;

                rready <= 1'b0;
            end
        join

        // Shim delay
        @(posedge aclk);
    endtask
endinterface

// AXI4 Full interface
interface axi4f_if
#(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter ID_WIDTH      = 4
)
(
    input   aclk,
    input   aresetn
);

    // The AXI4 bus signals
    logic [ADDR_WIDTH-1:0]      awaddr;
    logic [ID_WIDTH-1:0]        awid;
    logic [2:0]                 awprot;
    logic [1:0]                 awburst;
    logic [2:0]                 awsize;
    logic [3:0]                 awcache;
    logic [7:0]                 awlen;
    logic                       awlock;
    logic [3:0]                 awqos;
    logic                       awvalid;
    logic                       awready;
    logic [3:0]                 awregion;
    logic [DATA_WIDTH-1:0]      wdata;
    logic [(DATA_WIDTH/8)-1:0]  wstrb;
    logic                       wlast;
    logic                       wvalid;
    logic                       wready;
    logic                       bvalid;
    logic                       bready;
    logic [ID_WIDTH-1:0]        bid;
    logic [1:0]                 bresp;
    logic [ID_WIDTH-1:0]        arid;
    logic [ADDR_WIDTH-1:0]      araddr;
    logic [7:0]                 arlen;
    logic [2:0]                 arsize;
    logic [1:0]                 arburst;
    logic [2:0]                 arprot;
    logic [3:0]                 arqos;
    logic                       arvalid;
    logic                       arready;
    logic [3:0]                 arregion;
    logic                       arlock;
    logic [3:0]                 arcache;
    logic [ID_WIDTH-1:0]        rid;
    logic [DATA_WIDTH-1:0]      rdata;
    logic [1:0]                 rresp;
    logic                       rvalid;
    logic                       rready;
    logic                       rlast;

    modport master (
        input   aclk,
        input   aresetn,
        output  awaddr,
        output  awid,
        output  awprot,
        output  awburst,
        output  awsize,
        output  awcache,
        output  awlen,
        output  awlock,
        output  awqos,
        output  awvalid,
        input   awready,
        output  awregion,
        output  wdata,
        output  wstrb,
        output  wlast,
        output  wvalid,
        input   wready,
        input   bvalid,
        output  bready,
        input   bid,
        input   bresp,
        output  arid,
        output  araddr,
        output  arlen,
        output  arsize,
        output  arburst,
        output  arprot,
        output  arqos,
        output  arvalid,
        input   arready,
        output  arregion,
        output  arlock,
        output  arcache,
        input   rid,
        input   rdata,
        input   rresp,
        input   rvalid,
        output  rready,
        input   rlast
    );

    modport slave (
        input   aclk,
        input   aresetn,
        input   awaddr,
        input   awid,
        input   awprot,
        input   awburst,
        input   awsize,
        input   awcache,
        input   awlen,
        input   awlock,
        input   awqos,
        input   awvalid,
        output  awready,
        input   awregion,
        input   wdata,
        input   wstrb,
        input   wlast,
        input   wvalid,
        output  wready,
        output  bvalid,
        input   bready,
        output  bid,
        output  bresp,
        input   arid,
        input   araddr,
        input   arlen,
        input   arsize,
        input   arburst,
        input   arprot,
        input   arqos,
        input   arvalid,
        output  arready,
        input   arregion,
        input   arlock,
        input   arcache,
        output  rid,
        output  rdata,
        output  rresp,
        output  rvalid,
        input   rready,
        output  rlast
    );

    modport monitor (
        input  aclk,
        input  aresetn,
        input  awaddr,
        input  awid,
        input  awprot,
        input  awburst,
        input  awsize,
        input  awcache,
        input  awlen,
        input  awlock,
        input  awqos,
        input  awvalid,
        input  awready,
        input  awregion,
        input  wdata,
        input  wstrb,
        input  wlast,
        input  wvalid,
        input  wready,
        input  bvalid,
        input  bready,
        input  bid,
        input  bresp,
        input  arid,
        input  araddr,
        input  arlen,
        input  arsize,
        input  arburst,
        input  arprot,
        input  arqos,
        input  arvalid,
        input  arready,
        input  arregion,
        input  arlock,
        input  arcache,
        input  rid,
        input  rdata,
        input  rresp,
        input  rvalid,
        input  rready,
        input  rlast
    );

    // Zero out all control signals
    task set_idle();
        @(posedge aclk);
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
        arvalid <= 1'b0;
        rready <= 1'b0;

        // Normally unused, but they must be driven so the PC is happy
        awprot <= 3'd0;
        awcache <= 4'd0;
        awlock <= 1'b0;
        awqos <= 4'd0;
        awregion <= 4'd0;
        arprot <= 3'd0;
        arcache <= 4'd0;
        arlock <= 1'b0;
        arqos <= 4'd0;
        arregion <= 4'd0;
    endtask

    // Write access
    task write_data(
        input logic [ADDR_WIDTH-1:0]    write_addr,
        input logic [DATA_WIDTH-1:0]    write_data []
    );

        // When needed, split the burst into a series of bursts to meet the 4KiB boundary constraint
        // of the AXI4 specification
        automatic logic [ADDR_WIDTH-1:0] start_addrs [];
        automatic integer burst_lens [];
        axi4_pkg::AXI4F_Utils#(DATA_WIDTH,ADDR_WIDTH)::split_axi4f_write(write_addr, write_data, start_addrs, burst_lens);

        // Write address and Write data channels proceed in parallel. Only one burst at a time is
        // scheduled from the list of bursts
        for(int bdx = 0, int wdx_global = 0; bdx < start_addrs.size(); bdx++) begin
            fork
                begin
                    awvalid <= 1'b1;
                    awaddr <= start_addrs[bdx];
                    awlen <= 8'(burst_lens[bdx] - 1);
                    awburst <= axi4_pkg::BURST_INCR;
                    awid <= $random;
                    awsize <= $clog2(DATA_WIDTH/8);

                    // Wait for address to be sampled
                    forever begin
                        @(posedge aclk);
                        if(awvalid && awready) break;
                    end

                    awvalid <= 1'b0;
                end

                begin
                    //for(int wdx = 1; wdx <= write_data.size(); wdx++) begin
                    for(int wdx = 1; wdx <= burst_lens[bdx]; wdx++) begin
                        wvalid <= 1'b1;
                        wdata <= write_data[wdx_global++];
                        wstrb <= {DATA_WIDTH/8{1'b1}};
                        wlast <= (wdx == burst_lens[bdx] ? 1'b1 : 1'b0);

                        // Wait for data to be sampled
                        forever begin
                            @(posedge aclk);
                            if(wvalid && wready) break;
                        end
                    end

                    wvalid <= 1'b0;
                end

                begin
                    forever begin
                        @(posedge aclk);
                        if(bvalid && !bready) bready <= 1'b1;
                        else if(bvalid && bready) break;
                    end
                end

                bready <= 1'b0;
            join
        end

        // Shim delay
        @(posedge aclk);
    endtask

    // Read access
    task read_data(
        input logic [ADDR_WIDTH-1:0]    read_addr,
        input logic [7:0]               read_len,
        output logic [DATA_WIDTH-1:0]   read_data []
    );

        // When needed, split the burst into a series of bursts to meet the 4KiB boundary constraint
        // of the AXI4 specification
        automatic logic [ADDR_WIDTH-1:0] start_addrs [];
        automatic integer burst_lens [];
        axi4_pkg::AXI4F_Utils#(DATA_WIDTH,ADDR_WIDTH)::split_axi4f_read(read_addr, read_len, start_addrs, burst_lens);

        // Read address and Read data channels proceed in parallel
        for(int bdx = 0, int rdx_global = 0; bdx < start_addrs.size(); bdx++) begin
            fork
                begin
                    arvalid <= 1'b1;
                    araddr <= start_addrs[bdx];
                    arlen <= 8'(burst_lens[bdx] - 1);
                    arburst <= axi4_pkg::BURST_INCR;
                    arid <= $random;
                    arsize <= $clog2(DATA_WIDTH/8);

                    // Wait for address to be sampled
                    forever begin
                        @(posedge aclk);
                        if(arvalid && arready) break;
                    end

                    arvalid <= 1'b0;
                end

                begin
                    rready <= 1'b1;

                    for(int rdx = 1; rdx <= burst_lens[bdx]; rdx++) begin
                        // Wait for data to be sampled
                        forever begin
                            @(posedge aclk);
                            if(rvalid && rready) break;
                        end

                        read_data = new [read_data.size()+1](read_data);
                        read_data[rdx_global++] = rdata;
                    end

                    rready <= 1'b0;
                end
            join
        end

        // Shim delay
        @(posedge aclk);
    endtask
endinterface
