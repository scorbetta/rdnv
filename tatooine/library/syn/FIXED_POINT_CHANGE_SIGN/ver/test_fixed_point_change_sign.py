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
async def test_fixed_point_change_sign(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Golden model
    golden = FixedPoint(width, frac_bits)

    # Defaults
    dut.VALUE_IN.value = 0
    dut.VALID_IN.value = 0
    dut.TARGET_SIGN.value = 0
    dut.RSTN.value = 0

    # Reset procedure
    for cycle in range(4):
        await RisingEdge(dut.CLK)
    dut.RSTN.value = 1

    # Shim delay
    for cycle in range(4):
        await RisingEdge(dut.CLK)

    # Constants
    one_value = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=1.0)
    minus_one_value = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=-1.0)

    for test in range(1000):
        # Generate random values
        random_value_in_range,value_bit_string = get_random_fixed_point_value(width, frac_bits)
        value = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value_in_range)

        # Generate random change sign direction
        change_sign_direction = random.choice([0,1])

        # Golden model
        if random_value_in_range >= 0:
            if change_sign_direction == 0:
                golden_result = golden.do_op("mul", value, one_value)
            else:
                golden_result = golden.do_op("mul", value, minus_one_value)
        else:
            if change_sign_direction == 0:
                golden_result = golden.do_op("mul", value, minus_one_value)
            else:
                golden_result = golden.do_op("mul", value, one_value)

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUE_IN.value = int(value_bit_string, 2)
        dut.VALID_IN.value = 1
        dut.TARGET_SIGN.value = change_sign_direction
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0

        # Verify
        await FallingEdge(dut.VALID_OUT)
        dut_result = bin2fp(dut.VALUE_OUT.value.binstr, width, frac_bits)
        assert(dut_result == golden_result),print(f'Results mismatch: dut_result={dut_result},golden_result={golden_result},value={value},sign_direction={change_sign_direction}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
