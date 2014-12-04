----------------------------------------------------------------------------------
-- Synchronous Slave FIFO Interface Main Module
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;
----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------
entity slave_fifo_main is 
generic 
(
    fifo_mode_bit   : natural := 3
);
Port 
(
    clock50     : in std_logic;         -- default input clock 50 MHz
    pclk : out std_logic;
    fifo_mode   : in std_logic_vector(fifo_mode_bit-1 downto 0):="000";             -- select mode: (000) idle, (001) loop, (010) stream out, (100) stream in
    reset_n_con : in std_logic;                                                 -- input reset FIFO
    
    lcd_strataflash : out std_logic;
    lcd_e : out std_logic;
    lcd_rs : out std_logic; -- 1 lcd_data register; 0 command/instruction
    lcd_rw : out std_logic;
    lcd_data_out : out std_logic_vector(3 downto 0)
);
end slave_fifo_main;
----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------
architecture slave_fifo_main_arch of slave_fifo_main is
----------------------------------------------------------------------------------
-- FPGA Master-Mode Finished State Machine
----------------------------------------------------------------------------------
type fpga_master_states is (idle_state, loopback_state, stream_out_state, stream_in_state);
signal current_state, next_state : fpga_master_states;

type lcd_states is (start, clearscr, move1, move2, idle, send1, send2);
signal lcd_current_state : lcd_states := start;
----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
constant MASTER_IDLE : std_logic_vector(2 downto 0):="000";
constant LOOPBACK : std_logic_vector(2 downto 0):="001";
constant STREAM_OUT : std_logic_vector(2 downto 0):="010";
constant STREAM_IN : std_logic_vector(2 downto 0):="100";
----------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------
signal reset_dcm : std_logic:='0';
signal reset_fpga : std_logic:='0';
signal locked : std_logic:='0';
signal clock100 : std_logic;
signal current_mode : std_logic_vector(2 downto 0);

signal lcd_data_in, goto : std_logic_vector(7 downto 0);
signal data_request, clear, goto_request, request_served, display_ready : std_logic;
----------------------------------------------------------------------------------
-- Text Variables
----------------------------------------------------------------------------------
signal text_line1 : string(1 to 12) := "Current Mode";
signal text_line2 : string(1 to 16);
----------------------------------------------------------------------------------
-- Components
----------------------------------------------------------------------------------
COMPONENT clock_dcm PORT 
(
    CLKIN_IN : IN std_logic;
    RST_IN : IN std_logic;          
    CLKIN_IBUFG_OUT : OUT std_logic;
    CLK0_OUT : OUT std_logic;
    CLK2X_OUT : OUT std_logic;
    LOCKED_OUT : OUT std_logic
);
END COMPONENT;
component lcd_controller port
(
    clock50 : in std_logic;
    reset_fpga : in std_logic;
    lcd_e : out std_logic;
    lcd_rs : out std_logic;
    lcd_rw : out std_logic;
    lcd_data_out : out std_logic_vector(3 downto 0);
    lcd_data_input : in std_logic_vector(7 downto 0);
    lcd_data_request : in std_logic;
    lcd_clear : in std_logic;
    lcd_goto : in std_logic_vector(7 downto 0);
    lcd_goto_request : in std_logic;
    lcd_request_served : out std_logic;
    lcd_ready : buffer std_logic
);
end component;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------
-- Generate 100 MHz Clock (DCM)
----------------------------------------------------------------------------------
Inst_clock_dcm : clock_dcm PORT MAP
(
    CLKIN_IN => clock50,
    RST_IN => reset_dcm,
    CLKIN_IBUFG_OUT => open,
    CLK0_OUT => open,
    CLK2X_OUT => clock100,
    LOCKED_OUT => locked
);
----------------------------------------------------------------------------------
-- LCD Controller Port Map
----------------------------------------------------------------------------------
Inst_lcd_controller : lcd_controller PORT MAP
(
    clock50 => clock50,
    reset_fpga => reset_fpga,
    lcd_e => lcd_e,
    lcd_rs => lcd_rs,
    lcd_rw => lcd_rw,
    lcd_data_out => lcd_data_out,
    lcd_data_input => lcd_data_in,
    lcd_data_request => data_request,
    lcd_clear => clear,
    lcd_goto => goto,
    lcd_goto_request => goto_request,
    lcd_request_served => request_served,
    lcd_ready => display_ready
);
-- -- -- -- -- -- Signals
pclk <= clock100;               -- send to FX3 synch clock

