`timescale 1ns/100ps

module FPGA_TOP (
    // PCIe interface
    input [7:0]     PCIE_RXN,
    input [7:0]     PCIE_RXP,
    output [7:0]    PCIE_TXN,
    output [7:0]    PCIE_TXP,
    input           PCIE_REFCLK_P,
    input           PCIE_REFCLK_N,
    input           PCIE_RSTN,
    // UART interface
    input           UART_RX,
    output          UART_TX
);

    // Connections
    logic   pcie_sysclk;    
    logic   pcie_sysclk_gt;
    logic   pcie_rstn_c;

    // Block design
    design_1 design_1_i (
        // PCIe interface
        .pcie_mgt_rxn   (PCIE_RXN),
        .pcie_mgt_rxp   (PCIE_RXP),
        .pcie_mgt_txn   (PCIE_TXN),
        .pcie_mgt_txp   (PCIE_TXP),
        .pcie_sysclk    (pcie_sysclk),
        .pcie_sysclkgt  (pcie_sysclk_gt),
        .pcie_sysrstn   (pcie_rstn_c),
        // UART interface
        .UART_rxd       (UART_RX),
        .UART_txd       (UART_TX)
    );
    
    // PCIe clock and reset buffering
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