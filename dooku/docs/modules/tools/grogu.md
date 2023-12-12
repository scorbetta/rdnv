# GROGU

## Features
GROGU is a tool to design Control and Status Register (CSR) blocks for memory-mapped systems hosting
a microprocessor. The tool is based on the SystemRDL design language to fully specify register maps,
registers and fields.

## Requirements
Python 3.10.6 with packages:

- SystemRDL compiler: https://systemrdl-compiler.readthedocs.io/en/stable/
- PeakRDL-regblock: https://github.com/SystemRDL/PeakRDL-regblock
- PeakRDL-html: https://github.com/SystemRDL/PeakRDL-html/blob/main/README.md
- JINJA: https://jinja.palletsprojects.com/en/3.1.x/

## Principles of operation
In general terms, JINJA processes template files with user-defined values. Templates provide the
source files that will be used to generate the output file: they contain placeholders that will be
expanded to user-defined values. This process will generate (*render* in JINJA terms) the output
file, representing a particular instance of the source template case. Template files contain
mixed-language code: both the target language and JINJA markdowns are present. The output file, on
the other hand, is strictly free of JINJA markdowns.

Based on JINJA, `grogu` generates:

- SystemVerilog files with synthesizable RTL code of the register map containing all registers,
  Write and Read decoders;
- C files containing register contents and offset definitions to be used during Software
  development;
- HTML files containing the documentation of each register and an utility to decode fields from
  register value or encode register from fields values.

`grogu` requires:

- Register map specification, one or more `.rdl` files written in SystemRDL, containing the register
  map configuration (address width, data width, address type, interface type) and configuration of
  each register (width, default value, number of fields, fields layout);
- A folder containing templates files.

In the provided example the template folder contains templates for SystemVerilog and C outputs. HTML
output is generated using the built-in functionality of `peakrdl-html' library.

## Example
The example files are located in `example_files`:

- `common.rdl`, Common definitions for other RDL files (uses SystemVerilog-like syntax);
- `example_regs.rdl`, Definition of registers in the register map;
- `example_regmap.rdl`, Register map top-level definition;
- `reg_defines.h`, Template C file for union-based registers definition for Software development;
- `offset_defines.h`, Template C file for offsets definition.

The following command will generate all output products in the `grogu.gen` folder:

```cli
; Run grogu
$> ./grogu.py -r example_files/example_regmap.rdl -t example_files
```

The output folder `grogu.gen` shall look similar to the following:

```cli
grogu.gen/
└── EXAMPLE_REGMAP
    ├── c
    │   ├── example_regmap_pkg_reg_defines.h
    │   └── example_regmap_pkg_reg_offsets.h
    ├── csr.tree
    ├── html
    │   ├── index.html
    └── rtl
        ├── EXAMPLE_REGMAP.sv
        └── example_regmap_pkg.sv
```

## References
- SystemRDL 2.0 language standard: https://www.accellera.org/downloads/standards/systemrdl
- SystemRDL toolchain: https://github.com/SystemRDL
- JINJA example: https://realpython.com/primer-on-jinja-templating/
