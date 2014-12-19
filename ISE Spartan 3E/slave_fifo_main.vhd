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
entity slave_fifo_main is port
(
	clock50 : in std_logic; -- input 50 MHz onboard clock
	clock100_out : out std_logic; -- output 100 MHz clock to FX3 (PCLK)

	reset_from_slide : in std_logic;
	reset_from_fx3 : in std_logic; -- input reset FIFO from FX3 (INT_N_CTL15)
	reset_to_fx3 : out std_logic; -- RESET
	
	slide_select_mode : in std_logic_vector(2 downto 0):="000"; -- select mode (idle, stream, loop)
    leds_show_mode : out std_logic:='0'; -- show mode on leds

    address : out std_logic_vector(1 downto 0):="00"; -- 2-bit address bus (A)
	data : inout std_logic_vector(15 downto 0):="0000000000000000"; -- 16-bit data bus (DQ)
	pktend : out std_logic;
	pmode : out std_logic_vector(1 downto 0);

	slcs : out std_logic; -- chip select
	slwr : out std_logic; -- write strobe
	slrd : out std_logic; -- read strobe
	sloe : out std_logic; -- output enable

	flaga : in std_logic; -- write
	flagb : in std_logic; -- write
	flagc : in std_logic; -- read
	flagd : in std_logic; -- read
	
	lcd_e : out std_logic; -- lcd enable
	lcd_rs : out std_logic; 
	lcd_rw : out std_logic;
	lcd_data : out std_logic_vector(3 downto 0); -- lcd 4-bit bus
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
constant RESET_MODE : std_logic_vector(2 downto 0):="101";
----------------------------------------------------------------------------------
-- LCD Signals
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
-- General Signals
----------------------------------------------------------------------------------
signal clock100 : std_logic;
signal lcd_clock50 : std_logic;
signal reset_fpga : std_logic:='0';
signal locked : std_logic:='0';
signal data_get : std_logic_vector(15 downto 0);
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
----------------------------------------------------------------------------------
-- Stream In Signals
----------------------------------------------------------------------------------
signal stream_in_mode_active: std_logic;
signal data_stream_in : std_logic_vector(15 downto 0);
signal slwr_stream_in: std_logic;
----------------------------------------------------------------------------------
-- Stream Out Signals
----------------------------------------------------------------------------------
signal stream_out_mode_active: std_logic;
signal data_stream_out : std_logic_vector(15 downto 0);
signal sloe_stream_out : std_logic;
signal slrd_stream_out : std_logic;
signal data_stream_out_ok : std_logic;
----------------------------------------------------------------------------------
-- Loopback Signals
----------------------------------------------------------------------------------
signal loopback_mode_active: std_logic;
----------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------
component slave_fifo_dcm port
(
	CLKIN_IN : IN std_logic;
	RST_IN : IN std_logic;          
	CLKIN_IBUFG_OUT : OUT std_logic;
	CLK0_OUT : OUT std_logic;
	CLK2X_OUT : OUT std_logic;
	LOCKED_OUT : OUT std_logic
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
	data_request : in std_logic;
	clear : in std_logic;
	goto : in std_logic_vector(7 downto 0);
	goto_request : in std_logic;
	request_served : out std_logic;
	display_ready : buffer std_logic
); end component;
component slave_fifo_stream_in port 
(
	clock100 : in std_logic;
	flaga_get : in std_logic;
	flagb_get : in std_logic;
	reset : in std_logic;
	stream_in_mode_active : in std_logic;
	slwr_stream_in : out std_logic;
	data_stream_in : out std_logic_vector(15 downto 0)
); end component;
component slave_fifo_stream_out port 
(
	clock100 					: in std_logic;
	flagc_get 					: in std_logic;
	flagd_get 					: in std_logic;
	reset 						: in std_logic;
	stream_out_mode_active 		: in std_logic;
	data_stream_out	: in std_logic_vector(15 downto 0);
	sloe_stream_out 			: out std_logic;
	slrd_stream_out 			: out std_logic;
	data_stream_out_ok 			: out std_logic
); end component;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------	
function chr(sl: std_logic) return character is
    variable c: character;
    begin
      case sl is
         when 'U' => c:= 'U';
         when 'X' => c:= 'X';
         when '0' => c:= '0';
         when '1' => c:= '1';
         when 'Z' => c:= 'Z';
         when 'W' => c:= 'W';
         when 'L' => c:= 'L';
         when 'H' => c:= 'H';
         when '-' => c:= '-';
      end case;
    return c;
   end chr;
function str(slv: std_logic_vector) return string is
     variable result : string (1 to slv'length);
     variable r : integer;
   begin
     r := 1;
     for i in slv'range loop
        result(r) := chr(slv(i));
        r := r + 1;
     end loop;
     return result;
   end str;
begin
----------------------------------------------------------------------------------
-- Port Maps
----------------------------------------------------------------------------------
inst_slave_fifo_dcm : slave_fifo_dcm port map
(
	CLKIN_IN => clock50,
	RST_IN => '0',
	CLKIN_IBUFG_OUT => open,
	CLK0_OUT => lcd_clock50,
	CLK2X_OUT => clock100,
	LOCKED_OUT => locked
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
	data_request => data_request,
	clear => clear,
	goto => goto,
	goto_request => goto_request,
	request_served => request_served,
	display_ready => display_ready
);
inst_stream_in : slave_fifo_stream_in port map
(
	clock100 => clock100,
	flaga_get => flaga_get,
	flagb_get => flagb_get,
	reset => not reset_fpga,
	stream_in_mode_active => stream_in_mode_active,
	slwr_stream_in => slwr_stream_in,
	data_stream_in => data_stream_in
);
int_stream_out : slave_fifo_stream_out port map
(
	clock100 => clock100,
	flagc_get => flagc_get,
	flagd_get => flagd_get,
	reset => not reset_fpga,
	stream_out_mode_active => stream_out_mode_active,
	data_stream_out => data_stream_out,
	sloe_stream_out => sloe_stream_out,
	slrd_stream_out => slrd_stream_out,
	data_stream_out_ok => data_stream_out_ok
);
----------------------------------------------------------------------------------
-- General Signals
----------------------------------------------------------------------------------
clock100_out <= clock100;
reset_fpga <= reset_from_slide;

lcd_srataflash_disable <= '1';
reset_to_fx3 <= '1';
pmode <= "11";
pktend_get <= '1';

leds_show_mode <= data_stream_out_ok;--stream_in_mode_active or stream_out_mode_active;
----------------------------------------------------------------------------------
-- FPGA Send All Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if reset_fpga = '1' then
		data <= (others => '0');
    elsif (rising_edge(clock100)) then
    	data <= data_get;
    	address <= address_get;
    	slwr <= slwr_get;
    	slcs <= slcs_get;
		slrd <= slrd_get;
		sloe <= sloe_get;
		pktend <= pktend_get;
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
-- Get Chip Select Signal 
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = idle_state then
		slcs_get <= '1';
    else 
    	slcs_get <= '0';
    end if;
end process;
----------------------------------------------------------------------------------
-- Get Current FPGA Data
----------------------------------------------------------------------------------
process (current_state) begin
    case current_state is
        when loopback_state => 
            data_get <= (others => '1');
        when stream_out_state => 
            data_get <= data_stream_out;
        when stream_in_state => 
            data_get <= data_stream_in;
        when others => 
            data_get <= (others => '1');
    end case;
end process;
----------------------------------------------------------------------------------
-- Get Loopback, Stream Out, Stream In Mode Active Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = loopback_state then
		loopback_mode_active <= '1';
	else 
		loopback_mode_active <= '0';
	end if;
	if current_state = stream_out_state then
		stream_out_mode_active <= '1';
	else 
		stream_out_mode_active <= '0';
	end if;
	if current_state = stream_in_state then
		stream_in_mode_active <= '1';
	else 
		stream_in_mode_active <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- Get Output/Enable, Read/Write and Write Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_in_state then
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= slwr_stream_in;
	elsif current_state = stream_out_state then
		sloe_get <= sloe_stream_out;
		slrd_get <= slrd_stream_out;
		slwr_get <= '1';
	else
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- Get Address Signals
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_in_state then	
		address_get <= "00";
	elsif current_state = stream_out_state or current_state = loopback_state then
		address_get <= "11";
	end if;
end process;
----------------------------------------------------------------------------------
-- FPGA Master-Mode Change State and Select Mode from Slide Switches
----------------------------------------------------------------------------------
process (clock100, reset_fpga) begin
    if (reset_fpga = '1')  then
        current_state <= idle_state;
        current_mode <= MASTER_IDLE;
		text_line1 <= "FSM FPGA";
		text_line2 <= "MODE: RESET     ";
    elsif (rising_edge(clock100)) then
    	text_line1 <= "FSM FPGA";
        current_state <= next_state;
        current_mode <= slide_select_mode;
        case current_state is
            when loopback_state => 
            	text_line2 <= "MODE: LOOPBACK  ";
            when stream_out_state => 
	            text_line2 <= str(data_stream_out);
            when stream_in_state => 
	            text_line2 <= "MODE: STREAM IN ";
            when others => 
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
process(lcd_clock50, request_served)
	variable counter : integer range 0 to 50000000 := 1;
	variable letter_index : integer := 0;
begin
	if rising_edge(lcd_clock50) then
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

