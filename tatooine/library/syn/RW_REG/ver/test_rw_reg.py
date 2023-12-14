import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from cocotb_coverage.coverage import *

@cocotb.test()
async def test_rw_reg(dut):
    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Defaults
    dut.RSTN.value = 0
    dut.WEN.value = 0

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(100):
        random_data = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)

        # Write data
        await RisingEdge(dut.CLK)
        dut.WEN.value = 1
        dut.VALUE_IN.value = random_data
        await RisingEdge(dut.CLK)
        dut.WEN.value = 0

        # Without Write enable asserted, output value shall not change
        random_wait_cycles = randint(2, 10)
        for _ in range(random_wait_cycles):
            await RisingEdge(dut.CLK)
            await FallingEdge(dut.CLK)
            assert dut.VALUE_OUT.value == random_data
