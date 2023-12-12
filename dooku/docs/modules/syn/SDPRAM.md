# SDPRAM

## Features
Simple dual-port RAM with Write Byte enables and configurable zero-latency Reads.

## Principles of operation
When the same address is written and read at the same cycle, the *current* value of the data stored
at the address is returned.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| WIDTH | integer | 64 | Row data width |
| DEPTH | integer | 512 | Number of rows |
| ZL_READ | integer | 0 | When 1, Reads have zero latency |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock signal |
| RST | input | 1 | Active-high synchronous reset |
| WEN | input | 1 | Write access request |
| WADDR | input | $log2(DEPTH) | Write address |
| WDATA | input | WIDTH | Write data |
| WSTRB | input | WIDTH/8 | Byte-wise Write enable |
| REN | input | 1 | Read access request |
| RADDR | input | $log2(DEPTH) | Read address |
| RVALID | output | 1 | Read data strobe |
| RDATA | output | WIDTH | Read data |

## Design notes
