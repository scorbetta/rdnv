# NI Cores
This repository contains a collection of RTL design snippets, blocks, example designs, scripts and
design tools to foster design reuse.

# Database organization
The database is organized in *groups*. Groups determine the type of entries they store. For instance
the *synthesis* group contains RTL design files of self-consistent synthesizable digital blocks, while
the *tools* group contains design utilities.

Every group has its own layout. The following sections report notes on how contents are organized in
each group.

Please use existing folders as a starting point for new entries. Also, naming conventions apply.
Please stick to them whenever possible. This will keep the database consistent and easier to
consult.

## Synthesis and simuation groups
For each design block, source code is present and simulation code might be present as well. In
general, the following naming conventions apply to this group:

### Naming conventions
1. Names of SystemVerilog modules are all upper-case, as in `REGISTER`;
2. The name of the SystemVerilog top-level file is called accordingly, e.g. `REGISTER.sv`;
3. The top-level folder beneath either `syn` or `sim` follows the same naming convention, e.g.
`syn/REGISTER`;
4. SystemVerilog is the preferred HDL language to describe digital blocks.

### Layout
In general, given **$ROOT** as the block base folder:

- **\$ROOT/src** contains source code organized per HDL, e.g. **\$ROOT/src/sv** for SystemVerilog and
  **\$ROOT/src/vhdl** for VHDL;
- **\$ROOT/ootbtb** when present it contains code for the out-of-the-box test bench, meant to
  provide a template for design instance creation and an example of pins twiggling.

### OOTBTB
An OOTBTB can be found in many design blocks. This testbench is meant to be as simple as possible,
containing only tests of the very basic functionality of the referenced DUT. It also provides a good
starting point to set a more realistic testbench.

In general, the OOTBTB is accompanied with a few supporting files to launch the simulation:

- **Makefile** a link to the standard Makefile;
- **rtl_sources.list** a link to the list of sources that build up the design block;
- **ootbtb_sources.list** the list of sources that are required for the testbench to compile;
- **xsim.in** a link to the Xilinx simulation commands file. Please do not modify this file;
- **ootbtb.sv** the testbench file. The name is standard and shall not be modified, since the
  Makefile expects an *ootbtb* module from an *ootbtb.sv* design file.

Please notice that OOTBTB has been validated with Xilinx Vivado tools only. Third-party simulators
require tweaking the compilation and simulation scripts.

The compilation, elaboration and simulation phases are controlled by the local Makefile. As an
example, the following steps are all it takes to simulate the *ReadyValidFilterWithREn* design:

```cli
    ; Surf into synthesis group and then into desired folder
    $> cd synthesis/READY_VALID_FILTER_WITH_REN/ootbtb

    ; Compile, elaborate and simulate
    $> make sim

    ; Open waveforms
    $> make waves
```

## Example design group

## Tools group

## AXI4 group
