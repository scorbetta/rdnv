import random
from fxpmath import *


#---- FXP LIBRARY RELATED -------------------------------------------------------------------------

# Return a well-known FXP configuration object to be used to create Fxp() instances
def fxp_get_config():
    fxp_config = Config()
    fxp_config.overflow = 'wrap'#'saturate'
    fxp_config.rounding = 'trunc'
    fxp_config.shifting = 'expand'
    fxp_config.op_method = 'raw'
    fxp_config.op_input_size = 'same'
    fxp_config.op_sizing = 'same'
    fxp_config.const_op_sizing = 'same'
    return fxp_config

# Return a random fixed-point number
def fxp_generate_random(width, frac_bits):
    word_str = ''.join(random.choice(['0','1']) for bit in range(width))
    value = Fxp(val=f'0b{word_str}', signed=True, n_word=width, n_frac=frac_bits, config=get_fxp_config())
    return value

# Return the fixed-point range
def fxp_get_range(width, frac_bits):
    # Minimum value
    frac_part_str = '0' * frac_bits
    int_part_str = '1' + '0' * (width - frac_bits - 1)
    fp_str = int_part_str + frac_part_str
    fxp_min = Fxp(val=f'0b{fp_str}', signed=True, n_word=width, n_frac=frac_bits, config=get_fxp_config())

    # Maximum value
    frac_part_str = '1' * frac_bits
    int_part_str = '0' + '1' * (width - frac_bits - 1)
    fp_str = int_part_str + frac_part_str
    fxp_max = Fxp(val=f'0b{fp_str}', signed=True, n_word=width, n_frac=frac_bits, config=get_fxp_config())

    return fxp_min,fxp_max

# Compute the absolute distance between a reference quantity and a measured quantity. To avoid
# division-by-0, increment the reference value by a 0.01% of its value, so that it is certainly
# different than 0
def fxp_abs_err(ref_value, test_value):
    return abs( ((ref_value * 1.0001) - test_value) / (ref_value * 1.0001) )

# Get the resolution of a given fixed-point configuration. Resolution depends on number of bits in
# the fractional part. Resolution is the number given by a binary string that has only the LSB set
def fxp_get_lsb(width, frac_bits):
    resolution_bin_str = f"0b{'0' * (width-frac_bits)}{'0' * (frac_bits-1)}1"
    lsb = Fxp(val=resolution_bin_str, signed=True, n_word=width, n_frac=frac_bits, config=get_fxp_config())
    return lsb
