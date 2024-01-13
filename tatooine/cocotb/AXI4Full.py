import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Combine, ReadOnly, NextTimeStep
from cocotb.utils import get_sim_time
from random import *

# AXI4 Full
class AXI4Full:
    """A class containing utilities to work with AXI 4 Full buses"""

    def __init__(self, dut, clock, data_width=32, addr_width=32, prefix=''):
        """
        Initialization

        Parameters
        ----------
            dut: cocotb.handle.HierarchyObject
                A reference to the DUT
            clock: cocotb.handle.ModifiableObject
                A reference to the clock signal within the DUT
            data_width: int
                Width (bits) of the data bus. Must be an integer multiple of a Byte. Optional (default: 32)
            addr_width: int
                Width (bits) of the address bus. Optional (default: 32)
            prefix: str
                The prefix name is prepended to the conventional AXI4 Stream signal names to access
                those signals within the DUT
        """
        # Reference to DUT
        self.dut = dut
        # Reference clcok
        self.clock = clock
        # Bus specs
        self.data_width = data_width
        self.addr_width = addr_width

        # Default naming for AXI4 Full signals
        self.names = {}
        self.names['awaddr'] = f'{prefix}AWADDR'
        self.names['awid'] = f'{prefix}AWID'
        self.names['awburst'] = f'{prefix}AWBURST'
        self.names['awsize'] = f'{prefix}AWSIZE'
        self.names['awlen'] = f'{prefix}AWLEN'
        self.names['awvalid'] = f'{prefix}AWVALID'
        self.names['awready'] = f'{prefix}AWREADY'
        self.names['wdata'] = f'{prefix}WDATA'
        self.names['wstrb'] = f'{prefix}WSTRB'
        self.names['wlast'] = f'{prefix}WLAST'
        self.names['wvalid'] = f'{prefix}WVALID'
        self.names['wready'] = f'{prefix}WREADY'
        self.names['bvalid'] = f'{prefix}BVALID'
        self.names['bready'] = f'{prefix}BREADY'
        self.names['bid'] = f'{prefix}BID'
        self.names['bresp'] = f'{prefix}BRESP'
        self.names['arid'] = f'{prefix}ARID'
        self.names['araddr'] = f'{prefix}ARADDR'
        self.names['arlen'] = f'{prefix}ARLEN'
        self.names['arsize'] = f'{prefix}ARSIZE'
        self.names['arburst'] = f'{prefix}ARBURST'
        self.names['arvalid'] = f'{prefix}ARVALID'
        self.names['arready'] = f'{prefix}ARREADY'
        self.names['rid'] = f'{prefix}RID'
        self.names['rdata'] = f'{prefix}RDATA'
        self.names['rresp'] = f'{prefix}RRESP'
        self.names['rvalid'] = f'{prefix}RVALID'
        self.names['rready'] = f'{prefix}RREADY'
        self.names['rlast'] = f'{prefix}RLAST'

        # Miscellanea, used to manage Write and Read accesses
        self.write_len = 0
        self.curr_write_addr = 0
        self.read_len = 0
        self.curr_read_addr = 0
        self.mem = {}
        self.write_history = []
        self.read_history = []

    def get_write_history(self):
        """
        Retrieves the current Write history. The history is a list of tuples (t,d,s) with the
        following: (t)imestamp, (d)ata and (s)trobe of the Write access. Once accessed, the history
        is cleared
        """
        temp = self.write_history
        self.write_history = []
        return temp

    def get_read_history(self):
        """
        Retrieves the current Read history. The history is a list of tuples (t,d) with the
        following: (t)imestamp and (d)ata of the Read access. Once accessed, the history is cleared
        """
        temp = self.read_history
        self.read_history = []
        return temp

    async def monitor(self):
        """
        Monitors accesses on an both sides (Master and Slave) of the AXI4 Stream interface. Once
        started it keeps collecting Write and Read accesses. Every time the interfaces are idle, the
        user can access the  write_history  and  read_history  data to retrieve those accesses. This
        method never returns
        """
        write_base_addr = 0
        read_base_addr = 0
        while 1:
            await RisingEdge(self.clock)

            await ReadOnly()

            # Write access
            if (int(self.dut._id(self.names['wvalid'],extended=False).value) == 1) and (int(self.dut._id(self.names['wready'],extended=False).value) == 1):
                self.write_history.append(
                    (
                        get_sim_time(),
                        hex(int(self.dut._id(self.names['wdata'],extended=False).value)),
                        hex(int(self.dut._id(self.names['wstrb'],extended=False).value))
                    )
                )

            # Read access (remember address)
            if (int(self.dut._id(self.names['rvalid'],extended=False).value) == 1) and (int(self.dut._id(self.names['rready'],extended=False).value) == 1):
                self.read_history.append(
                    (
                        get_sim_time(),
                        hex(int(self.dut._id(self.names['rdata'],extended=False).value))
                    )
                )

            await NextTimeStep()

# AXI4 Full Master
class AXI4FullMaster(AXI4Full):
    """AXI4 Full Master interface class"""
    pass

