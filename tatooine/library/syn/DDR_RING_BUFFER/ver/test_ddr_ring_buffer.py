import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from AXI4Stream import *
from AXI4Full import *

@cocotb.test()
async def test_ideal_slaves(dut):
    # Retrieve DUT static configuration
    addr_width = int(dut.AXI_ADDR_WIDTH.value)
    data_width = int(dut.DATA_WIDTH.value)
    burst_len = int(dut.DRAIN_BURST_LEN.value)

    # AXI4 Stream objects
    ififo_axi4s_master = AXI4StreamMaster(dut, dut.CLK, "IFIFO_AXI_PORT_", 0)
    ofifo_axi4s_slave = AXI4StreamSlave(dut, dut.CLK, "OFIFO_AXI_PORT_", 0)

    # AXI4 Full object
    mig_axi4f_slave = AXI4FullSlave(dut, dut.CLK, data_width, addr_width, "DDR_CTRL_AXI_PORT_")

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Put AXI4 interfaces in idle
    ififo_axi4s_master.set_idle()
    ofifo_axi4s_slave.set_idle()
    mig_axi4f_slave.set_idle()

    # Defaults
    dut.RSTN.value = 0
    dut.SOFT_RSTN.value = 1

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1
    for _ in range(4):
        await RisingEdge(dut.CLK)

    # Apply DUT dynamic configuration (from register map)
    await RisingEdge(dut.CLK)
    ring_buffer_len = int((1 << addr_width) / burst_len)
    dut.RING_BUFFER_LEN.value = ring_buffer_len
    dut.AXI_BASE_ADDR.value = int(0x0)
    dut.AXI_ADDR_MASK.value = int(0x3f0)
    await RisingEdge(dut.CLK)

    # DDR MIG model (an ideal AXI4 Full Slave)
    cocotb.start_soon(mig_axi4f_slave.recv_write(0))
    cocotb.start_soon(mig_axi4f_slave.recv_read(0))

    # Output FIFO sink model (an ideal AXI4 Stream Slave)
    cocotb.start_soon(ofifo_axi4s_slave.recv_stream(0))

    # Start monitors
    cocotb.start_soon(ififo_axi4s_master.monitor())
    cocotb.start_soon(mig_axi4f_slave.monitor())
    cocotb.start_soon(ofifo_axi4s_slave.monitor())

    for test in range(1):#ring_buffer_len+4):
        # Generate stream
        #data = [ int(hex(getrandbits(data_width)),16) for x in range(burst_len) ]
        data = [ (test*burst_len)+x for x in range(burst_len) ]
        await ififo_axi4s_master.send_stream(data)

    for cycle in range(1000):
        await RisingEdge(dut.CLK)

    print(ififo_axi4s_master.get_stream_history())
    print(mig_axi4f_slave.get_write_history())
    print(mig_axi4f_slave.get_read_history())
    print(ofifo_axi4s_slave.get_stream_history())
