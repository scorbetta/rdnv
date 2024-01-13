import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from fxpmath import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_mul(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)
    fxp_lsb = fxp_get_lsb(width, frac_bits)
    fxp_quants = 2 ** width - 1
    fxp_min,fxp_max = fxp_get_range(width, frac_bits)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

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

    ratios = []
    for test in range(1000):
        # Generate random values
        value_a = fxp_generate_random(width, frac_bits)
        value_b = fxp_generate_random(width, frac_bits)

        # Golden model
        golden_result = value_a * value_b

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUE_A_IN.value = int(value_a.hex(),16)
        dut.VALUE_B_IN.value = int(value_b.hex(),16)
        dut.VALID_IN.value = 1
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0

        await RisingEdge(dut.VALID_OUT)
        await FallingEdge(dut.CLK)
        dut_result = Fxp(val=f'0b{dut.VALUE_OUT.value}', signed=True, n_word=width, n_frac=frac_bits, config=fxp_get_config())

        # FXP library gives slightly different results due to the way it internally computes the
        # values. For this reason, we expect a non-null error. We verify that the error (computed as
        # the absolute distance between the reference value and the measured one) is below a number
        # of LSBs. We use a threshold value to determine the percentage of LSB-related error, i.e.
        # relative to the entire binary range (determined by the  width  parameter)
        threshold = 0.01
        abs_err = fxp_abs_err(golden_result, dut_result)
        quant_err = float(abs_err) / fxp_quants
        assert(quant_err <= threshold),print(f'Results differ more than {threshold*100}% LSBs: dut_result={dut_result},golden_result={golden_result},abs_err={abs_err},quant_error={quant_err}')

        # For debug and characterization
        ratios.append([ abs_err.get_val(), quant_err ])

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)

    #@DBUGfor rat in ratios:
    #@DBUG    print(rat)
