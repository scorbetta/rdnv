----*************************************************
---- Copy the Component Declaration in your project:
----************************************************

--	component INDEPENDENT_CLOCK_FIFO is	
--	generic
--		( 
--		Fifo_depth					: positive := 8;
--		data_width					: natural  := 32; 
--		FWFT_ShowAhead				: boolean  := false;
--		Synchronous_Clocks			: boolean  := false;
--		Prog_Full_ThresHold			: positive := 4; 
--		Prog_Empty_ThresHold		: positive := 4
--		);
--	port
--		( 		
--		Async_rst		: in std_logic;	  								
--		wr_clk 			: in std_logic;									
--		rd_clk 			: in std_logic;									
--		we  			: in std_logic;									
--		din				: in std_logic_vector(data_width - 1 downto 0);	
--		full			: out std_logic;								
--		prog_full		: out std_logic; 								
--		wr_data_count	: out std_logic_vector(31 downto 0);  			
--		valid			: out std_logic;								
--		re  			: in std_logic;								   	
--		dout			: out std_logic_vector(data_width - 1 downto 0);
--		empty			: out std_logic;								
--		prog_empty		: out std_logic;								
--		rd_data_count	: out std_logic_vector(31 downto 0)				
--		);
--	end component;

-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL; 
use IEEE.MATH_REAL.all;

entity INDEPENDENT_CLOCK_FIFO is	
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
		
		-----------------------
		-- This parameter disable the gray coding (not needed when clocks are related) and set the minimum latency.
		-- This parameter can be set to true ONLY if BOTH the following condition are satisfied:
		-- 1) Write and Read clocks have a fixed and known phase relationship.
		-- 2) Write clock and Read clocks MUST BE CONSTRAINED AS RELATED IN THE UCF or SDC file.
		-----------------------
		Synchronous_Clocks			: boolean  := false;
		
		-------------------------------------------------------------------------------------------------------
		-- Specify the Programmable full assertion. This value MUST be programmed between 4 and Fifo_depth - 4
		-- This flag is asserted high when wr_data_count is equal or greater than Prog_Full_ThresHold
		-------------------------------------------------------------------------------------------------------
		Prog_Full_ThresHold			: positive := 4; 
		
		-------------------------------------------------------------------------------------------------------
		-- Specify the Programmable Empty assertion. This value MUST be programmed between 4 and Fifo_depth - 4
		-- This flag is asserted low when rd_data_count is greater than Prog_Empty_ThresHold
		-------------------------------------------------------------------------------------------------------
		Prog_Empty_ThresHold		: positive := 4
		);
	port
		( 
		-- Asynchronous reset. Reset is internally synchronized
		Async_rst		: in std_logic;	  								
		
		-- Write clock
		wr_clk 			: in std_logic;
		
		-- Read Clock
		rd_clk 			: in std_logic;									
		
		----------------------------------------------
		-- Following ports are synchronous with wr_clk
		----------------------------------------------
		
		-- Write enable (Assert High)
		we  			: in std_logic;	
		
		-- Data in
		din				: in std_logic_vector(data_width - 1 downto 0);	
		
		-- Full flag. (Assert High)
		full			: out std_logic;
		
		-- Programmable Full flag. (Assert High)
		prog_full		: out std_logic; 
		
		-- (Written Data - Read Data) in the wr_clk domain.
		wr_data_count	: out std_logic_vector(31 downto 0);  			 
		
		----------------------------------------------
		-- Following ports are synchronous with rd_clk
		----------------------------------------------
		
		-- Valid signal (Asset high)
		valid			: out std_logic;
		
		-- Read enable	(Assert High)
		re  			: in std_logic;	
		
		-- Data out
		dout			: out std_logic_vector(data_width - 1 downto 0);
		
		-- Empty flag. (Assert High)
		empty			: out std_logic;
		
		-- Programmable Empty flag. assert High
		prog_empty		: out std_logic;
		
		-- Number of data that can be read.
		rd_data_count	: out std_logic_vector(31 downto 0)				
		);
