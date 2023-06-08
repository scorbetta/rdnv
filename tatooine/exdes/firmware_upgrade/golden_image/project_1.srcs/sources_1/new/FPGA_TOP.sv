`timescale 1ns/100ps

module FPGA_TOP (
    input [7:0]     PCIE_RXN,
    input [7:0]     PCIE_RXP,
    output [7:0]    PCIE_TXN,
    output [7:0]    PCIE_TXP,
    input           PCIE_REFCLK_P,
    input           PCIE_REFCLK_N,
    input           PCIE_RSTN
);

    logic   pcie_sysclk;
    logic   pcie_sysclk_gt;
    logic   pcie_rstn_c;

    base_mb base_mb_i (
        .pcie_mgt_rxn   (PCIE_RXN),
        .pcie_mgt_rxp   (PCIE_RXP),
        .pcie_mgt_txn   (PCIE_TXN),
        .pcie_mgt_txp   (PCIE_TXP),
        .sys_clk        (pcie_sysclk),
        .sys_clk_gt     (pcie_sysclk_gt),
        .sys_rst_n      (pcie_rstn_c)
    );

    IBUFDS_GTE3 #(
        .REFCLK_HROW_CK_SEL ("00")
    )
    PCIE_REFCLK_IBUF (
        .I      (PCIE_REFCLK_P),
        .IB     (PCIE_REFCLK_N),
        .CEB    (1'b0),
        .O      (pcie_sysclk_gt),
        .ODIV2  (pcie_sysclk)
    );

    IBUF PCIE_SYSRSTN_IBUF (
        .I  (PCIE_RSTN),
        .O  (pcie_rstn_c)
    );
endmodule