import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

@cocotb.test()
async def test_register_pipeline(dut):
    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Defaults
    dut.RSTN.value = 0
    dut.CE.value = 0
    dut.DATA_IN.value = 0

    # Reset procedure
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(100):
        random_data = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)
        random_ce = randint(0, 1)
        await RisingEdge(dut.CLK)
        dut.CE.value = random_ce
        dut.DATA_IN.value = random_data

        # Two cases: w/ CE asserted or w/ CE negated
        if random_ce == 0:
            # The output value shall never be updated. Test against number of stages cycles plus a
            # little bit more
            curr_value_out = dut.DATA_OUT.value
            for _ in range(dut.NUM_STAGES.value+4):
                await RisingEdge(dut.CLK)
                assert dut.DATA_OUT.value == curr_value_out
        else:
            # The output value shall be updated with the one from previous stage
            for idx in range(dut.NUM_STAGES.value):
                # Save values from each stage
                await FallingEdge(dut.CLK)
                early_values = []
                for jdx in range(dut.NUM_STAGES.value):
                    early_values.append(int(dut.pipe_data_out[jdx]))

                # Let the pipeline evolve
                await RisingEdge(dut.CLK)

                # Re-check values from each stage
                await FallingEdge(dut.CLK)
                late_values = []
                for jdx in range(dut.NUM_STAGES.value):
                    late_values.append(int(dut.pipe_data_out[jdx]))

                assert late_values[0] == random_data
                for jdx in range(1,dut.NUM_STAGES.value):
                    assert late_values[jdx] == early_values[jdx-1]

        # Wait random time
        rand_wait = randint(1, 10)
        for _ in range(rand_wait):
            await RisingEdge(dut.CLK)
