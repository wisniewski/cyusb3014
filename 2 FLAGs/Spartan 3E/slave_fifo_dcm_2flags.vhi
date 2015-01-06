
-- VHDL Instantiation Created from source file slave_fifo_dcm_2flags.vhd -- 11:15:37 01/06/2015
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT slave_fifo_dcm_2flags
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		CLK2X_OUT : OUT std_logic
		);
	END COMPONENT;

	Inst_slave_fifo_dcm_2flags: slave_fifo_dcm_2flags PORT MAP(
		CLKIN_IN => ,
		RST_IN => ,
		CLKIN_IBUFG_OUT => ,
		CLK0_OUT => ,
		CLK2X_OUT => 
	);


