# Features

# Parameters
| PARAMETER | DEFAULT |
|-|-|
| ADDR_WIDTH | 32 |
| DATA_WIDTH | 64 |

# Ports
| PORT | DIRECTION | WIDTH |
|-|-|-|
| CLK | input | 1 |
| RSTN | input | 1 |
| READ_START | input | 1 |
| RADDR_START | input | 32 |
| READ_LENGTH | input | 32 |
| RREQ_COUNT_DONE | output | 1 |
| RVALID_COPY | output | 1 |
| RDATA_COPY | output | 64 |
| RVALID_COUNT_DONE | output | 1 |
| RREQ | output | 1 |
| RADDR | output | 32 |
| RVALID | input | 1 |
| RDATA | input | 64 |

# Coverage report

# Implementation

# Notes
[`Source code on github.com`](https://github.com/scorbetta/rdnv/tree/main/tatooine/library/syn/READ_ENGINE/rtl)