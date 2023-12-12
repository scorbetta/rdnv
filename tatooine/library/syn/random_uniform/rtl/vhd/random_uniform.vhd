library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uniform numbers are generated through an LFSR. This code has been derived from:
-- https://hforsten.com/generating-normally-distributed-pseudorandom-numbers-on-a-fpga.html
entity random_uniform is
    generic (
        SEED        : STD_LOGIC_VECTOR(30 downto 0) := (others => '0');
        OUT_WIDTH   : integer := 10
    );

    port (
        clk     : in  STD_LOGIC;
        random  : out  STD_LOGIC_VECTOR(OUT_WIDTH-1 downto 0);
        reset   : in  STD_LOGIC
    );
end random_uniform;

architecture Behavioral of random_uniform is
    signal rand : std_logic_vector(30 downto 0);
    signal feedback : std_logic;
begin

    feedback <= not((rand(0) xor rand(3)));

    process(clk,reset) begin
        if reset = '1' then
            rand <= SEED;
        elsif rising_edge(clk) then
            rand <= feedback&rand(30 downto 1);
        end if;
    end process;

    random <= rand(OUT_WIDTH-1 downto 0);
end Behavioral;
