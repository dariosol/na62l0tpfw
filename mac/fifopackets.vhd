--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component fifopackets  
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

package component_fifopackets is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- fifopackets inputs (constant)
--
type fifopackets_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (703 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- fifopackets outputs (constant)
--
type fifopackets_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (703 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (6 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (6 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- fifopackets component common interface (constant)
--
type fifopackets_t is record
   inputs : fifopackets_inputs_t;
   outputs : fifopackets_outputs_t;
end record;

--
-- fifopackets vector type (constant)
--
type fifopackets_vector_t is array(NATURAL RANGE <>) of fifopackets_t;

--
-- fifopackets component declaration (constant)
--
component fifopackets
port (
   inputs : in fifopackets_inputs_t;
   outputs : out fifopackets_outputs_t
);
end component;

--
-- fifopackets global signal to export range/width params (constant)
--
signal component_fifopackets : fifopackets_t;

end component_fifopackets;

--
-- fifopackets entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_fifopackets.all;

-- fifopackets entity (constant)
entity fifopackets is
port (
   inputs : in fifopackets_inputs_t;
   outputs : out fifopackets_outputs_t
);
end fifopackets;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of fifopackets is

--
-- altfifopackets component declaration (constant)
--
component altfifopackets
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (703 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q : out STD_LOGIC_VECTOR (703 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (6 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (6 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altfifopackets_inst : altfifopackets port map
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
