# INDEPENDENT_CLOCK_FIFO

## Features
Dual-clock FIFO logic with embedded RAM, with configurable depth, width and programmable flags.

## Principles of operation

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| Fifo_depth | integer | 8 | Define FIFO depth. If depth is not specified as power of 2, it is automatically rounded to nearest and greater power of 2. Minimum depth is 8 |
| data_width | integer | 32 | Data bus width |
| FWFT_ShowAhead | boolean | false | If true, first word appears at the output without asserting read enable |
| Synchronous_Clocks | boolean | false | This parameter disables the gray coding (not needed when clocks are related) and set the minimum latency. This parameter can be set to true iff: 1) Write and Read clocks have a fixed and known phase relationship *and* 2) Write clock and Read clocks are constrained as related in the XDC |
| Prog_Full_ThresHold | integer | 4 | Specify the programmable full assertion. This value must be programmed between 4 and Fifo_depth-4 |
| Prog_Empty_ThresHold | integer | 4 | Specify the Programmable Empty assertion. This value must be programmed between 4 and Fifo_depth-4 |


## Ports
| NAME | DIRECTION | WIDTH | CLOCK DOMAIN | NOTES |
|-|-|-|-|-|
| Async_rst | input | 1 | Asynchronous | Active-high asynchronous reset |
| wr_clk | input | 1 | wr_clk | Write clock |
| rd_clk | input | 1 | rd_clk | Read clock |
| we | input | 1 | wr_clk | Write enable |
| din | input | data_width | wr_clk | Data in |
| full | output | 1 | wr_clk | Asserted when the FIFO is full |
| prog_full | output | 1 | wr_clk | This flag is asserted high when data_count is equal or greater than Prog_Full_ThresHold |
| wr_data_count | output | 32 | wr_clk | Written data count |
| valid | output | 1 | rd_clk | Read data strobe |
| re | input | 1 | rd_clk | Read enable |
| dout | output | data_width | rd_clk | Read data |
| empty | output | 1 | rd_clk | Asserted when the FIFO is empty |
| prog_empty | output | 1 | rd_clk | This flag is asserted low when data_count is greater than Prog_Empty_ThresHold |
| rd_data_count | output | 32 | rd_clk | Read data count |

## Design notes
The dual-clock FIFO contains synchronizers. The user must be aware of the time relationship between
the Write and the Read interfaces before making any assumption.

Dual-clock FIFO does not expose an absolute `data_count` as done for the `COMMON_CLOCK_FIFO` case.
This is due to the time required for the Write and Read data counts to settle to a common clock
domain, that would result in an unnecessary long delay. For this reason, the user shall use the
Write and Read counters as it is.

The user is required to generate the proper timing grouping in the target XDC file. The following
example can be used, although adaptation to user design will likely be necessary. In the following,
`WCLK` and `RCLK` are assumed to be already declared somewhere in the constraints fileset.

```tcl linenums="1"
# Synchronizer flops. Make sure the output of get_cells covers the sole FIFO instance
set_property ASYNC_REG true [ get_cells -hierarchical -filter {NAME =~ *read_pointer_gray_q*_reg*} ]
set_false_path -to [ get_pins -hierarchical -filter {NAME =~ *read_pointer_gray_q1_reg*/D} ]

set_property ASYNC_REG true [ get_cells -hierarchical -filter {NAME =~ *write_pointer_gray_q*_reg*} ]
set_false_path -to [ get_pins -hierarchical -filter {NAME =~ *write_pointer_gray_q1_reg*/D} ]

# Write and Read clocks are asynchronous. Modify instance name  IC_FIFO_0  to design's own
set wr_clk_object [ get_pins -hierarchical -filter {NAME =~ *IC_FIFO_0/wr_clk} ]
set rd_clk_object [ get_pins -hierarchical -filter {NAME =~ *IC_FIFO_0/rd_clk} ]
set_clock_groups -asynchronous -group [ get_clocks -of_objects $wr_clk_oject ] -group [ get_clocks -of_objects $rd_clk_object ]
```
