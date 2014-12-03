----------------------------------------------------------------------------------
-- LCD Controller Spartan 3E
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity lcd_controller is 
generic 
(
	data_out_bit : natural := 4;
	data_in_bit : natural := 8
);
port
(
	clock50 : in std_logic;
	reset_fpga : in std_logic;
	lcd_e : out std_logic;
	lcd_rs : out std_logic; -- 1 data register; 0 command/instruction
	lcd_rw : out std_logic;
	lcd_data_out : out std_logic_vector(3 downto 0);
	lcd_data_input : in std_logic_vector(7 downto 0);
	lcd_data_request : in std_logic;
	lcd_clear : in std_logic;
	lcd_goto : in std_logic_vector(7 downto 0);
	lcd_goto_request : in std_logic;
	lcd_request_served : out std_logic := '0';
	lcd_ready : buffer std_logic := '0'
);
end lcd_controller;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture lcd_controller_arch of lcd_controller is
----------------------------------------------------------------------------------
-- LCD Controller Finished State Machine
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
	conf_finish
);
type send_byte is 
(
	setup_high_nibble, 
	send_high_nibble, 
	nibble_separation, 
	setup_low_nibble, 
	send_low_nibble, 
	send_finish, 
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
signal current_init_state;
signal next_init_state : init_state := waiting;

signal current_conf_state;
signal next_conf_state : conf_state := function_set;

signal current_send_state;
signal next_send_state: send_byte := idle;

signal current_write_state;
signal next_write_state : write_state := idle;

signal data_half_byte : std_logic_vector(3 downto 0) := "0000";
signal data_full_byte : std_logic_vector(7 downto 0) := "00000000";
signal data_config_byte : std_logic_vector(7 downto 0) := "00000000";

signal is_byte_send : std_logic := '0';
signal byte_to_send : std_logic_vector(7 downto 0);

signal lcd_is_configuring : std_logic := '1';
signal init_lcd_data : std_logic_vector(3 downto 0) := "0000";
signal init_lcd_e : std_logic := '0';
signal init_lcd_rs : std_logic := '0';

signal conf_lcd_rs : std_logic := '0';
signal write_lcd_rs : std_logic := '0';

signal send_lcd_e : std_logic := '0';
signal is_lcd_ready : std_logic := '0';

signal send_config_byte_request : std_logic :='0';
signal send_request : std_logic :='0';


----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin

lcd_rw <= '0'; 
lcd_data_out <= data_half_byte when lcd_is_configuring = '0' else init_lcd_data;
lcd_e <=  send_lcd_e when lcd_is_configuring = '0' else init_lcd_e;
lcd_rs <= write_lcd_rs when is_lcd_ready = '1' else conf_lcd_rs;

send_byte_request <= send_config_byte_request when is_lcd_ready = '0' else send_request;
data_full_byte <= byte_to_send when is_lcd_ready = '1' else data_config_byte;

----------------------------------------------------------------------------------
-- LCD Init Process
----------------------------------------------------------------------------------
lcd_init : process(clock50, reset_fpga) 
variable counter : integer range 0 to 59000000 := 0;
variable send_three_times : integer range 0 to 3 := 1;
begin
	current_init_state <= next_init_state;
	counter := counter + 1;

	if reset_fpga = '1' then
		counter := 0;
		current_init_state <= waiting;
		lcd_is_configuring <= '1';
	elsif rising_edge(clock50) and lcd_is_configuring = '1' then
		case current_init_state is
			when waiting => 
				if counter > 50000000 then
					counter := 0;
					init_lcd_rs <= '0';
					next_init_state <= send_three;
				end if;
			
			when send_three =>
				send_three_times := send_three_times + 1;
				init_lcd_e <= '1';
				init_lcd_data <= "0011";
				if (counter > 250000) then
					counter := 0;
					next_init_state <= wait_after_three;
				end if;

			when wait_after_three =>
				init_lcd_e <= '0';
				if (counter > 250000) then
					counter := 0;
					if (send_three_times < 3) then
						next_init_state <= send_three;
					else 
						next_init_state <= conf_four_bits;
					end if;
				end if;

			when conf_four_bits =>
				init_lcd_e <= '1';
				init_lcd_data <= "0010";
				if(counter > 250000)
					counter := 0;
					next_init_state <= wait_after_bits;
				end if;

			when wait_after_bits =>
				init_lcd_e <= '0';
				if(counter > 250000)
					counter := 0;
					lcd_is_configuring = '0';
					next_init_state <= waiting;
				end if;

			when others =>
				next_init_state <= waiting;
		end case;
	end if;
end process;
----------------------------------------------------------------------------------
-- LCD Conf Process
----------------------------------------------------------------------------------
lcd_conf : process(clock50, reset_fpga) 
variable counter : integer range 0 to 59000000 := 0;

begin
	current_conf_state <= next_conf_state;
	counter := counter + 1;
	conf_lcd_rs <= '0';
	if reset_fpga = '1' then
		counter := 0;
		conf_lcd_rs <= '0';
		current_conf_state <= function_set;
		is_lcd_ready <= '0';

	elsif rising_edge(clock50) and lcd_is_configuring = '1' then
		conf_lcd_rs <= '0';
		send_config_byte_request <= '0';

		case current_conf_state is
			when function_set =>
				data_config_byte <= "00101000";
				send_config_byte_request <= '1';
				if (counter > 250000) then
					counter := 0;
				end if;

			when entry_mode_set =>
				data_config_byte <= "00000110";
				send_config_byte_request <= '1';
				if (counter > 250000) then
					counter := 0;
					if byte
				end if;

			when set_display =>
				data_config_byte <= "00001100";
				send_config_byte_request <= '1';
				if (counter > 250000) then
					counter := 0;
				end if;

			when display_clear =>
				data_config_byte <= "00000001";
				send_config_byte_request <= '1';
				if (counter > 250000) then
					counter := 0;
				end if;
			
			when conf_finish =>
				if (counter > 250000) then
					counter := 0;
					is_lcd_ready = '1';
				end if;

			when others =>
				next_conf_state <= function_set;
		end case;
	end if;
end process;
----------------------------------------------------------------------------------
-- LCD Send Byte
----------------------------------------------------------------------------------
lcd_send_byte : process(clock50, reset_fpga) 
variable counter : integer range 0 to 59000000 := 0;

begin
	current_send_state <= next_send_state;
	counter := counter + 1;

	if reset_fpga = '1' then
		counter := 0;
		current_send_state <= idle;
		send_lcd_e <= '0';
	elsif rising_edge(clock50) and lcd_is_configuring = '0' then
		is_byte_send = '0';
		case current_send_state is
			when idle => 
			when setup_high_nibble =>
			when send_high_nibble =>
			when nibble_separation =>
			when setup_low_nibble =>
			when send_low_nibble =>
			when send_finish =>

			when others =>
				next_send_state <= idle;
		end case;
	end if;
end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end lcd_controller_arch;
