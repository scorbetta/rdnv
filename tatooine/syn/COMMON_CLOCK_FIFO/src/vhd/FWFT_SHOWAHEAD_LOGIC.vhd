library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL;

entity FWFT_SHOWAHEAD_LOGIC is
    generic 
    (
        data_width      : positive := 8
    );

    port 
    (
	rd_clk          : in  std_logic;
	async_rst      	: in  std_logic;
	sync_rst		: in  std_logic;
	rd_en           : in  std_logic;
	fifo_empty      : in  std_logic;
	ram_dout     	: in  std_logic_vector(data_width-1 DOWNTO 0);
	fifo_dout       : out std_logic_vector(data_width-1 DOWNTO 0);
	user_empty      : out std_logic; 
	empty_int		: out std_logic;
	user_valid		: out std_logic;
	ram_re        	: out std_logic;
	stage1_valid	: out std_logic;
	stage2_valid	: out std_logic
    );	
end entity;	

architecture FWFT_SHOWAHEAD_LOGIC of FWFT_SHOWAHEAD_LOGIC is
	
	signal data_reg 			: std_logic_vector(data_width -1 downto 0) := (others => '0');
	signal preloadstage1     	: std_logic := '0';
	signal preloadstage2     	: std_logic := '0';
	signal ram_valid_i       	: std_logic := '0';
	signal read_data_valid_i 	: std_logic := '0';
	signal ram_regout_en     	: std_logic := '0';
	signal ram_rd_en         	: std_logic := '0';
	signal empty_s				: std_logic;
	signal empty_i           	: std_logic := '1';
	signal empty_i_duplicate	: std_logic := '1';
	
	attribute syn_preserve 	: string;
	attribute syn_preserve of empty_i			: signal is "true";
	attribute syn_preserve of read_data_valid_i	: signal is "true";
	attribute syn_preserve of empty_i_duplicate	: signal is "true";
begin  
	
	preloadstage1 	<= ((not ram_valid_i) or preloadstage2) and (not fifo_empty);
	preloadstage2 	<= ram_valid_i and ((not read_data_valid_i) or rd_en);
	ram_regout_en 	<= preloadstage2;
	ram_rd_en     	<= (rd_en and (not fifo_empty)) or preloadstage1;
	empty_s			<= ((not ram_valid_i) and (not read_data_valid_i)) or ((not ram_valid_i) and rd_en);
	
	process (rd_clk, async_rst)
	begin  
		if async_rst = '1' then
			ram_valid_i 		<= '0';	
			read_data_valid_i 	<= '0';
			empty_i 			<= '1';
			data_reg 			<= (others => '0');
			empty_i_duplicate	<= '1';
			
		elsif rising_edge(rd_clk) then
			if sync_rst = '1' then
				ram_valid_i 		<= '0';	
				read_data_valid_i 	<= '0';
				empty_i 			<= '1';
				data_reg 			<= (others => '0');
				empty_i_duplicate	<= '1';
			else  
				if ram_regout_en = '1' then
					data_reg <= ram_dout;
				end if;
				
				if ram_rd_en = '1' then
					ram_valid_i <= '1';
				else
					if ram_regout_en = '1' then
						ram_valid_i <= '0';
					else
						ram_valid_i <= ram_valid_i;
					end if;
				end if;
				read_data_valid_i 	<= ram_valid_i or (read_data_valid_i and (not rd_en));
				empty_i  			<= empty_s;
				empty_i_duplicate	<= empty_s;
			end if;
		end if;
	end process; 
	
	user_valid		<= read_data_valid_i;
	user_empty 		<= empty_i;
	empty_int		<= empty_i_duplicate;
	ram_re  		<= ram_rd_en;
	fifo_dout  		<= data_reg; 
	stage1_valid  	<= ram_valid_i; 
	stage2_valid   	<= read_data_valid_i;
	
end architecture;
