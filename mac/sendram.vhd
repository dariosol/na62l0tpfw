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

package component_SENDRAM is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- SENDRAM inputs (constant)
--
type SENDRAM_inputs_t is record

   -- input list
      address_a		:  STD_LOGIC_VECTOR (9 DOWNTO 0);
		address_b		:  STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock_a		:  STD_LOGIC ;
		clock_b		:  STD_LOGIC ;
		data_a		:  STD_LOGIC_VECTOR (575 DOWNTO 0);
		data_b		:  STD_LOGIC_VECTOR (575 DOWNTO 0);
		wren_a		:  STD_LOGIC  ;
		wren_b		:  STD_LOGIC  ;
		rden_a		:  STD_LOGIC  ;
		rden_b		:  STD_LOGIC  ;
end record;

--
--  SENDRAM outputs (constant)
--
type SENDRAM_outputs_t is record

   -- output list
	q_a		:  STD_LOGIC_VECTOR (575 DOWNTO 0);
	q_b		:  STD_LOGIC_VECTOR (575 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- SENDRAM component common interface (constant)
--
type SENDRAM_t is record
   inputs  : SENDRAM_inputs_t;
   outputs : SENDRAM_outputs_t;
end record;

--
-- SENDRAM vector type (constant)
--
type SENDRAM_vector_t is array(NATURAL RANGE <>) of SENDRAM_t;

--
--  SENDRAM component declaration (constant)
--
component SENDRAM
port (
   inputs  : in SENDRAM_inputs_t;
   outputs : out SENDRAM_outputs_t
);
end component;

--
-- SENDRAM global signal to export params (constant)
--
signal component_SENDRAM : SENDRAM_t;

end component_SENDRAM;

--
-- SENDRAM entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_SENDRAM.all;

--  SENDRAM entity (constant)
entity SENDRAM is
port (
   inputs  : in SENDRAM_inputs_t;
   outputs : out SENDRAM_outputs_t
);
end SENDRAM;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of SENDRAM is

--
-- altdpramDARIO component declaration (constant)
--
component altSENDRAM
port
(
      address_a	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (575 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (575 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		rden_a		: IN STD_LOGIC  := '1';
		rden_b		: IN STD_LOGIC  := '1';
		q_a		   : OUT STD_LOGIC_VECTOR (575 DOWNTO 0);
		q_b		   : OUT STD_LOGIC_VECTOR (575 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altSENDRAM_inst : altSENDRAM port map
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
