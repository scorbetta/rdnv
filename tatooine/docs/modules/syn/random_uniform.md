# random_uniform

## Features
An engine that generates Uniformly distributed pseudo-random values.

## Principles of operation
Values are generated using an LFSR.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| SEED | std_logic_vector(30 downto 0) | 31'd0 | LFSR initial seed |
| OUT_WIDTH | integer | 10 | Output value width |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| clk | input | 1 | Clock signal |
| rst | input | 1 | Active-high reset |
| random | output | OUT_WIDTH | Generated value |

## Design notes
The Uniform generator is based on an LFSR implementation, whose credits go to [Henrik
Forstén](https://hforsten.com/generating-normally-distributed-pseudorandom-numbers-on-a-fpga.html).
