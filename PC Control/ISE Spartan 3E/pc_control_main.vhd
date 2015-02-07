----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface Main Module
-- Three Modules: 
-- 1) FPGA continuously writes full packets (Stream from FPGA to FX3)
-- 2) FPGA continuously reads full packets (Stream from FX3 to FPGA)
-- Author: Mariusz Wisniewski (www.kocurkolandia.pl)
-- December 2014 - January 2015
----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_main is 
generic
(
	SLIDE_BITS : natural := 3;
	ADDRESS_BITS : natural := 2;
	DATA_BITS : natural := 16;
	PMODE_BITS : natural := 2;
	LCD_BITS : natural := 4
);
port
(
	clock50 : in std_logic; -- input 50 MHz onboard clock
	clock100_out : out std_logic; -- output 100 MHz clock to FX3 (PCLK)

	reset_from_slide : in std_logic;
	reset_from_fx3 : in std_logic; -- input reset FIFO from FX3 (INT_N_CTL15)
	reset_to_fx3 : out std_logic; -- RESET
	
	slide_select_mode : in std_logic_vector(SLIDE_BITS-1 downto 0):="000"; -- select mode (idle, stream, loop)
    led_buffer_empty_show : out std_logic:='0'; -- show FIFO state - empty or not

    address : out std_logic_vector(ADDRESS_BITS-1 downto 0):="00"; -- 2-bit address bus (A)
	data : inout std_logic_vector(DATA_BITS-1 downto 0):="0000000000000000"; -- 16-bit data bus (DQ)
	pktend : out std_logic; -- always '1'
	pmode : out std_logic_vector(PMODE_BITS-1 downto 0):="11"; -- always "11"

	slcs : out std_logic; -- chip select
	slwr : out std_logic; -- write strobe
	slrd : out std_logic; -- read strobe
	sloe : out std_logic; -- output enable

	flaga : in std_logic; -- write to fx3
	flagb : in std_logic; -- write to fx3
	flagc : in std_logic; -- read from fx3
	flagd : in std_logic; -- read from fx3
	
	lcd_e : out std_logic; -- lcd signals
	lcd_rs : out std_logic; 
	lcd_rw : out std_logic;
	lcd_data : out std_logic_vector(LCD_BITS-1 downto 0); -- lcd 4-bit bus
	lcd_srataflash_disable : out std_logic -- disable useless feature
); end slave_fifo_main;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture slave_fifo_arch of slave_fifo_main is
----------------------------------------------------------------------------------
-- FPGA Master-Mode Finished State Machine
----------------------------------------------------------------------------------
type fpga_master_states is 
(
	idle_state, 
	stream_read_from_fx3_state, 
	stream_write_to_fx3_state
);
signal current_state : fpga_master_states:=idle_state;
signal next_state : fpga_master_states:=idle_state;
signal current_mode : std_logic_vector(2 downto 0):="111";
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant MASTER_IDLE : std_logic_vector(2 downto 0):="111";
constant STREAM_OUT : std_logic_vector(2 downto 0):="010";
constant STREAM_IN : std_logic_vector(2 downto 0):="100";

constant DATA_BIT : natural := 16;
----------------------------------------------------------------------------------
-- LCD Signals
----------------------------------------------------------------------------------
signal lcd_text_line1 : string(1 to DATA_BIT);
signal lcd_text_line2 : string(1 to DATA_BIT);
signal lcd_data_to_send, lcd_goto : std_logic_vector(7 downto 0);
signal lcd_data_request, lcd_clear, lcd_goto_request, lcd_request_served, lcd_display_ready : std_logic;
type lcd_states is 
(
	start, 
	clearscr, 
	move1, 
	move2, 
	idle, 
	send1, 
	send2
);
signal lcd_current_state : lcd_states := start;
----------------------------------------------------------------------------------
-- General Signals
----------------------------------------------------------------------------------
signal clock100 : std_logic;
signal lcd_clock50 : std_logic;
signal reset_fpga : std_logic:='0';
signal address_get : std_logic_vector(1 downto 0);
signal pktend_get : std_logic;
signal slwr_get : std_logic;
signal sloe_get : std_logic;
signal slrd_get : std_logic;
signal slcs_get : std_logic;
signal flaga_get : std_logic;
signal flagb_get : std_logic;
signal flagc_get : std_logic;
signal flagd_get : std_logic;
signal data_in_get : std_logic_vector(DATA_BIT-1 downto 0);
signal data_out_get : std_logic_vector(DATA_BIT-1 downto 0);
signal data_out_get2 : std_logic_vector(DATA_BIT-1 downto 0);
----------------------------------------------------------------------------------
-- Stream In Signals
----------------------------------------------------------------------------------
signal stream_in_mode_active: std_logic;
signal data_stream_in : std_logic_vector(DATA_BIT-1 downto 0):="1111000011110000";
signal slwr_stream_in: std_logic;
----------------------------------------------------------------------------------
-- Stream Out Signals
----------------------------------------------------------------------------------
signal stream_out_mode_active: std_logic;
signal data_stream_out : std_logic_vector(DATA_BIT-1 downto 0):="1111000011110000";
signal data_stream_out_to_show : std_logic_vector(DATA_BIT-1 downto 0):="1111000011110000";
signal sloe_stream_out : std_logic;
signal slrd_stream_out : std_logic;