# AXI4 Full Slave
class AXI4FullSlave(AXI4Full):
    """AXI4 Full Slave interface class"""

    def set_idle(self):
        """
        Set the Master interface idle, by clearing all control signals
        """
        self.dut._id(self.names['awready'],extended=False).value = 0
        self.dut._id(self.names['wready'],extended=False).value = 0
        self.dut._id(self.names['bvalid'],extended=False).value = 0
        self.dut._id(self.names['rvalid'],extended=False).value = 0

    async def recv_write_address_phase(self, backpressure=0):
        """
        Responds to an incoming Write Address phase.

        Parameters
        ----------
            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted before asserting the AWREADY signal. Optional (default: 0).
        """
        # Wait for  AWVALID  to be asserted
        while int(self.dut._id(self.names['awvalid'],extended=False).value) == 0:
            await RisingEdge(self.clock)

        # Accept Write Address request by asserting  AWREADY  
        if backpressure == 1:
            rand_wait_cycles = randint(1,4)
            for _ in range(rand_wait_cycles):
                await RisingEdge(self.clock)
        self.dut._id(self.names['awready'],extended=False).value = 1

        # Sample Write request specs
        self.curr_write_addr = int(self.dut._id(self.names['awaddr'],extended=False).value)
        self.write_len = int(self.dut._id(self.names['awlen'],extended=False).value) + 1

        await RisingEdge(self.clock)
        self.dut._id(self.names['awready'],extended=False).value = 0
     
    async def recv_write_data_phase(self, backpressure=0):
        """
        Responds to an incoming Write Data phase.

        Parameters
        ----------
            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted while asserting the WREADY signal. Optional (default: 0).
        """

        # Wait for  WVALID  to be asserted
        self.dut._id(self.names['wready'],extended=False).value = 1
        for wdx in range(self.write_len):
            while 1:
                await RisingEdge(self.clock)
                if int(self.dut._id(self.names['wvalid'],extended=False).value) == 1:
                    break

            # Sample data
            self.mem[self.curr_write_addr] = int(self.dut._id(self.names['wdata'],extended=False).value)

            # AXI4 is Byte-addressable, plus adjust by wrapping around
            self.curr_write_addr = int((self.curr_write_addr + (self.data_width / 8)) % (1 << self.addr_width))

            # Verify last flag
            assert ( (int(self.dut._id(self.names['wlast'],extended=False).value) == 0) and (wdx < self.write_len-1) ) or ( (int(self.dut._id(self.names['wlast'],extended=False).value) == 1) and (wdx == self.write_len-1) )

            # Backpressure
            if backpressure == 1:
                self.dut._id(self.names['wready'],extended=False).value = 0
                rand_wait_cycles = randint(1,4)
                for _ in range(rand_wait_cycles):
                    await RisingEdge(self.clock)
                self.dut._id(self.names['wready'],extended=False).value = 1

        self.dut._id(self.names['wready'],extended=False).value = 0

    async def send_write_resp_phase(self):
        """
        Generates a response on the Write Reponse channel
        """
        self.dut._id(self.names['bvalid'],extended=False).value = 1
        while int(self.dut._id(self.names['bready'],extended=False).value) == 0:
            await RisingEdge(self.clock)

        await RisingEdge(self.clock)
        self.dut._id(self.names['bvalid'],extended=False).value = 0

    async def recv_write(self, backpressure=0):
        """
        Keeps serving Write requests. This method spawns methods to manage Write Address, Write Data
        and Write Response channels. The Slave forces ordering so that Write Data phase is initiated
        if and only if the Write Address phase has succesfully ended.

        Parameters
        ----------
            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted before asserting the ARREADY signal. Optional (default: 0).
        """
        while 1:
            await self.recv_write_address_phase(backpressure)
            await self.recv_write_data_phase(backpressure)
            await self.send_write_resp_phase()

    async def recv_read_address_phase(self, backpressure=0):
        """
        Responds to an incoming Read Address phase.

        Parameters
        ----------
            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted before asserting the ARREADY signal. Optional (default: 0).
        """

        # Wait for  ARVALID  to be asserted
        while int(self.dut._id(self.names['arvalid'],extended=False).value) == 0:
            await RisingEdge(self.clock)

        # Accept Read Address request by asserting  ARREADY  
        if backpressure == 1:
            rand_wait_cycles = randint(1,4)
            for _ in range(rand_wait_cycles):
                await RisingEdge(self.clock)
        self.dut._id(self.names['arready'],extended=False).value = 1

        # Sample Read request specs
        self.curr_read_addr = int(self.dut._id(self.names['araddr'],extended=False).value)
        self.read_len = int(self.dut._id(self.names['arlen'],extended=False).value) + 1

        await RisingEdge(self.clock)
        self.dut._id(self.names['arready'],extended=False).value = 0

    async def send_read_resp_phase(self):
        """
        Generates a response with data over the Read Response channel.
        """

        # Send back data from  self.mem  container
        for rdx in range(self.read_len):
            await RisingEdge(self.clock)
            self.dut._id(self.names['rvalid'],extended=False).value = 1
            self.dut._id(self.names['rdata'],extended=False).value = self.mem[self.curr_read_addr]
            self.dut._id(self.names['rlast'],extended=False).value = 0
            if rdx == self.read_len-1:
                self.dut._id(self.names['rlast'],extended=False).value = 1
 
            # Address is incremented if and only if  (RVALID && RREADY)  
            while int(self.dut._id(self.names['rready'],extended=False).value) == 0:
                await RisingEdge(self.clock)

            self.curr_read_addr = int((self.curr_read_addr + (self.data_width / 8)) % (1 << self.addr_width))

        await RisingEdge(self.clock)
        self.dut._id(self.names['rvalid'],extended=False).value = 0
        self.dut._id(self.names['rlast'],extended=False).value = 0

    async def recv_read(self, backpressure=0):
        """
        Keeps serving incoming Read accesses. This method spawns methods to manage Read Address and
        Read Data phases.

        Parameters
        ----------
            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted before asserting the ARREADY signal. Optional (default: 0).
        """
        while 1:
            await self.recv_read_address_phase(backpressure)
            await self.send_read_resp_phase()
