library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.MATH_REAL.all;

entity COMMON_CLOCK_FIFO_GOLDEN is	
	generic
		( 
		-----------------------
		-- Define Fifo Depth. If depth is not specified as power of 2, it is automatically rounded to nearest and greater power of 2.
		-- Minimum depth is 8.
		----------------------
		Fifo_depth					: positive := 8;
		
		-----------------------
		-- Data Bus width
		-----------------------
		data_width					: natural  := 32; 
		
		-----------------------
		-- FWFT_ShowAhead = true, first word appears at the output without asserting read enable
		-- FWFT_ShowAhead = false, a standard Fifo will be generated.
		-----------------------
		FWFT_ShowAhead				: boolean  := false;
		
		-------------------------------------------------------------------------------------------------------
		-- Specify the Programmable full assertion. This value MUST be programmed between 4 and Fifo_depth - 4
		-- This flag is asserted high when data_count is equal or greater than Prog_Full_ThresHold.
		-------------------------------------------------------------------------------------------------------
		Prog_Full_ThresHold			: positive  := 4; 
		
		-------------------------------------------------------------------------------------------------------
		-- Specify the Programmable Empty assertion. This value MUST be programmed between 4 and Fifo_depth - 4
		-- This flag is asserted low when data_count is greater than Prog_Empty_ThresHold
		-------------------------------------------------------------------------------------------------------
		Prog_Empty_ThresHold		: positive := 4
		);
	port
		(
		-- Async Reset Active High. Connect to GND if unused.
		Async_rst		: in std_logic;
		
		 -- Sync Reset Active High. Connect to GND if unused.
		Sync_rst		: in std_logic;	
		
		-- Clock 
		clk 			: in std_logic;								   
		
		-- Write enable (Assert High)
		we  			: in std_logic;
		
		-- Data in
		din				: in std_logic_vector(data_width - 1 downto 0);	
		
		-- Full flag. (Assert High)
		full			: out std_logic;
		
		-- Programmable Full flag. (Assert High)
		prog_full		: out std_logic; 								
		
		-- Valid signal (Asset high)
		valid			: out std_logic;
		
		-- Read enable	(Assert High)	
		re  			: in std_logic;	
		
		-- Data out
		dout			: out std_logic_vector(data_width - 1 downto 0);
		
		-- Empty flag. (Assert High)
		empty			: out std_logic;
		
		-- Programmable Empty flag. (Assert High)
		prog_empty		: out std_logic;
		
		-- Number of elements in FIFO
		data_count		: out std_logic_vector(31 downto 0)  			
		);
end entity;

architecture COMMON_CLOCK_FIFO_GOLDEN of COMMON_CLOCK_FIFO_GOLDEN is
	
	constant Fifo_depth_min	: positive := 8; 
	constant addr_width		: positive := positive(ceil(LOG2( REALMAX(real(Fifo_depth_min), real(Fifo_depth)))));
	
	type dual_port_ram_type is array (0 to (2**addr_width - 1)) of std_logic_vector(data_width - 1 downto 0);
	signal dual_port_ram 	: dual_port_ram_type := (others => (others => '0')); 
	
	component FWFT_ShowAhead_Logic_Golden is
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
	end component;	
	
	signal rst_q0 				: STD_LOGIC := '1';
	signal rst_q1 				: STD_LOGIC := '1';
	signal rst_q2				: std_logic := '1';
	signal async_rst_int		: std_logic;
	signal disable_fifo			: std_logic;
	signal we_masked			: std_logic;
	signal re_masked			: std_logic;
	
	signal write_allow			: std_logic;
	signal write_pointer		: std_logic_vector(addr_width downto 0) := (others => '0');	
	signal next_write_pointer	: std_logic_vector(addr_width downto 0);
	signal write_pointer_actual : std_logic_vector(addr_width downto 0); 
	signal full_comp1			: std_logic;
	signal full_comp0			: std_logic;
	signal prog_full_comb		: std_logic;
	signal going_full			: std_logic;
	signal ram_full_comb		: std_logic;
	signal full_i				: std_logic := '1';
	signal prog_full_i			: std_logic := '1';
	signal read_allow			: std_logic;
	signal read_pointer			: std_logic_vector(addr_width downto 0) := (others => '0');
	signal next_read_pointer	: std_logic_vector(addr_width downto 0);
	signal read_pointer_actual : std_logic_vector(addr_width downto 0);
	signal empty_comp1			: std_logic;
	signal empty_comp0			: std_logic;
	signal prog_empty_comb		: std_logic;
	signal going_empty			: std_logic;
	signal ram_empty_comb		: std_logic;
	signal prog_empty_i			: std_logic := '1';
	signal empty_i				: std_logic := '1';	
	signal valid_i				: std_logic := '0';	
	
	signal diff_pointer			: std_logic_vector(addr_width downto 0);
	signal data_counter			: std_logic_vector(addr_width downto 0) := (others => '0');
	signal we_porta				: std_logic;
	signal addra				: std_logic_vector(addr_width - 1 downto 0);	
	signal dina					: std_logic_vector(data_width - 1 downto 0);
	signal ce_portb				: std_logic;
	signal addrb				: std_logic_vector(addr_width - 1 downto 0);
	signal doutb				: std_logic_vector(data_width - 1 downto 0) := (others => '0');
	
