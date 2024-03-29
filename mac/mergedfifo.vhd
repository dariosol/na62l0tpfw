--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component mergedfifo  
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

package component_mergedfifo is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- mergedfifo inputs (constant)
--
type mergedfifo_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (39 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- mergedfifo outputs (constant)
--
type mergedfifo_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (39 DOWNTO 0);
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
-- mergedfifo component common interface (constant)
--
type mergedfifo_t is record
   inputs : mergedfifo_inputs_t;
   outputs : mergedfifo_outputs_t;
end record;

--
-- mergedfifo vector type (constant)
--
type mergedfifo_vector_t is array(NATURAL RANGE <>) of mergedfifo_t;

--
-- mergedfifo component declaration (constant)
--
component mergedfifo
port (
   inputs : in mergedfifo_inputs_t;
   outputs : out mergedfifo_outputs_t
);
end component;

--
-- mergedfifo global signal to export range/width params (constant)
--
signal component_mergedfifo : mergedfifo_t;

end component_mergedfifo;

--
-- mergedfifo entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_mergedfifo.all;

-- mergedfifo entity (constant)
entity mergedfifo is
port (
   inputs : in mergedfifo_inputs_t;
   outputs : out mergedfifo_outputs_t
);
end mergedfifo;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of mergedfifo is

--
-- altmergedfifo component declaration (constant)
--
component altmergedfifo
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (39 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q     : out STD_LOGIC_VECTOR (39 DOWNTO 0);
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
altmergedfifo_inst : altmergedfifo port map
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