signal start_transfer : std_logic_vector(1 downto 0):="00";
----------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------
component pc_control_dcm port
(
	CLKIN_IN : IN std_logic;
	RST_IN : IN std_logic;          
	CLKIN_IBUFG_OUT : OUT std_logic;
	CLK0_OUT : OUT std_logic;
	CLK2X_OUT : OUT std_logic
); end component;
component lcd_controller port
(
	clock50 : in std_logic;
	reset : in std_logic;
	lcd_e : out std_logic;
	lcd_rs : out std_logic;
	lcd_rw : out std_logic;
	lcd_data : out std_logic_vector(3 downto 0);
	lcd_data_to_send : in std_logic_vector(7 downto 0);
	lcd_data_request : in std_logic;
	lcd_clear : in std_logic;
	lcd_goto : in std_logic_vector(7 downto 0);
	lcd_goto_request : in std_logic;
	lcd_request_served : out std_logic;
	lcd_display_ready : buffer std_logic
); end component;
component slave_fifo_stream_write_to_fx3 port 
(
	clock100 : in std_logic;
	flaga_get : in std_logic;
	flagb_get : in std_logic;
	reset : in std_logic;
	stream_in_mode_active : in std_logic;
	slwr_stream_in : out std_logic;
	data_stream_in : out std_logic_vector(DATA_BIT-1 downto 0)
); end component;
component slave_fifo_stream_read_from_fx3 port 
(
	clock100 					: in std_logic;
	flagc_get 					: in std_logic;
	flagd_get 					: in std_logic;
	reset 						: in std_logic;
	stream_out_mode_active 		: in std_logic;
	data_stream_out	: in std_logic_vector(DATA_BIT-1 downto 0);
	data_stream_out_to_show	: out std_logic_vector(DATA_BIT-1 downto 0);
	sloe_stream_out 			: out std_logic;
	slrd_stream_out 			: out std_logic;
	start_transfer : out std_logic_vector(1 downto 0)
); end component;
----------------------------------------------------------------------------------
-- Function: Convert std logic to string
----------------------------------------------------------------------------------	
function vector_to_string (vector : std_logic_vector) return string is
	variable i : integer range 0 to 15 := 0;
	variable result : string (1 to 16);
begin
	for i in 0 to 15 loop
		if vector(i) = '0' then
			result(i+1) := '0';
		else 
			result(i+1) := '1';
		end if;
	end loop;
	return result;
