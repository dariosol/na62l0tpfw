--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component MIRRORFIFO  
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

package component_MIRRORFIFO is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- MIRRORFIFO inputs (constant)
--
type MIRRORFIFO_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- MIRRORFIFO outputs (constant)
--
type MIRRORFIFO_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (8 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (8 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- MIRRORFIFO component common interface (constant)
--
type MIRRORFIFO_t is record
   inputs : MIRRORFIFO_inputs_t;
   outputs : MIRRORFIFO_outputs_t;
end record;

--
-- MIRRORFIFO vector type (constant)
--
type MIRRORFIFO_vector_t is array(NATURAL RANGE <>) of MIRRORFIFO_t;

--
-- MIRRORFIFO component declaration (constant)
--
component MIRRORFIFO
port (
   inputs : in MIRRORFIFO_inputs_t;
   outputs : out MIRRORFIFO_outputs_t
);
end component;

--
-- MIRRORFIFO global signal to export range/width params (constant)
--
signal component_MIRRORFIFO : MIRRORFIFO_t;

end component_MIRRORFIFO;

--
-- MIRRORFIFO entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_MIRRORFIFO.all;

-- MIRRORFIFO entity (constant)
entity MIRRORFIFO is
port (
   inputs : in MIRRORFIFO_inputs_t;
   outputs : out MIRRORFIFO_outputs_t
);
end MIRRORFIFO;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of MIRRORFIFO is

--
-- altMIRRORFIFO component declaration (constant)
--
component altMIRRORFIFO
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q     : out STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (8 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (8 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altMIRRORFIFO_inst : altMIRRORFIFO port map
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
