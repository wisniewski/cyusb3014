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
entity slave_fifo_loopback is 
generic
(
	DATA_BITS : natural := 16
);
port 
(
	clock100 : in std_logic;
	reset : in std_logic;
	data_loopback_in : in std_logic_vector(DATA_BITS-1 downto 0);
	data_loopback_out : out std_logic_vector(DATA_BITS-1 downto 0);
	loopback_mode_active : in std_logic;
	flaga_get : in std_logic;
	flagb_get : in std_logic;
	slwr_loopback : out std_logic;
	sloe_loopback : out std_logic;
	slrd_loopback : out std_logic;
	loopback_address : out std_logic;
	buffer_empty_show : out std_logic
); end slave_fifo_loopback;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture loopback_arch of slave_fifo_loopback is
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant DATA_BIT : natural := 16;
constant CNT_BIT : natural := 2;
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal buffer_write_enable : std_logic;
signal buffer_read_enable : std_logic;
signal buffer_full : std_logic;
signal buffer_empty : std_logic;
signal buffer_reset : std_logic;

signal rd_oe_delay_cnt : std_logic_vector(CNT_BIT-1 downto 0):="00";
signal oe_delay_cnt : std_logic_vector(CNT_BIT-1 downto 0):="00";
signal data_loopback_in_get : std_logic_vector(DATA_BIT-1 downto 0);

signal slrd_loopback_get : std_logic;
signal slwr_loopback_get : std_logic;
signal sloe_loopback_get : std_logic;
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
COMPONENT slave_fifo_buffer_2flags PORT 
(
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(DATA_BIT-1 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(DATA_BIT-1 DOWNTO 0);
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
inst_fifo_buffer : slave_fifo_buffer_2flags PORT MAP 
(
	clk => clock100,
    rst => buffer_reset,
    din => data_loopback_in_get,
    wr_en => buffer_write_enable,
    rd_en => buffer_read_enable,
    dout => data_loopback_out,
    full => buffer_full,
    empty => buffer_empty
);
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
slwr_loopback <= slwr_loopback_get;
slrd_loopback <= slrd_loopback_get;
sloe_loopback <= sloe_loopback_get;
buffer_empty_show <= buffer_empty;
----------------------------------------------------------------------------------
-- FIFO Reset Flush
----------------------------------------------------------------------------------
process(current_state, reset) begin
	if  (reset = '0') or (current_state = loopback_flush_fifo) then
		buffer_reset <= '1';
	else 
		buffer_reset <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- SLRD Loopback
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = loopback_read) or (current_state = loopback_read_rd_oe_delay) then
		slrd_loopback_get <= '0';
	else 
		slrd_loopback_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- SLOE Loopback
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = loopback_read) or (current_state = loopback_read_rd_oe_delay) 
	or (current_state = loopback_read_oe_delay) then
		sloe_loopback_get <= '0';
	else 
		sloe_loopback_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- SLWR Loopback
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = loopback_write) then
		slwr_loopback_get <= '0';
	else 
		slwr_loopback_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- Buffer Read Enable
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = loopback_write) and (slwr_loopback_get = '0') then
		buffer_read_enable <= '1';
	else 
		buffer_read_enable <= '0';
	end if;
end process;
--------------------------------------------------------------------
-- Buffer Write Enable
----------------------------------------------------------------------------------
process(slrd_loopback_get, loopback_mode_active) begin
	if (slrd_loopback_get = '0') and (loopback_mode_active = '1') then
		buffer_write_enable <= '1';
		data_loopback_in_get <= data_loopback_in;
	else 
		buffer_write_enable <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- Loopback Address
----------------------------------------------------------------------------------
process(current_state) begin
	if (current_state = loopback_flagc_rcvd) or (current_state = loopback_wait_flagd) 
	or (current_state = loopback_read) or (current_state = loopback_read_rd_oe_delay)
	or (current_state = loopback_read_oe_delay) then
		loopback_address <= '1';
	else 
		loopback_address <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- RD OE Delay Counter
----------------------------------------------------------------------------------
process(clock100, reset, current_state) begin
	if (reset = '0') then
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
	if (reset = '0') then
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
process(current_state, loopback_mode_active, flaga_get, flagb_get, rd_oe_delay_cnt, oe_delay_cnt) begin
	next_state <= current_state;
	case current_state is
		when loopback_idle =>
			if (flagb_get = '1') and (loopback_mode_active = '1') then
				next_state <= loopback_flagc_rcvd;
			else 
				next_state <= loopback_idle;
			end if;
		when loopback_flagc_rcvd =>
			next_state <= loopback_wait_flagd;
		when loopback_wait_flagd =>
			if (flagb_get = '1') then
				next_state <= loopback_read;
			else 
				next_state <= loopback_wait_flagd;
			end if;
		when loopback_read =>
			if (flagb_get = '0') then
				next_state <= loopback_read_rd_oe_delay;
			else 
				next_state <= loopback_read;
			end if;
		when loopback_read_rd_oe_delay =>
			if (rd_oe_delay_cnt = "00") then
				next_state <= loopback_wait_flaga;
			else 
				next_state <= loopback_read_rd_oe_delay;
			end if;
		when loopback_wait_flaga =>
			if (flaga_get = '1') then
				next_state <= loopback_write;
			else 
				next_state <= loopback_wait_flaga;
			end if;
		when loopback_write =>
			if (flaga_get = '0') then
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