reset_dcm <= not reset_n_con;   -- original active low, so set it to high
reset_fpga <= not locked;       -- if clock is not stable or DCM is not working

lcd_strataflash <= '1';
----------------------------------------------------------------------------------
-- FPGA Master-Mode Change State and Select Mode from Slide Switches
----------------------------------------------------------------------------------
process (clock100, reset_fpga) begin
    if(reset_fpga='0') then
        current_state <= idle_state;
        current_mode <= MASTER_IDLE;
    elsif (rising_edge(clock100)) then
        current_state <= next_state;
        current_mode <= fifo_mode;
    end if;
end process;
----------------------------------------------------------------------------------
-- FPGA State Machine
----------------------------------------------------------------------------------
process(current_state, current_mode) begin
    case current_state is
        when idle_state =>
            case current_mode is
                when LOOPBACK =>
                    next_state <= loopback_state;
                when STREAM_OUT =>
                    next_state <= stream_out_state;
                when STREAM_IN =>
                    next_state <= stream_in_state;
                when others =>
                    next_state <= idle_state;
            end case;

        when loopback_state =>
            case current_mode is
                when LOOPBACK =>
                    next_state <= loopback_state;
                    text_line2 <= "Loopback Mode   ";
                when others =>
                    next_state <= idle_state; 
            end case;

        when stream_out_state =>
            case current_mode is
                when STREAM_OUT =>
                    next_state <= stream_out_state;
                    text_line2 <= "Stream Out Mode ";
                when others =>
                    next_state <= idle_state;
            end case;

        when stream_in_state =>
            case current_mode is
                when STREAM_IN =>
                    next_state <= stream_in_state;
                    text_line2 <= "Stream In Mode  ";
                when others =>
                    next_state <= idle_state;
            end case;

        when others => 
            next_state <= idle_state;
    end case;
end process;
----------------------------------------------------------------------------------
-- LCD Main Process
----------------------------------------------------------------------------------
lcd_show : process(reset_fpga, clock50, request_served)
        variable counter : integer range 0 to 50000000 := 1;
        variable letter_index : integer := 0;
    begin
        if reset_fpga = '1' then
            counter := 1;
            lcd_current_state <= start;
        elsif rising_edge(clock50) then
            case lcd_current_state is
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
                        goto <= "10000011";
                        goto_request <= '1';
                    elsif request_served = '1' then
                        goto_request <= '0';
                        lcd_current_state <= send1;
                        counter := 0;
                    end if;
                when send1 =>
                    if counter = 1 then
                        letter_index := letter_index + 1;
                        lcd_data_in <= conv_std_logic_vector(character'pos(text_line1(letter_index)), 8);
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
                        goto <= "11000101";
                        goto_request <= '1';
                    elsif request_served = '1' then
                        goto_request <= '0';
                        lcd_current_state <= send2;
                        counter := 0;
                        letter_index := 0;
                    end if;
                when send2 =>
                    if counter = 1 then
                        letter_index := letter_index + 1;
                        lcd_data_in <= conv_std_logic_vector(character'pos(text_line2(letter_index)), 8);
                        data_request <= '1';
                    elsif request_served = '1' then
                        data_request <= '0';
                        counter := 0;
                        if letter_index = text_line2'length then
                            lcd_current_state <= idle;
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
end slave_fifo_main_arch;