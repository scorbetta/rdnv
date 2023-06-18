`ifndef __{{module_name}}_SVH__
`define __{{module_name}}_SVH__
{% for reg in regs %}
    {%- for reg_inst in reg.unrolled() %}
        {%- if reg.is_array %}
`define {{reg_inst.inst_name}}_{{reg_inst.current_idx[0]}}_OFFSET {{"16'h{:x}".format(reg_inst.address_offset)}}
        {%- else %}
`define {{reg_inst.inst_name}}_OFFSET {{"16'h{:x}".format(reg_inst.address_offset)}}
        {%- endif %}
    {%- endfor %}
{%- endfor %}

`endif /* __{{module_name}}_SVH__ */