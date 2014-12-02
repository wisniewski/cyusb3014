----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface - Stream In Module
-- FPGA Writing to Slave FIFO
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity stream_in is
generic 
(
	data_bit 				: natural := 16
);
port 
(
	clock100 				: in std_logic;
	flaga_d 				: in std_logic;
	flagb_d 				: in std_logic;
	reset 					: in std_logic;
	stream_in_mode_active 	: in std_logic;
	slwr_stream_in 			: out std_logic;
	data_stream_in_to_fx3 	: out std_logic_vector(data_bit-1 downto 0)
);
end stream_in;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture stream_in_arch of stream_in is
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant DATA_BITS 		: natural := 16;
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal slwr_stream_in_n : std_logic;
signal data_stream_in_n : std_logic_vector(DATA_BITS-1 downto 0);
----------------------------------------------------------------------------------
-- Stream In Finished State Machine
----------------------------------------------------------------------------------
type stream_in_states is (stream_in_idle, stream_in_wait_flagb, stream_in_write, stream_in_wr_delay);
signal current_state, next_state : stream_in_states;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
slwr_stream_in <= slwr_stream_in_n;
data_stream_in_to_fx3 <= data_stream_in_n; 
----------------------------------------------------------------------------------
-- Stream In State Change
----------------------------------------------------------------------------------
stream_in_fsm : process (clock100, reset) begin
	if (reset = '0') then
		current_state <= stream_in_idle;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
----------------------------------------------------------------------------------
-- SLWR Signal Enable/Disable
----------------------------------------------------------------------------------
slwr_stream_in_enable : process(current_state, flagb_d) begin
	if (current_state = stream_in_write) and (flagb_d = '1') then
		slwr_stream_in_n <= '0';
	else 
		slwr_stream_in_n <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- Data Generator
---------------------------------------------------------------------------------
generate_data : process(clock100, reset) begin
	if (reset = '0') then
		data_stream_in_n <= (others => '0');
	elsif rising_edge(clock100) then
		if (stream_in_mode_active = '1') and (slwr_stream_in_n = '0') then
			data_stream_in_n <= data_stream_in_n + '1';
		else 
			data_stream_in_n <= (others => '0');
		end if;
	end if;
end process;
----------------------------------------------------------------------------------
-- Stream In Main FSM
----------------------------------------------------------------------------------
stream_in_main_fsm : process(current_state, flaga_d, flagb_d, stream_in_mode_active) begin
	case current_state is
		when stream_in_idle =>
			if (flaga_d = '1') and (stream_in_mode_active = '1') then
				next_state <= stream_in_wait_flagb;
			else 
				next_state <= stream_in_idle;
			end if;

		when stream_in_wait_flagb =>
			if (flagb_d = '1') then
				next_state <= stream_in_write;
			else 
				next_state <= stream_in_wait_flagb;
			end if;

		when stream_in_write =>
			if (flagb_d = '0') then
				next_state <= stream_in_wr_delay;
			else 
				next_state <= stream_in_write;
			end if;

		when stream_in_wr_delay =>
			next_state <= stream_in_idle;

		when others =>
			next_state <= stream_in_idle;
	end case;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end stream_in_arch;