end vector_to_string;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------	
begin
----------------------------------------------------------------------------------
-- Port Maps
----------------------------------------------------------------------------------
inst_pc_control_dcm : pc_control_dcm port map
(
	CLKIN_IN => clock50,
	RST_IN => '0',
	CLKIN_IBUFG_OUT => open,
	CLK0_OUT => lcd_clock50,
	CLK2X_OUT => clock100
);
inst_lcd_controller : lcd_controller port map
(
	clock50 => lcd_clock50,
	reset => '0',
	lcd_e => lcd_e,
	lcd_rs => lcd_rs,
	lcd_rw => lcd_rw,
	lcd_data => lcd_data,
	lcd_data_to_send => lcd_data_to_send,
	lcd_data_request => lcd_data_request,
	lcd_clear => lcd_clear,
	lcd_goto => lcd_goto,
	lcd_goto_request => lcd_goto_request,
	lcd_request_served => lcd_request_served,
	lcd_display_ready => lcd_display_ready
);
inst_stream_write_to_fx3 : slave_fifo_stream_write_to_fx3 port map
(
	clock100 => clock100,
	flaga_get => flaga_get,
	flagb_get => flagb_get,
	reset => not reset_fpga,
	stream_in_mode_active => stream_in_mode_active,
	slwr_stream_in => slwr_stream_in,
	data_stream_in => data_stream_in
);
int_stream_read_from_fx3 : slave_fifo_stream_read_from_fx3 port map
(
	clock100 => clock100,
	flagc_get => flagc_get,
	flagd_get => flagd_get,
	reset => not reset_fpga,
	stream_out_mode_active => stream_out_mode_active,
	data_stream_out => data_stream_out,
	data_stream_out_to_show => data_stream_out_to_show,
	sloe_stream_out => sloe_stream_out,
	slrd_stream_out => slrd_stream_out,
	start_transfer => start_transfer
);
----------------------------------------------------------------------------------
-- General Signals
----------------------------------------------------------------------------------
clock100_out <= clock100;
reset_fpga <= reset_from_slide;
led_buffer_empty_show <= start_transfer(0);
lcd_srataflash_disable <= '1';
--reset_to_fx3 <= '1';
pmode <= "11";
pktend_get <= '1';
----------------------------------------------------------------------------------
-- FPGA Send All Signals
----------------------------------------------------------------------------------
process (reset_fpga, current_state) begin
	if reset_fpga = '1' then
		address <= "11";
    	slwr <= '1';
    	slcs <= '1';
		slrd <= '1';
		sloe <= '1';
		pktend <= '1';
    elsif (rising_edge(clock100)) then
    	address <= address_get;
    	slwr <= slwr_get;
    	slcs <= slcs_get;
		slrd <= slrd_get;
		sloe <= sloe_get;
		pktend <= pktend_get;
    end if;
end process;
----------------------------------------------------------------------------------
-- Get Output Data
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_write_to_fx3_state then
		data_out_get <= data_stream_in;
	else 
		data_out_get <= (others => '0');
    end if;
end process;
----------------------------------------------------------------------------------
-- Send Output Data 2
----------------------------------------------------------------------------------
process (reset_fpga, clock100) begin
	if reset_fpga = '1' then
		data_out_get2 <= (others => '0');
    elsif (rising_edge(clock100)) then
		data_out_get2 <= data_out_get;
    end if;
end process;
----------------------------------------------------------------------------------
-- Send Output Data 3
----------------------------------------------------------------------------------
process (slwr_get) begin
    if (slwr_get = '0') then
		data <= data_out_get2;
	else 
		data <= (others => 'Z');
    end if;
end process;
----------------------------------------------------------------------------------
-- Get Input Data
----------------------------------------------------------------------------------
process (reset_fpga, clock100, current_state) begin
	if reset_fpga = '1' then
		data_in_get <= (others => '0');
    elsif (rising_edge(clock100)) then
		data_in_get <= data;
    end if;
end process;
----------------------------------------------------------------------------------
-- Get Input Data 2
----------------------------------------------------------------------------------
process (current_state, slrd_stream_out) begin
	if current_state = stream_read_from_fx3_state then
		data_stream_out <= data_in_get;
	else 
		data_stream_out <= (others => '0');
	end if;
end process;
----------------------------------------------------------------------------------
-- Get Current Flag Signal
----------------------------------------------------------------------------------
process (reset_fpga, clock100) begin
	if reset_fpga = '1' then
		flaga_get <= '0';
		flagb_get <= '0';
		flagc_get <= '0';
		flagd_get <= '0';
    elsif (rising_edge(clock100)) then
		flaga_get <= flaga;
    	flagb_get <= flagb;
    	flagc_get <= flagc;
    	flagd_get <= flagd;
    end if;
end process;
----------------------------------------------------------------------------------
-- Get Stream Out, Stream In Mode Active Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_read_from_fx3_state then
		stream_out_mode_active <= '1';
	else 
		stream_out_mode_active <= '0';
	end if;
	if current_state = stream_write_to_fx3_state then
		stream_in_mode_active <= '1';
	else 
		stream_in_mode_active <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- Get Output/Enable, Read/Write and Write Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_write_to_fx3_state then
		slcs_get <= '0';
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= slwr_stream_in;
	elsif current_state = stream_read_from_fx3_state then
		slcs_get <= '0';
		sloe_get <= sloe_stream_out;
		slrd_get <= slrd_stream_out;
		slwr_get <= '1';
	else
		slcs_get <= '1';
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- Get Address Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if (current_state = stream_read_from_fx3_state) then
		address_get <= "11";
	else	
		address_get <= "00";
	end if;
