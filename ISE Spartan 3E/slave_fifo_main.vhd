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
signal reset_dcm : std_logic:='0';
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
----------------------------------------------------------------------------------
-- Stream In Signals
----------------------------------------------------------------------------------
signal stream_in_mode_active: std_logic;
signal data_stream_in : std_logic_vector(15 downto 0);
signal slwr_stream_in: std_logic;
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
	flaga_d : in std_logic;
	flagb_d : in std_logic;
	reset : in std_logic;
	stream_in_mode_active : in std_logic;
	slwr_stream_in : out std_logic;
	data_stream_in : out std_logic_vector(15 downto 0)
); end component;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------	
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
	flaga_d => flaga_get,
	flagb_d => flagb_get,
	reset => not reset_fpga,
	stream_in_mode_active => stream_in_mode_active,
	slwr_stream_in => slwr_stream_in,
	data_stream_in => data_stream_in
);
----------------------------------------------------------------------------------
-- General Signals
----------------------------------------------------------------------------------
clock100_out <= clock100;
reset_fpga <= reset_from_slide;
lcd_srataflash_disable <= '1';

 
reset_to_fx3 <= '1';
address <= address_get; 

pmode <= "11";
slcs <= slcs_get;
slrd <= slrd_get;
sloe <= sloe_get;

leds_show_mode <= stream_in_mode_active;
----------------------------------------------------------------------------------
-- Get flags - good
----------------------------------------------------------------------------------
process (reset_fpga, clock100) begin
	if reset_fpga = '1' then
		flaga_get <= '0';
		flagb_get <= '0';
    elsif (rising_edge(clock100)) then
    	flaga_get <= flaga;
    	flagb_get <= flagb;
    end if;
end process;
----------------------------------------------------------------------------------
-- Chip select - good
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = idle_state then
		slcs_get <= '1';
    else 
    	slcs_get <= '0';
    end if;
end process;
----------------------------------------------------------------------------------
-- FPGA Data Send/Get - good
----------------------------------------------------------------------------------
process (current_state) begin
	if reset_fpga = '1' then
		data <= (others => '0');
    elsif (rising_edge(clock100)) then
    	data <= data_get;
    	pktend <= pktend_get;
    	slwr <= slwr_get;
    end if;
end process;
----------------------------------------------------------------------------------
-- FPGA Data Switch - good
----------------------------------------------------------------------------------
process (current_state) begin
    case current_state is
        when loopback_state => 
            data_get <= (others => '0');
        when stream_out_state => 
            data_get <= (others => '0');
        when stream_in_state => 
            data_get <= data_stream_in;
        when others => 
            data_get <= (others => '0');
    end case;
end process;
----------------------------------------------------------------------------------
-- Stream In Mode Active - good
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_in_state then
		stream_in_mode_active <= '1';
	else 
		stream_in_mode_active <= '0';
	end if;
end process;
----------------------------------------------------------------------------------
-- Stream In Mode Active
----------------------------------------------------------------------------------
process (current_state) begin
	if current_state = stream_in_state then
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= slwr_stream_in;
		address_get <= "00";
		pktend_get <= '1';
	else 
		sloe_get <= '1';
		slrd_get <= '1';
		slwr_get <= '1';
		address_get <= "11";
		pktend_get <= '1';
	end if;
end process;
----------------------------------------------------------------------------------
-- FPGA Master-Mode Change State and Select Mode from Slide Switches
----------------------------------------------------------------------------------
process (clock100, reset_fpga) begin
    if (reset_fpga = '1')  then
        current_state <= idle_state;
        current_mode <= MASTER_IDLE;
        --leds_show_mode <= '1';
		text_line1 <= "FSM FPGA";
		text_line2 <= "MODE: RESET     ";
    elsif (rising_edge(clock100)) then
    	text_line1 <= "FSM FPGA";
        current_state <= next_state;
        current_mode <= slide_select_mode;

        case current_state is
            when loopback_state => 
            	--leds_show_mode <= '0';
            	text_line2 <= "MODE: LOOPBACK  ";
            when stream_out_state => 
	            --leds_show_mode <= '0'; 
	            text_line2 <= "MODE: STREAM OUT";
            when stream_in_state => 
	            --leds_show_mode <= '1'; 
	            text_line2 <= "MODE: STREAM IN ";
            when others => 
	           -- leds_show_mode <= '0'; 
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