end entity;

architecture INDEPENDENT_CLOCK_FIFO of INDEPENDENT_CLOCK_FIFO is
	
	constant Fifo_depth_min	: positive := 8; 
	constant addr_width		: positive := positive(ceil(LOG2( REALMAX(real(Fifo_depth_min), real(Fifo_depth)))));
	
	type dual_port_ram_type is array (0 to (2**addr_width - 1)) of std_logic_vector(data_width - 1 downto 0);
	signal dual_port_ram 	: dual_port_ram_type := (others => (others => '0')); 
	
	component FWFT_ShowAhead_Logic is
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
	
	signal rst_wr_clk_q0 				: STD_LOGIC := '1';
	signal rst_wr_clk_q1 				: STD_LOGIC := '1';
	signal rst_wr_clk_q2 				: STD_LOGIC := '1';
	signal rst_wr_clk_q3 				: STD_LOGIC := '1';
	signal rst_wr_clk_s					: std_logic;
	signal rst_wr_clk					: std_logic := '1';
	signal disable_we					: std_logic := '1';
	signal we_masked					: std_logic;
	signal write_allow					: std_logic;
	signal write_pointer				: std_logic_vector(addr_width downto 0) := (others => '0');
	signal next_write_pointer			: std_logic_vector(addr_width downto 0);
	signal full_comp1					: std_logic;
	signal full_comp0					: std_logic;
	signal prog_full_comb				: std_logic;
	signal going_full					: std_logic;
	signal ram_full_comb				: std_logic; 
	signal full_i						: std_logic := '1';
	signal prog_full_i					: std_logic := '1';
	signal wr_count						: std_logic_vector(addr_width downto 0) := (others => '0');
	signal diff_wr_clk					: std_logic_vector(addr_width  downto 0);
	signal write_pointer_actual			: std_logic_vector(addr_width downto 0);
	signal write_pointer_to_gray		: std_logic_vector(addr_width downto 0);
	signal write_pointer_gray			: std_logic_vector(addr_width  downto 0);
	signal write_pointer_gray_q0		: std_logic_vector(addr_width  downto 0) := (others => '0');
	signal write_pointer_gray_q1		: std_logic_vector(addr_width  downto 0) := (others => '0');
	signal write_pointer_gray_q2		: std_logic_vector(addr_width  downto 0) := (others => '0');
	signal write_pointer_rd_clk_bin_s	: std_logic_vector(addr_width  downto 0);
	signal write_pointer_rd_clk_bin		: std_logic_vector(addr_width  downto 0) := (others => '0');
	
	signal rst_rd_clk_q0 				: STD_LOGIC := '1';
	signal rst_rd_clk_q1 				: STD_LOGIC := '1';
	signal rst_rd_clk_q2				: std_logic := '1';
	signal rst_rd_clk_q3				: std_logic := '1';
	signal rst_rd_clk_s					: std_logic;
	signal rst_rd_clk					: std_logic := '1';
	signal disable_re					: std_logic := '1';
	signal re_masked					: std_logic; 
	signal read_allow					: std_logic;
	signal read_pointer					: std_logic_vector(addr_width downto 0) := (others => '0');
	signal next_read_pointer			: std_logic_vector(addr_width downto 0);
	signal empty_comp1					: std_logic;
	signal empty_comp0					: std_logic;
	signal prog_empty_comb				: std_logic;
	signal going_empty					: std_logic;
	signal ram_empty_comb				: std_logic;
	signal prog_empty_i					: std_logic := '1';
	signal empty_i						: std_logic := '1';	
	signal rd_count						: std_logic_vector(addr_width downto 0) := (others => '0');
	signal diff_rd_clk					: std_logic_vector(addr_width  downto 0);
	signal read_pointer_actual			: std_logic_vector(addr_width downto 0);
	signal read_pointer_to_gray			: std_logic_vector(addr_width downto 0);
	signal read_pointer_gray			: std_logic_vector(addr_width downto 0);
	signal read_pointer_gray_q0			: std_logic_vector(addr_width downto 0) := (others => '0');
	signal read_pointer_gray_q1			: std_logic_vector(addr_width downto 0) := (others => '0');
	signal read_pointer_gray_q2			: std_logic_vector(addr_width downto 0) := (others => '0');
	signal read_pointer_wr_clk_bin_s	: std_logic_vector(addr_width downto 0);
	signal read_pointer_wr_clk_bin		: std_logic_vector(addr_width downto 0) := (others => '0');
	
	signal valid_i						: std_logic := '0';
	signal we_porta						: std_logic;
	signal addra						: std_logic_vector(addr_width - 1 downto 0);	
	signal dina							: std_logic_vector(data_width - 1 downto 0);
	signal ce_portb						: std_logic;
	signal addrb						: std_logic_vector(addr_width - 1 downto 0);
	signal doutb						: std_logic_vector(data_width - 1 downto 0) := (others => '0');
	
	
	attribute altera_attribute : string;
	attribute altera_attribute of read_pointer_gray_q1	: signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
	attribute altera_attribute of write_pointer_gray_q1	: signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
	
