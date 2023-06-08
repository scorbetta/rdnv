#pragma once

// Array registers are defined only once
{%- set var_ns = namespace() %}
{%- set var_ns.num_instances = 0 %}
{%- set var_ns.offset_0 = 0 %}
{% for reg in regs %}
    {%- for reg_inst in reg.unrolled() %}
        {%- if not(reg.is_array) %}
// {{prefix}}{{reg_inst.inst_name}} @+{{"0x{:x}".format(reg_inst.address_offset)}}
        {%- else %}
            {%- if reg_inst.current_idx[0] == 0 %}
                {#- Save number size of the array and starting offset of the batch #}
                {%- set var_ns.num_instances = reg_inst.array_dimensions[0] %}
                {%- set var_ns.offset_0 = reg_inst.address_offset %}
                {%- continue %}
            {%- elif reg_inst.current_idx[0] < var_ns.num_instances-1 %}
                {%- continue %}
            {%- else %}
// {{prefix}}{{reg_inst.inst_name}}[{{var_ns.num_instances}}] @+{{"0x{:x}".format(var_ns.offset_0)}}:{{"0x{:x}".format(reg_inst.address_offset)}}
            {%- endif %}
        {%- endif %}
typedef union {{prefix}}{{reg_inst.inst_name}}_reg_tag {
    struct {
        {%- for field in reg_inst.fields() %}
        uint32_t {{field.inst.inst_name}} : {{field.width}}; // @[{{field.msb}}:{{field.lsb}}]
        {%- endfor %}
    } fields;
    uint32_t value;
} {{prefix}}{{reg_inst.inst_name}}_reg_t;
    {%- endfor %}
{% endfor %}
