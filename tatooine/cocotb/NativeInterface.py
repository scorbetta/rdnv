import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Combine
from random import *

# Native Interface interface class
class NativeInterface:
    # Initialize
    def __init__(self, prefix=''):
        # Default naming for Native Interface signals
        self.name = {}
        self.name['clock'] = f'CLK'
        self.name['reset'] = f'RSTN'
        self.name['wen'] = f'{prefix}WREQ'
        self.name['waddr'] = f'{prefix}WADDR'
        self.name['wdata'] = f'{prefix}WDATA'
        self.name['wack'] = f'{prefix}WACK'
        self.name['ren'] = f'{prefix}RREQ'
        self.name['raddr'] = f'{prefix}RADDR'
        self.name['rvalid'] = f'{prefix}RVALID'
        self.name['rdata'] = f'{prefix}RDATA'
        # Attached memory
        self.mem = {}

    def overwrite_name(self, old, new):
        self.name[old] = new

    # Put interface idle
    def set_idle(self, dut):
        dut._id(self.name['wen'],extended=False).value = 0
        dut._id(self.name['ren'],extended=False).value = 0

    # Write request
    async def write_access(self, dut, addr, data):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['wen'],extended=False).value = 1
        dut._id(self.name['waddr'],extended=False).value = addr
        dut._id(self.name['wdata'],extended=False).value = data
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['wen'],extended=False).value = 0
        await RisingEdge(dut._id(self.name['wack'],extended=False))
        await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Slave model
    async def start_slave(self, dut):
        self.mem = {}
    
        dut._id(self.name['rvalid'],extended=False).value = 0
        dut._id(self.name['wack'],extended=False).value = 0

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            await FallingEdge(dut._id(self.name['clock'],extended=False))

            # Write request
            if int(dut._id(self.name['wen'],extended=False).value) == 1:
                self.mem[str(int(dut._id(self.name['waddr'],extended=False).value))] = int(dut._id(self.name['wdata'],extended=False).value)
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['wack'],extended=False).value = 1
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['wack'],extended=False).value = 0
           
            # Read request
            if int(dut._id(self.name['ren'],extended=False).value) == 1:
                try:
                    dut._id(self.name['rdata'],extended=False).value = self.mem[str(int(dut._id(self.name['raddr'],extended=False).value))]
                except KeyError:
                    dut._id(self.name['rdata'],extended=False).value = int(hex(getrandbits(dut.DATA_WIDTH.value)),16)
                    pass
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['rvalid'],extended=False).value = 1
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['rvalid'],extended=False).value = 0
