import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Combine, ReadOnly, NextTimeStep
from random import *
from cocotb.utils import get_sim_time

# AXI4 Stream
class AXI4Stream:
    """A class containing utilities to work with AXI 4 Stream buses"""

    def __init__(self, dut, clock, prefix='', include_tlast=1):
        """
        Initialization

        Parameters
        ----------
            dut: cocotb.handle.HierarchyObject
                A reference to the DUT
            clock: cocotb.handle.ModifiableObject
                A reference to the clock signal within the DUT
            prefix: str
                The prefix name is prepended to the conventional AXI4 Stream signal names to access
                those signals within the DUT
            include_tlast: int
                When 1 the TLAST signal is used and the stream is assumed bounded by that signal.
                When 0, the stream is considered continuous. Optional (default: 1)
        """
        # Reference to DUT
        self.dut = dut
        # Reference clock signal
        self.clock = clock

        # Default naming for AXI4 Lite signals
        self.names = {}
        self.names['tvalid'] = f'{prefix}TVALID'
        self.names['tready'] = f'{prefix}TREADY'
        self.names['tdata'] = f'{prefix}TDATA'

        # Optional signals
        if include_tlast == 1:
            self.names['tlast'] = f'{prefix}TLAST'

        # For monitoring purposes
        self.stream_history = []

    def get_stream_history(self):
        """
        Retrieves the current stream history. The history is a list of tuples (t,d) with the
        following: (t)imestamp and (d)ata of the stream access. Once accessed, the history is
        cleared
        """
        temp = self.stream_history
        self.stream_history = []
        return temp

    async def monitor(self):
        """
        Monitors accesses over the AXI4 Stream interface. Once started it keeps collecting data.
        Every time the interfaces are idle, the user can access the  stram_history  data to retrieve
        those accesses. This method never returns
        """
        while 1:
            await RisingEdge(self.clock)

            # Check new beat
            await ReadOnly()
            if (int(self.dut._id(self.names['tvalid'],extended=False).value) == 1) and (int(self.dut._id(self.names['tready'],extended=False).value) == 1):
                self.stream_history.append(
                    (
                        get_sim_time(),
                        hex(int(self.dut._id(self.names['tdata'],extended=False).value))
                    )
                )
            await NextTimeStep()

# AXI4 Stream Master
class AXI4StreamMaster(AXI4Stream):
    """AXI4 Stream Master interface class"""
    def set_idle(self):
        """
        Set the Master interface idle, by clearing all control signals
        """
        self.dut._id(self.names['tvalid'],extended=False).value = 0

    # Send stream of given length (requires  TLAST  ) or start a continuous stream with no end
    async def send_stream(self, data=[]):
        """
        Sends data over the interface.

        According to the data argument, this method can or cannot return. When the data argument is
        an empty list, a continuous stream is assumed, and the method will not return. Otherwise,
        the stream is assumed bounded to the number of elements in the data list.

        Parameters
        ----------
            data: list of int
                The chunks to be sent over the interface. Optional (default: [])
        """
        if len(data) == 0:
            # Stream
            while 1:
                await RisingEdge(self.clock)
                self.dut._id(self.names['tvalid'],extended=False).value = 1
                self.dut._id(self.names['tdata'],extended=False).value = int(hex(getrandbits(self.dut.DATA_WIDTH), 16))
        else:
            # Packets
            for ddx in range(len(data)):
                await RisingEdge(self.clock)
                self.dut._id(self.names['tvalid'],extended=False).value = 1
                self.dut._id(self.names['tdata'],extended=False).value = data[ddx] & int('1'*int(self.dut.DATA_WIDTH), 2)

                if 'tlast' in self.names:
                    self.dut._id(self.names['tlast'],extended=False).value = 0
                    if ddx == (len(data) - 1):
                        self.dut._id(self.names['tlast'],extended=False).value = 1

                # Change data once current beat has been accepted. Manage timeout as well
                timeout = 1000
                while int(self.dut._id(self.names['tready'],extended=False).value) == 0:
                    await RisingEdge(self.clock)
                    timeout = timeout - 1
                    assert timeout > 0, "Timeout reached, TREADY has never been asserted"

            await RisingEdge(self.clock)
            self.dut._id(self.names['tvalid'],extended=False).value = 0

# AXI4 Stream Slave
class AXI4StreamSlave(AXI4Stream):
    """AXI4 Stream Slave interface class"""
    def set_idle(self):
        """
        Set the Slave interface idle, by clearing all control signals
        """
        self.dut._id(self.names['tready'],extended=False).value = 0

    async def recv_stream(self, num_data=0, backpressure=0):
        """
        Accepts data over the interface.

        According to the num_data argument, this method can or cannot return. When num_data is 0, a
        continuous incoming stream is assumed, and the method keeps accepting incoming data until
        TLAST is seen or undefinetely. Otherwise, the stream is assumed bounded and num_data chunks
        are expected.

        Parameters
        ----------
            num_data: int
                Number of chunks to expect over the interface. Optional (default: 0)

            backpressure: int
                Determines amount of backpressure on the interface. When 1, an idle cycle of random
                length is inserted at every beat before asserting the TREADY signal. Optional
                (default: 0).
        """
        
        # Start ready
        self.dut._id(self.names['tready'],extended=False).value = 1
 
        if num_data == 0:
            # Either an endless stream or one with unknown length
            while 1:
                await RisingEdge(self.clock)
                if ('tlast' in self.names) and (int(self.dut._id(self.names['tlast'],extended=False).value) == 1):
                    break

                # TREADY control for backpressure modeling. Include an idle time of  backpressure
                # clock cycles
                if backpressure == 1:
                    self.dut._id(self.names['tready'],extended=False).value = 0
                    rand_wait_cycles = randint(1,4)
                    for _ in range(rand_wait_cycles):
                        await RisingEdge(self.clock)
                    self.dut._id(self.names['tready'],extended=False).value = 1
        else:
            # Expect exactly  num_data  chunks or  TLAST  assertion
            data_count = 0
            while 1:
                await RisingEdge(self.clock)
                if self.dut._id(self.names['tvalid'],extended=False).value == 0:
                    continue

                # Transaction accepted
                data_count = data_count + 1
                if data_count == num_data:
                    if 'tlast' in self.names:
                        await ReadOnly()
                        assert int(self.dut._id(self.names['tlast'],extended=False).value) == 1
                        await NextTimeStep()
                    break

        await RisingEdge(self.clock)
        self.dut._id(self.names['tready'],extended=False).value = 0
