`dagobah` contains scripts and utilities of general use.

## `rdnv` configuration
To be able to use the resources of the `rdnv` repository, the following lines must be added to
`~/.bashrc`:

```bash
# Absolute location of cloned rdnv.git repo
export RDNV_ROOT=/home/user/rdnv
export TATOOINE_ROOT=${RDNV_ROOT}/tatooine
export ORGANA_ROOT=${RDNV_ROOT}/organa
export DAGOBAH_ROOT=${RDNV_ROOT}/dagobah
export PYTHONPATH="${PYTHONPATH}:${TATOOINE_ROOT}/cocotb"
```

## `rtlvim` plugin
The author's preferred and only editor is [vim](https://www.vim.org/). `rtlvim` is a plugin that
helps RTL designers.

By using this plugin, the designer can:

- Preview the definition of the module whose name is under the cursor with one click;
- Create the skeleton of an instance of the module whose name is under the cursor;
- Paste the instance skeleton undert the cursor.

The plugin is managed through the [`vim-plug`](https://github.com/junegunn/vim-plug) plugin manager.
Configuration is straightforward, just add the following line within the `plug#begin`/`plug#end`
pairs in `~/.vimrc`:

```
Plug '/home/user/rdnv/dagobah/rtlvim'
```

By pressing `<F2>`, the entire *WORD* under the cursor is interpreted as an RTL module. The plugin
will first search for a module named *WORD.[v|sv|vhd|vh|svh]* located anywhere beneath the
`${TATOOINE_ROOT}/library` folder. If a single file is found, a preview is open in a separate
window; if more than one files is found, then a menu appears and the user can choose which one to
open; if none, nothing happens. A second press on `<F2>` closes the preview.

In the following example, `<F2>` is hit just above the `RW_REG` module. `RW_REG` has two flavors and
the user chosses the SystemVerilog version to be displayed.

![Hitting <F2> over RW_REG](./dagobah/rtlvim_example_1.png)

![Choosing SystemVerilog flavor](./dagobah/rtlvim_example_2.png)

By pressing `<F3>`, the same *WORD* is used to search for *WORD.json* file, which contains the
interface definition of the module *WORD.[v|sv|vhd]*. If found, an instance of the selected module
is created and copied into register `z`. If not found, please refer to [organa]('../organa').

The plugin engine recognizes the target HDL language from the extension of the file currently opened
in the buffer. It then uses that extension to create the proper instance. Three languages are
supported: Verilog (`*.v` files), SystemVerilog (`*.sv`) and VHDL (`*.vhd`).

The instance can then be pasted under the cursor with `<F4>`. The following screenshots shows a new
instance of `RW_REG` named `RW_REG_0` is copied.

![Hitting <F3> over RW_REG then <F4>](./dagobah/rtlvim_example_3.png)

Please notice that if no *WORD.json* file is found, the `z` register is *not* overwritten. This
means that any hit on `<F4>` will paste the previous match, if any.
