----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface Main Module
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_main is
port(
	clock50 : in std_logic;
	reset : in std_logic;

	buttons : in std_logic_vector(2 downto 0):="000";
    leds : out std_logic_vector(2 downto 0):="000";

	lcd_e : out std_logic;
	lcd_rs : out std_logic;
	lcd_rw : out std_logic;
	lcd_data : out std_logic_vector(3 downto 0);
	lcd_srataflash_disable : out std_logic
);
end slave_fifo_main;
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
	loopback_state, 
	stream_out_state, 
	stream_in_state
);
signal current_state : fpga_master_states:=idle_state;
signal next_state : fpga_master_states:=idle_state;
signal current_mode : std_logic_vector(2 downto 0):="111";
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant MASTER_IDLE : std_logic_vector(2 downto 0):="111";
constant LOOPBACK : std_logic_vector(2 downto 0):="001";
constant STREAM_OUT : std_logic_vector(2 downto 0):="010";
constant STREAM_IN : std_logic_vector(2 downto 0):="100";
constant RESET_MODE : std_logic_vector(2 downto 0):="100";
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal text_line1 : string(1 to 8);
signal text_line2 : string(1 to 16);
signal lcd_data_to_send, goto : std_logic_vector(7 downto 0);
signal data_request, clear, goto_request, request_served, display_ready : std_logic;
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
-- Components
----------------------------------------------------------------------------------
component lcd_controller port 
(
	clock50 : in std_logic;
	reset : in std_logic;
	lcd_e : out std_logic;
	lcd_rs : out std_logic;
	lcd_rw : out std_logic;
	lcd_data : out std_logic_vector(3 downto 0);
	lcd_data_to_send : in std_logic_vector(7 downto 0);
	data_request : in std_logic;
	clear : in std_logic;
	goto : in std_logic_vector(7 downto 0);
	goto_request : in std_logic;
	request_served : out std_logic;
	display_ready : buffer std_logic
); end component;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------	
begin
----------------------------------------------------------------------------------
-- LCD Controller Port Map
----------------------------------------------------------------------------------	
inst_lcd_controller : lcd_controller port map
(
	clock50 => clock50,
	reset => reset,
	lcd_e => lcd_e,
	lcd_rs => lcd_rs,
	lcd_rw => lcd_rw,
	lcd_data => lcd_data,
	lcd_data_to_send => lcd_data_to_send,
	data_request => data_request,
	clear => clear,
	goto => goto,
	goto_request => goto_request,
	request_served => request_served,
	display_ready => display_ready
);
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
lcd_srataflash_disable <= '1';
----------------------------------------------------------------------------------
-- FPGA Master-Mode Change State and Select Mode from Slide Switches
----------------------------------------------------------------------------------
process (clock50, reset) begin
    if (reset='1')  then
        current_state <= idle_state;
        current_mode <= MASTER_IDLE;
        leds <= RESET_MODE;
    elsif (rising_edge(clock50)) then
    	text_line1 <= "FSM FPGA";
        current_state <= next_state;
        current_mode <= buttons;

        case current_state is
            when loopback_state => 
            	leds <= LOOPBACK;
            	text_line2 <= "MODE: LOOPBACK  ";
            when stream_out_state => 
	            leds <= STREAM_OUT; 
	            text_line2 <= "MODE: STREAM OUT";
            when stream_in_state => 
	            leds <= STREAM_IN; 
	            text_line2 <= "MODE: STREAM IN ";
            when others => 
	            leds <= MASTER_IDLE; 
	            text_line2 <= "MODE: IDLE STATE"; 
        end case;
    end if;
end process;
----------------------------------------------------------------------------------
-- FPGA State Machine
----------------------------------------------------------------------------------
process(current_state, current_mode) begin
   	next_state <= current_state;

    case current_state is
        when idle_state =>
            if current_mode = LOOPBACK then
                next_state <= loopback_state;
            elsif current_mode = STREAM_OUT then 
                next_state <= stream_out_state;
            elsif current_mode = STREAM_IN then 
                next_state <= stream_in_state;
            else 
                next_state <= idle_state;
            end if;
        when loopback_state => 
            if current_mode /= LOOPBACK then
                next_state <= idle_state;
            end if;
        when stream_out_state => 
            if current_mode /= STREAM_OUT then
                next_state <= idle_state;
            end if;
        when stream_in_state =>
           if current_mode /= STREAM_IN then
                next_state <= idle_state;
            end if;
        when others => 
            next_state <= idle_state;
    end case;
end process;
----------------------------------------------------------------------------------
-- LCD Main Process
----------------------------------------------------------------------------------
process(reset, clock50, request_served)
	variable counter : integer range 0 to 50000000 := 1;
	variable letter_index : integer := 0;
begin
	if reset = '1' then
		counter := 1;
		lcd_current_state <= start;
	elsif rising_edge(clock50) then
		case lcd_current_state is
			when idle =>
				lcd_current_state <= start;
			when start =>
				if display_ready = '1' then
					counter := 0;
					lcd_current_state <= move1;
				end if;
			when clearscr =>
				if counter = 1 then
					clear <= '1';
				elsif request_served = '1' then
					clear <= '0';
					lcd_current_state <= move1;
					counter := 0;
				end if;
			when move1 =>
				if counter = 1 then
					goto <= "10000100";
					goto_request <= '1';
				elsif request_served = '1' and counter > 250000 then
					goto_request <= '0';
					lcd_current_state <= send1;
					counter := 0;
				end if;
			when send1 =>
				if counter = 1 then
					letter_index := letter_index + 1;
					lcd_data_to_send <= conv_std_logic_vector(character'pos(text_line1(letter_index)), 8);
					data_request <= '1';
				elsif request_served = '1' then
					data_request <= '0';
					counter := 0;
					if letter_index = text_line1'length then
						lcd_current_state <= move2;
					end if;
				end if;
			when move2 =>
				if counter = 1 then
					goto <= "11000000";
					goto_request <= '1';
				elsif request_served = '1' and counter > 250000 then
					goto_request <= '0';
					lcd_current_state <= send2;
					counter := 0;
					letter_index := 0;
				end if;
			when send2 =>
				if counter = 1 then
					letter_index := letter_index + 1;
					lcd_data_to_send <= conv_std_logic_vector(character'pos(text_line2(letter_index)), 8);
					data_request <= '1';
				elsif request_served = '1' then
					data_request <= '0';
					counter := 0;
					if letter_index = text_line2'length then
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

