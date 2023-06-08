# AXIL2NATIVE

## Features
A simple adapter logic to shim transactions between an AXI4 Lite Slave interface and a Native
interface.

## Principles of operation

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 32 | Data bus width |
| ADDR_WIDTH | integer | 32 | Address bus width |

## Ports
| NAME | DIRECTION | WIDTH  | NOTES |
|-|-|-|-|
| AXI_ACLK | input | 1 | Clock |
| AXI_ARESETN | input | 1 | Active-low synchronous reset |
| AXI_AWADDR | input | ADDR_WIDTH | Write address |
| AXI_AWPROT | input | 3 | Unused |
| AXI_AWVALID | input | 1 | Write address valid |
| AXI_AWREADY | output | 1 | Write address ready |
| AXI_WDATA | input | DATA_WIDTH | Write data |
| AXI_WSTRB | input | DATA_WIDTH/8 | Write data Byte enables |
| AXI_WVALID | input | 1 | Write data valid |
| AXI_WREADY | output | 1 | Write data ready |
| AXI_BRESP | output | 2 | Write response |
| AXI_BVALID | output | 1 | Write response valid |
| AXI_BREADY | input | 1 | Write response ready |
| AXI_ARADDR | input | ADDR_WIDTH | Read address | 
| AXI_ARPROT | input | 3 | Unused |
| AXI_ARVALID | input | Read address valid |
| AXI_ARREADY | output | Read address ready |
| AXI_RDATA | output | DATA_WIDTH | Read data |
| AXI_RRESP | output | 2 | Read response |
| AXI_RVALID | output | 1 | Read response valid |
| AXI_RREADY | input | 1 | Read response ready |
| WEN | output | 1 | Write enable |
| WADDR | output | ADDR_WIDTH | Write address |
| WDATA | output | DATA_WIDTH | Write data |
| WACK | output | 1 | Write acknowledgement |
| REN | output | 1 | Read enable |
| RADDR | output | ADDR_WIDTH | Read address |
| RDATA | input | DATA_WIDTH | Read data |
| RVALID | input | 1 | Read data valie |

## Design notes