begin
	
	----------------------------
	----- RESET SYNCHRONIZATION 
	----------------------------
	-- 1) Write clock domain
	process (Async_rst, wr_clk)
	begin
		if Async_rst = '1' then	
			rst_wr_clk_q0		<= '1';
			rst_wr_clk_q1		<= '1';
		elsif rising_edge(wr_clk) then
			rst_wr_clk_q0		<= '0';
			rst_wr_clk_q1		<= rst_wr_clk_q0;
		end if;
	end process;
	
	process (rst_rd_clk_q1, wr_clk)
	begin
		if rst_rd_clk_q1 = '1' then	
			rst_wr_clk_q2 	<= '1';
			rst_wr_clk_q3 	<= '1';
		elsif rising_edge(wr_clk) then
			rst_wr_clk_q2 	<= '0';
			rst_wr_clk_q3 	<= rst_wr_clk_q2;
		end if;
	end process;
	
	rst_wr_clk_s <= rst_wr_clk_q3 or rst_wr_clk_q1;
	
	process (rst_wr_clk_s, wr_clk)
	begin
		if rst_wr_clk_s = '1' then
			rst_wr_clk	<= '1';
			disable_we	<= '1';
		elsif rising_edge(wr_clk) then
			rst_wr_clk	<= '0';
			disable_we	<= rst_wr_clk;
		end if;
	end process;
	
	-- 1) Read clock domain
	process (Async_rst, rd_clk)
	begin
		if Async_rst = '1' then	
			rst_rd_clk_q0		<= '1';
			rst_rd_clk_q1		<= '1';
		elsif rising_edge(rd_clk) then
			rst_rd_clk_q0		<= '0';
			rst_rd_clk_q1		<= rst_rd_clk_q0;
		end if;
	end process;
	
	process (rst_wr_clk_q1, rd_clk)
	begin
		if rst_wr_clk_q1 = '1' then	
			rst_rd_clk_q2 	<= '1';
			rst_rd_clk_q3 	<= '1';
		elsif rising_edge(rd_clk) then
			rst_rd_clk_q2 	<= '0';
			rst_rd_clk_q3 	<= rst_rd_clk_q2;
		end if;
	end process;
	
	rst_rd_clk_s <= rst_rd_clk_q3 or rst_rd_clk_q1;
	
	
	process (rst_rd_clk_s, rd_clk)
	begin
		if rst_rd_clk_s = '1' then
			rst_rd_clk  	<= '1';
			disable_re   	<= '1';
		elsif rising_edge(rd_clk) then
			rst_rd_clk  	<= '0';
			disable_re   	<= rst_rd_clk;
		end if;
	end process;
	
	
	process(rst_wr_clk, wr_clk)	
	begin
		if rst_wr_clk = '1' then
			write_pointer 	<= (others => '0');
			full_i			<= '1';
			prog_full_i		<= '1';
			wr_count 		<= (others => '0');
		elsif rising_edge(wr_clk) then
			if write_allow = '1' then
				write_pointer <= next_write_pointer;
			end if;
			full_i			<= ram_full_comb or disable_we;
			prog_full_i		<= prog_full_comb or disable_we;
			wr_count 		<= diff_wr_clk;
		end if;
	end process; 
	
	we_masked								<= we and (not disable_we);
	write_allow 							<= we_masked and (not full_i);
	next_write_pointer 						<= write_pointer + 1;
	we_porta								<= write_allow;
	dina									<= din;
	addra									<= write_pointer(addr_width - 1 downto 0);
	wr_data_count(addr_width downto 0)		<= wr_count(addr_width downto 0);
	wr_data_count(31 downto addr_width + 1)	<= (others => '0');
	full									<= full_i;
	prog_full								<= prog_full_i;
	
	
	process(rst_rd_clk, rd_clk)	
	begin
		if rst_rd_clk = '1' then
			read_pointer 	<= (others => '0');
			empty_i			<= '1';
		elsif rising_edge(rd_clk) then	
			if read_allow = '1' then
				read_pointer <= next_read_pointer;
			end if;	
			empty_i 		<= ram_empty_comb or disable_re;
		end if;
	end process; 
	
	re_masked								<= re and (not disable_re);
	next_read_pointer 						<= read_pointer + 1;
	addrb									<= read_pointer(addr_width - 1 downto 0);
	rd_data_count(addr_width downto 0)		<= rd_count(addr_width downto 0);
	rd_data_count(31 downto addr_width + 1)	<= (others => '0');
	prog_empty								<= prog_empty_i;
	valid									<= valid_i;
	
	----------------------
	---- FULL GENERATOR 
	-----------------------
	
	full_comp0   	<= '1' 
	when (write_pointer(addr_width - 1 downto 0) = read_pointer_wr_clk_bin(addr_width - 1 downto 0))
	and (write_pointer(addr_width) /= read_pointer_wr_clk_bin(addr_width))
	else '0';
	
	full_comp1   	<= '1' 
	when (next_write_pointer(addr_width - 1 downto 0) = read_pointer_wr_clk_bin(addr_width - 1 downto 0))
	and (next_write_pointer(addr_width) /= read_pointer_wr_clk_bin(addr_width))
	else '0'; 
	
	going_full    	<= full_comp1 and write_allow; 
	ram_full_comb 	<= (going_full or full_comp0);	
	
	diff_wr_clk		<= write_pointer_actual - read_pointer_wr_clk_bin; 
	prog_full_comb	<= '0' when diff_wr_clk < conv_std_logic_vector(Prog_Full_ThresHold, addr_width) else '1';
	
	----------------------
	---- EMPTY GENERATOR 
	-----------------------
	
	empty_comp0 	<= '1' 
	when (read_pointer(addr_width downto 0) = write_pointer_rd_clk_bin(addr_width downto 0))   
	else '0';
	
	empty_comp1 	<= '1' 
	when next_read_pointer(addr_width downto 0) = write_pointer_rd_clk_bin(addr_width downto 0)  
	else '0'; 
	
	going_empty 	<= empty_comp1 and read_allow;
	ram_empty_comb	<= going_empty or empty_comp0;
	
	diff_rd_clk 	<= write_pointer_rd_clk_bin - read_pointer_actual;
	prog_empty_comb	<= '0' when diff_rd_clk > conv_std_logic_vector(Prog_Empty_ThresHold, addr_width) else '1';
	
	generate_Unrelated_Clocks: if Synchronous_Clocks = false generate
		
		read_pointer_gray 	<= read_pointer_to_gray(addr_width downto 0) xor ("0" & read_pointer_to_gray(addr_width downto 1));
		write_pointer_gray 	<= write_pointer_to_gray(addr_width downto 0) xor ("0" & write_pointer_to_gray(addr_width downto 1));
		
		process(rst_rd_clk, rd_clk)	
		begin
			if rst_rd_clk = '1' then
				read_pointer_gray_q0  	 <= (others => '0');
				write_pointer_gray_q1 	 <= (others => '0');
				write_pointer_gray_q2 	 <= (others => '0');
				write_pointer_rd_clk_bin <= (others => '0');
			elsif rising_edge(rd_clk) then
				read_pointer_gray_q0  	 <= read_pointer_gray;
				write_pointer_gray_q1 	 <= write_pointer_gray_q0;
				write_pointer_gray_q2 	 <= write_pointer_gray_q1;
				write_pointer_rd_clk_bin <= write_pointer_rd_clk_bin_s;
			end if;
		end process;
		write_pointer_rd_clk_bin_s 	<= write_pointer_gray_q2 xor ("0" & write_pointer_rd_clk_bin_s(addr_width downto 1));
		
		
		process(rst_wr_clk, wr_clk)	
		begin
			if rst_wr_clk = '1' then
				write_pointer_gray_q0		<= (others => '0');
				read_pointer_gray_q1 		<= (others => '0');
				read_pointer_gray_q2		<= (others => '0');
				read_pointer_wr_clk_bin		<= (others => '0');
			elsif rising_edge(wr_clk) then
				write_pointer_gray_q0		<= write_pointer_gray; 
				read_pointer_gray_q1 		<= read_pointer_gray_q0;
				read_pointer_gray_q2 		<= read_pointer_gray_q1;
				read_pointer_wr_clk_bin		<= read_pointer_wr_clk_bin_s;
			end if;
		end process;
		read_pointer_wr_clk_bin_s	<= read_pointer_gray_q2 xor ("0" & read_pointer_wr_clk_bin_s(addr_width downto 1));
		
	end generate;
	
	
	generate_Related_Clocks: if Synchronous_Clocks = true generate
		
		read_pointer_gray 		<= read_pointer_to_gray;
		write_pointer_gray 		<= write_pointer_to_gray;
		
		process(rst_rd_clk, rd_clk)	
		begin
			if rst_rd_clk = '1' then
				read_pointer_gray_q0  <= (others => '0');
				write_pointer_gray_q1 <= (others => '0');
			elsif rising_edge(rd_clk) then
				read_pointer_gray_q0  <= read_pointer_gray;
				write_pointer_gray_q1 <= write_pointer_gray_q0;
			end if;
		end process;
		
		write_pointer_gray_q2 	 	<= write_pointer_gray_q1;
		write_pointer_rd_clk_bin_s 	<= write_pointer_gray_q2;
		write_pointer_rd_clk_bin 	<= write_pointer_rd_clk_bin_s;
		
		process(rst_wr_clk, wr_clk)	
		begin
			if rst_wr_clk = '1' then
				write_pointer_gray_q0 <= (others => '0');
				read_pointer_gray_q1  <= (others => '0');
			elsif rising_edge(wr_clk) then
				write_pointer_gray_q0 <= write_pointer_gray; 
				read_pointer_gray_q1  <= read_pointer_gray_q0;
			end if;
		end process;
		
		read_pointer_gray_q2 		<= read_pointer_gray_q1;
		read_pointer_wr_clk_bin_s	<= read_pointer_gray_q2;
		read_pointer_wr_clk_bin		<= read_pointer_wr_clk_bin_s;
		
	end generate;
	
	
	
	generate_standard_fifo: if FWFT_ShowAhead = false generate 
		
		write_pointer_actual 	<= write_pointer;
		write_pointer_to_gray   <= write_pointer; 
		
		read_pointer_actual	 	<= read_pointer;
		read_pointer_to_gray	<= read_pointer;
		
		read_allow  		 	<= re_masked and (not empty_i);
		empty				 	<= empty_i;
		ce_portb			 	<= read_allow; 
		dout				 	<= doutb;
		
		process(rst_rd_clk, rd_clk)
		begin
			if rst_rd_clk = '1' then
				rd_count 		<= (others => '0');
				prog_empty_i	<= '1';
				valid_i			<= '0';
			elsif rising_edge(rd_clk) then
				rd_count 		<= diff_rd_clk;
				prog_empty_i	<= prog_empty_comb or disable_re;
				valid_i			<= read_allow;
			end if;
		end process;
	end generate;
	
	
	----------------------------------------
	---- INSERT FWFT_SHOWAHEAD LOGIC 
	----------------------------------------
	
	generate_fwft_logic :  if FWFT_ShowAhead = true generate 
		
		signal empty_int				: std_logic;
		signal user_read_pointer		: std_logic_vector(addr_width downto 0);
		signal user_read_enable			: std_logic;
		signal stage1_valid				: std_logic;
		signal stage2_valid				: std_logic;
		signal next_user_read_pointer	: std_logic_vector(addr_width downto 0);
		
		begin 
		
		
		write_pointer_actual 	<= write_pointer;
		read_pointer_actual	 	<= user_read_pointer;
		
		write_pointer_to_gray   <= write_pointer;		
		read_pointer_to_gray	<= user_read_pointer  when user_read_enable = '0' else next_user_read_pointer;	
		
		read_allow  		 	<= ce_portb and (not empty_i);
		user_read_enable		<= re_masked and (not empty_int);
		
		next_user_read_pointer  <= user_read_pointer + 1;
		
		process (rd_clk, rst_rd_clk)
		begin
			if rst_rd_clk = '1' then
				user_read_pointer	<= (others => '0');
				rd_count 			<= (others => '0');
				prog_empty_i		<= '1';
				
			elsif rising_edge(rd_clk) then
				
				if user_read_enable = '1' then
					user_read_pointer	<= next_user_read_pointer;
				end if;	
				
				if stage2_valid = '0' then 
					rd_count(addr_width downto 0) 	<= (others => '0');
					prog_empty_i					<= '1';
				elsif (stage2_valid = '1' and stage1_valid = '0') then 
					rd_count(addr_width downto 1) 	<= (others => '0');
					rd_count(0) 					<= '1';
					prog_empty_i					<= '1';
				else
					rd_count(addr_width downto 0) 	<= diff_rd_clk;
					prog_empty_i					<= prog_empty_comb or disable_re;
				end if;
				
			end if;
		end process;
		
		FWFT_ShowAhead_Logic_inst: FWFT_ShowAhead_Logic 
		generic map 
			(
			data_width  	=> data_width
			)
		port map
			(
			rd_clk      	=> rd_clk,
			async_rst  		=> rst_rd_clk,
			sync_rst		=> '0',
			rd_en       	=> re_masked,
			fifo_empty  	=> empty_i,
			ram_dout    	=> doutb,
			fifo_dout   	=> dout,
			user_empty  	=> empty,
			empty_int		=> empty_int,
			user_valid 		=> valid_i,
			ram_re      	=> ce_portb,
			stage1_valid	=> stage1_valid,
			stage2_valid	=> stage2_valid	 
			
			);		
	end generate;
	
	
	--------------------------------------
	--------	DUAL PORT RAM ------------
	--------------------------------------
	
	INDEPENDENT_CLOCK_DUAL_PORT_RAM_inst: block
		
		begin
		
		process(wr_clk)
		begin
			if rising_edge(wr_clk) then
				if we_porta = '1' then
					dual_port_ram(conv_integer(addra)) <= dina;	
				end if;	
			end if;
		end process;
		
		process(rd_clk)
		begin
			if rising_edge(rd_clk) then
				if ce_portb = '1' then
					doutb <= dual_port_ram(conv_integer(addrb));
				end if;
			end if;
		end process;
	end block;
	
end architecture; 




