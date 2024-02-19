import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Combine
from cocotb.types import LogicArray
from random import *

# Scalable Configuration Interface class
class SCI:
    # Initialize
    def __init__(self, num_peripherals, prefix=''):
        # Default naming for Native Interface signals
        self.name = {}
        self.name['csn'] = f'{prefix}CSN'
        self.name['resp'] = f'{prefix}RESP'
        self.name['req'] = f'{prefix}REQ'
        self.name['ack'] = f'{prefix}ACK'
        self.name['clock'] = f'CLK'
        self.name['reset'] = f'RSTN'
        # Number of peripherals
        self.num_peripherals = num_peripherals
        self.all_1s = ''.join([ '1' for pid in range(self.num_peripherals) ])
        # Attached memory
        self.mems = {}
        for pid in range(self.num_peripherals):
            self.mems[pid] = {}

    def overwrite_name(self, old, new):
        self.name[old] = new

    def get_mask(self, pid):
        assert pid >= 0 and pid < self.num_peripherals
        bit = self.num_peripherals - 1 - pid
        mask = self.all_1s[:bit] + '0' + self.all_1s[bit+1:]
        return mask

    # Put interface idle
    def set_idle(self, dut):
        dut._id(self.name['csn'],extended=False).value = LogicArray(self.all_1s)

    # Write request
    async def send_data(self, dut, addr, data, pid):
        assert pid >= 0 and pid < self.num_peripherals
        #@DBUGprint(f'dbug: scif: send_data(): addr={addr}, data={data}, pid={pid}')

        # 1st clock cycle: Write-not-Read
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['csn'],extended=False).value = LogicArray(self.get_mask(pid))
        dut._id(self.name['req'],extended=False).value = 1

        # Address clock cycles. Send LSB first
        for bit in reversed(range(len(addr))):
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            dut._id(self.name['req'],extended=False).value = int(addr[bit])

        # Data clock cycles. Send LSB first
        for bit in reversed(range(len(data))):
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            dut._id(self.name['req'],extended=False).value = int(data[bit])

        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['req'],extended=False).value = 0

        # Wait for ack, SCI Writes are *not* posted
        while 1:
            await FallingEdge(dut._id(self.name['clock'],extended=False))
            if int(dut._id(self.name['ack'],extended=False).value) == 1:
                break
            await RisingEdge(dut._id(self.name['clock'],extended=False))

        # De-select the peripheral
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['csn'],extended=False).value = LogicArray(self.all_1s)

        # ACK must last one cycle
        await FallingEdge(dut._id(self.name['clock'],extended=False))
        assert int(dut._id(self.name['ack'],extended=False).value) == 0
        await RisingEdge(dut._id(self.name['clock'],extended=False))

    # Read request
    async def recv_data(self, dut, addr, data_len, pid):
        assert pid >= 0 and pid < self.num_peripherals
        #@DBUGprint(f'dbug: scif: recv_data(): addr={addr}, pid={pid}')

        # 1st clock cycle: Write-not-Read
        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['csn'],extended=False).value = LogicArray(self.get_mask(pid))
        dut._id(self.name['req'],extended=False).value = 0

        # Address clock cycles. Send LSB first
        for bit in reversed(range(len(addr))):
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            dut._id(self.name['req'],extended=False).value = int(addr[bit])

        # Wait start of data clock cycles. Receive LSB first
        while 1:
            await FallingEdge(dut._id(self.name['clock'],extended=False))
            if int(dut._id(self.name['ack'],extended=False)) == 1:
                break
            await RisingEdge(dut._id(self.name['clock'],extended=False))

        data = ''
        data = f"{dut._id(self.name['resp'],extended=False).value}{data}"
        for bit in range(data_len-1):
            await RisingEdge(dut._id(self.name['clock'],extended=False))
            await FallingEdge(dut._id(self.name['clock'],extended=False))
            assert int(dut._id(self.name['ack'],extended=False)) == 1
            data = f"{dut._id(self.name['resp'],extended=False).value}{data}"

        await RisingEdge(dut._id(self.name['clock'],extended=False))
        dut._id(self.name['csn'],extended=False).value = LogicArray(self.all_1s)
        await FallingEdge(dut._id(self.name['clock'],extended=False))
        assert int(dut._id(self.name['ack'],extended=False)) == 0

        return data

    # Simple Slave model
    async def start_slave(self, dut, addr_len, data_len):
        while 1:
            # Wait for peripheral select (Slaves will wait a rising edge in this state)
            while 1:
                old_val = str(dut._id(self.name['csn'],extended=False).value)
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                await FallingEdge(dut._id(self.name['clock'],extended=False))
                if old_val == self.all_1s and str(dut._id(self.name['csn'],extended=False).value) != self.all_1s:
                    break

            # Check which peripheral has been selected           
            pids = []
            for pdx in range(self.num_peripherals):
                if str(dut._id(self.name['csn'],extended=False).value) == self.get_mask(pdx):
                    pids.append(pdx)

            assert len(pids) == 1
            pid = pids[0]
            #@DBUGprint(f'dbug: Peripheral selected #{pid}')

            wnr = int(dut._id(self.name['req'],extended=False).value)
            addr = ''
            for adx in range(addr_len):
                await FallingEdge(dut._id(self.name['clock'],extended=False))
                addr = f"{dut._id(self.name['req'],extended=False).value}{addr}"
    
            if wnr == 1:
                # Write
                data = ''
                for ddx in range(data_len):
                    await FallingEdge(dut._id(self.name['clock'],extended=False))
                    data = f"{dut._id(self.name['req'],extended=False).value}{data}"
    
                self.mems[pid][addr] = data
                #@DBUGprint(f'dbug: [{pid}] Write to {addr} --> {self.mems}')

                # Random delay for the ack
                random_wait = randint(1, 4)
                for _ in range(random_wait):
                    await RisingEdge(dut._id(self.name['clock'],extended=False))

                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['ack'],extended=False).value = 1
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['ack'],extended=False).value = 0
            else:
                # Read
                random_wait = randint(10, 25)
                for _ in range(random_wait):
                    await RisingEdge(dut._id(self.name['clock'],extended=False))
    
                assert addr in self.mems[pid]
                data = self.mems[pid][addr]
                #@DBUGprint(f'dbug: [{pid}] Read from {addr}')
                for ddx in range(data_len):
                    await RisingEdge(dut._id(self.name['clock'],extended=False))
                    dut._id(self.name['ack'],extended=False).value = 1
                    dut._id(self.name['resp'],extended=False).value = int(data[data_len - 1 - ddx])
                await RisingEdge(dut._id(self.name['clock'],extended=False))
                dut._id(self.name['ack'],extended=False).value = 0
