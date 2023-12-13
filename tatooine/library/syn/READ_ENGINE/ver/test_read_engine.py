import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from NativeInterface import *

@cocotb.test()
async def test_register_pipeline(dut):
    # Clock and reset procedure
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())
    dut.RSTN.value = 0
    dut.READ_START.value = 0
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Start ideal Slave
    ni_obj = NativeInterface()
    ni_obj.overwrite_name('wen', 'WREQ')
    ni_obj.overwrite_name('ren', 'RREQ')
    cocotb.start_soon(ni_obj.start_slave(dut))

    for _ in range(100):
        # Select random length and start address of read
        random_len = randint(1, 256)
        random_addr_start = randint(0, 2**(int(dut.ADDR_WIDTH.value)-2)-1) * 4
        await RisingEdge(dut.CLK)
        dut.READ_START.value = 1
        dut.READ_LENGTH.value = random_len
        dut.RADDR_START.value = random_addr_start
        await RisingEdge(dut.CLK)
        dut.READ_START.value = 0

        # Wait for read to finish
        await RisingEdge(dut.RREQ_COUNT_DONE)
        await RisingEdge(dut.RVALID_COUNT_DONE)

        for _ in range(4):
            await RisingEdge(dut.CLK)
