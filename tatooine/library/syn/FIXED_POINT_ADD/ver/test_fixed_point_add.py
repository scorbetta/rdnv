import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from fxpmath import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_add(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)
    fxp_lsb = fxp_get_lsb(width, frac_bits)
    fxp_quants = 2 ** width - 1

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

    for test in range(1000):
        # Generate random values
        value_a = fxp_generate_random(width, frac_bits)
        value_b = fxp_generate_random(width, frac_bits)

        # Golden model
        golden_result = value_a + value_b

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUE_A_IN.value = int(value_a.hex(),16)
        dut.VALUE_B_IN.value = int(value_b.hex(),16)
        dut.VALID_IN.value = 1
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0

        # Verify
        threshold = 0.01
        await RisingEdge(dut.VALID_OUT)
        await FallingEdge(dut.CLK)
        dut_result = Fxp(val=f'0b{dut.VALUE_OUT.value}', signed=True, n_word=width, n_frac=frac_bits, config=fxp_get_config())
        abs_err = fxp_abs_err(golden_result, dut_result)
        quant_err = float(abs_err) / float(fxp_lsb) / fxp_quants

        if dut.OVERFLOW.value == 0:
            assert(quant_err <= threshold),print(f'Results differ more than {threshold*100}% LSBs: dut_result={dut_result},golden_result={golden_result},abs_err={abs_err}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
