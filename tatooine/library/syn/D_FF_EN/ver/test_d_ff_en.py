import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

@cocotb.test()
async def test_d_ff_en(dut):
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.EN.value = 0
    dut.RSTN.value = 0
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(100):
        await RisingEdge(dut.CLK)
        dut.EN.value = randint(0,1)

        await FallingEdge(dut.CLK)
        if dut.EN.value == 0:
            # Keep applying random data and check output does not change
            curr_q = int(dut.Q.value)
            for _ in range(10):
                dut.D.value = randint(0,1)
                await RisingEdge(dut.CLK)
                await FallingEdge(dut.CLK)
                assert curr_q == int(dut.Q.value),print(f'Flip-flop shall not update when disabled: EN={dut.EN.value},D={dut.D.value},Q={dut.Q.value}')
        else:
            # Keep applying random data and check output does change
            for _ in range(10):
                dut.D.value = randint(0,1)
                await RisingEdge(dut.CLK)
                await FallingEdge(dut.CLK)
                assert int(dut.Q.value) == int(dut.D.value),print(f'Flip-flop output mismatch when enabled: EN={dut.EN.value},D={dut.D.value},Q={dut.Q.value}')

        # Shim delay between ops
        for _ in range(4):
            await RisingEdge(dut.CLK)
