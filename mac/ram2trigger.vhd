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

package component_ram2trigger is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- ram2trigger inputs (constant)
--
type ram2trigger_inputs_t is record

   -- input list
      address_a		:  STD_LOGIC_VECTOR (13 DOWNTO 0);
      address_b		:  STD_LOGIC_VECTOR (13	DOWNTO 0);
      clock_a		:  STD_LOGIC ;
      clock_b		:  STD_LOGIC ;
      data_a		:  STD_LOGIC_VECTOR (41 DOWNTO 0);
      data_b		:  STD_LOGIC_VECTOR (41 DOWNTO 0);
      wren_a		:  STD_LOGIC  ;
      wren_b		:  STD_LOGIC  ;
      rden_a		:  STD_LOGIC  ;
      rden_b		:  STD_LOGIC  ;
end record;

--
--  ram2trigger outputs (constant)
--
type ram2trigger_outputs_t is record

   -- output list
   q_a		:  STD_LOGIC_VECTOR (41	DOWNTO 0);
   q_b		:  STD_LOGIC_VECTOR (41 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- ram2trigger component common interface (constant)
--
type ram2trigger_t is record
   inputs  : ram2trigger_inputs_t;
   outputs : ram2trigger_outputs_t;
end record;

--
-- ram2trigger vector type (constant)
--
type ram2trigger_vector_t is array(NATURAL RANGE <>) of ram2trigger_t;

--
--  ram2trigger component declaration (constant)
--
component ram2trigger
port (
   inputs  : in ram2trigger_inputs_t;
   outputs : out ram2trigger_outputs_t
);
end component;

--
-- ram2trigger global signal to export params (constant)
--
signal component_ram2trigger : ram2trigger_t;

end component_ram2trigger;

--
-- ram2trigger entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_ram2trigger.all;

--  ram2trigger entity (constant)
entity ram2trigger is
port (
   inputs  : in ram2trigger_inputs_t;
   outputs : out ram2trigger_outputs_t
);
end ram2trigger;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of ram2trigger is

--
-- altdpramDARIO component declaration (constant)
--
component altram2trigger
port
(
      address_a		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      address_b	: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      clock_a		: IN STD_LOGIC  := '1';
      clock_b		: IN STD_LOGIC ;
      data_a		: IN STD_LOGIC_VECTOR (41 DOWNTO 0);
      data_b		: IN STD_LOGIC_VECTOR (41 DOWNTO 0);
      wren_a		: IN STD_LOGIC  := '0';
      wren_b		: IN STD_LOGIC  := '0';
      rden_a		: IN STD_LOGIC  := '0';
      rden_b		: IN STD_LOGIC  := '0';
      q_a		: OUT STD_LOGIC_VECTOR (41 DOWNTO 0);
      q_b		: OUT STD_LOGIC_VECTOR (41 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altram2trigger_inst : altram2trigger port map
(
   address_a=>inputs.address_a,
	address_b=>inputs.address_b,
	clock_a=>inputs.clock_a,
	clock_b=>inputs.clock_b,
	data_a=>inputs.data_a,
	data_b=>inputs.data_b,
	wren_a=>inputs.wren_a,
	wren_b=>inputs.wren_b,
	rden_a=>inputs.rden_a,
	rden_b=>inputs.rden_b,
	q_a => outputs.q_a,
	q_b =>outputs.q_b
	);

end rtl;
