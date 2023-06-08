#pragma once

// Write-only registers
{%- for reg in regs %}
    {%- if reg.has_sw_writable and not(reg.has_sw_readable) %}
        {%- for reg_inst in reg.unrolled() %}
            {%- if reg.is_array %}
#define {{prefix}}{{reg_inst.inst_name}}_{{reg_inst.current_idx[0]}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- else %}
#define {{prefix}}{{reg_inst.inst_name}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- endif %}
        {%- endfor %}
    {%- endif %}
{%- endfor %}

// Read-only registers
{%- for reg in regs %}
    {%- if reg.has_sw_readable and not(reg.has_sw_writable) %}
        {%- for reg_inst in reg.unrolled() %}
            {%- if reg.is_array %}
#define {{prefix}}{{reg_inst.inst_name}}_{{reg_inst.current_idx[0]}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- else %}
#define {{prefix}}{{reg_inst.inst_name}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- endif %}
        {%- endfor %}
    {%- endif %}
{%- endfor %}

// Read/Write registers
{%- for reg in regs %}
    {%- if reg.has_sw_readable and reg.has_sw_writable %}
        {%- for reg_inst in reg.unrolled() %}
            {%- if reg.is_array %}
#define {{prefix}}{{reg_inst.inst_name}}_{{reg_inst.current_idx[0]}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- else %}
#define {{prefix}}{{reg_inst.inst_name}}_OFFSET {{"0x{:x}".format(reg_inst.address_offset)}}
            {%- endif %}
        {%- endfor %}
    {%- endif %}
{%- endfor %}
