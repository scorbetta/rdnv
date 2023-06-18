#!/usr/bin/python3


#---- IMPORTS -----------------------------------------------------------------

# Standard includes
import sys
import os
import shutil
import argparse
from pathlib import Path

# Import SystemRDL compiler
from systemrdl import RDLCompiler, RDLCompileError, RDLWalker
from systemrdl import RDLListener
from systemrdl.node import FieldNode

# Import PeakRDL regblock
#from peakrdl_regblock import RegblockExporter
from MyRegblockExporter import MyRegblockExporter
from peakrdl_regblock.cpuif.axi4lite import AXI4Lite_Cpuif

# Import PeakRDL html
from peakrdl_html import HTMLExporter

# Import jinja template utils
from jinja2 import Environment, FileSystemLoader


#---- SYSTEMVERILOG EXPORTER --------------------------------------------------

# Define our own SystemVerilog exporter
class MyAXI4LiteInterface(AXI4Lite_Cpuif):
    #@TBD# Override template path
    #@TBDtemplate_path = "My_AXI4Lite_Interface.sv"

    @property
    def port_declaration(self) -> str:
        # Override AXI port declaration
        return "axi4l_if.slave AXIL"

    def signal(self, name:str) -> str:
        # Override signal naming
        return "AXIL." + name.lower()

    @property
    def max_outstanding(self) -> int:
        # Force one outstanding transaction at a time
        return 1

# Exports defines as well
def CreateSVHeaders(root, ofolder, basename, tfolder):
    jinja_env = Environment(loader=FileSystemLoader(tfolder))
    jinja_env.add_extension('jinja2.ext.loopcontrols')
    template = jinja_env.get_template("offset_defines.svh")

    # Save list of registers, so that can re-iterate over them multiple times
    all_regs = list(root.top.registers())
    context = {
        "regs": all_regs,
        "module_name": basename.upper()
    }
    ofile_name = f'{ofolder}/{basename.upper()}.svh'
    jinja_render = template.render(context)
    with open(ofile_name, mode="w", encoding="utf-8") as fid:
        fid.write(jinja_render)


#---- C EXPORTER --------------------------------------------------------------

# Exports defines for C code
def CreateCHeaders(root, ofolder, basename, tfolder, prefix):
    # Create JINJA template environment
    jinja_env = Environment(loader=FileSystemLoader(tfolder))
    jinja_env.add_extension('jinja2.ext.loopcontrols')

    # JINJA render 1: Registers definitions
    template = jinja_env.get_template("reg_defines.h")
    all_regs = list(root.top.registers())
    context = {
        "regs": all_regs,
        "prefix": prefix
    }
    ofile_name = f'{ofolder}/{basename}_reg_defines.h'
    jinja_render = template.render(context)
    with open(ofile_name, mode="w", encoding="utf-8") as fid:
        fid.write(jinja_render)

    # JINJA render 2: Registers offsets
    template = jinja_env.get_template("offset_defines.h")
    context = {
        "regs": all_regs,
        "prefix": prefix
    }
    ofile_name = f'{ofolder}/{basename}_reg_offsets.h'
    jinja_render = template.render(context)
    with open(ofile_name, mode="w", encoding="utf-8") as fid:
        fid.write(jinja_render)


#---- HIERARCHY LISTENER ------------------------------------------------------

# A listener will print out the register model hierarchy
class MyModelPrintingListener(RDLListener):
    def __init__(self, ofile):
        self.indent = 0
        self.ofile = ofile
        self.fid = open(self.ofile, 'w')
        self.original_stdout = sys.stdout
        sys.stdout = self.fid

    def enter_Component(self, node):
        if not isinstance(node, FieldNode):
            print("\t"*self.indent, node.get_path_segment())
            self.indent += 1

    def enter_Field(self, node):
        # Print some stuff about the field
        bit_range_str = "[%d:%d]" % (node.high, node.low)
        sw_access_str = "sw=%s" % node.get_property('sw').name
        print("\t"*self.indent, bit_range_str, node.get_path_segment(), sw_access_str)

    def exit_Component(self, node):
        if not isinstance(node, FieldNode):
            self.indent -= 1

    def __del__(self):
        sys.stdout = self.original_stdout


#---- BODY --------------------------------------------------------------------

def main(rdl_file, tfolder, module_template, package_template, prefix):
    # Check input files exist
    if not(os.path.exists(rdl_file)):
        print(f'erro: File {rdl_file} not found')
        sys.exit(-65)
    
    # Create module name and package name from input RDL base
    basename = Path(rdl_file).stem
    module_name = basename.upper()

    package_name = module_name + "_pkg"
    package_name = package_name.lower()

    # Create RDL compiler instance
    rdlc = RDLCompiler()

    # Create RTL and HTML exporters
    sv_exporter = MyRegblockExporter(tfolder=tfolder)
    html_exporter = HTMLExporter()

    # Create walker for CSR tree
    walker = RDLWalker(unroll=True)

    try:
        # Compile RDL file
        rdlc.compile_file(rdl_file)
        
        # Elaborate the design, returns an instance of systemrdl.node.RootNode class
        root = rdlc.elaborate()

        # Create folders
        ofolder = f'grogu.gen/{basename.upper()}'

        # If folder already exists, create a copy but delete the previous copy
        ofolder_copy = f'{ofolder}.copy'
        shutil.rmtree(ofolder_copy, ignore_errors=True)
        if os.path.exists(ofolder):
            shutil.move(ofolder, ofolder_copy)
        os.makedirs(f'{ofolder}', exist_ok=True)
        print(f'info: Files will be written to \"{ofolder}\" folder')

        # Generate output products 1: Export RTL
        os.mkdir(f'{ofolder}/rtl')
        sv_exporter.export(root, f'{ofolder}/rtl', cpuif_cls=MyAXI4LiteInterface, module_name=module_name, package_name=package_name, module_template=module_template, package_template=package_template)

        # Generate output products 2: Export SystemVerilog headers
        CreateSVHeaders(root, f'{ofolder}/rtl', f'{module_name}', tfolder)

        # Generate output products 3: Export HTML
        os.mkdir(f'{ofolder}/html')
        html_exporter.export(root, f'{ofolder}/html')

        # Generate output products 4: Export C
        os.mkdir(f'{ofolder}/c')
        CreateCHeaders(root, f'{ofolder}/c', f'{package_name}', tfolder, prefix)

        # Generate output products 5: Export CSR tree
        listener = MyModelPrintingListener(f'{ofolder}/csr.tree')
        walker.walk(root, listener)      

    except RDLCompileError:
        # A compilation error occurred. Exit with error code
        sys.exit(1)

if __name__ == "__main__":
    # Define command line
    parser = argparse.ArgumentParser(prog=sys.argv[0], description='Control and Status Register tool')
    parser.add_argument('-r', '--rdl-file', type=str, required=True, help='Input RDL specification')
    parser.add_argument('-t', '--template-dir', type=str, required=True, help='Template files folder')
    parser.add_argument('-m', '--module-template', type=str, required=False, help='Module template file (default: module_tmpl.sv', default='module_tmpl.sv')
    parser.add_argument('-p', '--package-template', type=str, required=False, help='Package template file (default: package_tmpl.sv)', default='package_tmpl.sv')
    parser.add_argument('-x', '--prefix', type=str, required=False, help='Specify prefix for register names and defines for C headers', default='')

    # Parse and execute
    args = parser.parse_args()
    main(args.rdl_file, args.template_dir, args.module_template, args.package_template, args.prefix)
