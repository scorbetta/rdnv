# Generate the MarkDown files for the on-line documentation

import sys
import os
import shutil
from pathlib import Path
import jinja2 as jj
from jinja2 import Environment, FileSystemLoader
from dataclasses import dataclass, field
import glob
import json

@dataclass
class PortItem:
    name: str = '' # Name
    dir: str = ''  # Direction
    width: str = ''  # Width

@dataclass
class ParamItem:
    name: str = ''  # Name
    default: str = ''  # Default value

@dataclass
class CovItem:
    cov_file: str = 'N/A'  # Coverage file
    line_cov: int = 0 # Coverage result metrics
    toggle_cov: int = 0 # Toggle coverage, average between 0->1 and 1->0
    comb_cov: int = 0 # Comb coverage
    fsm_cov: int = 0 # FSM coverage, average between Arc and State

@dataclass
class Flavor:
    hdl: str = ''  # RTL language
    git_url: str = ''  # Full URL to file within git repo

@dataclass
class Module:
    name: str = ''  # Name
    type: str = '' # Either 'syn' or 'sim'
    brief: str = ''  # Quick description
    params: list() = field(default_factory=list) # List of parameters
    ports: list() = field(default_factory=list) # List of ports
    flavors: list() = field(default_factory=list) # List of flavors
    md_file: str = '' # .md file
    doc_path: str = ''  # Link to documentation page, relative to  tatooine/  
    cov: CovItem = field(default_factory=CovItem) # Coverage item
    git_url: str = '' # Full URL to rtl/ foldern within git repo

# Get background color for cell in coverage table according to its value
def get_bg_color(value):
    value_perc = value * 1.0 / 100

    # Knee point of the gradient
    knee = 0.75

    # Range in RGB sense
    rgb_lb = [ 224, 40, 40 ]
    rgb_knee = [ 245, 247, 40 ]
    rgb_ub = [ 129, 237, 40 ]

    if value_perc < knee:
        r = int(rgb_lb[0] + value_perc * (rgb_knee[0] - rgb_lb[0]))
        g = int(rgb_lb[1] + value_perc * (rgb_knee[1] - rgb_lb[1]))
        b = 40
    elif value_perc == knee:
        r = rgb_knee[0]
        g = rgb_knee[1]
        b = 40
    else:
        r = int(rgb_knee[0] + value_perc * (rgb_ub[0] - rgb_knee[0]))
        g = int(rgb_knee[1] + value_perc * (rgb_ub[1] - rgb_knee[1]))
        b = 40
 
    print(f'---> {value_perc} {r},{g},{b}')
    return '#{:02x}{:02x}{:02x}'.format(r,g,b)

# Generate parameters and ports list from JSON file
def get_specs(json_file):
    with open(json_file, 'r') as fid:
        data = json.load(fid)

    params = []
    if 'parameter_default_values' in data:
        for param in data['parameter_default_values']:
            temp = ParamItem(
                name = param,
                default = int(data['parameter_default_values'][param], 2)
            )
            params.append(temp)
 
    ports = []
    if 'ports' in data:
        for port in data['ports']:
            temp = PortItem(
                name = port,
            dir = data['ports'][port]['direction'],
                width = len(data['ports'][port]['bits'])
            )
            ports.append(temp)

    return params,ports

def render_tatooine(modules):
    # Jinja engine
    jj_env = jj.Environment(loader=jj.FileSystemLoader('./'))


    #---- Generate an .md file from template ------------------------------------------------------

    for module in modules:
        # Skip if MarkDown file already exists
        if os.path.isfile(f'{module.md_file}'):
            print(f'warn:    MarkDown file already present: {module.md_file}')
            continue

        # Else, create new one from template
        template = jj_env.get_template(f'scripts/{module.type}_module.template')

        # Fill in with actual data
        context = {
            "module": module
        }
        stream = template.render(context)

        # Stream out!
        print(f'info:    Creating MarkDown file: {module.md_file}')
        with open(f'{module.md_file}', 'w') as fid:
            fid.write(stream)


    #---- Generate table in tatooine's home page --------------------------------------------------

    # Sort by name
    modules.sort(key=lambda x: x.name, reverse=False)

    template = jj_env.get_template('scripts/tatooine.template')
    context = {
        "modules": list(modules),
        "get_bg_color": get_bg_color
    }
    stream = template.render(context)
    
    fname = 'docs/tatooine.md'
    print(f'info:    Creating MarkDown file {fname}')
    with open(fname, 'w') as fid:
        fid.write(stream) 

