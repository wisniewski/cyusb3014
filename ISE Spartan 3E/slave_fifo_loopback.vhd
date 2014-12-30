----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface - Loopback Module
-- FPGA Reading and Writing to Slave FIFO
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_loopback is port 
(
	clock100 				: in std_logic;
	reset 					: in std_logic;
	data_loopback_in 	: in std_logic_vector(15 downto 0);
	data_loopback_out 	: out std_logic_vector(15 downto 0);
	loopback_mode_active 	: in std_logic;
	flaga_get 				: in std_logic;
	flagb_get 				: in std_logic;
	flagc_get 				: in std_logic;
	flagd_get 				: in std_logic;
	slwr_loopback 			: out std_logic;
	sloe_loopback 			: out std_logic;
	slrd_loopback 			: out std_logic;
	loopback_address : out std_logic
);
end slave_fifo_loopback;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture loopback_arch of slave_fifo_loopback is
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal buffer_write_enable : std_logic;
signal buffer_read_enable : std_logic;
signal buffer_full : std_logic;
signal buffer_empty : std_logic;

signal rd_oe_delay_cnt				: std_logic_vector(1 downto 0):="00";
signal oe_delay_cnt					: std_logic_vector(1 downto 0):="00";
----------------------------------------------------------------------------------
-- Stream In Finished State Machine
----------------------------------------------------------------------------------
type loopback_states is 
(
	loopback_idle,
	loopback_flagc_rcvd,
	loopback_wait_flagd,
	loopback_read,
	loopback_read_rd_oe_delay,
	loopback_read_oe_delay,
	loopback_wait_flaga,
	loopback_wait_flagb,
	loopback_write,
	loopback_write_wr_delay,
	loopback_flush_fifo
);
signal current_state, next_state : loopback_states;
----------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------
COMPONENT slave_fifo_buffer PORT 
(
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
); END COMPONENT;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Port map
----------------------------------------------------------------------------------
inst_fifo_buffer : slave_fifo_buffer PORT MAP 
(
	clk => clock100,
    rst => reset,
    din => data_loopback_in,
    wr_en => buffer_write_enable,
    rd_en => buffer_read_enable,
    dout => data_loopback_out,
    full => buffer_full,
    empty => buffer_empty
);
----------------------------------------------------------------------------------
-- RD OE Delay Counter
----------------------------------------------------------------------------------
process(clock100, reset) begin
	if (reset = '1') then
		rd_oe_delay_cnt <= (others => '0');
	elsif (rising_edge(clock100)) then
		if (current_state = loopback_read) then
			rd_oe_delay_cnt <= "01";
		elsif (current_state = loopback_read_rd_oe_delay) and (rd_oe_delay_cnt > 0) then 
			rd_oe_delay_cnt <= rd_oe_delay_cnt - '1';
		else 
			rd_oe_delay_cnt <= rd_oe_delay_cnt;
		end if;
	end if; 
end process;
----------------------------------------------------------------------------------
-- OE Delay Counter
----------------------------------------------------------------------------------
process(clock100, reset) begin
	if (reset = '1') then
		oe_delay_cnt <= (others => '0');
	elsif (rising_edge(clock100)) then
		if (current_state = loopback_read_rd_oe_delay) then
			oe_delay_cnt <= "10";
		elsif (current_state = loopback_read_oe_delay) and (oe_delay_cnt > 0) then 
			oe_delay_cnt <= oe_delay_cnt - '1';
		else 
			oe_delay_cnt <= oe_delay_cnt;
		end if;
	end if; 
end process;
----------------------------------------------------------------------------------
-- Loopback State Change
----------------------------------------------------------------------------------
process (clock100, reset) begin
	if (reset = '0') then
		current_state <= loopback_idle;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
----------------------------------------------------------------------------------
-- Loopback Main FSM
----------------------------------------------------------------------------------
process(current_state, loopback_mode_active) begin
	next_state <= current_state;
	case current_state is
		when loopback_idle =>
			if (flagc_get = '1') and (loopback_mode_active = '1') then
				next_state <= loopback_flagc_rcvd;
			else 
				next_state <= loopback_idle;
			end if;
		when loopback_flagc_rcvd =>
			next_state <= loopback_wait_flagd;
		when loopback_wait_flagd =>
			if (flagd_get = '1') then
				next_state <= loopback_read;
			else 
				next_state <= loopback_wait_flagd;
			end if;
		when loopback_read =>
			if (flagd_get = '0') then
				next_state <= loopback_read_rd_oe_delay;
			else 
				next_state <= loopback_read;
			end if;
		when loopback_read_rd_oe_delay =>
			if (rd_oe_delay_cnt = "00") then
				next_state <= loopback_read_oe_delay;
			else 
				next_state <= loopback_read_rd_oe_delay;
			end if;
		when loopback_read_oe_delay =>
			if (oe_delay_cnt = "00") then
				next_state <= loopback_wait_flaga;
			else 
				next_state <= loopback_read_oe_delay;
			end if;
		when loopback_wait_flaga =>
			if (flaga_get = '0') then
				next_state <= loopback_wait_flagb;
			else 
				next_state <= loopback_wait_flaga;
			end if;
		when loopback_wait_flagb =>
			if (flagb_get = '1') then
				next_state <= loopback_write;
			else 
				next_state <= loopback_wait_flagb;
			end if;
		when loopback_write =>
			if (flagb_get = '0') then
				next_state <= loopback_write_wr_delay;
			else 
				next_state <= loopback_write;
			end if;
		when loopback_write_wr_delay =>
			next_state <= loopback_flush_fifo;
		when loopback_flush_fifo =>
			next_state <= loopback_idle;
		when others =>
			next_state <= loopback_idle;
	end case;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end loopback_arch;