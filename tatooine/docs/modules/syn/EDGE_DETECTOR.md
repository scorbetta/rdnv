# EDGE_DETECTOR

## Features
A configurable edge detector.

## Principles of operation
A pulse is generated on the `RISE_EDGE_OUT` and `FALL_EDGE_OUT` ports once a rising edge
respectively falling edge is detected over the input signal.

## Parameters

## Ports
| NAME | DIRECTION | WIDTH  | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock |
| RSTN | input | 1 | Active-low synchronous reset |
| SAMPLE_IN | input | 1 | Data stream is read through this port |
| RISE_EDGE_OUT | output | 1 | A single-cycle pulse is generated on this port when `SAMPLE_IN` changes from 1'b0 to 1'b1 |
| FALL_EDGE_OUT | output | 1 | A single-cycle pulse is generated on this port when `SAMPLE_IN` changes from 1'b0 to 1'b1 |

## Design notes
