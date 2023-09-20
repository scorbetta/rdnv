# COUNTER

## Features
A simple free-running counter.

## Principles of operation
This is a simple free-running counter. It will increment its value every cycle as long as the `EN`
is asserted. The `WIDTH` parameters determines the `OVERFLOW` assertion period, given a knwon clock
frequency.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| WIDTH | integer | 64 | Counter data width |

## Ports
| NAME | DIRECTION | WIDTH  | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock |
| RSTN | input | 1 | Active-low synchronous reset |
| EN | input | 1 | Counter enable |
| VALUE | output | WIDTH | Counter value |
| OVERFLOW | output | 1 | Asserted when the counter exceeds the configured width |

## Design notes
