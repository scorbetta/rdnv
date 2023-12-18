# Features

# Parameters
| PARAMETER | DEFAULT |
|-|-|
| ADDR_WIDTH | 32 |
| DATA_WIDTH | 32 |

# Ports
| PORT | DIRECTION | WIDTH |
|-|-|-|
| AXI_ACLK | input | 1 |
| AXI_ARESETN | input | 1 |
| AXI_AWADDR | input | 32 |
| AXI_AWPROT | input | 3 |
| AXI_AWVALID | input | 1 |
| AXI_AWREADY | output | 1 |
| AXI_WDATA | input | 32 |
| AXI_WSTRB | input | 4 |
| AXI_WVALID | input | 1 |
| AXI_WREADY | output | 1 |
| AXI_BRESP | output | 2 |
| AXI_BVALID | output | 1 |
| AXI_BREADY | input | 1 |
| AXI_ARADDR | input | 32 |
| AXI_ARPROT | input | 3 |
| AXI_ARVALID | input | 1 |
| AXI_ARREADY | output | 1 |
| AXI_RDATA | output | 32 |
| AXI_RRESP | output | 2 |
| AXI_RVALID | output | 1 |
| AXI_RREADY | input | 1 |
| WEN | output | 1 |
| WADDR | output | 32 |
| WDATA | output | 32 |
| WACK | output | 1 |
| REN | output | 1 |
| RADDR | output | 32 |
| RDATA | input | 32 |
| RVALID | input | 1 |

# Coverage report

# Implementation

# Notes
[`Source code on github.com`](https://github.com/scorbetta/rdnv/tree/main/tatooine/library/syn/AXIL2NATIVE/rtl)