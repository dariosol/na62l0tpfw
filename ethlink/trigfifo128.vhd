--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component trigfifo128  
--
--
--
--
--
--
-- Notes:
--
-- (edit)     --> custom description (component edit)
-- (constant) --> common description (do not modify)
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

package component_trigfifo128 is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- trigfifo128 inputs (constant)
--
type trigfifo128_inputs_t is record

   -- input list
   clock : STD_LOGIC;
   data : STD_LOGIC_VECTOR (127 DOWNTO 0);
   rdreq : STD_LOGIC;
   sclr : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- trigfifo128 outputs (constant)
--
type trigfifo128_outputs_t is record

   -- output list
   empty : STD_LOGIC;
   full : STD_LOGIC;
   q : STD_LOGIC_VECTOR (127 DOWNTO 0);
   usedw : STD_LOGIC_VECTOR (3 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- trigfifo128 component common interface (constant)
--
type trigfifo128_t is record
   inputs : trigfifo128_inputs_t;
   outputs : trigfifo128_outputs_t;
end record;

--
-- trigfifo128 vector type (constant)
--
type trigfifo128_vector_t is array(NATURAL RANGE <>) of trigfifo128_t;

--
-- trigfifo128 component declaration (constant)
--
component trigfifo128
port (
   inputs : in trigfifo128_inputs_t;
   outputs : out trigfifo128_outputs_t
);
end component;

--
-- trigfifo128 global signal to export range/width params (constant)
--
signal component_trigfifo128 : trigfifo128_t;

end component_trigfifo128;

--
-- trigfifo128 entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_trigfifo128.all;

-- trigfifo128 entity (constant)
entity trigfifo128 is
port (
   inputs : in trigfifo128_inputs_t;
   outputs : out trigfifo128_outputs_t
);
end trigfifo128;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of trigfifo128 is

--
-- altscfifo128 component declaration (constant)
--
component altscfifo128
port
(
   clock : in STD_LOGIC;
   data : in STD_LOGIC_VECTOR (127 DOWNTO 0);
   rdreq : in STD_LOGIC;
   sclr : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   empty : out STD_LOGIC;
   full : out STD_LOGIC;
   q : out STD_LOGIC_VECTOR (127 DOWNTO 0);
   usedw : out STD_LOGIC_VECTOR (3 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altscfifo128_inst : altscfifo128 port map
(
   clock => inputs.clock,
   data => inputs.data,
   rdreq => inputs.rdreq,
   sclr => inputs.sclr,
   wrreq => inputs.wrreq,
   empty => outputs.empty,
   full => outputs.full,
   q => outputs.q,
   usedw => outputs.usedw
);

end rtl;
