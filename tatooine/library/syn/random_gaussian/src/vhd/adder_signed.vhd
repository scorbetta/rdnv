library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_signed is
    generic (
        IN_WIDTH : integer := 10
    );
    
    Port (
        clk : in  STD_LOGIC;
        a   : in  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0);
        b   : in  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0);
        r   : out  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0)
    );      
end adder_signed;

architecture Behavioral of adder_signed is
    signal r_next : std_logic_vector(IN_WIDTH-1 downto 0) := (others => '0');
begin
    process(clk) begin
        if rising_edge(clk) then
            r <= r_next;
            r_next <= std_logic_vector(signed(a)+signed(b));
        end if;
    end process;
end Behavioral;