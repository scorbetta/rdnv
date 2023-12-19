# Features
Fixed-point adder with configurable fixed-point configuration. The output being registered, the
adder takes one cycle to compute the addition of the two inputs. Values are considered signed.

# Parameters
| PARAMETER | DEFAULT |
|-|-|
| FRAC_BITS | 3 |
| WIDTH | 8 |

# Ports
| PORT | DIRECTION | WIDTH |
|-|-|-|
| CLK | input | 1 |
| RSTN | input | 1 |
| VALUE_A_IN | input | 8 |
| VALUE_B_IN | input | 8 |
| VALID_IN | input | 1 |
| VALUE_OUT | output | 8 |
| VALID_OUT | output | 1 |

# Coverage report

# Implementation

# Notes
[`Source code on github.com`](https://github.com/scorbetta/rdnv/tree/main/tatooine/library/syn/FIXED_POINT_ADD/rtl)
