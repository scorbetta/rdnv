#!/usr/bin/python3

import json
import sys
import os

# Import entire tree
with open(sys.argv[1], 'r') as fid:
    data = json.load(fid)

# Top-level basename from input file
modname = os.path.basename(sys.argv[1])
# Remove  .json  extension
modname = modname[:-5]

# Prune it, and keep only few nodes
data = data['modules'][modname]

key_to_remove = [ 'attributes', 'cells', 'netnames' ]
for key in key_to_remove:
    data.pop(key, None)

# Save to same file
with open(sys.argv[1], 'w') as fod:
    json.dump(data, fod)
