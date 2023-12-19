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
async def test_tdpram(dut):
    width = int(dut.WIDTH.value)
    depth = int(dut.DEPTH.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    sram = {}

    # Defaults
    dut.RST.value = 1
    dut.PORTA_WEN.value = 0
    dut.PORTA_REN.value = 0
    dut.PORTB_WEN.value = 0
    dut.PORTB_REN.value = 0

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

        # Launch few Writes followed by same amount of Reads over random ports
        num_writes = randint(1, 10)
        write_port = randint(0, 1)
        for _ in range(num_writes):
            waddrs.append(int(getrandbits(int(log2(depth)))))
            wdatas.append(int(getrandbits(width)))

            await RisingEdge(dut.CLK)
            if write_port == 1:
                dut.PORTA_WEN.value = 1
                dut.PORTA_ADDR.value = waddrs[-1]
                dut.PORTA_WDATA.value = wdatas[-1]
                dut.PORTA_WSTRB.value = int(f"0b{'1' * int(width/8)}", 2)
            else:
                dut.PORTB_WEN.value = 1
                dut.PORTB_ADDR.value = waddrs[-1]
                dut.PORTB_WDATA.value = wdatas[-1]
                dut.PORTB_WSTRB.value = int(f"0b{'1' * int(width/8)}", 2)
            sram[f'{waddrs[-1]}'] = wdatas[-1]

            await RisingEdge(dut.CLK)
            dut.PORTA_WEN.value = 0
            dut.PORTB_WEN.value = 0

            # Random shim delay
            wait_period = randint(5, 10)
            for _ in range(wait_period):
                await RisingEdge(dut.CLK)

        # Read from ports
        for wdx in range(num_writes):
            read_port = randint(0, 2)

            await RisingEdge(dut.CLK)
            if read_port == 0 or read_port == 2:
                dut.PORTA_REN.value = 1
                dut.PORTA_ADDR.value = waddrs[wdx]
            if read_port == 1 or read_port == 2:
                dut.PORTB_REN.value = 1
                dut.PORTB_ADDR.value = waddrs[wdx]

            await RisingEdge(dut.CLK)
            dut.PORTA_REN.value = 0
            dut.PORTB_REN.value = 0

            await FallingEdge(dut.CLK)
            if read_port == 0 or read_port == 2:
                assert int(dut.PORTA_RDATA.value) == sram[f'{waddrs[wdx]}']
            if read_port == 1 or read_port == 2:
                assert int(dut.PORTB_RDATA.value) == sram[f'{waddrs[wdx]}']

            # Random shim delay
            wait_period = randint(5, 10)
            for _ in range(wait_period):
                await RisingEdge(dut.CLK)