end process;
----------------------------------------------------------------------------------
-- FPGA Master-Mode Change State and Select Mode from Slide Switches
----------------------------------------------------------------------------------
process (clock100, reset_fpga) begin
    if (reset_fpga = '1')  then
        current_state <= idle_state;
        current_mode <= MASTER_IDLE;
		lcd_text_line1 <= "FSM FPGA        ";
		lcd_text_line2 <= "MODE: RESET     ";
    elsif (rising_edge(clock100)) then
        current_state <= next_state;
        current_mode <= slide_select_mode;
        case current_state is
			when stream_read_from_fx3_state =>
            	lcd_text_line1 <= "FSM: STREAM OUT ";
	            lcd_text_line2 <= vector_to_string(data_stream_out_to_show);
            when stream_write_to_fx3_state => 
            	lcd_text_line1 <= "FSM: STREAM IN  ";
	            lcd_text_line2 <= vector_to_string(data_stream_in);
            when others =>
            	lcd_text_line1 <= "FSM FPGA        ";
	            lcd_text_line2 <= "MODE: IDLE STATE"; 
        end case;
    end if;
end process;
----------------------------------------------------------------------------------
-- FPGA State Machine
----------------------------------------------------------------------------------
process(current_state, start_transfer)
	variable counter : integer range 0 to 510000000 := 1;
	variable abc : std_logic:='0';
begin
if(rising_edge(clock100)) then
   	next_state <= current_state;
    case current_state is
        when idle_state =>
        	reset_to_fx3 <= '0';
        	counter := 1;
        	next_state <= stream_read_from_fx3_state;
        when stream_read_from_fx3_state =>
        if counter = 50000 then
        	if start_transfer = "01" and abc = '0' then --start
        		counter := 1;
        		abc := '1';
        		next_state <= stream_write_to_fx3_state;
        	elsif start_transfer = "10" and abc = '1' then --stop
        		counter := 1;
        		abc := '0';
        		next_state <= idle_state;
        	elsif abc = '1' then
        		counter := 1;
        		next_state <= stream_write_to_fx3_state;
        	end if;
        elsif counter > 50001 then
        	counter := 1;
        end if;
        when stream_write_to_fx3_state =>
        	if counter = 500000000 and slwr_get = '1' then --5s
        		next_state <= idle_state;
        		counter := 1;
        	end if;
        when others => 
            next_state <= idle_state;
    end case;
    counter := counter + 1;
end if;
end process;
----------------------------------------------------------------------------------
-- LCD Main Process
----------------------------------------------------------------------------------
process(lcd_clock50, lcd_request_served)
	variable counter : integer range 0 to 50000000 := 1;
	variable letter_index : integer := 0;
begin
	if rising_edge(lcd_clock50) then
		case lcd_current_state is
			when idle =>
				lcd_current_state <= start;
			when start =>
				if lcd_display_ready = '1' then
					counter := 0;
					lcd_current_state <= move1;
				end if;
			when clearscr =>
				if counter = 1 then
					lcd_clear <= '1';
				elsif lcd_request_served = '1' then
					lcd_clear <= '0';
					lcd_current_state <= move1;
					counter := 0;
				end if;
			when move1 =>
				if counter = 1 then
					lcd_goto <= "10000000";
					lcd_goto_request <= '1';
				elsif lcd_request_served = '1' and counter > 250000 then
					lcd_goto_request <= '0';
					lcd_current_state <= send1;
					counter := 0;
				end if;
			when send1 =>
				if counter = 1 then
					letter_index := letter_index + 1;
					lcd_data_to_send <= conv_std_logic_vector(character'pos(lcd_text_line1(letter_index)), 8);
					lcd_data_request <= '1';
				elsif lcd_request_served = '1' then
					lcd_data_request <= '0';
					counter := 0;
					if letter_index = lcd_text_line1'length then
						lcd_current_state <= move2;
					end if;
				end if;
			when move2 =>
				if counter = 1 then
					lcd_goto <= "11000000";
					lcd_goto_request <= '1';
				elsif lcd_request_served = '1' and counter > 250000 then
					lcd_goto_request <= '0';
					lcd_current_state <= send2;
					counter := 0;
					letter_index := 0;
				end if;
			when send2 =>
				if counter = 1 then
					letter_index := letter_index + 1;
					lcd_data_to_send <= conv_std_logic_vector(character'pos(lcd_text_line2(letter_index)), 8);
					lcd_data_request <= '1';
				elsif lcd_request_served = '1' then
					lcd_data_request <= '0';
					counter := 0;
					if letter_index = lcd_text_line2'length then
						lcd_current_state <= idle;
						letter_index := 0;
					end if;
				end if;
			when others => null;
		end case;
	counter := counter + 1;
	end if;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end slave_fifo_arch;

