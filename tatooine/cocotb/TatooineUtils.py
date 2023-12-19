import sys
import random
from fpbinary import FpBinary
from bitstring import BitArray

# Convert a generic bit string to a fixed-point value
def bin2fp(bin_str, width, frac_bits):
    if len(bin_str) != width:
        print(f'erro: Size mismatch: len(bin_str)={len(bin_str)} and width={width}')
        exit(-1)

    if frac_bits > width or frac_bits == 0:
        print(f'erro: Unexpected number of fractional bits: {frac_bits}')
        exit(-1)

    # Integral part is just a decimal value. Since Python does not know about 2's complement, we use
    # the external  bitstring  module to manager negative numbers
    int_part_str = bin_str[0:width-frac_bits]
    int_part = BitArray(bin = int_part_str).int

    # Fraction part must be processed
    frac_part_str = bin_str[width-frac_bits:]
    frac_part = 0.0
    for bit in range(frac_bits):
        factor = int(frac_part_str[bit])
        exp = (bit + 1)
        frac_part += factor * 2.0**-exp

    # Generate real value w/ fixed-point representation
    fixed_point = float(int_part + frac_part)
    return fixed_point

# Convert a number to its decimal representation
def to_decimal(value):
    while value > 1:
        value /= 10

    return value

# Add two binary numbers
def bin_add(a, b):
    max_len = max(len(a), len(b))
    a = a.zfill(max_len)
    b = b.zfill(max_len)

    # Initialize the result
    result = ''

    # Initialize the carry
    carry = 0

    # Traverse the string
    for i in range(max_len - 1, -1, -1):
        r = carry
        r += 1 if a[i] == '1' else 0
        r += 1 if b[i] == '1' else 0
        result = ('1' if r % 2 == 1 else '0') + result

        # Compute the carry.
        carry = 0 if r < 2 else 1

    if carry != 0:
        result = '1' + result

    return result.zfill(max_len)

# Convert a fixed-point value to binary string
def fp2bin(fp_value, width, frac_bits):
    # In case of scientific representation, convert it to float at first
    fp_value_float = float(fp_value)

    # Get binary representation of positive value first
    fp_value_abs = str(abs(fp_value_float))
    whole,frac = fp_value_abs.split('.')

    # Whole part is easy
    whole_part_bin = format(int(whole), f'0{width-frac_bits}b')

    # Decimal part algorithm rolls over exactly  frac_bits  iterations. In every iteration, the
    # decimal part is multiplied by 2, and the whole part of the result is appended to the binary
    # string of the resut
    frac_part_bin = ''
    for x in range(frac_bits):
        # Convert to decimal representation
        frac = to_decimal(int(frac))
        whole,frac = str(frac * 2.0).split('.')
        frac_part_bin += whole

    fp_value_bin = f'{whole_part_bin}{frac_part_bin}'

    # In case, take 2's complement to get negative number
    if fp_value_float < 0:
        # Bitwise negation
        fp_value_bin = fp_value_bin.replace('0', 'x')
        fp_value_bin = fp_value_bin.replace('1', '0')
        fp_value_bin = fp_value_bin.replace('x', '1')
        # Add 1 to the result
        fp_value_bin = bin_add(fp_value_bin, '1')

    # Sanity check
    assert(len(fp_value_bin) == width)

    # Return whatever
    return fp_value_bin

# Return a random fixed-point number
def get_random_fixed_point_value(width, frac_bits):
    word_str = ''.join(random.choice(['0','1']) for bit in range(width))
    fixed_point = bin2fp(word_str, width, frac_bits)
    return fixed_point,word_str

# Return the minimum fixed-point value
def get_fixed_point_min_value(width, frac_bits):
    frac_part_str = '0' * frac_bits
    int_part_str = '1' + '0' * (width - frac_bits - 1)
    fp_str = int_part_str + frac_part_str
    return bin2fp(fp_str, width, frac_bits)

# Return the maximum fixed-point value
def get_fixed_point_max_value(width, frac_bits):
    frac_part_str = '1' * frac_bits
    int_part_str = '0' + '1' * (width - frac_bits - 1)
    fp_str = int_part_str + frac_part_str
    return bin2fp(fp_str, width, frac_bits)
