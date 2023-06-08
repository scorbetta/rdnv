# PARAMETRIC_MUX

## Features
Simple, all-combinational multiplexer with parametric data width and number of
inputs to mux from.

## Principles of operation
The output gets the value of the selected input.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 1 | Input and output data width |
| NUM_INPUTS | integer | 2 | Number of inputs to mux from |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| BUS_IN | input | DATA_WIDTH x NUM_INPUTS | Set of input data |
| SEL_IN | input | $log2(NUM_INPUTS) | Selector |
| BUS_OUT | output | DATA_WIDTH | Output data |

## Design notes
