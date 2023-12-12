import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Combine

# AXI4 Lite interface class
class AXI4Lite:
    # Initialize
    def __init__(self, prefix=''):
        # Default naming for AXI4 Lite signals
        self.name = {}
        self.name['clock'] = f'{prefix}ACLK'
        self.name['reset'] = f'{prefix}ARESETN'
        self.name['awaddr'] = f'{prefix}AWADDR'
        self.name['awprot'] = f'{prefix}AWPROT'
        self.name['awvalid'] = f'{prefix}AWVALID'
        self.name['awready'] = f'{prefix}AWREADY'
        self.name['wdata'] = f'{prefix}WDATA'
        self.name['wstrb'] = f'{prefix}WSTRB'
        self.name['wvalid'] = f'{prefix}WVALID'
        self.name['wready'] = f'{prefix}WREADY'
        self.name['bresp'] = f'{prefix}BRESP'
        self.name['bvalid'] = f'{prefix}BVALID'
        self.name['bready'] = f'{prefix}BREADY'
        self.name['araddr'] = f'{prefix}ARADDR'
        self.name['arprot'] = f'{prefix}ARPROT'
        self.name['arvalid'] = f'{prefix}ARVALID'
        self.name['arready'] = f'{prefix}ARREADY'
        self.name['rdata'] = f'{prefix}RDATA'
        self.name['rresp'] = f'{prefix}RRESP'
        self.name['rvalid'] = f'{prefix}RVALID'
        self.name['rready'] = f'{prefix}RREADY'

    # Put the interface in idle mode
    def set_idle(self, dut):
        dut._id(self.name['awvalid'],extended=False).value = 0
        dut._id(self.name['wvalid'],extended=False).value = 0
        dut._id(self.name['arvalid'],extended=False).value = 0
        dut._id(self.name['bready'],extended=False).value = 1
        dut._id(self.name['rready'],extended=False).value = 1

    # Standard reset procedure
    async def reset(self, dut):
        dut._id(self.name['reset'],extended=False).value = 0
        for cycle in range(4):
            await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['reset'],extended=False).value = 1

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Write address phase
    async def write_address_phase(self, dut, addr):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['awvalid'],extended=False).value = 1
        dut._id(self.name['awaddr'],extended=False).value = addr

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            if dut._id(self.name['awvalid'],extended=False).value == 1 and dut._id(self.name['awready'],extended=False).value == 1:
                break

        dut._id(self.name['awvalid'],extended=False).value = 0
        await RisingEdge(dut._id(self.name['clock'],extended=False))
     
    # Write data phase
    async def write_data_phase(self, dut, data):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['wvalid'],extended=False).value = 1
        dut._id(self.name['wdata'],extended=False).value = data

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            if dut._id(self.name['wvalid'],extended=False).value == 1 and dut._id(self.name['wready'],extended=False).value == 1:
                break

        dut._id(self.name['wvalid'],extended=False).value = 0
        await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Write response phase
    async def write_resp_phase(self, dut):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['bready'],extended=False).value = 1

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            if dut._id(self.name['bvalid'],extended=False).value == 1 and dut._id(self.name['bready'],extended=False).value == 1:
                break

        await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Write transaction
    async def write_access(self, dut, addr, data):
        addr_phase = cocotb.start_soon(self.write_address_phase(dut, addr))
        data_phase = cocotb.start_soon(self.write_data_phase(dut, data))
        resp_phase = cocotb.start_soon(self.write_resp_phase(dut))
        await Combine(addr_phase, data_phase, resp_phase)

    # Read address phase
    async def read_address_phase(self, dut, addr):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['arvalid'],extended=False).value = 1
        dut._id(self.name['araddr'],extended=False).value = addr

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            if dut._id(self.name['arvalid'],extended=False).value == 1 and dut._id(self.name['arready'],extended=False).value == 1:
                break

        dut._id(self.name['arvalid'],extended=False).value = 0
        await RisingEdge(dut._id(self.name['clock'],extended=False))
     
    # Read response phase
    async def read_resp_phase(self, dut):
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['rready'],extended=False).value = 1

        while 1:
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            if dut._id(self.name['rvalid'],extended=False).value == 1 and dut._id(self.name['rready'],extended=False).value == 1:
                break

        await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Read transaction
    async def read_access(self, dut, addr):
        addr_phase = cocotb.start_soon(self.read_address_phase(dut, addr))
        resp_phase = cocotb.start_soon(self.read_resp_phase(dut))
        await Combine(addr_phase, resp_phase)
        return dut._id(self.name['rdata'],extended=False).value
