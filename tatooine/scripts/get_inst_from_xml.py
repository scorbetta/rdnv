#!/usr/bin/python3

# Generate an instance of a module starting from its XML definition

import xml.etree.ElementTree as et
import sys
import regex
from math import ceil

# Parent class specifying the printer algorithm and the methods to override
class HDLInstancePrinter:
    def __init__(self, module_name, instance_name, params_list, ports_list, tab_width):
        self._module_name = module_name
        self._instance_name = instance_name
        self._params_list = params_list
        self._ports_list = ports_list
        self._tab_width = tab_width

        # Compute the length of the longest parameter/port name so that we can align the text
        temp = 0
        [ temp := max(temp, len(item.attrib['name'])) for item in self._params_list ]
        self._params_list_max_len = temp
        temp = 0
        [ temp := max(temp, len(item.attrib['name'])) for item in self._ports_list ]
        self._ports_list_max_len = temp

        # Defaults must be overwritten by the specified class
        self._params_max_col_stretch = 0
        self._params_open_align = 0
        self._ports_max_col_stretch = 0
        self._ports_open_align = 0

    def ComputeAlignment(self):
        return seld._tab_width

    def PrintComment(self):
        return ""

    def PrintHeader(self):
        return ""

    def OpenParamList(self):
        return ""

    def PrintItem(self, item, stretch):
        return ""

    def CloseParamList(self):
        return ""

    def OpenPortList(self):
        return ""

    def ClosePortList(self):
        return ""

    def FixLastParam(self, instance_str):
        return instance_str

    def FixLastPort(self, instance_str):
        return instance_str

    def PrintInstance(self):
        # Comment before header
        instance_str = self.PrintComment() + "\n"

        # Module name and instance name
        instance_str += self.PrintHeader()

        # Compute alignment of text
        self.ComputeAlignment()

        # Parameters
        max_len = 0
        instance_str += self.OpenParamList() + "\n"
        for param in self._params_list:
            instance_str += self.PrintItem(param, self._params_open_align) + "\n"
            max_len = max(max_len, len(param.attrib['name']))
        instance_str += self.CloseParamList() + "\n"

        # Ports
        instance_str += self.OpenPortList() + "\n"
        for port in self._ports_list:
            instance_str += self.PrintItem(port, self._ports_open_align) + "\n"
            max_len = max(max_len, len(port.attrib['name']))
        instance_str += self.ClosePortList()

        # Fix closing parameter and port
        instance_str = self.FixLastParam(instance_str)
        instance_str = self.FixLastPort(instance_str)

        return instance_str

# Prints instance using Verilog/SystemVerilog syntax
class VerilogPrinter(HDLInstancePrinter):
    def ComputeAlignment(self):
        # Compute the column of the last character of the longest parameter
        self._params_max_col_stretch = self._tab_width + 1 + self._params_list_max_len + 1

        # Compute the column where the opening mapping for the longest parameter begins. This is the
        # column that forces alignment of all other items
        self._params_open_align = self._tab_width * ceil(self._params_max_col_stretch / self._tab_width) + 1

        # Repeat for port
        self._ports_max_col_stretch = self._tab_width + 1 + self._ports_list_max_len + 1
        self._ports_open_align = self._tab_width * ceil(self._ports_max_col_stretch / self._tab_width) + 1

    def PrintComment(self):
        return "//"

    def PrintHeader(self):
        return f"{self._module_name} {self._instance_name}"

    def OpenParamList(self):
        if len(self._params_list) > 0:
            return " #("
        else:
            return ""

    def PrintItem(self, item, alignment):
        # The item is printed so that the opening parenthesis is aligned to an integer multiple of
        #  self._tab_width  from the beginning of the line (column 1). The leading indent is instead
        # fixed to  self._tab_width
        retstr = " " * self._tab_width
        retstr += f".{item.attrib['name']}"

        # Compute the column of the last character of the item's name. The length has three
        # contributions (column counting starts with 1)
        #                  1/leading tab     2/. 3/item name
        item_col_stretch = self._tab_width + 1 + len(item.attrib['name']) + 1

        # Compute the space to insert until the next  (  so that the  (  character gets printed
        # exactly at the  alignment  column
        space_width = alignment - item_col_stretch
        #@DBUGprint(f"dbug: {item.attrib['name']} --> {item_col_stretch} --> {space_width}")
        retstr += " " * space_width
        retstr += "(),"
        return retstr

    def CloseParamList(self):
        if len(self._params_list) > 0:
            return ")"
        else:
            return ""

    def OpenPortList(self):
        if len(self._params_list) > 0:
            return "("
        else:
            return ""

    def ClosePortList(self):
        return ");"

    def FixLastParam(self, instr):
        return instr.replace("(),\n)", "()\n)")

    def FixLastPort(self, instr):
        return instr.replace("(),\n);", "()\n);")

