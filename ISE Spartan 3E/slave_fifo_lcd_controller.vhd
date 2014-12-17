----------------------------------------------------------------------------------
-- LCD Controller Module
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity lcd_controller is port
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
	request_served : out std_logic := '0';
	display_ready : buffer std_logic := '0'
);
end lcd_controller;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture lcd_controller_arch of lcd_controller is
----------------------------------------------------------------------------------
-- LCD Finished State Machines
----------------------------------------------------------------------------------
type init_state is 
(
	waiting, 
	send_three, 
	wait_after_three, 
	conf_four_bits, 
	wait_after_bits
);
type conf_state is 
(
	function_set, 
	set_display, 
	display_clear, 
	entry_mode_set, 
	finish
);
type send_byte is 
(
	setup_high_nibble, 
	send_high_nibble, 
	nibble_separation, 
	setup_low_nibble, 
	send_low_nibble, 
	finish, 
	idle
);	
type write_state is 
(
	idle, 
	clearing, 
	moving, 
	writing, 
	waiting
);
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal write_fsm : write_state := idle;
	
signal init_fsm : init_state := waiting;
signal init_nibble : std_logic;
signal init_enabled : std_logic;
signal configuring : std_logic := '1';

signal config_fsm : conf_state := function_set;

signal data_nibble : std_logic_vector(3 downto 0);
signal data_enabled : std_logic;
signal config_register_select : std_logic := '0';
signal register_select : std_logic := '0';
	
signal curr_byte : std_logic_vector(7 downto 0);
signal byte_to_send : std_logic_vector(7 downto 0);
signal config_byte_to_send : std_logic_vector(7 downto 0);
	
signal send_byte_request : std_logic := '0';
signal byte_sent : std_logic := '0';
signal send_byte_fsm : send_byte := idle;
	
signal send_config_byte_request : std_logic := '0';
signal send_request : std_logic := '0';
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------		
begin
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
lcd_rs <= config_register_select when display_ready = '0' else register_select;
lcd_rw <= '0';
lcd_data <= ("001" & init_nibble) when configuring = '1' else data_nibble;
lcd_e <= init_enabled when configuring = '1' else data_enabled;
send_byte_request <= send_config_byte_request when display_ready = '0' else send_request;
curr_byte <= config_byte_to_send when display_ready = '0' else byte_to_send;
----------------------------------------------------------------------------------
-- Data Write State Machine
----------------------------------------------------------------------------------
process(reset, clock50, data_request, goto_request, clear)
	variable counter : integer range 0 to 300000 := 1;
begin
	if reset = '1' then
		counter := 0;
	elsif rising_edge(clock50) and display_ready = '1' then
		request_served <= '0';
		send_request <= '0';
		case write_fsm is
			when idle =>
				counter := 0;
				if clear = '1' then
					write_fsm <= clearing;
					register_select <= '0';
					byte_to_send <= "00000001";
					send_request <= '1';
				elsif goto_request = '1' then
					write_fsm <= moving;
					register_select <= '0';
					byte_to_send <= goto;
					send_request <= '1';
				elsif data_request = '1' then
					write_fsm <= writing;
					register_select <= '1';
					byte_to_send <= lcd_data_to_send;
					send_request <= '1';
				end if;
			when clearing =>
				if byte_sent = '1' then
					counter := 0;
					write_fsm <= waiting;
				end if;
			when waiting =>
				if counter > 250000 then
					write_fsm <= idle;
					request_served <= '1';
				end if;
			when moving =>
				if byte_sent = '1' then
					write_fsm <= idle;
					request_served <= '1';
				end if;
			when writing =>
				if byte_sent = '1' then
					write_fsm <= idle;
					request_served <= '1';
				end if;
		end case;
			
		counter := counter + 1;
	end if;
end process;
----------------------------------------------------------------------------------
-- LCD Init State Machine
----------------------------------------------------------------------------------	
process(reset, clock50)
	variable counter : integer range 0 to 760000;
	variable times_sent_number_three : integer range 0 to 3;
	variable wait_time : integer range 2000 to 205000;
