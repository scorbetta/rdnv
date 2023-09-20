# TDPRAM

## Features
Single-clock true dual-port RAM with Write Byte enables and Read-first scheduling policy.

## Principles of operation
Concurrent accesses can be issued to ports A and B. These are independent ports, with their own
address. In case of concurrent Write and Read access to the same address, the *current* version of
the data is returned on the Read interface.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| WIDTH | integer | 64 | Row data width |
| DEPTH | integer | 512 | Number of rows |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock signal |
| RST | input | 1 | Active-high synchronous reset |
| PORTA_ADDR | input | $log2(DEPTH) | Address on Port-A |
| PORTA_REN | input | 1 | Read access request on Port-A |
| PORTA_RVALID | outut | 1 | Read data strobe on Port-A |
| PORTA_RDATA | output | WIDTH | Read data on Port-A |
| PORTA_WEN | input | 1 | Write access request on Port-A |
| PORTA_WDATA | input | WIDTH | Write data on Port-A |
| PORTA_WSTRB | input | WIDTH/8 | Byte-wise Write enable on Port-A |
| PORTB_ADDR | input | $log2(DEPTH) | Address on Port-B |
| PORTB_REN | input | 1 | Read access request on Port-B |
| PORTB_RVALID | outut | 1 | Read data strobe on Port-B |
| PORTB_RDATA | output | WIDTH | Read data on Port-B |
| PORTB_WEN | input | 1 | Write access request on Port-B |
| PORTB_WDATA | input | WIDTH | Write data on Port-B |
| PORTB_WSTRB | input | WIDTH/8 | Byte-wise Write enable on Port-B |

## Design notes
