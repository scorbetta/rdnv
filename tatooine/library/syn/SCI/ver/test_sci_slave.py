import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from cocotb.types import LogicArray
from NativeInterface import *
from SCI import *

@cocotb.test()
async def test_sci_slave(dut):
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # SCI Master
    sci_obj = SCI(1, prefix='SCI_')

    # Native Slave
    ni_obj = NativeInterface(prefix='NI_')
    cocotb.start_soon(ni_obj.start_slave(dut))

    sci_obj.set_idle(dut)
    dut.RSTN.value = 0
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    for test in range(1000):
        random_data = ''.join([ str(randint(0,1)) for bit in range(dut.DATA_WIDTH.value) ])
        random_addr = ''.join([ str(randint(0,1)) for bit in range(dut.ADDR_WIDTH.value) ])
        #@DBUGprint(f'dbug: random_addr={random_addr}, random_data={random_data}')

        # Write
        await RisingEdge(dut.CLK)
        await sci_obj.send_data(dut, random_addr, random_data, 0)

        # Read
        rdata = await sci_obj.recv_data(dut, random_addr, int(dut.DATA_WIDTH.value), 0)
        assert rdata == random_data

        # Shim delay
        for _ in range(4):
            await RisingEdge(dut.CLK)