begin
	
	----------------------------
	----- RESET GENERATION -----
	----------------------------
	
	process (Async_rst, clk)
	begin
		if Async_rst = '1' then
			rst_q0  	<= '1';
			rst_q1  	<= '1';
			rst_q2  	<= '1';
		elsif rising_edge(clk) then
			rst_q0  	<= '0';
			rst_q1  	<= rst_q0;
			rst_q2		<= rst_q1;
		end if;
	end process;
	
	async_rst_int	<= rst_q1;
	disable_fifo	<= rst_q2;
	
	we_masked		<= we and (not disable_fifo);
	re_masked		<= re and (not disable_fifo);
	
	
	process(async_rst_int, clk)	
	begin
		if async_rst_int = '1' then
			write_pointer 	<= (others => '0');
			full_i			<= '1';
			prog_full_i		<= '1';
		elsif rising_edge(clk) then
			if Sync_rst = '1' then
				write_pointer 	<= (others => '0');
				full_i			<= '1';
				prog_full_i		<= '1';
			else	
				if write_allow = '1' then
					write_pointer <= next_write_pointer;
				end if;
				full_i			<= ram_full_comb or disable_fifo;
				prog_full_i		<= prog_full_comb or disable_fifo;
			end if;
		end if;
	end process; 
	
	write_allow 		<= we_masked and (not full_i);
	next_write_pointer 	<= write_pointer + 1;
	we_porta			<= write_allow;
	
	dina				<= din;
	addra				<= write_pointer(addr_width - 1 downto 0);
	full				<= full_i;
	prog_full			<= prog_full_i;
	
	
	process(async_rst_int, clk)	
	begin
		if async_rst_int = '1' then
			read_pointer 	<= (others => '0');
			empty_i			<= '1';
			prog_empty_i	<= '1';
			
		elsif rising_edge(clk) then
			if Sync_rst = '1' then
				read_pointer 	<= (others => '0');
				empty_i			<= '1';
				prog_empty_i	<= '1';
			else
				if read_allow = '1' then
					read_pointer <= next_read_pointer;
				end if;	
				empty_i 		<= ram_empty_comb or disable_fifo;
				prog_empty_i	<= prog_empty_comb or disable_fifo;	
			end if;
		end if;
	end process;
	
	next_read_pointer 		<= read_pointer + 1;
	addrb					<= read_pointer(addr_width - 1 downto 0);
	prog_empty				<= prog_empty_i;
	valid					<= valid_i;	
	
	-------------------------------
	---- DATA COUNT GENERATION ----
	-------------------------------
	process (clk, async_rst_int)
	begin
		if async_rst_int = '1' then
			data_counter	<= (others => '0');
		elsif rising_edge(clk) then
			if Sync_rst = '1' then
				data_counter	<= (others => '0');
			else 
				data_counter	<= diff_pointer;
			end if;
		end if;
	end process;
	
	data_count(addr_width downto 0)			<= data_counter(addr_width downto 0);
	data_count(31 downto addr_width + 1)	<= (others => '0');
	
	----------------------
	---- FULL GENERATOR 
	-----------------------
	
	full_comp0  	<= '1' 
	when (write_pointer(addr_width - 1 downto 0) = read_pointer(addr_width - 1 downto 0))
	and  (write_pointer(addr_width) /= read_pointer(addr_width))
	else '0';
	
	full_comp1 		<= '1' 
	when (next_write_pointer(addr_width - 1 downto 0) = read_pointer(addr_width - 1 downto 0))
	and  (next_write_pointer(addr_width) /= read_pointer(addr_width))
	else '0'; 
	
	going_full    	<= full_comp1 and write_allow;
	ram_full_comb 	<= (going_full or full_comp0) and (not read_allow);
	prog_full_comb	<= '0' when diff_pointer < conv_std_logic_vector(Prog_Full_ThresHold, addr_width) else '1';
	
	
	----------------------
	---- EMPTY GENERATOR 
	-----------------------
	
	empty_comp0 	<= '1' 
	when (read_pointer(addr_width downto 0) = write_pointer(addr_width downto 0)) 
	else '0';
	
	empty_comp1 	<= '1' 
	when next_read_pointer(addr_width downto 0) = write_pointer(addr_width downto 0)  
	else '0'; 
	
	going_empty 	<= empty_comp1 and read_allow;
	ram_empty_comb	<= (going_empty or empty_comp0) and (not write_allow); 
	prog_empty_comb	<= '0' when diff_pointer > conv_std_logic_vector(Prog_Empty_ThresHold, addr_width)  else '1';
	
	
	---------------------------------------------------
	---- DIFFERENCE BETWEEN WRITE AND READ POINTER ----
	---------------------------------------------------	
	diff_pointer  	 	 <= write_pointer_actual - read_pointer_actual;	
	
	
	----------------------------------------
	---- DO NOT INSERT FWFT_SHOWAHEAD LOGIC 
	----------------------------------------
	
	generate_standard_logic: if FWFT_ShowAhead = false generate
		
		write_pointer_actual <= write_pointer when write_allow = '0' else next_write_pointer;
		read_pointer_actual  <= read_pointer when read_allow = '0' else next_read_pointer;	
		
		process (clk, async_rst_int)
		begin
			if async_rst_int = '1' then
				valid_i	<= '0';
			elsif rising_edge(clk) then
				if Sync_rst = '1' then
					valid_i	<= '0';
				else 
					valid_i	<= read_allow;
				end if;
			end if;
		end process;
		
		read_allow  <= re_masked and (not empty_i);
		empty		<= empty_i;
		ce_portb	<= read_allow; 
		dout		<= doutb;	
		
	end generate;
	
	
	----------------------------------------
	---- INSERT FWFT_SHOWAHEAD LOGIC 
	----------------------------------------
	
	generate_FWFT_SHOWAHEAD_logic :  if FWFT_ShowAhead = true generate 
		
		signal empty_int				: std_logic;
		signal user_read_pointer		: std_logic_vector(addr_width downto 0);
		signal user_next_read_pointer	: std_logic_vector(addr_width downto 0) := (others => '0');
		signal user_read_enable			: std_logic;
		
		begin 
		
		
		read_allow  			<= ce_portb and (not empty_i);
		
		process (clk, async_rst_int)
		begin
			if async_rst_int = '1' then
				user_read_pointer	<= (others => '0');
			elsif rising_edge(clk) then
				if Sync_rst = '1' then
					user_read_pointer	<= (others => '0');
				else 
					if user_read_enable = '1' then
						user_read_pointer	<= user_next_read_pointer;
					end if;	
				end if;
			end if;
		end process;
		
		user_next_read_pointer  <= user_read_pointer + 1;
		user_read_enable		<= re_masked and (not empty_int);
		
		write_pointer_actual 	<= write_pointer when write_allow = '0' else next_write_pointer;
		read_pointer_actual  	<= user_read_pointer  when user_read_enable = '0' else user_next_read_pointer;	
		
		FWFT_ShowAhead_Logic_inst: FWFT_ShowAhead_Logic_Golden
		generic map 
			(
			data_width  	=> data_width
			)
		port map
			(
			rd_clk      	=> clk,
			async_rst  		=> async_rst_int,
			sync_rst		=> Sync_rst,
			rd_en       	=> re_masked,
			fifo_empty  	=> empty_i,
			ram_dout    	=> doutb,
			fifo_dout   	=> dout,
			user_empty  	=> empty,
			empty_int		=> empty_int,
			user_valid 		=> valid_i,
			ram_re      	=> ce_portb
			);	
		
	end generate;	
	
	
	SINGLE_CLOCK_DUAL_PORT_RAM_inst: block
		
		begin
		
		process(clk)
		begin
			if rising_edge(clk) then
				if we_porta = '1' then
					dual_port_ram(conv_integer(addra)) <= dina;	
				end if;	
			end if;
		end process;
		
		process(clk)
		begin
			if rising_edge(clk) then
				if ce_portb = '1' then
					doutb <= dual_port_ram(conv_integer(addrb));
				end if;
			end if;
		end process;
	end block;
	
	
	
	
end architecture; 

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.MATH_REAL.all;

entity FWFT_SHOWAHEAD_LOGIC_GOLDEN is
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

architecture FWFT_SHOWAHEAD_LOGIC_GOLDEN of FWFT_SHOWAHEAD_LOGIC_GOLDEN is
	
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
