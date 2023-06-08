# COUNTER

## Features
This module controls Read transactions to peripherals that act RAM-like, i.e. accepting Read request
(for instance through a Read enable signal) and generating Read data strobed by an acknowledge
signal (e.g., a Read valid). The engine is design in such a way that the request and repsonse paths
are completely independent from a functional and timing point-of-view. This means that any retiming
register pipeline added along the request and/or response paths does not invalidate the behavior of
the design. This is of utmost importance for complex designs, where pipelining helps in closing
timing.

## Principles of operation
The controller counts number of Read requests sent and Read responses received separately, so that
the forward path and the backward path can be timed independently, i.e. registers can be added on
their path to help timing without taking care of the asymmetry. This leads to a latency insensitive
design.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| DATA_WIDTH | integer | 64 | RAM data width |
| ADDR_WIDTH | integer | 32 | RAM address width |

## Ports
| NAME | DIRECTION | WIDTH  | NOTES |
|-|-|-|-|
| CLK | input | 1 | Clock |
| RSTN | input | 1 | Active-low reset |
| READ_START | input | Read enable. A rising-edge on this signal triggers the Read requests |
| RADDR_START | input | ADDR_WIDTH | Starting address. Addresses are incremented at each cycle |
| READ_LENGTH | input | 32 | Number of addresses to generate |
| RREQ_COUNT_DONE | output | 1 | Asserted when all READ_LENGTH requests have been sent |
| RVALID_COPY | output | 1 | Read response |
| RDATA_COPY | output DATA_WIDTH | Read data |
| RVALID_COUNT_DONE | output | 1 | Asserted when all READ_LENGTH responses have been received |
| RREQ | output | 1 | Read request to the RAM |
| RADDR | output | ADDR_WIDTH | Read address to the RAM |
| RVALID | input | 1 | Read valid from the RAM |
| RDATA | input | DATA_WIDTH | Read data from the RAM |

## Design notes
