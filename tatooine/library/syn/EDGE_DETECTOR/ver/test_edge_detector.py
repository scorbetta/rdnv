import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

@cocotb.test()
async def test_edge_detector(dut):
    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Defaults
    dut.RSTN.value = 0
    dut.SAMPLE_IN.value = 0

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(100):
        random_samples = []
        random_samples.append(randint(0,1))
        random_samples.append(randint(0,1))

        # Apply stimuli
        await RisingEdge(dut.CLK)
        dut.SAMPLE_IN.value = random_samples[0]
        await RisingEdge(dut.CLK)
        dut.SAMPLE_IN.value = random_samples[1]

        # Check edges
        await RisingEdge(dut.CLK)
        await FallingEdge(dut.CLK)
        if random_samples[0] != random_samples[1]:
            if random_samples[0] == 0 and random_samples[1] == 1:
                assert dut.RISE_EDGE_OUT.value == 1
                assert dut.FALL_EDGE_OUT.value == 0
            else:
                assert dut.RISE_EDGE_OUT.value == 0
                assert dut.FALL_EDGE_OUT.value == 1
        else:
            assert dut.RISE_EDGE_OUT.value == 0
            assert dut.FALL_EDGE_OUT.value == 0

        for _ in range(4):
            await RisingEdge(dut.CLK)