def render_dooku(root, rtllib_root, docs_root):
    pass

def render_dagobah(root, rtllib_root, docs_root):
    pass

# Parse tatooine library and create in-memory collection of modules
def create_db(rtllib_root, docs_root, git_url):
    all_modules = []

    # Search for synthesis-ready and simulation-only modules
    for mod_type in [ 'syn', 'sim']:
        print(f'info: Searching for {mod_type} modules')
        modules = glob.glob(f'{rtllib_root}/{mod_type}/*', recursive=True)

        for module in modules:
            new_module = Module()

            # Strip module name from full path
            modname = os.path.basename(module)
            new_module.name = modname
            new_module.type = mod_type
            new_module.git_url = f'{git_url}/tatooine/library/{mod_type}/{modname}/rtl'
            print(f'info: Found {mod_type} module {modname}')

            # Target MarkDown file
            new_module.md_file = f'docs/tatooine/{modname}.md'
            new_module.doc_path = f'{modname}'

            # Search for available JSON specs
            json_file = glob.glob(f'{rtllib_root}/{mod_type}/**/{modname}.json', recursive=True)
            if json_file == []:
                print(f'warn:    Unable to find JSON specs file')
                params = []
                ports = []
            else:
                print(f'warn:    Processing JSON specs file {json_file[0]}')
                params,ports = get_specs(json_file[0])

            new_module.params = params
            new_module.ports = ports

             # Search for flavors
            available_flavors = {}
            available_flavors['Verilog'] = 'v'
            available_flavors['SystemVerilog'] = 'sv'
            available_flavors['VHDL'] = 'vhd'

            for flavor_str in available_flavors:
                flavor_ext = available_flavors[flavor_str]
                retval = glob.glob(f'{rtllib_root}/{mod_type}/**/{modname}.{flavor_ext}', recursive=True)
                if retval != []:
                    new_module.flavors.append(
                        Flavor(
                            hdl = flavor_str,
                            git_url = f'{git_url}/tatooine/library/{mod_type}/{modname}/rtl/{flavor_ext}/{modname}.{flavor_ext}'
                        )
                    )
            
            # Search for coverage summary
            cov_summary = glob.glob(f'{rtllib_root}/{mod_type}/**/{modname}/ver/cov-report.metrics', recursive=True)
            if cov_summary != []:
                with open(cov_summary[0], 'r') as fid:
                    tokens = fid.read().split()

                # Sanity checks
                new_module.cov.cov_file = 'N/A'
                if len(tokens) == 6:
                    new_module.cov.line_cov = int(tokens[0][:-1])
                    new_module.cov.toggle_cov = int((int(tokens[1][:-1]) + int(tokens[2][:-1])) / 2)
                    new_module.cov.comb_cov = int(tokens[3][:-1])
                    new_module.cov.fsm_cov = int((int(tokens[4][:-1]) + int(tokens[5][:-1])) / 2)

            all_modules.append(new_module)

    return all_modules

def main():
    # Repo root
    root = os.popen('git rev-parse --show-toplevel').read().strip()
    # RTL library root
    rtllib_root = f'{root}/tatooine/library'
    # Docs root
    docs_root = f'{root}/dooku/docs'
    # Repo on github.com
    git_url = f'https://github.com/scorbetta/rdnv/tree/main'

    # Create modules db
    modules = create_db(rtllib_root, docs_root, git_url)

    # Render  tatooine  
    render_tatooine(modules)

    # Render  dooku  
    render_dooku(root, rtllib_root, docs_root)

    # Render  dagobah  
    render_dagobah(root, rtllib_root, docs_root)

if __name__ == "__main__":
    main()
