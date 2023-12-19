import sys
import random
import time
import os
from fpbinary import FpBinary
from bitstring import BitArray
from TatooineUtils import *

# The  FixedPoint  class is used to verify fixed-point arithmetic operations. A generic fixed-point
# number of length N (bits) is defined as <Ni,Nf> such that:
#   N = Ni + Nf
# where  Ni  is the number of bits reserved to the integer part (portion of the number before the
# decimal point), and  Nf  is th number of bits reserved to the decimal portion (portion of the
# number past the decimal point)
class FixedPoint:
    def __init__(self, total_bits, frac_bits):
        self.format = (total_bits-frac_bits, frac_bits)
        self.reset_values()

    def reset_values(self):
        self.mul = FpBinary(int_bits=self.format[0], frac_bits=self.format[1], signed=True, value=0.0)
        self.acc = FpBinary(int_bits=self.format[0], frac_bits=self.format[1], signed=True, value=0.0)
        self.add = FpBinary(int_bits=self.format[0], frac_bits=self.format[1], signed=True, value=0.0)
        self.abs = FpBinary(int_bits=self.format[0], frac_bits=self.format[1], signed=True, value=0.0)
        self.act_fun = FpBinary(int_bits=self.format[0], frac_bits=self.format[1], signed=True, value=0.0)
        self.gt = 0
        self.eq = 0
        self.lt = 0

    def sanity_check(self, value):
        assert (value == None) or (type(value) is FpBinary)

    def do_op(self, op, value_a, value_b = None):
        # Preamble
        self.sanity_check(value_a)
        self.sanity_check(value_b)

        # Perform operation
        match op:
            case "add":
                self.add = value_a + value_b
                self.add = self.add.resize(self.format)
                return self.add

            case "mul":
                self.mul = value_a * value_b
                self.mul = self.mul.resize(self.format)
                return self.mul

            case "comp":
                self.gt = int(value_a > value_b)
                self.eq = int(value_a == value_b)
                self.lt = int(value_a < value_b)
                return self.gt,self.eq,self.lt

            case "acc":
                self.acc = self.acc + value_a
                self.acc = self.acc.resize(self.format)
                return self.acc

            case "abs":
                # The lowest negative number is a special case...
                if value_a == get_fixed_point_min_value(self.format[0]+self.format[1], self.format[1]):
                    self.abs = value_a
                elif value_a >= 0.0:
                    self.abs = value_a
                else:
                    self.abs = value_a * -1.0
                return self.abs

            case _:
                print(f'erro: Operation {op} not supported')
                assert 0

    def to_str(self):
        return f'gldn: Contents: mul={self.mul},acc={self.acc},add={self.add},abs={self.abs},gt={self.gt},eq={self.eq},lt={self.lt}'
