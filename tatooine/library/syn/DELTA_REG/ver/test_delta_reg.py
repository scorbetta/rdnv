import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

@cocotb.test()
async def test_delta_reg(dut):
    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Defaults
    dut.RSTN.value = 0
    dut.READ_EVENT.value = 0

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Test same value
    for test in range(25):
        random_data = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)

        # Change data once
        await RisingEdge(dut.CLK)
        dut.VALUE_IN.value = random_data

        # Manage first edge over  VALUE_CHANGE  
        await RisingEdge(dut.CLK)
        dut.READ_EVENT.value = 1
        await RisingEdge(dut.CLK)
        dut.READ_EVENT.value = 0

        random_wait_cycles = randint(2, 10)
        for _ in range(random_wait_cycles):
            await RisingEdge(dut.CLK)
            await FallingEdge(dut.CLK)
            assert dut.VALUE_OUT.value == random_data
            assert dut.VALUE_CHANGE.value == 0

    # Test different values
    for test in range(50):
        random_data_early = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)
        random_data_late = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)

        # Change data twice
        await RisingEdge(dut.CLK)
        dut.VALUE_IN.value = random_data_early
        await RisingEdge(dut.CLK)
        dut.VALUE_IN.value = random_data_late

        # Expect  VALUE_CHANGE  being asserted
        if random_data_late != random_data_early:
            await RisingEdge(dut.CLK)
            await FallingEdge(dut.CLK)
            assert dut.VALUE_OUT.value == random_data_late
            assert dut.VALUE_CHANGE.value == 1

        #  VALUE_CHANGE  gets reset by Software generally
        random_wait_cycles = randint(2, 10)
        for _ in range(random_wait_cycles):
            await RisingEdge(dut.CLK)
            await FallingEdge(dut.CLK)
            assert dut.VALUE_CHANGE.value == 1

        dut.READ_EVENT.value = 1
        await RisingEdge(dut.CLK)
        dut.READ_EVENT.value = 0
        await RisingEdge(dut.CLK)
        await FallingEdge(dut.CLK)
        assert dut.VALUE_CHANGE.value == 0
