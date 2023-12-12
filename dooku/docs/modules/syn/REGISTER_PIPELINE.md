# REGISTER_PIPELINE

## Features

## Principles of operation
A pipeline made of [REGISTER](modules/syn/REGISTER.md) instances, as a simple shift register.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 1 | Data width |
| RESET_VALID | integer | 1'b0 | Value of the Q pin after reset, for each stage |
| NUM_STAGES | integer | 1 | Number of pipeline stages |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock signal |
| RSTN | input | 1 | Active-low reset |
| CE | input | 1 | Chip enable |
| DATA_IN | input | DATA_WIDTH | Input value to the front pipe stage |
| DATA_OUT | output | DATA_WIDTH | Output value from the back pipe stage |

## Design notes
