--DPRAM 32 bit for data coming from pc trigger
--
--**************************************************************
--**************************************************************

--**************************************************************
--
--
-- Component Interface
--
--
--**************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package component_ram1trigger is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- ram1trigger inputs (constant)
--
type ram1trigger_inputs_t is record

   -- input list
      address_a		:  STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b		:  STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock_a		:  STD_LOGIC ;
		clock_b		:  STD_LOGIC ;
		data_a		:  STD_LOGIC_VECTOR (19 DOWNTO 0);
		data_b		:  STD_LOGIC_VECTOR (19 DOWNTO 0);
		wren_a		:  STD_LOGIC  ;
		wren_b		:  STD_LOGIC  ;
		rden_a		:  STD_LOGIC  ;
		rden_b		:  STD_LOGIC  ;
end record;

--
--  ram1trigger outputs (constant)
--
type ram1trigger_outputs_t is record

   -- output list
	q_a		:  STD_LOGIC_VECTOR (19	DOWNTO 0);
	q_b		:  STD_LOGIC_VECTOR (19 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- ram1trigger component common interface (constant)
--
type ram1trigger_t is record
   inputs  : ram1trigger_inputs_t;
   outputs : ram1trigger_outputs_t;
end record;

--
-- ram1trigger vector type (constant)
--
type ram1trigger_vector_t is array(NATURAL RANGE <>) of ram1trigger_t;

--
--  ram1trigger component declaration (constant)
--
component ram1trigger
port (
   inputs  : in ram1trigger_inputs_t;
   outputs : out ram1trigger_outputs_t
);
end component;

--
-- ram1trigger global signal to export params (constant)
--
signal component_ram1trigger : ram1trigger_t;

end component_ram1trigger;

--
-- ram1trigger entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_ram1trigger.all;

--  ram1trigger entity (constant)
entity ram1trigger is
port (
   inputs  : in ram1trigger_inputs_t;
   outputs : out ram1trigger_outputs_t
);
end ram1trigger;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of ram1trigger is

--
-- altdpramDARIO component declaration (constant)
--
component altram1trigger
port
(
      address_a		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (19 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (19 DOWNTO 0);
		rden_a		: IN STD_LOGIC  ;
		rden_b		: IN STD_LOGIC  
);
end component;

begin

--
-- component port map (constant)
--
altram1trigger_inst : altram1trigger port map
(
   address_a=>inputs.address_a,
	address_b=>inputs.address_b,
	clock_a=>inputs.clock_a,
	clock_b=>inputs.clock_b,
	data_a=>inputs.data_a,
	data_b=>inputs.data_b,
	wren_a=>inputs.wren_a,
	wren_b=>inputs.wren_b,
	q_a => outputs.q_a,
	q_b =>outputs.q_b,
	rden_a => inputs.rden_a,
   rden_b => inputs.rden_b
	);

end rtl;
