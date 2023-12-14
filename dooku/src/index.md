The `rdnv` repository is the one-stop shop for reusable resources for your research, design and
verification tasks in the digital electronics domain.

The author puts his best effort in delivering pre-verified resources; for instance, most of the RTL
modules are either FPGA or ASIC proven.  However, this is a continuous work-in-progress, so any
comment, request or criticism can be easily addressed to the author himself.

The repository is organized in *sections*. Groups Every section is reserved to a specific type of
resources. Every section is documented in this mini-site. Readers use the menu on the top to
navigate to every section of interest. Sections are described next.

`dooku`

The documentation system. This section includes the source code and tools to generate this
mini-site, and the `grogu` documentation engine for RTL designs.

`tatooine`

The RTL library of verified components. Synthesis-ready and simulation-only modules are regrouped.

`organa`

The verification environment for the `tatooine` library. The verification environment is based on
[`cocotb`](https://www.cocotb.org/) and tools from [`YosysHQ`](https://github.com/YosysHQ).

`the order`

A set of rules to deliver high-quality RTL designs and readable source code. Rationale (cit.):
"*Code is read much more often than it is written*".
