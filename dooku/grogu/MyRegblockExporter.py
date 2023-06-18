# The  MyRegblockExporter  class has been derived from the  RegblockExporter  class released within
# the PeakRDL Python package. The original code is very bad written, with too many constant paths
# that cannot be overwritten. This top-level has been improved:
#   1. The module and package templates are now an argument
#   2. The code has been reduced in its most important parts

# Standard imports
import os
from typing import Union, Any, Type, Optional

# JINJA imports
import jinja2 as jj
from systemrdl.node import AddrmapNode, RootNode

# Import everything from PeakRDL to be compatible with existing code
from peakrdl_regblock import *
from peakrdl_regblock.addr_decode import AddressDecode
from peakrdl_regblock.field_logic import FieldLogic
from peakrdl_regblock.dereferencer import Dereferencer
from peakrdl_regblock.readback import Readback
from peakrdl_regblock.identifier_filter import kw_filter as kwf
from peakrdl_regblock.utils import get_always_ff_event
from peakrdl_regblock.scan_design import DesignScanner
from peakrdl_regblock.validate_design import DesignValidator
from peakrdl_regblock.cpuif import CpuifBase
from peakrdl_regblock.cpuif.apb4 import APB4_Cpuif
from peakrdl_regblock.hwif import Hwif

# The class to export SystemVerilog RTL design files
class MyRegblockExporter:
    def __init__(self, **kwargs: Any) -> None:
        self.top_node = None
        self.hwif = None
        self.cpuif = None
        self.address_decode = AddressDecode(self)
        self.field_logic = FieldLogic(self)
        self.readback = None
        self.write_buffering = None
        self.read_buffering = None
        self.dereferencer = Dereferencer(self)
        self.min_read_latency = 0
        self.min_write_latency = 0
        self.tfolder = kwargs.pop("tfolder", ".")
        self.jj_env = jj.Environment(loader=jj.FileSystemLoader(self.tfolder))

    def export(self, node: Union[RootNode, AddrmapNode], output_dir:str, **kwargs: Any) -> None:
        """
        Parameters
        ----------
        node: AddrmapNode
            Top-level SystemRDL node to export.
        output_dir: str
            Path to the output directory where generated SystemVerilog will be written.
            Output includes two files: a module definition and package definition.
        cpuif_cls: :class:`peakrdl_regblock.cpuif.CpuifBase`
            Specify the class type that implements the CPU interface of your choice.
            Defaults to AMBA APB4.
        module_name: str
            Override the SystemVerilog module name. By default, the module name
            is the top-level node's name.
        package_name: str
            Override the SystemVerilog package name. By default, the package name
            is the top-level node's name with a "_pkg" suffix.
        reuse_hwif_typedefs: bool
            By default, the exporter will attempt to re-use hwif struct definitions for
            nodes that are equivalent. This allows for better modularity and type reuse.
            Struct type names are derived using the SystemRDL component's type
            name and declared lexical scope path.

            If this is not desireable, override this parameter to ``False`` and structs
            will be generated more naively using their hierarchical paths.
        retime_read_fanin: bool
            Set this to ``True`` to enable additional read path retiming.
            For large register blocks that operate at demanding clock rates, this
            may be necessary in order to manage large readback fan-in.

            The retiming flop stage is automatically placed in the most optimal point in the
            readback path so that logic-levels and fanin are minimized.

            Enabling this option will increase read transfer latency by 1 clock cycle.
        retime_read_response: bool
            Set this to ``True`` to enable an additional retiming flop stage between
            the readback mux and the CPU interface response logic.
            This option may be beneficial for some CPU interfaces that implement the
            response logic fully combinationally. Enabling this stage can better
            isolate timing paths in the register file from the rest of your system.

            Enabling this when using CPU interfaces that already implement the
            response path sequentially may not result in any meaningful timing improvement.

            Enabling this option will increase read transfer latency by 1 clock cycle.
        address_width: int
            Override the CPU interface's address width. By default, address width
            is sized to the contents of the regblock.
        """
        # If it is the root node, skip to top addrmap
        if isinstance(node, RootNode):
            self.top_node = node.top
        else:
            self.top_node = node
        msg = self.top_node.env.msg


        cpuif_cls = kwargs.pop("cpuif_cls", None) or APB4_Cpuif # type: Type[CpuifBase]
        module_name = kwargs.pop("module_name", None) or kwf(self.top_node.inst_name) # type: str
        package_name = kwargs.pop("package_name", None) or (module_name + "_pkg") # type: str
        reuse_hwif_typedefs = kwargs.pop("reuse_hwif_typedefs", True) # type: bool
        user_addr_width = kwargs.pop("address_width", None) # type: Optional[int]
        module_template = kwargs.pop("module_template", None)
        package_template = kwargs.pop("package_template", None)

        # Pipelining options
        retime_read_fanin = kwargs.pop("retime_read_fanin", False) # type: bool
        retime_read_response = kwargs.pop("retime_read_response", True) # type: bool

        # Check for stray kwargs
        if kwargs:
            raise TypeError(f"got an unexpected keyword argument '{list(kwargs.keys())[0]}'")

        self.min_read_latency = 0
        self.min_write_latency = 0
        if retime_read_fanin:
            self.min_read_latency += 1
        if retime_read_response:
            self.min_read_latency += 1

        addr_width = self.top_node.size.bit_length()
        if user_addr_width is not None:
            if user_addr_width < addr_width:
                msg.fatal(f"User-specified address width shall be greater than or equal to {addr_width}.")
            addr_width = user_addr_width

        # Scan the design for pre-export information
        scanner = DesignScanner(self)
        scanner.do_scan()

        # Construct exporter components
        self.cpuif = cpuif_cls(
            self,
            cpuif_reset=self.top_node.cpuif_reset,
            data_width=scanner.cpuif_data_width,
            addr_width=addr_width
        )
        self.hwif = Hwif(
            self,
            package_name=package_name,
            in_hier_signal_paths=scanner.in_hier_signal_paths,
            out_of_hier_signals=scanner.out_of_hier_signals,
            reuse_typedefs=reuse_hwif_typedefs,
        )

        # Validate that there are no unsupported constructs
        validator = DesignValidator(self)
        validator.do_validate()

        # Reuse list of registers in multipe places
        all_regs = list(self.top_node.registers())

        # Build Jinja template context
        context = {
            "regs" : all_regs,
            "module_name": module_name,
            "cpuif": self.cpuif,
            "hwif": self.hwif,
            "field_logic": self.field_logic,
            "readback": self.readback,
            "package_name" : package_name
        }

        # Write out design
        package_file_path = os.path.join(output_dir, package_name + ".sv")
        #template = self.jj_env.get_template("package_tmpl.sv")
        template = self.jj_env.get_template(package_template)
        stream = template.stream(context)
        stream.dump(package_file_path)

        module_file_path = os.path.join(output_dir, module_name + ".sv")
        #template = self.jj_env.get_template("module_tmpl.sv")
        template = self.jj_env.get_template(module_template)
        stream = template.stream(context)
        stream.dump(module_file_path)
