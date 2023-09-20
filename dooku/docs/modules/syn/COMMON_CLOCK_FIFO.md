# COMMON_CLOCK_FIFO

## Features
Single-clock FIFO logic with embedded RAM, with configurable depth, width and programmable flags.

## Principles of operation

## Parameters (VHDL version)
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| Fifo_depth | integer | 8 | Define FIFO depth. If depth is not specified as power of 2, it is automatically rounded to nearest and greater power of 2. Minimum depth is 8 |
| data_width | integer | 32 | Data bus width |
| FWFT_ShowAhead | boolean | false | If true, first word appears at the output without asserting read enable |
| Prog_Full_ThresHold | integer | 4 | Specify the programmable full assertion. This value must be programmed between 4 and Fifo_depth-4 |
| Prog_Empty_ThresHold | integer | 4 | Specify the Programmable Empty assertion. This value must be programmed between 4 and Fifo_depth-4 |


## Ports (VHDL version)
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| Async_rst | input | 1 | Active-high asynchronous reset |
| Sync_rst | input | 1 | Active-high synchronous reset |
| clk | input | 1 | Clock |
| we | input | 1 | Write enable |
| din | input | data_width | Data in |
| full | output | 1 | Asserted when the FIFO is full |
| prog_full | output | 1 | This flag is asserted high when data_count is equal or greater than Prog_Full_ThresHold |
| valid | output | 1 | Read data strobe |
| re | input | 1 | Read enable |
| dout | output | data_width | Read data |
| empty | output | 1 | Asserted when the FIFO is empty |
| prog_empty | output | 1 | This flag is asserted low when data_count is greater than Prog_Empty_ThresHold |
| data_count | output | 32 | Number of elements currently stored in FIFO |

## Parameters (SystemVerilog version)
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| FIFO_DEPTH | integer | 8 | Define FIFO depth. If depth is not specified as power of 2, it is automatically rounded to nearest and greater power of 2. Minimum depth is 8 |
| DATA_WIDTH | integer | 32 | Data bus width |
| FWFT_SHOWAHEAD | boolean | false | If true, first word appears at the output without asserting read enable |

## Ports (SystemVerilog version)
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| SYNC_RST | input | 1 | Active-high synchronous reset |
| CLK | input | 1 | Clock |
| WE | input | 1 | Write enable |
| DIN | input | data_width | Data in |
| FULL | output | 1 | Asserted when the FIFO is full |
| PROG_FULL | output | 1 | This flag is asserted high when data_count is equal or greater than Prog_Full_ThresHold |
| VALID | output | 1 | Read data strobe |
| RE | input | 1 | Read enable |
| DOUT | output | data_width | Read data |
| EMPTY | output | 1 | Asserted when the FIFO is empty |
| PROG_EMPTY | output | 1 | This flag is asserted low when data_count is greater than Prog_Empty_ThresHold |
| data_count | output | 32 | Number of elements currently stored in FIFO |
| PROG_FULL_THRESHOLD | integer | 4 | Specify the programmable full assertion. This value must be programmed between 4 and FIFO_DEPTH-4 |
| PROG_EMPTY_THRESHOLD | integer | 4 | Specify the Programmable Empty assertion. This value must be programmed between 4 and FIFO_DEPTH-4 |

## Design notes
The two implementations are *not* completely pin-compatible.

The (original) VHDL version contains a bug, since the `full` and `prog_full` signals are not
properly cleared out of reset. They get cleared one cycle after the reset has been cleared. The
SystemVerilog implementation fixed this issue.

SystemVerilog version ain't no longer contain the asynchronous reset, and the programmable threshold
are now ports. They can be connected for instance to memory-mapped registers.

The `ootbtb` contains a simplified set of tests to check the outputs compatibility of the two
versions, with cycle-wise checks whenever appropriate.
