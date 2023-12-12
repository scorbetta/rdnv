# Synthesizable RTL blocks
All the modules in this category are synthesizable.

## List of available cores
| TOP NAME | BRIEF DESCRIPTION | TARGET HDL | NOTES |
|-|-|-|-|
| [AXIL2NATIVE](modules/syn/AXIL2NATIVE.md) | A simple AXI4 Lite to Native adapter | SystemVerilog | |
| [COMMON_CLOCK_FIFO](modules/syn/COMMON_CLOCK_FIFO.md) | A single-clock FIFO | VHDL, SystemVerilog | |
| [COUNTER](modules/syn/COUNTER.md) | A simple wrapping counter | SystemVerilog | |
| [DDR_RING_BUFFER](modules/syn/DDR_RING_BUFFER.md) | A virtual buffer to store large amount of data on AXI-based peripherals, such as DDR | SystemVerilog | |
| [EDGE_DETECTOR](modules/syn/EDGE_DETECTOR.md) | An edge detector | SystemVerilog | |
| [INDEPENDENT_CLOCK_FIFO](modules/syn/INDEPENDENT_CLOCK_FIFO.md) | Dual-clock FIFO | VHDL | |
| [random_gaussian](modules/syn/random_gaussian.md) | A generator of Normally distributed values | VHDL | |
| [random_uniform](modules/syn/random_uniform.md) | A generator of Uniformly distributed values | VHDL | |
| [READ_ENGINE](modules/syn/READ_ENGINE.md) | An engine that manages Read requests to RAM-like peripheral, with asymmetric request and response timing paths | SystemVerilog | |
| [REGISTER](modules/syn/REGISTER.md) | A simple register w/ chip enable | SystemVerilog | |
| [REGISTER_PIPELINE](modules/syn/REGISTER_PIPELINE.md) | A pipeline (shift register) w/ chip enable | SystemVerilog | |
| [PARAMETRIC_DEMUX](modules/syn/PARAMETRIC_DEMUX.md) | A simple parametric de-multiplexer | SystemVerilog | |
| [PARAMETRIC_MUX](modules/syn/PARAMETRIC_MUX.md) | A simple parametric multiplexer | SystemVerilog | |
| [SDPRAM](modules/syn/SDPRAM.md) | A simple dual-port RAM | SystemVerilog | |
| [TDPRAM](modules/syn/TDPRAM.md) | A true dual-port RAM w/ Read-first scheduling | SystemVerilog | |
