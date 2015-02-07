----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface - Stream Read From FX3 Module
-- FPGA Reading from Slave FIFO
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_stream_read_from_fx3 is 
generic
(
	DATA_BITS : natural := 16
);
port 
(
	clock100 : in std_logic;
	flagc_get : in std_logic;
	flagd_get : in std_logic;
	reset : in std_logic;
	stream_out_mode_active : in std_logic;
	data_stream_out	: in std_logic_vector(DATA_BITS-1 downto 0);
	data_stream_out_to_show	: out std_logic_vector(DATA_BITS-1 downto 0);
	sloe_stream_out : out std_logic;
	slrd_stream_out : out std_logic;
	start_transfer : out std_logic_vector(1 downto 0)
); end slave_fifo_stream_read_from_fx3;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture stream_read_from_fx3_arch of slave_fifo_stream_read_from_fx3 is
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant CNT_BIT : natural := 2;
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal sloe_stream_out_n : std_logic:='1';
signal slrd_stream_out_n : std_logic:='1';
signal rd_oe_delay_cnt : std_logic_vector(CNT_BIT-1 downto 0):="00";
signal oe_delay_cnt	: std_logic_vector(CNT_BIT-1 downto 0):="00";
signal data_get : std_logic_vector(15 downto 0);
----------------------------------------------------------------------------------
-- Stream Read From FX3 Finished State Machine
----------------------------------------------------------------------------------
type stream_read_from_fx3 is 
(
	stream_out_idle,
	stream_out_flagc_rcvd, 
	stream_out_wait_flagd, 
	stream_out_read, 
	stream_out_read_rd_oe_delay, 
	stream_out_read_oe_delay
);
signal current_state, next_state : stream_read_from_fx3;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
sloe_stream_out <= sloe_stream_out_n;
slrd_stream_out <= slrd_stream_out_n;
----------------------------------------------------------------------------------
-- Stream Read From FX3 - Get Data to Show
----------------------------------------------------------------------------------
process(slrd_stream_out_n, stream_out_mode_active) begin
	if (slrd_stream_out_n = '0') then
		data_stream_out_to_show <= data_stream_out;
		data_get <= data_stream_out;
	elsif (stream_out_mode_active = '0') then
		data_stream_out_to_show <= "0000111100001111";
		data_get <= "0000111100001111";
	end if;
end process;
----------------------------------------------------------------------------------
-- Stream Read From FX3 - Get Data to Show
----------------------------------------------------------------------------------
process(clock100) begin
	if (rising_edge(clock100)) then
		if (data_get = "0101011101001101") then -- 0x574d
			start_transfer <= "01";
		elsif (data_get = "0100110101010111") then -- 0x4d57
			start_transfer <= "10";
		else
			start_transfer <= "00";
		end if;
	end if;
end process;
----------------------------------------------------------------------------------
-- Stream Read From FX3 State Change
----------------------------------------------------------------------------------
process (clock100, reset) begin
	if (reset = '0') then
		current_state <= stream_out_idle;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
----------------------------------------------------------------------------------
-- SLOE Signal Enable/Disable
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = stream_out_read) or (current_state = stream_out_read_rd_oe_delay) or (current_state = stream_out_read_oe_delay) then
		sloe_stream_out_n <= '0';
	else 
		sloe_stream_out_n <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- SLRD Signal Enable/Disable
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = stream_out_read) or (current_state = stream_out_read_rd_oe_delay) then
		slrd_stream_out_n <= '0';
	else 
		slrd_stream_out_n <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- RD OE Delay Counter
----------------------------------------------------------------------------------
process(clock100, reset, current_state) begin
	if (reset = '0') then
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
process(clock100, reset, current_state) begin
	if (reset = '0') then
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
-- Stream Read From FX3 Main FSM
----------------------------------------------------------------------------------
process(current_state, flagc_get, flagd_get, stream_out_mode_active) begin
	case current_state is
		when stream_out_idle =>
			if (flagc_get = '1') and (stream_out_mode_active = '1') then
				next_state <= stream_out_flagc_rcvd;
			else 
				next_state <= stream_out_idle;
			end if;
		when stream_out_flagc_rcvd =>
			next_state <= stream_out_wait_flagd;
		when stream_out_wait_flagd =>
			if (flagd_get = '1') then
				next_state <= stream_out_read;
			else 
				next_state <= stream_out_wait_flagd;
			end if;
		when stream_out_read =>
			if (flagd_get = '0') then
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
end stream_read_from_fx3_arch;

