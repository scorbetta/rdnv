# DDR_RING_BUFFER

## Features
A virtual buffer that stores data on external AXI-based devices, such as DDR, can be used to stage a
large amount of data, larger than any typical FPGA design would allow with on-chip BRAMs. The size
of the FIFO is limited only by the device storing the data. For external DDR memories, this can be
in the order of GiB.

## Principles of operation
The data is received over an AXI4 Stram interface, and transparently sent to the external device via
an AXI3 or AXI4 Full (configurable) bus. The data is then read back and staged in a second buffer
accessible via a convenient AXI4 Stream interface. Data is sent to memory in fixed (known) bursts.

## Parameters
| NAME | TYPE | DEFAULT | NOTES |
|-|-|-|-|
| AXI_ID_WIDTH | integer | 1 | The ID width of the AXI interface |
| AXI_ADDR_WIDTH | integer | 32 | Address bus width |
| AXI_DATA_WIDTH | integer | 32 | Data bus width |
| DRAIN_BURST_LEN | integer | 128 | This parameter sets the burst length (`AWLEN`) on the AXI interface |
| STAGE_FIFOS_DEPTH | integer | 256 | Depth of the input and output buffers. To sustain highest performance, keep this value at least twice the `DRAIN_BURST_LEN` value |
| EXTERNAL_READ_ITF | boolean | 0 | When 1'b0, data is read through the output FIFO buffer interface; when 1'b1, the output FIFO buffer is disabled |

## Ports
| NAME | DIRECTION | WIDTH | NOTES |
|-|-|-|-|
| S_AXI_ACLK | input | 1 | Core and AXI interface clock |
| S_AXI_ARESETN | input | 1 | Core and AXI active-low reset |
| IFIFO_AXI_PORT | *multiple* | *multiple* | AXI4 Stream Slave interface for Write data |
| OFIFO_AXI_PORT | *multiple* | *multiple* | AXI4 Stream Slave interface for Read data |
| DDR_CTRL_AXI_PORT | *multiple* | *multiple* | AXI3 or AXI4 Full Master interface for memory or peripheral |
| RING_BUFFER_LEN | input | 32 | Number of slots in the buffer; each slot is `DRAIN_BURST_LEN` deep and `AXI_DATA_WIDTH` bits wide |
| AXI_BASE_ADDR | input | 32 | Base address of the ring buffer |
| AXI_ADDR_MASK | input | 32 | Address mask, for address wrapping |
| SOFT_RSTN | input | 1 | Active-low Software-initiated reset |
| MM2S_FULL | output | 1 | Output buffer full flag |
| EMPTY | output | 1 | Virtual FIFO empty flag |
| CORE_FILL | output | `AXI_ADDR_WIDTH - ($clog2(AXI_DATA_WIDTH)-3)` | Number of elements in the virtual FIFO |
| IFIFO_FILL | output | `$clog2(STAGE_FIFOS_DEPTH)` | Number of elements in the input buffer |
| IFIFO_FULL | output | 1 | Input buffer full flag |
| OFIFO_FILL | output | `$clog2(STAGE_FIFOS_DEPTH)` | Number of elements in the output buffer |
| DATA_LOSS | output | 1 | Asserted when the Write pointer grows faster then Read's |
| RING_BUFFER_WPTR | output | `AXI_ADDR_WIDTH` | Current Write address |
| RING_BUFFER_RPTR | output | `AXI_ADDR_WIDTH` | Current Read address |
| WRITE_OFFSET | output | 32 | Current Write offset |
| CLEAR_EOB | input | 1 | IRQ line clear signal |
| DDR_EOB | output | 1 | Asserted when a burst to the external AXI buffer ends |

## Design notes
