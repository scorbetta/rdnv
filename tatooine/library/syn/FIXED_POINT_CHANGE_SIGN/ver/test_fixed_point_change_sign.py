import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from fxpmath import *
from TatooineUtils import *

@cocotb.test()
async def test_fixed_point_change_sign(dut):
    width = int(dut.WIDTH.value)
    frac_bits = int(dut.FRAC_BITS.value)

    # Run the clock asap
    clock = Clock(dut.CLK, 10, units="ns")
    cocotb.start_soon(clock.start())

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

    for test in range(1):
        # Generate random values
        value = fxp_generate_random(width, frac_bits)
        value = Fxp(-4.0, signed=True, n_word=width, n_frac=frac_bits, config=fxp_get_config())

        # Generate random change sign direction
        change_sign_direction = random.choice([0,1])

        # Golden model
        if value >= 0:
            if change_sign_direction == 0:
                golden_result = value
            else:
                golden_result = -value
        else:
            if change_sign_direction == 0:
                golden_result = -value
            else:
                golden_result = value

        # DUT
        await RisingEdge(dut.CLK)
        dut.VALUE_IN.value = int(value.hex(),16)
        dut.VALID_IN.value = 1
        dut.TARGET_SIGN.value = change_sign_direction
        await RisingEdge(dut.CLK)
        dut.VALID_IN.value = 0

        # Verify
        await RisingEdge(dut.VALID_OUT)
        await FallingEdge(dut.CLK)
        dut_result = Fxp(val=f'0b{dut.VALUE_OUT.value}', signed=True, n_word=width, n_frac=frac_bits, confg=fxp_get_config())

        if dut.OVERFLOW.value == 0:
            assert(dut_result == golden_result),print(f'Results mismatch: dut_result={dut_result},golden_result={golden_result},value={value},sign_direction={change_sign_direction}')

        # Shim delay
        for cycle in range(4):
            await RisingEdge(dut.CLK)
