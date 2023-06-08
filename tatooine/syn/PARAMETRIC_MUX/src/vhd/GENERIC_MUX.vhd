-- Verbose VHDL
library ieee;
use ieee.std_logic_1164.all;

package my_pkg is
    type bus_array is array(natural range <>) of std_logic_vector;
end package;

package body my_pkg is
end package body;

library ieee;
use ieee.std_logic_1164.all;
use work.my_pkg;

entity GENERIC_MUX is
    generic(
        -- Input and output data width
        DATA_WIDTH  : natural;
        -- Number of inputs
        NUM_INPUTS  : natural
    );

    port(
        BUS_IN  : in my_pkg.bus_array(0 to NUM_INPUTS-1)(DATA_WIDTH-1 downto 0);
        SEL_IN  : in natural range 0 to NUM_INPUTS-1;
        BUS_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture Behavioral of GENERIC_MUX is
begin
    BUS_OUT <= BUS_IN(SEL_IN);
end architecture;

