// For each interface, three modes are included: master, slave and monitor. In Master mode, the
// module initiates a transaction; in Slave mode, it responds to transactions; Monitor mode can be
// used to snoop signals as they go (all signals are trated as inputs).

// Native Interface protocol utility package
package ni_pkg;
endpackage

// Native Interface interface
interface ni_if
#(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 16
)
(
    input   clk,
    input   rstn
);

    logic                   wen;
    logic [ADDR_WIDTH-1:0]  waddr;
    logic [DATA_WIDTH-1:0]  wdata;
    logic                   wack;
    logic                   ren;
    logic [ADDR_WIDTH-1:0]  raddr;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   rvalid;

    modport master (
        input   clk,
        input   rstn,
        output  wen,
        output  waddr,
        output  wdata,
        input   wack,
        output  ren,
        output  raddr,
        input   rdata,
        input   rvalid
    );

    modport slave (
        input   clk,
        input   rstn,
        input   wen,
        input   waddr,
        input   wdata,
        output  wack,
        input   ren,
        input   raddr,
        output  rdata,
        output  rvalid
    );

    modport monitor (
        input   clk,
        input   rstn,
        input   wen,
        input   waddr,
        input   wdata,
        input   wack,
        input   ren,
        input   raddr,
        input   rdata,
        input   rvalid
    );

    // Zero out all control signals of a Master interface
    task set_master_idle();
        wen <= 1'b0;
        ren <= 1'b0;
        @(posedge clk);
    endtask

    // Zero out all control signals of a Slave interface
    task set_slave_idle();
        wack <= 1'b0;
        rvalid <= 1'b0;
        @(posedge clk);
    endtask

    // Ideal Slave interface, answers with random data in one clock cycle
    task start_slave();
        rvalid <= 1'b0;

        forever begin
            @(posedge ren);
            rvalid <= 1'b1;
            rdata <= $random;

            @(posedge clk);
            rvalid <= 1'b0;
        end
    endtask
endinterface
