--**************************************************************
--**************************************************************
--
-- Template file: compmap1.rec (Std --> RecType)
--
--**************************************************************
--**************************************************************
--
--
-- Component fifoMTPnum  
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

package component_fifoMTPnum is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- fifoMTPnum inputs (constant)
--
type fifoMTPnum_inputs_t is record

   -- input list
   aclr : STD_LOGIC;
   data : STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdclk : STD_LOGIC;
   rdreq : STD_LOGIC;
   wrclk : STD_LOGIC;
   wrreq : STD_LOGIC;

end record;

--
-- fifoMTPnum outputs (constant)
--
type fifoMTPnum_outputs_t is record

   -- output list
   q : STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdempty : STD_LOGIC;
   rdfull : STD_LOGIC;
   rdusedw : STD_LOGIC_VECTOR (2 DOWNTO 0);
   wrempty : STD_LOGIC;
   wrfull : STD_LOGIC;
   wrusedw : STD_LOGIC_VECTOR (2 DOWNTO 0);

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- fifoMTPnum component common interface (constant)
--
type fifoMTPnum_t is record
   inputs : fifoMTPnum_inputs_t;
   outputs : fifoMTPnum_outputs_t;
end record;

--
-- fifoMTPnum vector type (constant)
--
type fifoMTPnum_vector_t is array(NATURAL RANGE <>) of fifoMTPnum_t;

--
-- fifoMTPnum component declaration (constant)
--
component fifoMTPnum
port (
   inputs : in fifoMTPnum_inputs_t;
   outputs : out fifoMTPnum_outputs_t
);
end component;

--
-- fifoMTPnum global signal to export range/width params (constant)
--
signal component_fifoMTPnum : fifoMTPnum_t;

end component_fifoMTPnum;

--
-- fifoMTPnum entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_fifoMTPnum.all;

-- fifoMTPnum entity (constant)
entity fifoMTPnum is
port (
   inputs : in fifoMTPnum_inputs_t;
   outputs : out fifoMTPnum_outputs_t
);
end fifoMTPnum;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of fifoMTPnum is

--
-- altfifoMTPnum component declaration (constant)
--
component altfifoMTPnum
port
(
   aclr : in STD_LOGIC  := '0';
   data : in STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdclk : in STD_LOGIC;
   rdreq : in STD_LOGIC;
   wrclk : in STD_LOGIC;
   wrreq : in STD_LOGIC;
   q : out STD_LOGIC_VECTOR (7 DOWNTO 0);
   rdempty : out STD_LOGIC;
   rdfull : out STD_LOGIC;
   rdusedw : out STD_LOGIC_VECTOR (2 DOWNTO 0);
   wrempty : out STD_LOGIC;
   wrfull : out STD_LOGIC;
   wrusedw : out STD_LOGIC_VECTOR (2 DOWNTO 0)
);
end component;

begin

--
-- component port map (constant)
--
altfifoMTPnum_inst : altfifoMTPnum port map
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