# Prints instance using VHDL syntax
class VHDLPrinter(HDLInstancePrinter):
    def ComputeAlignment(self):
        # Compute the column of the last character of the longest parameter
        self._params_max_col_stretch = self._tab_width * 2 + self._params_list_max_len + 1

        # Compute the column where the opening mapping for the longest parameter begins. This is the
        # column that forces alignment of all other items
        self._params_open_align = self._tab_width * ceil(self._params_max_col_stretch / self._tab_width) + 1

        # Repeat for port
        self._ports_max_col_stretch = self._tab_width * 2 + self._ports_list_max_len + 1
        self._ports_open_align = self._tab_width * ceil(self._ports_max_col_stretch / self._tab_width) + 1

    def PrintComment(self):
        return "--"

    def PrintHeader(self):
        return f"{self._instance_name}: {self._module_name}"

    def OpenParamList(self):
        if len(self._params_list) > 0:
            retstr = "\n"
            retstr += " " * self._tab_width
            retstr += "generic map ("
            return retstr
        else:
            return ""

    def PrintItem(self, item, alignment):
        # The item is printed so that the opening parenthesis is aligned to an integer multiple of
        #  self._tab_width  from the beginning of the line (column 1). The leading indent is instead
        # fixed to  self._tab_width
        retstr = " " * self._tab_width * 2
        retstr += f"{item.attrib['name']}"

        # Compute the column of the last character of the item's name. The length has tw
        # contributions (column counting starts with 1)
        #                  1/leading tab         2/item name
        item_col_stretch = 2 * self._tab_width + len(item.attrib['name']) + 1

        # Compute the space to insert until the next  =>  so that the  =>  character gets printed
        # exactly at the  alignment  column
        space_width = alignment - item_col_stretch
        retstr += " " * space_width
        retstr += "=> ,"
        return retstr

    def CloseParamList(self):
        if len(self._params_list) > 0:
            retstr = " " * self._tab_width
            retstr += ")"
            return retstr
        else:
            return ""

    def OpenPortList(self):
        if len(self._ports_list) > 0:
            retstr = "\n"
            retstr += " " * self._tab_width
            retstr += "port map ("
            return retstr
        else:
            return ""

    def ClosePortList(self):
        retstr = " " * self._tab_width
        retstr += ");"
        return retstr

    def FixLastParam(self, instr):
        return regex.sub(",(\n\s+\))", "\\1", instr)

def main(args):
    if not(len(args) == 4 or len(args) == 5):
        print(f'help: Usage: {args[0]} <target_hdl> <tab_width> <xml_file> [<instance_name>]')
        print(f'{args}')
    else:
        # Parse XML
        root = et.parse(args[3] + ".xml").getroot()

        # Collect info
        module_name = root.attrib['name']
        if len(args) == 5:
            instance_name = args[4]
        else:
            instance_name = module_name + "_0"
        params_list = list(root.iter('macro'))
        ports_list = list(root.iter('port'))
        tab_width = int(args[2])

        # Print according to HDL
        target_hdl = args[1]
        if target_hdl == "sv" or target_hdl == "v":
            printer = VerilogPrinter(module_name, instance_name, params_list, ports_list, tab_width)
            instance_str = printer.PrintInstance()
            print(f'{instance_str}')
        elif target_hdl == "vhd":
            printer = VHDLPrinter(module_name, instance_name, params_list, ports_list, tab_width)
            instance_str = printer.PrintInstance()
            print(f'{instance_str}')
        else:
            print(f'erro: Unrecognized target HDL: {target_hdl} (available: verilog, vhdl)')

if __name__ == "__main__":
    main(sys.argv)