begin
	if reset = '1' then
		configuring <= '1';
		counter := 0;
		init_fsm <= waiting;
	elsif rising_edge(clock50) and configuring = '1' then
		case init_fsm is
			when waiting => -- Wait after power on (15ms)
				init_enabled <= '0';
				if counter > 750000 then
					init_fsm <= send_three;
					counter := 0;
					times_sent_number_three := 0;
				end if;
			when send_three =>
				init_nibble <= '1';
				times_sent_number_three := times_sent_number_three + 1;
				init_enabled <= '1';
				if counter > 100 then
					init_fsm <= wait_after_three;
					counter := 0;
				end if;
			when wait_after_three =>
				init_enabled <= '0';
				case times_sent_number_three is 
					when 1 => wait_time := 205000; 
					when 2 => wait_time := 5000; 
					when 3 => wait_time := 2000; 
					when others => null;
				end case;
				if counter = wait_time then
					if times_sent_number_three = 3 then
						init_fsm <= conf_four_bits;
					else 
						init_fsm <= send_three;
					end if;
					counter := 0;
				end if;
			when conf_four_bits => -- We're working with 4 bits
				init_nibble <= '0';
				init_enabled <= '1';
				if counter = 12 then
					init_fsm <= wait_after_bits;
					counter := 0;
				end if;
			when wait_after_bits =>
				init_enabled <= '0';
				if counter > 2000 then
					init_fsm <= waiting;
					configuring <= '0';
				end if;
			when others => null;
		end case;
		
		counter := counter + 1;
	end if;
end process;
----------------------------------------------------------------------------------
-- Configure Display State Machine
----------------------------------------------------------------------------------
process(reset, clock50, configuring)
	variable counter : integer range 0 to 110000 := 1; -- We still need to adjust this value
begin
	if reset = '1' then
		display_ready <= '0';
		counter := 1;
		config_fsm <= function_set;
		config_register_select <= '0';
	elsif rising_edge(clock50) and configuring = '0' and display_ready = '0' then
		send_config_byte_request <= '0';
		config_register_select <= '0';
		case config_fsm is
			when function_set => 
				config_byte_to_send <= "00101000";
				send_config_byte_request <= '1';
				if byte_sent = '1' then
					config_fsm <= entry_mode_set;
					counter := 0;
				end if;
			when entry_mode_set =>
				config_byte_to_send <= "00000110";
				send_config_byte_request <= '1';
				if byte_sent = '1' then
					config_fsm <= set_display;
					counter := 0;
				end if;
			when set_display =>
				config_byte_to_send <= "00001100"; --0x0C
				send_config_byte_request <= '1';
				if byte_sent = '1' then
					config_fsm <= display_clear;
					counter := 0;
				end if;
			when display_clear =>
				config_byte_to_send <= "00000001";
				send_config_byte_request <= '1';
				if byte_sent = '1' then
					config_fsm <= finish;
					counter := 0;
				end if;
			when finish =>
				if counter > 100000 then
					counter := 0;
					display_ready <= '1';
				end if;
		end case;
		
		counter := counter + 1;
	end if;
end process;
----------------------------------------------------------------------------------
-- Send Bytes State Machine
----------------------------------------------------------------------------------
process(reset, clock50, send_byte_request)
	variable counter : integer range 0 to 51000 := 1;
	variable data_tmp : std_logic_vector(7 downto 0);
begin
	if reset = '1' then
		send_byte_fsm <= idle;
		counter := 1;
		data_enabled <= '0';
	elsif rising_edge(clock50) and configuring = '0' then
		byte_sent <= '0';
		case send_byte_fsm is
			when idle =>
				if send_byte_request = '1' then
					data_tmp := curr_byte;
					send_byte_fsm <= setup_high_nibble;
					counter := 0;
					data_enabled <= '0';
				end if;
			when setup_high_nibble => -- 40ns
				data_nibble <= data_tmp(7 downto 4);
				if counter = 2 then
					send_byte_fsm <= send_high_nibble;
					counter := 0;
				end if;
			when send_high_nibble => -- ~230ns
				data_enabled <= '1';
				if counter = 12 then
					counter := 0;
					send_byte_fsm <= nibble_separation;
				end if;
			when nibble_separation => -- 1us
				data_enabled <= '0';
				if counter = 50 then
					counter := 0;
					send_byte_fsm <= setup_low_nibble;
				end if;
			when setup_low_nibble =>
				data_nibble <= data_tmp(3 downto 0);
				if counter = 2 then
					send_byte_fsm <= send_low_nibble;
					counter := 0;
				end if;
			when send_low_nibble =>
				data_enabled <= '1';
				if counter = 12 then
					counter := 0;
					send_byte_fsm <= finish;
				end if;
			when finish => -- 40us
				data_enabled <= '0';
				if counter > 50000 then
					counter := 0;
					send_byte_fsm <= idle;
					byte_sent <= '1';
				end if;
			when others => null;
		end case;
			
		counter := counter + 1;
	end if;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------	
end lcd_controller_arch;

