import sys
import os
from fpbinary import FpBinary
import configparser
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from FixedPoint import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_acc(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    golden = FixedPoint(width, frac_bits)
    unused = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=0.0)

    # Defaults
    dut.VALID_IN.value = 0
    dut.RSTN.value = 0

    # Reset procedure
    for cycle in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Shim delay
    for cycle in range(4):
        await RisingEdge(dut.CLK)

    # Reset values only once, so that the value keeps cumulating
    golden.reset_values()

    for test in range(1000):
        # Default inputs to the module
        num_values = 16#random.randint(1, 256)
 
        # Generate random values
        random_values_in = []
        random_values_in_str = ""
        for vdx in range(num_values):
            random_value,random_value_bit_str = get_random_fixed_point_value(width, frac_bits)
            value = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value)
            random_values_in.append(value)
            random_values_in_str = f'{random_value_bit_str}{random_values_in_str}'

        # Golden model
        for vdx in range(num_values):
            golden_result = golden.do_op("acc", random_values_in[vdx], unused)

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUES_IN.value = int(random_values_in_str, 2)
        
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 1
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0
        await RisingEdge(dut.VALID_OUT)

        # Verify
        await FallingEdge(dut.CLK)
        dut_result = bin2fp(dut.VALUE_OUT.value.binstr, width, frac_bits)
        assert(dut_result == golden_result),print(f'Results mismatch: dut_result={dut_result},golden_result={golden_result},values_in={random_values_in}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
