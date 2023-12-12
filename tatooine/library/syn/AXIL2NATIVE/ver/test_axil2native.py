import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from AXI4Lite import *

# Slave model
async def axil2native_slave(dut):
    mem = {}

    while 1:
        dut.RVALID.value = 0
        await RisingEdge(dut.AXI_ACLK)

        if dut.WEN.value == 1:
            mem[str(int(dut.WADDR.value))] = int(dut.WDATA.value)
        elif dut.REN.value == 1:
            await RisingEdge(dut.AXI_ACLK)
            try:
                dut.RDATA.value = mem[str(int(dut.RADDR.value))]
            except KeyError:
                print(f'erro: Reading uninitialized memory @{hex(int(dut.RADDR.value))}')
                assert 0
            dut.RVALID.value = 1
            await RisingEdge(dut.AXI_ACLK)
            dut.RVALID.value = 0

@cocotb.test()
async def test_axil2native(dut):
    # AXI4 Lite driver
    axi4l_obj = AXI4Lite(prefix="AXI_")

    # Run the clock asap
    clock = Clock(dut.AXI_ACLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # AXI4L2NATIVE ideal Slave
    cocotb.start_soon(axil2native_slave(dut))

    # Defaults
    axi4l_obj.set_idle(dut)

    # Reset procedure
    await axi4l_obj.reset(dut)

    for test in range(1000):
        random_data = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)
        random_addr = randrange(0, 512, 4)
        await axi4l_obj.write_access(dut, random_addr, random_data)
        readout_data = await axi4l_obj.read_access(dut, random_addr)
        assert readout_data == random_data
        for cycle in range(4):
            await RisingEdge(dut.AXI_ACLK)
