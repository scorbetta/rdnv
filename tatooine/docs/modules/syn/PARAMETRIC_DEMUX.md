# PARAMETRIC_DEMUX

## Features
Simple, all-combinational de-multiplexer with parametric data width and number
of output to demux to.

## Principles of operation
The selected outputs gets the input value.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 1 | Input and output data width |
| NUM_OUTPUTS | integer | 2 | Number of outputs to demux to |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| BUS_IN | input | DATA_WIDTH | Input data |
| SEL_IN | input | $log2(NUM_INPUTS) | Selector |
| BUS_OUT | output | DATA_WIDTH x NUM_OUTPUTS | Set of output data |

## Design notes
