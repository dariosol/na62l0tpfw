--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component fifo1trigger  
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

package component_fifo1trigger is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- fifo1trigger inputs (constant)
--
type fifo1trigger_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (31 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- fifo1trigger outputs (constant)
--
type fifo1trigger_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (31 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (5 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (5 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- fifo1trigger component common interface (constant)
--
type fifo1trigger_t is record
   inputs : fifo1trigger_inputs_t;
   outputs : fifo1trigger_outputs_t;
end record;

--
-- fifo1trigger vector type (constant)
--
type fifo1trigger_vector_t is array(NATURAL RANGE <>) of fifo1trigger_t;

--
-- fifo1trigger component declaration (constant)
--
component fifo1trigger
port (
   inputs : in fifo1trigger_inputs_t;
   outputs : out fifo1trigger_outputs_t
);
end component;

--
-- fifo1trigger global signal to export range/width params (constant)
--
signal component_fifo1trigger : fifo1trigger_t;

end component_fifo1trigger;

--
-- fifo1trigger entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_fifo1trigger.all;

-- fifo1trigger entity (constant)
entity fifo1trigger is
port (
   inputs : in fifo1trigger_inputs_t;
   outputs : out fifo1trigger_outputs_t
);
end fifo1trigger;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of fifo1trigger is

--
-- altfifo1trigger component declaration (constant)
--
component altfifo1trigger
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (31 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q : out STD_LOGIC_VECTOR (31 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (5 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (5 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altfifo1trigger_inst : altfifo1trigger port map
(
   aclr => inputs.aclr,
   data => inputs.data,
   rdclk => inputs.rdclk,
   rdreq => inputs.rdreq,
   wrclk => inputs.wrclk,
   wrreq => inputs.wrreq,
   q => outputs.q,
   rdempty => outputs.rdempty,
   rdfull => outputs.rdfull,
   rdusedw => outputs.rdusedw,
   wrempty => outputs.wrempty,
   wrfull => outputs.wrfull,
   wrusedw => outputs.wrusedw
);

end rtl;
