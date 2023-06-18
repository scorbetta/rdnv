// For each interface, three modes are included: master, slave and monitor. In Master mode, the
// module initiates a transaction; in Slave mode, it responds to transactions; Monitor mode can be
// used to snoop signals as they go, all signals are inputs.

// AXI4-Stream interface
interface axi4s_if
#(
    parameter DATA_WIDTH = 32
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
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32
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

    // Put the Write and Read channels in idle state
    task set_idle;
        @(posedge aclk) begin
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            bready <= 1'b1;
            arvalid <= 1'b0;
            rready <= 1'b1;
        end
    endtask

    // Write access
    task write_data(
        input logic [ADDR_WIDTH-1:0]    write_addr,
        input logic [DATA_WIDTH-1:0]    write_data
    );

        // All Bytes enable
        wstrb <= {DATA_WIDTH/8{1'b1}};

        // Initiate Write address channel request
        @(posedge aclk) begin
            awvalid <= 1'b1;
            awaddr <= write_addr;
        end

        while(1) begin
            if(awvalid && awready) break;
            @(posedge aclk);
        end
        awvalid <= 1'b0;

        // Write request accepted, initiate Write data channel request
        @(posedge aclk) begin
            wvalid <= 1'b1;
            wdata <= write_data;
        end

        while(1) begin
            if(wvalid && wready) break;
            @(posedge aclk);
        end
        wvalid <= 1'b0;

        // Accept response
        @(posedge aclk) begin
            bready <= 1'b1;
        end

        while(1) begin
            if(bvalid && bready) break;
            @(posedge aclk);
        end
        bready <= 1'b0;

        // Shim delay
        @(posedge aclk);
    endtask

    task read_data(
        input logic [ADDR_WIDTH-1:0]    read_addr,
        output logic [DATA_WIDTH-1:0]   read_data
    );

        // Initiate Read address channel request
        @(posedge aclk) begin
            arvalid <= 1'b1;
            araddr <= read_addr;
        end

        while(1) begin
            if(arvalid && arready) break;
            @(posedge aclk);
        end
        arvalid <= 1'b0;

        // Wait for data
        rready <= 1'b1;
        while(1) begin
            if(rvalid && rready) break;
            @(posedge aclk);
        end
        read_data <= rdata;
        rready <= 1'b0;

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
endinterface

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
endpackage
