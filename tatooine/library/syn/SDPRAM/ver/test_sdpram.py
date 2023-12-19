import sys
import os
from fpbinary import FpBinary
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from TatooineUtils import *
from random import *
from math import *

@cocotb.test()
async def test_sdpram(dut):
    width = int(dut.WIDTH.value)
    depth = int(dut.DEPTH.value)
    zl_read = int(dut.ZL_READ.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    sram = {}

    # Defaults
    dut.RST.value = 1
    dut.WEN.value = 0
    dut.REN.value = 0

    # Reset procedure
    for cycle in range(4):
        await RisingEdge(dut.CLK)
    dut.RST.value = 0

    # Shim delay
    for cycle in range(4):
        await RisingEdge(dut.CLK)

    for test in range(1000):
        waddrs = []
        wdatas = []

        # Launch few Writes followed by same amount of Reads
        num_writes = randint(1, 10)
        for _ in range(num_writes):
            # Random address and data
            waddrs.append(int(getrandbits(int(log2(depth)))))
            wdatas.append(int(getrandbits(width)))

            await RisingEdge(dut.CLK)
            dut.WEN.value = 1
            dut.WADDR.value = waddrs[-1]
            dut.WDATA.value = wdatas[-1]
            dut.WSTRB.value = int(f"0b{'1' * int(width/8)}", 2)
            sram[f'{waddrs[-1]}'] = wdatas[-1]

            await RisingEdge(dut.CLK)
            dut.WEN.value = 0

            # Random shim delay
            wait_period = randint(5, 10)
            for _ in range(wait_period):
                await RisingEdge(dut.CLK)

        for wdx in range(num_writes):
            await RisingEdge(dut.CLK)
            dut.REN.value = 1
            dut.RADDR.value = waddrs[wdx]

            if zl_read == 1:
                await FallingEdge(dut.CLK)
                dut.REN.value = 0
            else:
                await RisingEdge(dut.CLK)
                dut.REN.value = 0
                await FallingEdge(dut.CLK)

            assert int(dut.RDATA.value) == sram[f'{waddrs[wdx]}']

            # Random shim delay
            wait_period = randint(5, 10)
            for _ in range(wait_period):
                await RisingEdge(dut.CLK)
