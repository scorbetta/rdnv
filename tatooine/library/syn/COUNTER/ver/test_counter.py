import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

@cocotb.test()
async def test_counter(dut):
    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Defaults
    dut.RSTN.value = 0
    dut.EN.value = 0

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(100):
        random_en = randint(0, 1)
        await RisingEdge(dut.CLK)
        dut.EN.value = random_en

        # Two cases: w/ EN asserted or w/ EN negated
        if random_en == 0:
            # The counter is never updated, current outputs don't change
            await FallingEdge(dut.CLK)
            early_value = int(dut.VALUE.value)
            early_overflow = int(dut.OVERFLOW.value)
            rand_wait = randint(10, 100)
            for _ in range(rand_wait):
                await RisingEdge(dut.CLK)
            await FallingEdge(dut.CLK)
            late_value = int(dut.VALUE.value)
            late_overflow = int(dut.OVERFLOW.value)
            assert late_value == early_value
            assert late_overflow == early_overflow
        else:
            # Outputs are updated. Wait for the overflow to be eventually set
            await RisingEdge(dut.OVERFLOW)
            await FallingEdge(dut.OVERFLOW)

        # Wait random time
        rand_wait = randint(1, 10)
        for _ in range(rand_wait):
            await RisingEdge(dut.CLK)
