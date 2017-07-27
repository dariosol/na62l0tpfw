library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.globals.all;

package component_TriggerLUT is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- TriggerLUT inputs (constant)
--
type TriggerLUT_inputs_t is record

   -- input list
	clk              : std_logic                          ;
	reset            : std_logic                          ;
	wena             : std_logic                          ;
	detector         : vector16bit_t(0 to ethlink_NODES-2);
	primitiveID0        : vector16bit_t(0 to ethlink_NODES-2);
	primitiveID1        : vector16bit_t(0 to ethlink_NODES-2);
	primitiveID2        : vector16bit_t(0 to ethlink_NODES-2);
	timestamp_in     : std_logic_vector(31 downto 0)      ;
	finetime_ref_in  : std_logic_vector(7 downto 0)       ;
	finetime_in0     : vector8bit_t(0 to ethlink_NODES-2) ;
	finetime_in1     : vector8bit_t(0 to ethlink_NODES-2) ;
	finetime_in2     : vector8bit_t(0 to ethlink_NODES-2) ;
	mask             : mem                                ;
	dontcare         : mem                                ;
	control_detector_mask : std_logic_vector(111 downto 0) ;
	control_detector_dontcare : std_logic_vector(111 downto 0);

	enable_mask      : std_logic_vector(nmask-1 downto 0) ;
        enable_control_detector : std_logic                   ;
	control_detector : std_logic_vector(1 downto 0)       ;
	bit_finetime     : std_logic_vector(2 downto 0)       ;
end record;

--
-- TriggerLUT outputs (constant)
--
type TriggerLUT_outputs_t is record

   -- output list
	timestamp_out            :std_logic_vector(31 downto 0)       ;
	triggerword              : std_logic_vector(7 downto 0)       ;
	rdready                  : std_logic                          ;
	n_of_trigger             : std_logic_vector(nmask-1 downto 0) ;
	finetime_ref_out         : std_logic_vector(7 downto 0)       ;
	finetime_out0            : vector8bit_t(0 to ethlink_NODES-2) ;	
	finetime_out1            : vector8bit_t(0 to ethlink_NODES-2) ;	
	finetime_out2            : vector8bit_t(0 to ethlink_NODES-2) ;	
	primitiveID_t_out0       : vector16bit_t(0 to ethlink_NODES-2);
	primitiveID_t_out1       : vector16bit_t(0 to ethlink_NODES-2);
	primitiveID_t_out2       : vector16bit_t(0 to ethlink_NODES-2);
	control_detector_out     : std_logic_vector(1 downto 0);
	address_ref              : std_logic_vector(32 downto 0);
	
end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- TriggerLUT component common interface (constant)
--
type TriggerLUT_t is record
	inputs : TriggerLUT_inputs_t;
	outputs : TriggerLUT_outputs_t;
end record;

--
-- TriggerLUT vector type (constant)
--
type TriggerLUT_vector_t is array(NATURAL RANGE <>) of TriggerLUT_t;

--
-- TriggerLUT component declaration (constant)
--
component TriggerLUT
port (
	inputs : in TriggerLUT_inputs_t;
	outputs : out TriggerLUT_outputs_t
);
end component;

--
-- TriggerLUT global signal to export range/width params (constant)
--
signal component_TriggerLUT : TriggerLUT_t;

end component_TriggerLUT;

--
-- TriggerLUT entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.globals.all;
use work.component_TriggerLUT.all;

-- TriggerLUT entity (constant)
entity TriggerLUT is
port (
   inputs : in TriggerLUT_inputs_t;
   outputs : out TriggerLUT_outputs_t
);
end TriggerLUT;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

architecture rtl of TriggerLUT is

