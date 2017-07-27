--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component FIFODETECTORFARM  
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

package component_FIFODETECTORFARM is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- FIFODETECTORFARM inputs (constant)
--
type FIFODETECTORFARM_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (10 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- FIFODETECTORFARM outputs (constant)
--
type FIFODETECTORFARM_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (10 DOWNTO 0);
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
-- FIFODETECTORFARM component common interface (constant)
--
type FIFODETECTORFARM_t is record
   inputs : FIFODETECTORFARM_inputs_t;
   outputs : FIFODETECTORFARM_outputs_t;
end record;

--
-- FIFODETECTORFARM vector type (constant)
--
type FIFODETECTORFARM_vector_t is array(NATURAL RANGE <>) of FIFODETECTORFARM_t;

--
-- FIFODETECTORFARM component declaration (constant)
--
component FIFODETECTORFARM
port (
   inputs : in FIFODETECTORFARM_inputs_t;
   outputs : out FIFODETECTORFARM_outputs_t
);
end component;

--
-- FIFODETECTORFARM global signal to export range/width params (constant)
--
signal component_FIFODETECTORFARM : FIFODETECTORFARM_t;

end component_FIFODETECTORFARM;

--
-- FIFODETECTORFARM entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_FIFODETECTORFARM.all;

-- FIFODETECTORFARM entity (constant)
entity FIFODETECTORFARM is
port (
   inputs : in FIFODETECTORFARM_inputs_t;
   outputs : out FIFODETECTORFARM_outputs_t
);
end FIFODETECTORFARM;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of FIFODETECTORFARM is

--
-- altFIFODETECTORFARM component declaration (constant)
--
component altFIFODETECTORFARM
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (10 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q     : out STD_LOGIC_VECTOR (10 DOWNTO 0);
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
altFIFODETECTORFARM_inst : altFIFODETECTORFARM port map
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
