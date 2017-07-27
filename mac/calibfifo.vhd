--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component calibfifo  
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

package component_calibfifo is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- calibfifo inputs (constant)
--
type calibfifo_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (55 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- calibfifo outputs (constant)
--
type calibfifo_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (55 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (4 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (4 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- calibfifo component common interface (constant)
--
type calibfifo_t is record
   inputs : calibfifo_inputs_t;
   outputs : calibfifo_outputs_t;
end record;

--
-- calibfifo vector type (constant)
--
type calibfifo_vector_t is array(NATURAL RANGE <>) of calibfifo_t;

--
-- calibfifo component declaration (constant)
--
component calibfifo
port (
   inputs : in calibfifo_inputs_t;
   outputs : out calibfifo_outputs_t
);
end component;

--
-- calibfifo global signal to export range/width params (constant)
--
signal component_calibfifo : calibfifo_t;

end component_calibfifo;

--
-- calibfifo entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_calibfifo.all;

-- calibfifo entity (constant)
entity calibfifo is
port (
   inputs : in calibfifo_inputs_t;
   outputs : out calibfifo_outputs_t
);
end calibfifo;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of calibfifo is

--
-- altcalibfifo component declaration (constant)
--
component altcalibfifo
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (55 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q : out STD_LOGIC_VECTOR (55 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (4 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (4 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altcalibfifo_inst : altcalibfifo port map
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
