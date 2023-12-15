import sys
import os
import shutil
from pathlib import Path
import jinja2 as jj
from jinja2 import Environment, FileSystemLoader
from dataclasses import dataclass
import glob
import json

# A set of utility C-like structures used to encapsulate info and render Jinja templates
@dataclass
class ModuleObject:
    # ---- MANDATORY FIELDS ----------------
    name: str # Module name
    doc_path: str # Link to documentation page
    lang: dict # Flavors

    # ---- OPTIONAL FIELDS -----------------
    brief: str = 'N/A' # Quick description
    cov_file: str = 'N/A' # Coverage file
    line_cov: str = '0%' # Coverage result metrics
    toggle_01_cov: str = '0%' # Toggle/0->1 coverage
    toggle_10_cov: str = '0%' # Toggle/1->0 coverage
    comb_cov: str = '0%' # Comb coverage
    fsm_arc_cov: str = '0%' # FSM/Arc coverage
    fsm_state_cov: str = '0%' # FSM/State coverage

@dataclass
class PortItem:
    name: str # Name
    dir: str # Direction
    width: str # Width

@dataclass
class ParamItem:
    name: str # Name
    default: str # Default value

# MarkDown/Jinja interface point
def define_env(env):
    # Relative folders are relative to  mkdocs.yml  location. Absolute folders are rooted in the
    # build  output folder
    templates_dir = './templates'
    rtl_syn_dir = '../tatooine/library/syn'
    src_sim_dir = '../tatooine/library/sim'
    
    # Jinja engine
    jj_env = jj.Environment(loader=jj.FileSystemLoader(templates_dir))

    # Render synthesis table
    @env.macro
    def tatooine_render_syn_table(url_git):
        # Search for synthesis-ready modules. There must exist a top-level file with the same name
        # of the containing folder
        syn_modules = []
        for modname in os.listdir(rtl_syn_dir):
            # Search for available flavors
            flavors = glob.glob(f'{rtl_syn_dir}/**/{modname}.*', recursive=True)

            # Search for coverage report
            cov_report = glob.glob(f'{rtl_syn_dir}/{modname}/ver/cov-report.details', recursive=True)
            cov_summary = glob.glob(f'{rtl_syn_dir}/{modname}/ver/cov-report.sumary', recursive=True)

            hdls = {}
            key = ''
            for flavor in flavors:
                if '.v' in flavor:
                    key = 'Verilog'
                if '.sv' in flavor:
                    key = 'SystemVerilog'
                if '.vhd' in flavor:
                    key = 'VHDL'
                hdls[key] = f'{url_git}/{flavor}'

            temp = ModuleObject(
                name = f'{modname}',
                doc_path = f'/tatooine/library/syn/{modname}',
                lang = hdls,
                cov_file = cov_report
                #brief = 'TBD',
                #line_cov = 'TBD',
                #toggle_01_cov = 'TBD',
                #toggle_10_cov = 'TBD',
                #comb_cov = 'TBD',
                #fsm_arc_cov = 'TBD',
                #fsm_state_cov = 'TBD'
            )

            syn_modules.append(temp)

        # Apply
        template = jj_env.get_template('tatooine_syn_table.template')
        context = {
            "syn_modules": syn_modules
        }
        stream = template.stream(context)

        # Stream out!
        return ''.join(stream)

    # Render simulation table
    @env.macro
    def tatooine_render_sim_table(url_git):
        # Search for simulation-only modules
        sim_modules = []
        for modname in os.listdir(src_sim_dir):
            # Search for available flavors
            flavors = glob.glob(f'{src_sim_dir}/**/{modname}.*', recursive=True)

            hdls = {}
            key = ''
            for flavor in flavors:
                if '.v' in flavor:
                    key = 'Verilog'
                if '.sv' in flavor:
                    key = 'SystemVerilog'
                if '.vhd' in flavor:
                    key = 'VHDL'
                hdls[key] = f'{url_git}/{flavor}'

            temp = ModuleObject(
                name = f'{modname}',
                doc_path = f'/tatooine/library/sim/{modname}',
                lang = hdls,
                brief = 'TBD'
            )

            sim_modules.append(temp)

        # Apply
        template = jj_env.get_template('tatooine_sim_table.template')
        context = {
            "sim_modules": sim_modules
        }
        stream = template.stream(context)

        # Stream out!
        return ''.join(stream)

    # Render module ports table
    @env.macro
    def tatooine_render_ports_table(modname):
        # Search for available JSON specs
        json_file = glob.glob(f'{rtl_syn_dir}/**/{modname}.json', recursive=True)
        if json_file == []:
            return ''

        with open(json_file[0], 'r') as fid:
            data = json.load(fid)

        ports = []
        for port in data['ports']:
            temp = PortItem(
                name = port,
                dir = data['ports'][port]['direction'],
                width = len(data['ports'][port]['bits'])
            )
            ports.append(temp)

        template = jj_env.get_template('module_generic_ports_table.template')
        context = {
            "ports": ports
        }
        stream = template.stream(context)
        return ''.join(stream)

    # Render module parameters table
    @env.macro
    def tatooine_render_params_table(modname):
        # Search for available JSON specs
        json_file = glob.glob(f'{rtl_syn_dir}/**/{modname}.json', recursive=True)
        if json_file == []:
            return ''

        with open(json_file[0], 'r') as fid:
            data = json.load(fid)

        params = []
        for param in data['parameter_default_values']:
            temp = ParamItem(
                name = param,
                default = int(data['parameter_default_values'][param], 2)
            )
            params.append(temp)

        template = jj_env.get_template('module_generic_params_table.template')
        context = {
            "params": params
        }
        stream = template.stream(context)
        return ''.join(stream)

    # Render coverage table
    @env.macro
    def tatooine_render_coverage_table(modname):
        return 'Coverage not available.'