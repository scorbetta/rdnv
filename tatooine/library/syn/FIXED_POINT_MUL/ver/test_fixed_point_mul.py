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
async def test_fixed_point_mul(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    golden = FixedPoint(width, frac_bits)

    # Defaults
    dut.VALUE_A_IN.value = 0
    dut.VALUE_B_IN.value = 0
    dut.VALID_IN.value = 0
    dut.RSTN.value = 0

    # Reset procedure
    for cycle in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Shim delay
    for cycle in range(4):
        await RisingEdge(dut.CLK)

    for test in range(1000):
        # Generate random values
        random_value_a_in_range,value_a_bit_string = get_random_fixed_point_value(width, frac_bits)
        value_a = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value_a_in_range)
        random_value_b_in_range,value_b_bit_string = get_random_fixed_point_value(width, frac_bits)
        value_b = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value_b_in_range)

        # Golden model
        golden_result = golden.do_op("mul", value_a, value_b)

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUE_A_IN.value = int(value_a_bit_string, 2)
        dut.VALUE_B_IN.value = int(value_b_bit_string, 2)
        dut.VALID_IN.value = 1
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0
        await RisingEdge(dut.VALID_OUT)

        # To avoid delta-cycle related problems, the result is sampled on the falling edge of the
        # clock right after the strobe
        await FallingEdge(dut.CLK)
        dut_result = bin2fp(dut.VALUE_OUT.value.binstr, width, frac_bits)
        assert(dut_result == golden_result),print(f'Results mismatch: dut_result={dut_result},golden_result={golden_result},value_a={value_a},value_b={value_b}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
