# CLK_WIZARD

## Features
Configurable clock generator with synchronous active-high and active-low reset signals. The clock
period and the phase are configurable at instance time.

## Principles of operation

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| CLK_PERIOD | integer | 10 | Clock period in [ns] |
| RESET_DELAY | integer | 4 | Number of clock cycles the reset is delayed before release |
| INIT_PHASE | integer | 0 | Initial phase [ns] |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| USER_CLK | output | 1 | Clock signal |
| USER_RST | output | 1 | Active-high reset |
| USER_RSTN | output | 1 | Active-low reset |

## Design notes
