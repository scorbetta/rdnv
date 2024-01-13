import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from fxpmath import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_acc(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)
    num_inputs = int(dut.NUM_INPUTS.value)
    fxp_lsb = fxp_get_lsb(width, frac_bits)
    fxp_quants = 2 ** width - 1
    fxp_min,fxp_max = fxp_get_range(width, frac_bits)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

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

    # Reset value
    golden_result = Fxp(0.0, signed=True, n_word=width, n_frac=frac_bits, config=fxp_get_config())

    for test in range(1000):
        # Generate random values
        random_values_in = []
        random_values_in_str = ""
        for vdx in range(num_inputs):
            value = fxp_generate_random(width, frac_bits)
            random_values_in.append(value)
            random_values_in_str = f'{value.bin()}{random_values_in_str}'

        # Golden model
        for vdx in range(num_inputs):
            golden_result = golden_result + random_values_in[vdx]

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUES_IN.value = int(random_values_in_str, 2)
        
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 1
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0

        # Verify
        await RisingEdge(dut.VALID_OUT)
        await FallingEdge(dut.CLK)
        dut_result = Fxp(val=f'0b{dut.VALUE_OUT.value}', signed=True, n_word=width, n_frac=frac_bits, config=fxp_get_config())
        assert(dut_result == golden_result),print(f'Results mismatch: dut_result={dut_result},golden_result={golden_result},values_in={random_values_in}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
