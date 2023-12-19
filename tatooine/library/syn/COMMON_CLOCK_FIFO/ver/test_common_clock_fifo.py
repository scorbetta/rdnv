import sys
import os
from fpbinary import FpBinary
import configparser
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from FixedPoint import *
from TatooineUtils import *
from random import *

@cocotb.test()
async def test_common_clock_fifo(dut):
    depth = int(dut.FIFO_DEPTH.value)
    width = int(dut.DATA_WIDTH.value)
    fwft = int(dut.FWFT_SHOWAHEAD.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    fifo = []

    # Defaults
    dut.SYNC_RST.value = 1
    dut.WE.value = 0
    dut.RE.value = 0
    dut.PROG_FULL_THRESHOLD.value = depth - 1
    dut.PROG_EMPTY_THRESHOLD.value = 1

    # Reset procedure
    for cycle in range(4):
        await RisingEdge(dut.CLK)
    dut.SYNC_RST.value = 0

    # Shim delay
    for cycle in range(4):
        await RisingEdge(dut.CLK)

    for test in range(250):
        # Random programmable thresholds (small range)
        dut.PROG_FULL_THRESHOLD.value = randint(depth-4, depth-1)
        dut.PROG_EMPTY_THRESHOLD.value = randint(1, 4)
 
        # Generate random traffic to fill up the FIFO
        for count in range(depth):
            data = int(getrandbits(width))

            await RisingEdge(dut.CLK)
            dut.WE.value = 1
            dut.DIN.value = data
            fifo.append(data)

            await RisingEdge(dut.CLK)
            dut.WE.value = 0

            # Always check data count
            await FallingEdge(dut.CLK)
            assert int(dut.DATA_COUNT.value) == (count + 1)

            # Check when prog-full
            if count == int(dut.PROG_FULL_THRESHOLD.value):
                assert int(dut.PROG_FULL.value) == 1

        await RisingEdge(dut.CLK)
        assert int(dut.FULL.value) == 1

        # Now empty the FIFO
        for count in range(depth):
            await RisingEdge(dut.CLK)
            dut.RE.value = 1

            await RisingEdge(dut.CLK)
            dut.RE.value = 0

            await FallingEdge(dut.CLK)
            assert int(dut.VALID.value) == 1
            assert int(dut.DOUT.value) == fifo.pop(0)

            # Always check data count
            assert int(dut.DATA_COUNT.value) == (depth - count - 1)

            # Check when prog-empty
            if (depth - count - 1) == int(dut.PROG_EMPTY_THRESHOLD.value):
                await FallingEdge(dut.CLK)
                assert int(dut.PROG_EMPTY.value) == 1

        await RisingEdge(dut.CLK)
        assert int(dut.EMPTY.value) == 1

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
