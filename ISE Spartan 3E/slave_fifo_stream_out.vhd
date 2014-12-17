----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface - Stream Out Module
-- FPGA Reading from Slave FIFO
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity stream_out is
generic 
(
	data_bit 					: natural := 16
);
port 
(
	clock100 					: in std_logic;
	flagc_d 					: in std_logic;
	flagd_d 					: in std_logic;
	reset 						: in std_logic;
	stream_out_mode_active 		: in std_logic;
	data_stream_out_from_fx3	: in std_logic_vector(data_bit-1 downto 0);
	sloe_stream_out 			: out std_logic;
	slrd_stream_out 			: out std_logic
	
);
end stream_out;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture stream_out_arch of stream_out is
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant DATA_BITS 					: natural := 16;
constant CNT_BITS 					: natural := 2;
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal sloe_stream_out_n 			: std_logic:='1';
signal slrd_stream_out_n 			: std_logic:='1';
signal data_stream_out_from_fx3_n 	: std_logic_vector(DATA_BITS-1 downto 0):="0000000000000000";
signal rd_oe_delay_cnt				: std_logic_vector(CNT_BITS-1 downto 0):="00";
signal oe_delay_cnt					: std_logic_vector(CNT_BITS-1 downto 0):="00";
----------------------------------------------------------------------------------
-- Stream Out Finished State Machine
----------------------------------------------------------------------------------
type stream_out_states is (stream_out_idle, stream_out_flagc_rcvd, stream_out_wait_flagd, 
	stream_out_read, stream_out_read_rd_oe_delay, stream_out_read_oe_delay);
signal current_state, next_state : stream_out_states;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
sloe_stream_out <= sloe_stream_out_n;
slrd_stream_out <= slrd_stream_out_n;
data_stream_out_from_fx3_n <= data_stream_out_from_fx3;
----------------------------------------------------------------------------------
-- Stream Out State Change
----------------------------------------------------------------------------------
stream_out_fsm : process (clock100, reset) begin
	if (reset = '0') then
		current_state <= stream_out_idle;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
----------------------------------------------------------------------------------
-- SLOE Signal Enable/Disable
----------------------------------------------------------------------------------
sloe_stream_out_enable : process(current_state) begin
	if (current_state = stream_out_read) or (current_state = stream_out_read_rd_oe_delay) or (current_state = stream_out_read_oe_delay) then
		sloe_stream_out_n <= '0';
	else 
		sloe_stream_out_n <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- SLRD Signal Enable/Disable
----------------------------------------------------------------------------------
slrd_stream_out_enable : process(current_state) begin
	if (current_state = stream_out_read) or (current_state = stream_out_read_rd_oe_delay) then
		slrd_stream_out_n <= '0';
	else 
		slrd_stream_out_n <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- RD OE Delay Counter
----------------------------------------------------------------------------------
rd_oe_delay_counter : process(clock100, reset) begin
	if (reset = '1') then
		rd_oe_delay_cnt <= (others => '0');
	elsif (rising_edge(clock100)) then
		if (current_state = stream_out_read) then
			rd_oe_delay_cnt <= "01";
		elsif (current_state = stream_out_read_rd_oe_delay) and (rd_oe_delay_cnt > 0) then 
			rd_oe_delay_cnt <= rd_oe_delay_cnt - '1';
		else 
			rd_oe_delay_cnt <= rd_oe_delay_cnt;
		end if;
	end if; 
end process;
----------------------------------------------------------------------------------
-- OE Delay Counter
----------------------------------------------------------------------------------
oe_delay_counter : process(clock100, reset) begin
	if (reset = '1') then
		oe_delay_cnt <= (others => '0');
	elsif (rising_edge(clock100)) then
		if (current_state = stream_out_read_rd_oe_delay) then
			oe_delay_cnt <= "10";
		elsif (current_state = stream_out_read_oe_delay) and (oe_delay_cnt > 0) then 
			oe_delay_cnt <= oe_delay_cnt - '1';
		else 
			oe_delay_cnt <= oe_delay_cnt;
		end if;
	end if; 
end process;
----------------------------------------------------------------------------------
-- Stream Out Main FSM
----------------------------------------------------------------------------------
stream_out_main_fsm : process(current_state, flagc_d, flagd_d, stream_out_mode_active) begin
	case current_state is
		when stream_out_idle =>
			if (flagc_d = '1') and (stream_out_mode_active = '1') then
				next_state <= stream_out_flagc_rcvd;
			else 
				next_state <= stream_out_idle;
			end if;

		when stream_out_flagc_rcvd =>
			next_state <= stream_out_wait_flagd;

		when stream_out_wait_flagd =>
			if (flagc_d = '1') then
				next_state <= stream_out_read;
			else 
				next_state <= stream_out_wait_flagd;
			end if;

		when stream_out_read =>
			if (flagc_d = '0') then
				next_state <= stream_out_read_rd_oe_delay;
			else 
				next_state <= stream_out_read;
			end if;

		when stream_out_read_rd_oe_delay =>
			if (rd_oe_delay_cnt = "00") then
				next_state <= stream_out_read_oe_delay;
			else 
				next_state <= stream_out_read_rd_oe_delay;
			end if;

		when stream_out_read_oe_delay =>
			if (oe_delay_cnt = "00") then
				next_state <= stream_out_idle;
			else 
				next_state <= stream_out_read_oe_delay;
			end if;

		when others =>
			next_state <= stream_out_idle;
	end case;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end stream_out_arch;

