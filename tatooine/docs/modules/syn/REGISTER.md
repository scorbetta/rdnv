# REGISTER

## Features

## Principles of operation
Models a barrier of D Flip-Flops.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 1 | Data width |
| RESET_VALUD | integer | 1'b0 | Value of the Q pin after reset |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock signal |
| RSTN | input | 1 | Active-low reset |
| CE | input | 1 | Chip enable |
| DATA_IN | input | DATA_WIDTH | Value on D pin |
| DATA_OUT | output | DATA_WIDTH | Value on Q pin |

## Design notes
