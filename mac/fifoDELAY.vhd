--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component FIFODELAY  
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

package component_FIFODELAY is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- FIFODELAY inputs (constant)
--
type FIFODELAY_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (63 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- FIFODELAY outputs (constant)
--
type FIFODELAY_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (63 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (12 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (12 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- FIFODELAY component common interface (constant)
--
type FIFODELAY_t is record
   inputs : FIFODELAY_inputs_t;
   outputs : FIFODELAY_outputs_t;
end record;

--
-- FIFODELAY vector type (constant)
--
type FIFODELAY_vector_t is array(NATURAL RANGE <>) of FIFODELAY_t;

--
-- FIFODELAY component declaration (constant)
--
component FIFODELAY
port (
   inputs : in FIFODELAY_inputs_t;
   outputs : out FIFODELAY_outputs_t
);
end component;

--
-- FIFODELAY global signal to export range/width params (constant)
--
signal component_FIFODELAY : FIFODELAY_t;

end component_FIFODELAY;

--
-- FIFODELAY entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_FIFODELAY.all;

-- FIFODELAY entity (constant)
entity FIFODELAY is
port (
   inputs : in FIFODELAY_inputs_t;
   outputs : out FIFODELAY_outputs_t
);
end FIFODELAY;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of FIFODELAY is

--
-- altFIFODELAY component declaration (constant)
--
component altFIFODELAY
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (63 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q     : out STD_LOGIC_VECTOR (63 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (12 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (12 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altFIFODELAY_inst : altFIFODELAY port map
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