--
-- altTriggerLUT component declaration (constant)
--
component altTriggerLUT
port
(
	clk                      : in std_logic;
	reset                    : in std_logic;
	wena                     : in std_logic;
	timestamp_in             : in std_logic_vector(31 downto 0);
	finetime_ref_in          : in std_logic_vector(7 downto 0);
	finetime_in0             : in vector8bit_t(0 to ethlink_NODES-2);
	finetime_in1             : in vector8bit_t(0 to ethlink_NODES-2);
	finetime_in2             : in vector8bit_t(0 to ethlink_NODES-2);
	detector                 : in vector16bit_t(0 to ethlink_NODES-2);
	primitiveID0             : in vector16bit_t(0 to ethlink_NODES-2);
	primitiveID1             : in vector16bit_t(0 to ethlink_NODES-2);
	primitiveID2             : in vector16bit_t(0 to ethlink_NODES-2);
	mask                     : in mem;
	dontcare                 : in mem;
	enable_mask              : in std_logic_vector(nmask-1 downto 0);
	enable_control_detector  : in std_logic;
	control_detector         : in std_logic_vector(1 downto 0);
	control_detector_mask    : in std_logic_vector(111 downto 0);
	control_detector_dontcare: in std_logic_vector(111 downto 0);
	bit_finetime             : in std_logic_vector(2 downto 0);
	
	triggerword              : out std_logic_vector(7 downto 0);
	timestamp_out            : out std_logic_vector(31 downto 0);
	finetime_ref_out         : out std_logic_vector(7 downto 0);
	finetime_out0            : out vector8bit_t(0 to ethlink_NODES-2);
	finetime_out1            : out vector8bit_t(0 to ethlink_NODES-2);
	finetime_out2            : out vector8bit_t(0 to ethlink_NODES-2);
	rdready                  : out std_logic;
	n_of_trigger             : out std_logic_vector(nmask-1 downto 0); 
	primitiveID_t_out0       : out vector16bit_t(0 to ethlink_NODES-2);
	primitiveID_t_out1       : out vector16bit_t(0 to ethlink_NODES-2);
	primitiveID_t_out2       : out vector16bit_t(0 to ethlink_NODES-2);
	control_detector_out     : out std_logic_vector(1 downto 0);
	address_ref              : out std_logic_vector(32 downto 0)
);
end component;

begin

--
-- component port map (constant)
--
altTriggerLUT_inst : altTriggerLUT port map
(
	clk                       => inputs.clk,
	reset                     => inputs.reset,
	wena                      => inputs.wena,
	detector                  => inputs.detector,
	primitiveID0              => inputs.primitiveID0,
	primitiveID1              => inputs.primitiveID1,
	primitiveID2              => inputs.primitiveID2,
	enable_mask               => inputs.enable_mask,
	enable_control_detector   => inputs.enable_control_detector,
	dontcare                  => inputs.dontcare,
	mask                      => inputs.mask,
	control_detector_mask     => inputs.control_detector_mask,
	control_detector_dontcare => inputs.control_detector_dontcare,
	
	timestamp_in              => inputs.timestamp_in,
	finetime_in0              => inputs.finetime_in0,
	finetime_in1              => inputs.finetime_in1,
	finetime_in2              => inputs.finetime_in2,
	finetime_ref_in           => inputs.finetime_ref_in,
	control_detector          => inputs.control_detector,
	bit_finetime              => inputs.bit_finetime,
	
	n_of_trigger              => outputs.n_of_trigger,
	triggerword               => outputs.triggerword,
	timestamp_out             => outputs.timestamp_out,
	rdready                   => outputs.rdready,
	primitiveID_t_out0        => outputs.primitiveID_t_out0,
	primitiveID_t_out1        => outputs.primitiveID_t_out1,
	primitiveID_t_out2        => outputs.primitiveID_t_out2,
	finetime_out0             => outputs.finetime_out0,
	finetime_out1             => outputs.finetime_out1,
	finetime_out2             => outputs.finetime_out2,
	finetime_ref_out          => outputs.finetime_ref_out,
	control_detector_out      => outputs.control_detector_out,
	address_ref               => outputs.address_ref
  );

end rtl;
