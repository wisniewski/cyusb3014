----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface - Stream Write to FX3 Module
-- FPGA Writing to Slave FIFO
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_stream_write_to_fx3 is 
generic
(
	DATA_BITS : natural := 16
);
port 
(
	clock100 : in std_logic;
	flaga_get : in std_logic;
	flagb_get : in std_logic;
	reset : in std_logic;
	stream_in_mode_active : in std_logic;
	slwr_stream_in : out std_logic;
	data_stream_in : out std_logic_vector(DATA_BITS-1 downto 0)
); end slave_fifo_stream_write_to_fx3;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture stream_write_to_fx3_arch of slave_fifo_stream_write_to_fx3 is
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant DATA_BIT : natural := 16;
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal slwr_stream_in_get : std_logic;
signal data_stream_in_get : std_logic_vector(DATA_BIT-1 downto 0);
----------------------------------------------------------------------------------
-- Stream Write to FX3 Finished State Machine
----------------------------------------------------------------------------------
type stream_write_to_fx3_states is 
(
	stream_in_idle, 
	stream_in_wait_flagb, 
	stream_in_write, 
	stream_in_wr_delay
);
signal current_state, next_state : stream_write_to_fx3_states;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
slwr_stream_in <= slwr_stream_in_get;
data_stream_in <= data_stream_in_get; 
----------------------------------------------------------------------------------
-- Stream Write to FX3 State Change
----------------------------------------------------------------------------------
process (clock100, reset) begin
	if (reset = '0') then
		current_state <= stream_in_idle;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
----------------------------------------------------------------------------------
-- SLWR Signal Enable/Disable
----------------------------------------------------------------------------------
process(current_state, flagb_get) begin
	if (current_state = stream_in_write) and (flagb_get = '1') then
		slwr_stream_in_get <= '0';
	else 
		slwr_stream_in_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- Data Generator: "MW" Ascii
---------------------------------------------------------------------------------
process(clock100, reset) begin
	if (reset = '0') then
		data_stream_in_get <= (others => '0');
	elsif rising_edge(clock100) then
		if (stream_in_mode_active = '1') and (slwr_stream_in_get = '0') then
			data_stream_in_get <= "0101011101001101";
		elsif (stream_in_mode_active = '0') then
			data_stream_in_get <= "1111000011110000";
		end if;
	end if;
end process;
----------------------------------------------------------------------------------
-- Stream Write to FX3 Main FSM
----------------------------------------------------------------------------------
process(current_state, flaga_get, flagb_get, stream_in_mode_active) begin
	next_state <= current_state;
	case current_state is
		when stream_in_idle =>
			if (flaga_get = '1') and (stream_in_mode_active = '1') then
				next_state <= stream_in_wait_flagb;
			else 
				next_state <= stream_in_idle;
			end if;
		when stream_in_wait_flagb =>
			if (flagb_get = '1') then
				next_state <= stream_in_write;
			else 
				next_state <= stream_in_wait_flagb;
			end if;
		when stream_in_write =>
			if (flagb_get = '0') then
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
end stream_write_to_fx3_arch;