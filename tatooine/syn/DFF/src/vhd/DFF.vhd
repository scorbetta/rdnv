library ieee;
use ieee.std_logic_1164.all;

-- A reusable D-type flop model
entity DFF is
    port (
        CLK     : in std_logic;
        RSTN    : in std_logic;
        D       : in std_logic;
        Q       : out std_logic
    );
end entity DFF;

architecture rtl of DFF is
begin
    process (CLK) is
        if RSTN = '0' then
            Q <= '0';
        else
            Q <= D;
        end if;
    end process;
end architecture rtl;
