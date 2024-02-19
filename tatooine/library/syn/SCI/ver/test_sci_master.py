import sys
import os
import cocotb
from random import *
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from cocotb.types import LogicArray
from SCI import *

@cocotb.test()
async def test_sci_master(dut):
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # SCI Slave starts asap
    sci_obj = SCI(int(dut.NUM_PERIPHERALS.value), prefix='SCI_')
    cocotb.start_soon(sci_obj.start_slave(dut, int(dut.ADDR_WIDTH.value), int(dut.DATA_WIDTH.value)))

    dut.REQ.value = 0
    dut.RSTN.value = 0
    for _ in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Utils
    csn_all_1s = ''.join([ '1' for bit in range(dut.NUM_PERIPHERALS.value) ])
    single_access_len = 1 + int(dut.ADDR_WIDTH.value) + int(dut.DATA_WIDTH)

    for test in range(1000):
        random_data = ''.join([ str(randint(0,1)) for bit in range(dut.DATA_WIDTH.value) ])
        random_addr = ''.join([ str(randint(0,1)) for bit in range(dut.ADDR_WIDTH.value) ])
        random_periph_select = randint(0, int(dut.NUM_PERIPHERALS.value)-1)
        random_periph_csn = csn_all_1s[:random_periph_select] + '0' + csn_all_1s[random_periph_select+1:]

        # Write
        #@DBUGprint(f'dbug: Write access, random_periph_csn={random_periph_csn}, random_addr={random_addr}, random_data={random_data}')
        await RisingEdge(dut.CLK)
        dut.REQ.value = 1
        dut.WNR.value = 1
        dut.ADDR.value = LogicArray(random_addr)
        dut.DATA_IN.value = LogicArray(random_data)
        dut.CSN_IN.value = LogicArray(random_periph_csn)
        await RisingEdge(dut.CLK)
        dut.REQ.value = 0
        await RisingEdge(dut.ACK)
        for _ in range(4):
            await RisingEdge(dut.CLK)

        # Read
        #@DBUGprint(f'dbug: Read access, random_periph_csn={random_periph_csn}, random_addr={random_addr}')
        await RisingEdge(dut.CLK)
        dut.REQ.value = 1
        dut.WNR.value = 0
        dut.ADDR.value = LogicArray(random_addr)
        dut.CSN_IN.value = LogicArray(random_periph_csn)
        await RisingEdge(dut.CLK)
        dut.REQ.value = 0
        await RisingEdge(dut.ACK)
        await FallingEdge(dut.CLK)
        assert str(dut.DATA_OUT.value) == random_data
        for _ in range(4):
            await RisingEdge(dut.CLK)
