library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Gaussian numbers are generated leveraging the central limit theorem
entity random_gaussian is
    generic (
        OUT_WIDTH : integer := 12
    );
    
    port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        random  : out  STD_LOGIC_VECTOR(OUT_WIDTH-1 downto 0)
    );
end random_gaussian;

architecture Behavioral of random_gaussian is
    -- Shitty VHDL here...
    component random_uniform is 
        generic (
            SEED        : STD_LOGIC_VECTOR(30 downto 0);
            OUT_WIDTH   : integer
        );
        port (
            clk     : in  STD_LOGIC;
            random  : out  STD_LOGIC_VECTOR (OUT_WIDTH-1 downto 0);
            reset   : in  STD_LOGIC
        );
    end component random_uniform;

    component adder_signed is
        generic (
            IN_WIDTH : integer
        );
        
        port (
            clk : in  STD_LOGIC;
            a   : in  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0);
            b   : in  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0);
            r   : out  STD_LOGIC_VECTOR(IN_WIDTH-1 downto 0)
        );      
    end component adder_signed;

    -- Connections
    signal uniform1 : std_logic_vector(OUT_WIDTH-2-1 downto 0);
    signal uniform2 : std_logic_vector(OUT_WIDTH-2-1 downto 0);
    signal uniform3 : std_logic_vector(OUT_WIDTH-2-1 downto 0);
    signal uniform4 : std_logic_vector(OUT_WIDTH-2-1 downto 0);
    signal adder_r12 : std_logic_vector(OUT_WIDTH-1 downto 0);
    signal adder_r34 : std_logic_vector(OUT_WIDTH-1 downto 0);
    signal adder_r : std_logic_vector(OUT_WIDTH-1 downto 0);
    
    -- Sign extension utility
    function SignExtend (
            DATA_IN_WIDTH   : integer;
            DATA_OUT_WIDTH  : integer;
            data_in         : std_logic_vector
        ) return std_logic_vector is
        
        variable temp : std_logic_vector(DATA_OUT_WIDTH-1 downto 0);
    begin
        if(DATA_IN_WIDTH >= DATA_OUT_WIDTH) then
            -- No need to sign extend, or error
            temp := data_in(DATA_OUT_WIDTH-1 downto 0);           
        else
            -- Sign extend
            temp(DATA_IN_WIDTH-1 downto 0) := data_in;
            for bdx in DATA_IN_WIDTH to DATA_OUT_WIDTH-1 loop
                temp(bdx) := data_in(DATA_IN_WIDTH-1);
            end loop;
        end if;
        
        return temp;
    end function SignExtend;
begin
    -- Create a number of instances of the Uniform generator. These constitute the base from which a
    -- Normally distributed number is generated, summing 'em up. The central limit theorem states 
    -- that summing up a 'sufficiently' high number of independent random variables, they tend to a
    -- Normally distributed random variable. Four seems enough for our case. With less than 4 samples
    -- the distribution tends to have a triangular shape, with more than four samples the design 
    -- starts to become complex
    unif1: random_uniform 
        generic map (
            SEED        => std_logic_vector(to_unsigned(697757461,31)),
            OUT_WIDTH   => OUT_WIDTH-2
        )
        port map (
            clk     => clk,
            random  => uniform1,
            reset   => reset
        );

    unif2: random_uniform 
        generic map (
            SEED        => std_logic_vector(to_unsigned(1885540239,31)),
            OUT_WIDTH   => OUT_WIDTH-2
        )
        port map (
            clk     => clk,
            random  => uniform2,
            reset   => reset
        );

    unif3: random_uniform 
        generic map (
            SEED        => std_logic_vector(to_unsigned(1505946904,31)),
            OUT_WIDTH   => OUT_WIDTH-2
        )
        port map (
            clk     => clk,
            random  => uniform3,
            reset   => reset
        );

    unif4: random_uniform 
        generic map (
            SEED        => std_logic_vector(to_unsigned(2693445,31)),
            OUT_WIDTH   => OUT_WIDTH-2
        )
        port map (
            clk     => clk,
            random  => uniform4,
            reset   => reset
        );

    -- Multiple adders help sticking into one clock cycle
    adder12 : adder_signed
        generic map (
            IN_WIDTH => OUT_WIDTH
        )
        PORT MAP (
            a   => SignExtend(OUT_WIDTH-2, OUT_WIDTH, uniform1),
            b   => SignExtend(OUT_WIDTH-2, OUT_WIDTH, uniform2),
            clk => clk,
            r   => adder_r12
        );

    adder34 : adder_signed
        generic map (
            IN_WIDTH => OUT_WIDTH
        )
        PORT MAP (
            a   => SignExtend(OUT_WIDTH-2, OUT_WIDTH, uniform3),
            b   => SignExtend(OUT_WIDTH-2, OUT_WIDTH, uniform4),
            clk => clk,
            r   => adder_r34
        );

    adderout : adder_signed
        generic map (
            IN_WIDTH => OUT_WIDTH
        )
        PORT MAP (
            a   => adder_r12,
            b   => adder_r34,
            clk => clk,
            r   => adder_r
        );

    -- Register output
    process(clk, reset) begin
        if rising_edge(clk) then
            if reset = '1' then
                random <= (others => '0');
            else
                random <= adder_r;
            end if;
        end if;
    end process;
end Behavioral;
