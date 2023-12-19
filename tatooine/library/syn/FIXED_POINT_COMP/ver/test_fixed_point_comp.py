import sys
import os
from fpbinary import FpBinary
import configparser
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from FixedPoint import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_comp(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)

    # Golden model
    golden = FixedPoint(width, frac_bits)

    # Defaults
    dut.VALUE_A_IN.value = 0
    dut.VALUE_B_IN.value = 0

    # Shim delay
    await Timer(2, units='ns')

    for test in range(1000):
        # Generate first random value
        random_value_a_in_range,value_a_bit_string = get_random_fixed_point_value(width, frac_bits)
        value_a = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value_a_in_range)

        # Sample desired comparison
        comparison_test = random.choice([0, 1, 2])

        # Adjust corner cases to guarantee convergence of the random algorithm below
        if comparison_test == 0 and random_value_a_in_range == get_fixed_point_min_value(width, frac_bits):
            comparison_test = 2
        elif comparison_test == 2 and random_value_a_in_range == get_fixed_point_max_value(width, frac_bits):
            comparison_test = 0

        match comparison_test:
            case 0:
                # value_a > value_b
                flag = True
                while flag:
                    random_value_b_in_range,value_b_bit_string = get_random_fixed_point_value(width, frac_bits)
                    if random_value_a_in_range > random_value_b_in_range:
                        flag = False

            case 1:
                # value_a == value_b
                random_value_b_in_range = random_value_a_in_range
                value_b_bit_string = value_a_bit_string

            case 2:
                # value_a < value_b
                flag = True
                while flag:
                    random_value_b_in_range,value_b_bit_string = get_random_fixed_point_value(width, frac_bits)
                    if random_value_a_in_range < random_value_b_in_range:
                        flag = False

        value_b = FpBinary(int_bits=width-frac_bits, frac_bits=frac_bits, signed=True, value=random_value_b_in_range)

        # Golden model
        golden_gt,golden_eq,golden_lt = golden.do_op("comp", value_a, value_b)

        # DUT
        await Timer(2, units='ns')
        dut.VALUE_A_IN.value = int(value_a_bit_string, 2)
        dut.VALUE_B_IN.value = int(value_b_bit_string, 2)

        # Verify
        await Timer(2, units='ns')
        dut_gt = dut.GT.value
        dut_eq = dut.EQ.value
        dut_lt = dut.LT.value

        # Compare against golden
        assert(dut_gt == golden_gt),print(f'Results mismatch for case {comparison_test}: dut_gt={dut_gt},golden_gt={golden_gt},value_a={value_a},value_b={value_b}')
        assert(dut_eq == golden_eq),print(f'Results mismatch for case {comparison_test}: dut_eq={dut_eq},golden_eq={golden_eq},value_a={value_a},value_b={value_b}')
        assert(dut_lt == golden_lt),print(f'Results mismatch for case {comparison_test}: dut_lt={dut_lt},golden_lt={golden_lt},value_a={value_a},value_b={value_b}')

        # Compare against desired
        match comparison_test:
            case 0:
                assert(dut_gt == 1),print(f'Unexpected value: dut_gt={dut_gt} with value_a={value_a},value_b={value_b} (expected: 1)')
                assert(dut_eq == 0),print(f'Unexpected value: dut_eq={dut_eq} with value_a={value_a},value_b={value_b} (expected: 0)')
                assert(dut_lt == 0),print(f'Unexpected value: dut_lt={dut_lt} with value_a={value_a},value_b={value_b} (expected: 0)')

            case 1:
                assert(dut_gt == 0),print(f'Unexpected value: dut_gt={dut_gt} with value_a={value_a},value_b={value_b} (expected: 0)')
                assert(dut_eq == 1),print(f'Unexpected value: dut_eq={dut_eq} with value_a={value_a},value_b={value_b} (expected: 1)')
                assert(dut_lt == 0),print(f'Unexpected value: dut_lt={dut_lt} with value_a={value_a},value_b={value_b} (expected: 0)')

            case 2:
                assert(dut_gt == 0),print(f'Unexpected value: dut_gt={dut_gt} with value_a={value_a},value_b={value_b} (expected: 0)')
                assert(dut_eq == 0),print(f'Unexpected value: dut_eq={dut_eq} with value_a={value_a},value_b={value_b} (expected: 0)')
                assert(dut_lt == 1),print(f'Unexpected value: dut_lt={dut_lt} with value_a={value_a},value_b={value_b} (expected: 1)')

        # Shim delay
        await Timer(2, units='ns')
