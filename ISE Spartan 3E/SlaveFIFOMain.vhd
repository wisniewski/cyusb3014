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
	addr_bit 	: natural := 2; 		--how many bits
	data_bit 	: natural := 16;
	pmode_bit 	: natural := 3;
	led_bit 	: natural := 3
);
Port 
(
	clock50 	: in std_logic; 		-- default input clock 50 MHz
	pclk 		: out std_logic; 		-- PCLK 100 MHz output to FX3

	slcs 		: out std_logic;		-- chip select
	slwr 		: out std_logic;		-- write strobe
	slrd 		: out std_logic;		-- read strobe
	sloe 		: out std_logic;		-- output enable
	pktend		: out std_logic;

	flaga 		: in std_logic;			-- write
	flagb 		: in std_logic;			-- write
	flagc 		: in std_logic;			-- read
	flagd 		: in std_logic;			-- read

	address 	: out std_logic_vector(addr_bit-1 downto 0):="00";						-- 2-bit address bus 
	--data 		: inout std_logic_vector(data_bit-1 downto 0):="0000000000000000";		-- 16-bit data bus

	pmode 		: in std_logic_vector(pmode_bit-1 downto 0):="000";				-- select mode: (000) idle, (001) loop, (010) stream out, (100) stream in
	reset_n_con : in std_logic;													-- input reset FIFO
	led_state 	: out std_logic_vector(led_bit-1 downto 0):="111";				-- show current FSM state on LEDs (7, 5, 3)

	--lcd
	strataflash_disable : out std_logic;
    enabled : out std_logic;
    rs : out std_logic; -- 1 data register; 0 command/instruction
    rw : out std_logic;
    db : out std_logic_vector(3 downto 0)
    --/lcd
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
--lcd
signal data, goto : std_logic_vector(7 downto 0);
signal data_request, clear, goto_request, request_served, display_ready : std_logic;
type send_fsm is (start, clearscr, move1, move2, idle, send1, send2);
signal fsm : send_fsm := start;
--/lcd
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
component HitachiLCDController port
(
  mclock : in std_logic;
  reset : in std_logic;
  enabled : out std_logic;
  rs : out std_logic; -- 1 data register; 0 command/instruction
  rw : out std_logic;
  db : out std_logic_vector(3 downto 0);
  data : in std_logic_vector(7 downto 0);
  data_request : in std_logic;
  clear : in std_logic;
  goto : in std_logic_vector(7 downto 0);
  goto_request : in std_logic;
  request_served : out std_logic := '0';
  display_ready : buffer std_logic := '0'
);
end component;
----------------------------------------------------------------------------------
-- Main code begin
----------------------------------------------------------------------------------
begin
-- -- -- -- -- -- Generate 100 MHz Clock (DCM)
Inst_clock_dcm : clock_dcm PORT MAP
(
	CLKIN_IN => clock50,
	RST_IN => reset_dcm,
	CLKIN_IBUFG_OUT => open,
	CLK0_OUT => open,
	CLK2X_OUT => clock100,
	LOCKED_OUT => locked
);
--lcd
strataflash_disable <= '1';
    
lcd : HitachiLCDController port map
(
        mclock => clock50,
        reset => reset_fpga,
        enabled => enabled,
        rs => rs,
        rw => rw,
        db => db,
        data => data,
        data_request => data_request,
        clear => clear,
        goto => goto,
        goto_request => goto_request,
        request_served => request_served,
        display_ready => display_ready
);
    
    test : process(reset_fpga, clock50, request_served)
        variable counter : integer range 0 to 50000000 := 1;
        constant line1 : string(1 to 11) := "Hola mundo.";
        constant line2 : string(1 to 7) := "World 4";
        variable letter_index : integer := 0;
    begin
        if reset_fpga = '1' then
            counter := 1;
            fsm <= start;
        elsif rising_edge(clock50) then
            case fsm is
                when start =>
                    if display_ready = '1' then
                        counter := 0;
                        fsm <= move1;
                    end if;
                when clearscr =>
                    if counter = 1 then
                        clear <= '1';
                    elsif request_served = '1' then
                        clear <= '0';
                        fsm <= move1;
                        counter := 0;
                    end if;
                when move1 =>
                    if counter = 1 then
                        goto <= "10000011";
                        goto_request <= '1';
                    elsif request_served = '1' then
                        goto_request <= '0';
                        fsm <= send1;
                        counter := 0;
                    end if;
                when send1 =>
                    if counter = 1 then
                        letter_index := letter_index + 1;
                        data <= conv_std_logic_vector(character'pos(line1(letter_index)), 8);
                        data_request <= '1';
                    elsif request_served = '1' then
                        data_request <= '0';
                        counter := 0;
                        if letter_index = line1'length then
                            fsm <= move2;
                        end if;
                    end if;
                when move2 =>
                    if counter = 1 then
                        goto <= "11000101";
                        goto_request <= '1';
                    elsif request_served = '1' then
                        goto_request <= '0';
                        fsm <= send2;
                        counter := 0;
                        letter_index := 0;
                    end if;
                when send2 =>
                    if counter = 1 then
                        letter_index := letter_index + 1;
                        data <= conv_std_logic_vector(character'pos(line2(letter_index)), 8);
                        data_request <= '1';
                    elsif request_served = '1' then
                        data_request <= '0';
                        counter := 0;
                        if letter_index = line2'length then
                            fsm <= idle;
                        end if;
                    end if;
                when others => null;
            end case;
            counter := counter + 1;
        end if;
    end process;
  --/lcd

-- -- -- -- -- -- Signals
led_state <= pmode;
address <= "00";
slcs <= '0';
sloe <= '0';
slrd <= '0';
pktend <= '1';
slwr <= '0';
pclk <= clock100;				-- send to FX3 synch clock

reset_dcm <= not reset_n_con;	-- original active low, so set it to high
reset_fpga <= not locked;		-- if clock is not stable or DCM is not working
-- -- -- -- -- -- FPGA Master-Mode Change State
process (clock100, reset_fpga) begin
	if(reset_fpga='0') then
		current_state <= idle_state;
	elsif (rising_edge(clock100)) then
		current_state <= next_state;
	end if;
end process;
-- -- -- -- -- -- Select mode from board switches
process(clock100, reset_fpga) begin
	if reset_fpga='0' then
		current_mode <= MASTER_IDLE;
	elsif(rising_edge(clock100)) then
		current_mode <= pmode;
	end if;
end process;
-- -- -- -- -- FPGA State Machine
--process(current_state, current_mode) begin
--	case current_state is
--		when idle_state =>
--			case current_mode is
--				when LOOPBACK =>
--					next_state <= loopback_state;
--				when STREAM_OUT =>
--					next_state <= stream_out_state;
--				when STREAM_IN =>
--					next_state <= stream_in_state;
--				when others =>
--					next_state <= idle_state;
--			end case;
--		when loopback_state =>
--
--
--	end case;
--end process;
----------------------------------------------------------------------------------
-- End Architecture
----------------------------------------------------------------------------------
end slave_fifo_main_arch;