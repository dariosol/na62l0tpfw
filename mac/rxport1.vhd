--**************************************************************
--**************************************************************
--
-- Template file: comp_ck2.rec (new component, dual clk)
--
--**************************************************************
--**************************************************************
--
--
-- Component rxport1
--
-- Array of receiving ports: 
--
-- - output ports:'1..NPORTS' (global param)
-- - received frames are written to rxport array using 'destport' index
-- - dcfifo based clock domain crossing:
--   write side --> common tx/rx clock domain
--   read side  --> user clock domain (each port has dedicated clock domain)
-- - output data width is 8bit (constant value)
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
use work.mac_globals.all;
-- !! Debug !!
use work.component_dcfiforx1.all;
use work.component_dcfiforx2.all;
-- !! Debug !!

package component_rxport1 is

--
-- rxport1 constants (edit)
--

-- total number of output ports (global param)
constant rxport1_NPORTS : natural := RX_NPORTS;
-- note: this is the main entry point for global constants (component description uses its
-- own 'rxport1_NPORTS' constant)   

--
-- rxport1 typedefs (edit)
--

-- rdata single/vector type
subtype rxport1_rdata_t is std_logic_vector(7 downto 0);
type rxport1_rdata_vector_t is array(NATURAL RANGE <>) of rxport1_rdata_t;

-- datalen single/vector type
subtype rxport1_datalen_t is std_logic_vector(13 downto 0);
type rxport1_datalen_vector_t is array(NATURAL RANGE <>) of rxport1_datalen_t;

-- srcport single/vector type
subtype rxport1_srcport_t is std_logic_vector(3 downto 0);
type rxport1_srcport_vector_t is array(NATURAL RANGE <>) of rxport1_srcport_t;

-- srcaddr single/vector type
subtype rxport1_srcaddr_t is std_logic_vector(7 downto 0);
type rxport1_srcaddr_vector_t is array(NATURAL RANGE <>) of rxport1_srcaddr_t;

-- frames single/vector type
subtype rxport1_frames_t is std_logic_vector(4 downto 0);
type rxport1_frames_vector_t is array(NATURAL RANGE <>) of rxport1_frames_t;

-- rxseqnum single/vector type
subtype rxport1_seqnum_t is std_logic_vector(31 downto 0);
type rxport1_seqnum_vector_t is array(NATURAL RANGE <>) of rxport1_seqnum_t;

--
-- Note: output ports use dual-clock components as clock-domain-crossing 
-- modules ('rxfifo' works as data-frame-buffer; 'rxparamfifo' works as 
-- datapath for all frame-params).
--
-- Eeach port has dedicated outputs for frame-params: 
-- (datalen(14),srcaddr(8),srcport(4),seqnum(32))
--
-- 'rxfifo' is 2048 bytes long (rxfifo can contain one ieee standard frame when framelen=1500) 
-- 'rxparamfifo' is a small fifo (maxlen = 16) so compiler can use MLABs:
-- StratixIII --> 320bit, max 16x20bit/MLAB (16words x 64bit : 4 MLABs) 
-- StratixIV  --> 640bit, max 32x20bit/MLAB (16words x 64bit : 4 MLABs)  
--   
-- Note1: all fifos generated with [ADD_USEDW_MSB_BIT STRING "ON"] 
-- (usedw indicates true fifo length)
-- Note2: all fifos generated with [LPM_SHOWAHEAD STRING "OFF"]
-- (rdreq works as true 'read request' signal)  
--

--**************************************************************
--
-- I/O section begin
--
--**************************************************************

--
-- rxport1 inputs (edit)
--
type rxport1_inputs_t is record

   -- rxport1 read interface: NPORTS clock domains
   rclk : std_logic_vector(1 to rxport1_NPORTS);
   rrst : std_logic_vector(1 to rxport1_NPORTS);

   -- rxport1 write side: common tx/rx clock domain
   clk2 : std_logic;
   rst2 : std_logic;
   --
   -- NOTE: we assume all resets async asserted, sync deasserted by related clocks
   --

   -- rxport1 read interface (clock domain rclk(),rrst()) 
   rena : std_logic_vector(1 to rxport1_NPORTS);
   rreq : std_logic_vector(1 to rxport1_NPORTS);
   rack : std_logic_vector(1 to rxport1_NPORTS);
   -- 
   -- rena = 1 --> rxport enable (read side enable request, rxport-enabled signaled by renasts = 1,
   --              frame ready signaled by rready = 1, frame datalen<>0 signaled by reoframe = 0)
   -- rena = 0 --> rxport flush (all loaded frames are discarded until rxport is empty)
   --   
   -- rreq = 1 --> rxfifo read request (accepted when rready = 1 and reoframe = 0, ignored when reoframe = 1)
   -- rack = 1 --> rxport read ack (accepted when rready = 1, rxport moves to next frame, unread frame data will be discarded)
   --

   -- rxframe interface (clock domain clk2, rst2)
   --wdestaddr : std_logic_vector(7 downto 0); -- not used
   wsrcaddr   : std_logic_vector(7 downto 0);
   wdestport  : std_logic_vector(3 downto 0);
   wsrcport   : std_logic_vector(3 downto 0);
   wseqnum    : std_logic_vector(31 downto 0);
   wdatalen   : std_logic_vector(13 downto 0);
   wdata      : std_logic_vector(7 downto 0);
   --
   wframeok   : std_logic;
   wframedone : std_logic;
   wreq       : std_logic;
   --
   -- wdestaddr  --> frame param destaddr (8bit) -- not used 
   -- wsrcaddr   --> frame param srcaddr (8bit)
   -- wdestport  --> frame param destport (4bit)
   -- wsrcport   --> frame param srcport (4bit)
   -- wseqnum    --> frame param seqnum (32bit)
   -- wdatalen   --> frame datalen (14bit)
   -- wdata      --> frame data (8bit)
   --
   -- wframeok   --> write in progress (note: write-loop starts 2 clock cycles after wframeok asserted)
   -- wframedone --> end-of-frame pulse (1 clock)
   -- wreq       --> write request (note: rxframe interface never stops, frame data always push forward assuming
   --                               rxport always ON --> frames are discarded when rxport not ready)

   -- cmdctrl-interface
   enable    : std_logic_vector(1 to rxport1_NPORTS); 
   --
   seqnumena : std_logic_vector(1 to rxport1_NPORTS);
   seqnumclr : std_logic_vector(1 to rxport1_NPORTS);
   --
   srcfilterena  : std_logic_vector(1 to rxport1_NPORTS);
   srcfilteraddr : rxport1_srcaddr_vector_t(1 to rxport1_NPORTS); 
   srcfilterport : rxport1_srcport_vector_t(1 to rxport1_NPORTS); 
   --
   -- enable  --> write side enable/flush request (level, cmdctrl driven)
   --             rxport is enabled when both 'rena,enable' are asserted
   --
   -- seqnumena --> seqnum enable flags (level, cmdctrl driven)
   --               0 --> seqnum filter OFF (frames with any 'wseqnum' accepted)
   --               1 --> seqnum filter ON  (frames accepted when 'wseqnum = rxseqnum(wdestport)';
   --                     rxseqnum is incremented at the end of frame-write-operation: frames written into 
   --                     rxport fifos without errors are considered delivered) 
   --
   -- seqnumclr --> rxseqnum(index) = 0 (pulse, 1 clock, cmdctrl driven)
   --               index = 1..NPORTS --> command applied in parallel to all selected ports
   --
   -- srcfilterena  --> srcfilter enable flags (level, cmdctrl driven)
   --                   0 --> srcfilter OFF (any src-node accepted)
   --                   1 --> srcfilter ON  (frame accepted when 'srcaddr,srcport = filteraddr,filterport')
   -- srcfilteraddr     srcfilter address (array 1..NPORTS of 8bit node-addr)
   -- srcfilterport     srcfilter port (array 1..NPORTS of 4bit node-port) 
   --

end record;

--
-- rxport1 outputs (edit)
--
type rxport1_outputs_t is record

   -- rxport1 read interface (clock domain rclk(),rrst()) 
   renasts  : std_logic_vector(1 to rxport1_NPORTS);
   rdata    : rxport1_rdata_vector_t(1 to rxport1_NPORTS);
   rready   : std_logic_vector(1 to rxport1_NPORTS);
   rempty   : std_logic_vector(1 to rxport1_NPORTS); 
   rfull    : std_logic_vector(1 to rxport1_NPORTS);
   rframes  : rxport1_frames_vector_t(1 to rxport1_NPORTS);
   rsrcaddr : rxport1_srcaddr_vector_t(1 to rxport1_NPORTS);
   rsrcport : rxport1_srcport_vector_t(1 to rxport1_NPORTS);
   rdatalen : rxport1_datalen_vector_t(1 to rxport1_NPORTS);
   rdatacnt : rxport1_datalen_vector_t(1 to rxport1_NPORTS);
   rseqnum  : rxport1_seqnum_vector_t(1 to rxport1_NPORTS);
   reoframe : std_logic_vector(1 to rxport1_NPORTS);
   --
   rerrfull  : std_logic_vector(1 to rxport1_NPORTS); 
   rerrempty : std_logic_vector(1 to rxport1_NPORTS); 
   --
   -- renasts  --> rxport status ('1' rxport enabled)
   -- rdata    --> rxport data (8bit)
   -- rready   --> rxport ready flag ('1' frame params are valid)
   -- rempty   --> rxport empty flag ('1' rxport is empty: rxparamfifo and rxfifo are both empty, received frames = 0) 
   -- rfull    --> rxport full  flag ('1' rxport is full: rxparamfifo is full, received frames >= 16)
   -- rframes  --> rxport received frames (0..16)
   -- rsrcaddr --> frame param srcaddr (8bit)
   -- rsrcport --> frame param srcport (4bit)
   -- rdatalen --> frame param datalen (14bit)
   -- rdatacnt --> frame data counter  (14bit)
   -- rseqnum  --> frame param seqnum  (!! Debug !!)
   -- reoframe --> frame data empty flag ('1' data field completely read)
   --
   -- rerrfull  --> write-when-full error (sticky bit)
   -- rerrempty --> read-when-empty error (sticky bit)
   --               note: error conditions mean not-aligned fifos, rxport is kept blocked 
   --               and must be flushed to recover from errors  
   --               note1: error sticky bits are cleared when rxport re-enabled
   --               note2: write-when-full error walks through rxparamfifo and appears to read-side when
   --               frame read operation starts (rerrfull flag is synchronous with frame read op) 
   --

   -- write side status (clock domain clk2, rst2)
   wready : std_logic_vector(1 to rxport1_NPORTS);
   wempty : std_logic_vector(1 to rxport1_NPORTS); 
   wfull : std_logic_vector(1 to rxport1_NPORTS); 
   wframes : rxport1_frames_vector_t(1 to rxport1_NPORTS);
   rxseqnum : rxport1_seqnum_vector_t(1 to rxport1_NPORTS);
   -- 
   werrempty : std_logic_vector(1 to rxport1_NPORTS); 
   werrfull  : std_logic_vector(1 to rxport1_NPORTS); 
   --
   -- wready  --> rxport ready (rready status to write-side)
   -- wempty  --> rxport empty (rxparamfifo wrempty)
   -- wfull   --> rxport full  (rxparamfifo wrfull)
   -- wframes --> rxport frames (rxparamfifo wrused)
   -- rxseqnum --> rxport seqnum (array 1..NPORTS of 32bit counters)
   -- 
   -- werrempty --> read-when-empty error (sticky bit, rerrempty status to write-side)
   -- werrfull  --> write-when-full error (sticky bit, write-side)
   --               note: sticky bits cleared when rxport re-enabled

   -- !! Debug !!
   rxfifo      : dcfiforx1_vector_t(1 to rxport1_NPORTS);
   rxparamfifo : dcfiforx2_vector_t(1 to rxport1_NPORTS);
   -- !! Debug !!

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- rxport1 component common interface (constant)
--
type rxport1_t is record
   inputs : rxport1_inputs_t;
   outputs : rxport1_outputs_t;
end record;

--
-- rxport1 vector type (constant)
--
type rxport1_vector_t is array(NATURAL RANGE <>) of rxport1_t;

--
-- rxport1 component declaration (constant)
--
component rxport1
port (
   inputs : in rxport1_inputs_t;
   outputs : out rxport1_outputs_t
);
end component;

end component_rxport1;

--
-- rxport1 entity declaration
--

-- Local libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.component_rxport1.all;
use work.component_dcfiforx1.all;
use work.component_dcfiforx2.all;

-- rxport1 entity (constant)
entity rxport1 is
port (
   inputs : in rxport1_inputs_t;
   outputs : out rxport1_outputs_t
);
end rxport1;

--**************************************************************
--**************************************************************

--**************************************************************
--
--
-- Component Architecture
--
--
--**************************************************************

architecture rtl of rxport1 is

--**************************************************************
--
-- Architecture declaration begin
--
--**************************************************************

--
-- constants (edit)
--
--constant [name] : [type] := [value];

--
-- state machines (edit)
--
type FSMrxportrd_t is (S0, S1, S1_1, S1_2, S1_3, S2_0, S2_1, S2_2, S3);
-- note: simple type, clock domain rclk(index) --> [regname].rclk(index).FSMrxportrd 
type FSMrxportwrena_t is (S0, S1_0, S1_1);
type FSMrxportwrena_vector_t is array(NATURAL RANGE <>) of FSMrxportwrena_t;
-- note: vector type, clock domain clk2 --> [regname].clk2.FSMrxportwrena(index)
type FSMrxportwr_t is (S0, S1, S1_1, S1_2, S2_0, S4);
type FSMrxportwr_vector_t is array(NATURAL RANGE <>) of FSMrxportwr_t;
-- note: vector type, clock domain clk2 --> [regname].clk2.FSMrxportwr(index)

--
-- local registers (edit)
--
--
-- Notes: one record-type for each clock domain
--

--
-- clock domain rclk()
--
type reglist_rclk_t is record

   -- FSM list
   FSMrxportrd : FSMrxportrd_t;

   -- read side enable command (send, sync from rclk() to clk2)
   rxportena : std_logic;

   -- read side enable command (return, sync from clk2 to rclk())
   rxportenaret : std_logic;
   rxportenaretI : std_logic;
   rxportenaretII : std_logic;

   -- read side error flags
   rerrempty : std_logic;
   rerrfull : std_logic;

   -- read side regs
   tdatacnt : std_logic_vector(1+13 downto 0);
   rdatacnt : std_logic_vector(13 downto 0);

   -- write side enable command (send, sync from clk2 to rclk())
   rxportwrena : std_logic;
   rxportwrenaI : std_logic;
   rxportwrenaII : std_logic;

   -- write side enable command (return, sync from clk2 to rclk())
   rxportwrenaret : std_logic;

   -- write side error flags (sync from clk2 to rclk()) ...forse non serve...
   err_rxportwrfull : std_logic;
   err_rxportwrfullI : std_logic;
   err_rxportwrfullII : std_logic;

   -- end of list
   eol : std_logic;

end record;
constant reglist_rclk_default : reglist_rclk_t :=
(
   FSMrxportrd => S0,   
   rxportena => '0',
   rxportenaret => '0',
   rxportenaretI => '0',
   rxportenaretII => '0',
   rerrempty => '0',
   rerrfull => '0',
   tdatacnt => (others => '0'),
   rdatacnt => (others => '0'),
   rxportwrena => '0',
   rxportwrenaI => '0',
   rxportwrenaII => '0',
   rxportwrenaret => '0',   
   err_rxportwrfull => '0',
   err_rxportwrfullI => '0',
   err_rxportwrfullII => '0',

   eol => '0'
);
type reglist_rclk_vector_t is array(NATURAL RANGE <>) of reglist_rclk_t;

--
-- clock domain clk2
--
type reglist2_t is record

   -- FSM list
   FSMrxportwrena : FSMrxportwrena_vector_t(1 to rxport1_NPORTS);
   FSMrxportwr    : FSMrxportwr_vector_t(1 to rxport1_NPORTS);

   -- write side enable request (send, sync from clk2 to rclk())
   rxportwrena  : std_logic_vector(1 to rxport1_NPORTS);

   -- write side enable command (return, sync from rclk() to clk2)
   rxportwrenaretI : std_logic_vector(1 to rxport1_NPORTS);
   rxportwrenaretII : std_logic_vector(1 to rxport1_NPORTS);
   rxportwrenaret : std_logic_vector(1 to rxport1_NPORTS);

   -- write side error flags (send, sync from clk2 to rclk())
   err_rxportwrfull : std_logic_vector(1 to rxport1_NPORTS);

   -- write side regs
   wframeok : std_logic;
   rxfifofull_test : std_logic_vector(1 to rxport1_NPORTS);
   seqnumclr : std_logic_vector(1 to rxport1_NPORTS);
   rxseqnum : rxport1_seqnum_vector_t(1 to rxport1_NPORTS);
   rxseqnum_test : std_logic_vector(1 to rxport1_NPORTS);
   srcfilter_test : std_logic_vector(1 to rxport1_NPORTS);

   -- read side enable command (send, sync from rclk() to clk2)
   rxportenaI : std_logic_vector(1 to rxport1_NPORTS);
   rxportenaII : std_logic_vector(1 to rxport1_NPORTS);
   rxportena : std_logic_vector(1 to rxport1_NPORTS);

   -- read side enable command (return, sync from clk2 to rclk())
   rxportenaret : std_logic_vector(1 to rxport1_NPORTS);

   -- read side error flags (send, sync from rclk() to clk2) .... forse non servono....
   err_rxportrdemptyI : std_logic_vector(1 to rxport1_NPORTS);
   err_rxportrdemptyII : std_logic_vector(1 to rxport1_NPORTS);
   err_rxportrdempty : std_logic_vector(1 to rxport1_NPORTS);

   -- end of list
   eol : std_logic;

end record;
constant reglist2_default : reglist2_t :=
(
   FSMrxportwrena => (others => S0),
   FSMrxportwr => (others => S0),
   rxportwrena => (others => '0'),
   rxportwrenaretI => (others => '0'),
   rxportwrenaretII => (others => '0'),
   rxportwrenaret => (others => '0'),
   err_rxportwrfull => (others => '0'),
   wframeok => '0',
   rxfifofull_test => (others => '0'),
   seqnumclr => (others => '0'),
   rxseqnum => (others => SLV(0, 32)),
   rxseqnum_test => (others => '0'),
   srcfilter_test => (others => '0'),
   rxportenaI => (others => '0'),
   rxportenaII => (others => '0'),
   rxportena => (others => '0'),
   rxportenaret => (others => '0'),
   err_rxportrdemptyI => (others => '0'),
   err_rxportrdemptyII => (others => '0'),
   err_rxportrdempty => (others => '0'),

   eol => '0'
);

--
-- all local registers (edit)
--
-- Notes: one record-element for each clock domain
--
type reglist_t is record
   rclk : reglist_rclk_vector_t(1 to rxport1_NPORTS); -- rclk() array
   clk2 : reglist2_t;                                 
end record;

--
-- all local nets (edit)
--
type netlist_t is record

   wframeok_pedge : std_logic;

   --
   -- component interface signals (edit)
   --
   -- [instance_name] : [component_name]_t;
   --
   rxfifo      : dcfiforx1_vector_t(1 to rxport1_NPORTS);
   rxparamfifo : dcfiforx2_vector_t(1 to rxport1_NPORTS);

end record;

--
-- local signals (edit)
--

--**************************************************************
--
-- Architecture declaration end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- inputs/outputs record-type alias (constant)
--
subtype inputs_t is rxport1_inputs_t;
subtype outputs_t is rxport1_outputs_t;

--
-- all local registers (constant)
--
type allregs_t is record
   din : reglist_t;
   dout : reglist_t;
end record;
signal allregs : allregs_t;

--
-- all local nets (constant)
--
signal allnets : netlist_t;
signal allcmps : netlist_t;

--
-- outputs driver (internal signal for read access) (constant)
--
signal allouts : outputs_t;

--**************************************************************
--**************************************************************

--**************************************************************
--
-- architecture rtl of rxport1
--
--**************************************************************
begin

--**************************************************************
--
-- components instances (edit)
--
--**************************************************************

--[instance/label_name] : [component_name] port map
--(
--   inputs => allnets.[instance_name].inputs,
--   outputs => allcmps.[instance_name].outputs
--);

L1 : FOR index IN allnets.rxfifo'range GENERATE

rxfifo : dcfiforx1 port map
(
   inputs => allnets.rxfifo(index).inputs,
   outputs => allcmps.rxfifo(index).outputs
);

rxparamfifo : dcfiforx2 port map
(
   inputs => allnets.rxparamfifo(index).inputs,
   outputs => allcmps.rxparamfifo(index).outputs
);

END GENERATE;

--**************************************************************
--
-- sequential logic
--
--
-- Notes: one process for each clock domain
--
--**************************************************************

--
-- clock domain: rclk(),rrst() (edit)
--
process_rclk : FOR i IN inputs.rclk'range GENERATE

process (inputs.rclk(i), inputs.rrst(i))
begin
   if (inputs.rrst(i) = '1') then
      allregs.dout.rclk(i) <= reglist_rclk_default;
   elsif rising_edge(inputs.rclk(i)) then
      allregs.dout.rclk(i) <= allregs.din.rclk(i);
   end if;
end process;

END GENERATE;

--
-- clock domain: clk2,rst2 (edit)
--
process (inputs.clk2, inputs.rst2)
begin
   if (inputs.rst2 = '1') then
      allregs.dout.clk2 <= reglist2_default;
   elsif rising_edge(inputs.clk2) then
      allregs.dout.clk2 <= allregs.din.clk2;
   end if;
end process;

--**************************************************************
--
-- combinatorial logic
--
--
-- Notes: single process with combinatorial procedures.
--
--**************************************************************

process (inputs, allouts, allregs, allnets, allcmps)

--**************************************************************
--
-- Combinatorial description begin
--
--**************************************************************

--
-- FSMrxportwrena combinatorial procedure (edit)
--
-- clock domain: clk2
--
procedure SubFSMrxportwrena
(
   variable i : in inputs_t;
   variable ri: in reglist2_t;
   variable ro: in reglist2_t;
   variable o : inout outputs_t;
   variable r : inout reglist2_t;
   variable n : inout netlist_t
) is
begin

FOR index IN 1 TO rxport1_NPORTS LOOP

   --
   -- 'rxportwrena' round-trip logic   
   --
   -- write-side 'enable' requests are transmitted to read-side where are merged 
   -- with 'rena' inputs --> main control logic located to the rxport read-side
   --
   -- note: round-trip logic always ON 
   --
   case ro.FSMrxportwrena(index) is
   when S0 =>
      --
      -- reset state
      --
      r.FSMrxportwrena(index) := S1_0;

   when S1_0 =>
      --
      -- not-enable request in progress
      --MODIFICATO
      r.rxportwrena(index) := '1';
      if ro.rxportwrenaret(index) = '0' then
         -- 'rxportwrena' negedge round-trip completed
         if i.enable(index) = '1' then
            -- write side enable request   
            r.rxportwrena(index) := '1';
            r.FSMrxportwrena(index) := S1_1;
         end if;
      else
         -- 'rxportwrena' negedge round-trip in progress
         null;
      end if;
      -- note: this is a blocking state, i.enable ignored until negedge round-trip
      -- completed because we must not inject single clock pulses into clock-crossing logic  

   when S1_1 =>
      --
      -- enable request in progress 
      --
      r.rxportwrena(index) := '1';
      if ro.rxportwrenaret(index) = '1' then
         -- 'rxportwrena' posedge round-trip completed
         if i.enable(index) = '0' then 
            -- write side not-enabled request
            r.rxportwrena(index) := '1'; --modificato
            r.FSMrxportwrena(index) := S1_0;
         end if;
      else
         -- 'rxportwrena' posedge round-trip in progress
         null;
      end if;
      -- note: this is a blocking state, i.enable ignored until posedge round-trip
      -- completed because we must not inject single clock pulses into clock-crossing logic  

   end case;
   
END LOOP;

end procedure;


--
-- FSMrxportrd combinatorial procedure (edit)
--
-- clock domain: all clocks
--
procedure SubFSMrxportrd
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

FOR index IN 1 TO rxport1_NPORTS LOOP

   --
   -- rxport read control
   --
   -- Read operations controlled by 'rena' input:
   --
   -- rxport enabled  --> rx data  
   -- rxport disabled --> rxport flush request, read side error flags cleared
   --
   --
   -- Note: read side works as master controller, all write-side enable requests 
   -- are simply transmitted to read side logic, 'rxportena' is the main rxport 
   -- status flag.     
   --

   -- rxfifo defaults (read side, clock domain rclk(index))
   n.rxfifo(index).inputs.rdclk := i.rclk(index);
   n.rxfifo(index).inputs.rdreq := '0';

   -- rxparamfifo defaults (read side, clock domain rclk(index))
   n.rxparamfifo(index).inputs.rdclk := i.rclk(index);
   n.rxparamfifo(index).inputs.rdreq := '0';

   -- output defaults
   o.rdatalen(index) := n.rxparamfifo(index).outputs.q(13 downto 0);
   o.rsrcaddr(index) := n.rxparamfifo(index).outputs.q(23 downto 16);
   o.rsrcport(index) := n.rxparamfifo(index).outputs.q(27 downto 24);
   o.rseqnum(index)  := n.rxparamfifo(index).outputs.q(63 downto 32); -- !! Debug !!
   --
   o.rfull(index)    := n.rxparamfifo(index).outputs.rdfull;
   o.rempty(index)   := n.rxparamfifo(index).outputs.rdempty and n.rxfifo(index).outputs.rdempty;
   o.rframes(index)  := n.rxparamfifo(index).outputs.rdusedw;
   --
   o.rdata(index)    := n.rxfifo(index).outputs.q;

   -- rxportrd control
   case ro.rclk(index).FSMrxportrd is
   when S0 =>
      --
      -- reset state
      --
      r.rclk(index).FSMrxportrd := S1;

   when S1 =>
      --
      -- init state
      --
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         -- read+write sides both enabled: enable command starts
         r.rclk(index).rxportena := '1';         
         r.rclk(index).FSMrxportrd := S1_1;
      else
         -- rxport not enabled: wait
         r.rclk(index).rxportena := '0';
      end if;

   when S1_1 =>
      --
      -- enable command in progress ('rxportena' posedge round-trip)
      --      
      r.rclk(index).rxportena := '1';
      if ro.rclk(index).rxportenaret = '1' then
         -- enable command done: continue
         r.rclk(index).FSMrxportrd := S1_2;
         -- rxport error flags cleared 
         r.rclk(index).rerrempty := '0';
         r.rclk(index).rerrfull  := '0';
      else
         -- command in progress
         null;
      end if;

   when S1_2 =>
      --
      -- waiting for new frames
      --      
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         if n.rxparamfifo(index).outputs.rdempty = '0' then
            -- rxport ready: next clock cycle frame params will be valid, continue
            n.rxparamfifo(index).inputs.rdreq := '1';
            r.rclk(index).FSMrxportrd := S1_3; 
         else
            -- rxport empty
            null;
         end if;
      else
         -- rxport not enbled: to flush operation
         r.rclk(index).FSMrxportrd := S3;
      end if;
      -- note: this is a blocking state --> exit from S1_2 when new frame is ready or rxport not enabled
 
   when S1_3 =>
      --
      -- output frame params are valid
      --      
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         -- rxport enabled: current 'rdatalen' captured (multi-frame queue)
         r.rclk(index).rdatacnt := SLV(0, 14);
         r.rclk(index).tdatacnt := SLV(16384 - UINT(o.rdatalen(index)), 1+14); -- note: up counter, msb test
         --
         if n.rxparamfifo(index).outputs.q(31) = '0' then
            -- frame without errors: fifos are aligned, continue
            r.rclk(index).FSMrxportrd := S2_0;
         else
            -- wrfull error asserted (sticky bit)
            r.rclk(index).rerrfull  := '1';
            r.rclk(index).FSMrxportrd := S2_2;
            --r.rclk(index).FSMrxportrd := S3;
            ---- note: forced flush operation marked by rerrfull flag (flag will be auto-cleared when rxport restarts)
            ---- ??? forse e' meglio passare per S2_2 con il flag rerrfull asserted in attesa della flush....
         end if;
      else
         -- rxport not enbled: to flush operation
         r.rclk(index).FSMrxportrd := S3;
      end if;

   when S2_0 =>
      --
      -- run state (output frame params are valid, read/ack requests accepted)
      --
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         -- read+write sides both enabled: ack/read request test
         if i.rack(index) = '1' then
            -- next frame request
            r.rclk(index).FSMrxportrd := S2_1;
         elsif i.rreq(index) = '1' then
            -- rxfifo rdreq
            if ro.rclk(index).tdatacnt(14) = '1' then
               -- frame done: read ignored
               n.rxfifo(index).inputs.rdreq := '0';
               -- note: we tolerate external logic extra-read operations ('rreq' ignored when end-of-frame asserted) 
            elsif n.rxfifo(index).outputs.rdempty = '0' then
               -- fifo not empty, current frame in progress: read 
               n.rxfifo(index).inputs.rdreq := '1';
               r.rclk(index).tdatacnt := SLV(UINT(ro.rclk(index).tdatacnt) + 1, 1+14);
               r.rclk(index).rdatacnt := SLV(UINT(ro.rclk(index).rdatacnt) + 1, 14);
            else
               -- rxfifo empty: error flag asserted (sticky bit)
               n.rxfifo(index).inputs.rdreq := '0';
               r.rclk(index).rerrempty := '1';
               r.rclk(index).FSMrxportrd := S2_2;
               -- note: this condition should never appear (rxparamfifo + rxfifo + tdatacnt must be aligned, 
               -- tdatacnt(14) is asserted when rxfifo is empty --> error condition captured by S2_2 state) 
            end if;
         end if;
      else
         -- rxport not enbled: to flush operation
         r.rclk(index).FSMrxportrd := S3;
      end if;

   when S2_1 =>
      --
      -- next frame request
      --
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         -- read+write sides both enabled
         if ro.rclk(index).tdatacnt(14) = '1' then
            -- frame data completely read: waiting for new frames
            r.rclk(index).FSMrxportrd := S1_2;
         else
            -- frame data not completely read: read loop continues
            if n.rxfifo(index).outputs.rdempty = '0' then
               -- rxfifo not empty: read op (data will be discarded) 
               n.rxfifo(index).inputs.rdreq := '1';
               r.rclk(index).tdatacnt := SLV(UINT(ro.rclk(index).tdatacnt) + 1, 1+14);
               r.rclk(index).rdatacnt := SLV(UINT(ro.rclk(index).rdatacnt) + 1, 14);
            else
               -- rxfifo empty: error flag asserted (sticky bit)
               n.rxfifo(index).inputs.rdreq := '0';
               r.rclk(index).rerrempty := '1';
               r.rclk(index).FSMrxportrd := S2_2;
               -- note: this condition should never appear (rxparamfifo + rxfifo + tdatacnt must be aligned, 
               -- tdatacnt(14) is asserted when rxfifo is empty --> error condition captured by S2_2 state) 
            end if;
         end if;
      else
         -- rxport not enbled: to flush operation
         r.rclk(index).FSMrxportrd := S3;
      end if;

   when S2_2 =>
      --
      -- fifo error: waiting for rxport not enabled (error flags asserted)
      --
      if i.rena(index) = '1' and ro.rclk(index).rxportwrena = '1' then
         -- read+write sides both enabled: error condition still present
         null;
      else
         -- rxport not enabled: now we move to flush operation to re-align fifos
         r.rclk(index).FSMrxportrd := S3;
      end if;
      -- note: system should never enter into S2_2 state --> but in case of error rxport must be deasserted
      -- by external logic to start flush operation for fifos re-alignement (error flags continuously 
      -- asserted until external logic decides to reset current rxport, we do not use a forced-flush-op with
      -- the risk of error flags auto-cleared when flush is completed and rxport still enabled)

   when S3 =>
      --
      -- flush operation
      --
      r.rclk(index).rxportena := '0';
      --
      if n.rxfifo(index).outputs.rdempty = '0' then
         -- rxfifo not empty, forced rxfifo read request, fifo data discarded
         n.rxfifo(index).inputs.rdreq := '1';
      end if;
      if n.rxparamfifo(index).outputs.rdempty = '0' then
         -- rxparamfifo not empty, forced rxparamfifo read request, fifo data discarded
         n.rxparamfifo(index).inputs.rdreq := '1';
      end if;

      if n.rxfifo(index).outputs.rdempty = '1' and n.rxparamfifo(index).outputs.rdempty = '1' then
         -- both fifos empty (read-side): flush done when 'rxportena' negedge round-trip completed
         if ro.rclk(index).rxportenaret = '0' then
            -- 'rxportena' negedge round-trip done: now fifos are really emtpy, to idle state
            r.rclk(index).FSMrxportrd := S1;
         else
            -- round-trip in progress
            null;
         end if;
      else
         -- flush in progress
         null;
      end if;
      -- note: enable command ignored during flush operation (o.rready deasserted) 
      -- note1: S3 is a blocking state --> fifos are continuously flushed until 'rxportena' negedge round-trip completed
      -- note2: dcfifo sync-logic may set rdempty flag when fifo is not really empty --> to avoid false 
      -- rdempty detection write-side must signal empty condition to read-side using rxportena round-trip-path
      -- ('rxfifoenaret = 0' means write-side has seen both fifos emtpy)

   end case;

   --
   -- read side outputs
   --
   --o.rdata(index)    := n.rxfifo(index).outputs.q;
   --o.rempty(index)   := n.rxfifo(index).outputs.rdempty;
   --o.rfull(index)    := n.rxfifo(index).outputs.rdfull;
   o.rdatacnt(index) := ro.rclk(index).rdatacnt(13 downto 0); -- !! Debug !!

   -- error flags
   o.rerrfull(index)  := ro.rclk(index).rerrfull;
   o.rerrempty(index) := ro.rclk(index).rerrempty;
   -- note: sticky bits, cleared when rxport re-enabled

   -- busy/ready/eoframe logic
   o.rready(index)   := '0';
   o.reoframe(index) := '0';
   if ro.rclk(index).FSMrxportrd = S2_0 then
      -- run state active: end-of-frame when 'msb(tdatacnt)' asserted
      o.reoframe(index) := ro.rclk(index).tdatacnt(14);
      -- run state active: read side is ready when enable request, write side enabled 
      o.rready(index)   := i.rena(index) and ro.rclk(index).rxportwrena;
   end if;
   -- note: rready reoframe
   --          0       X    --> frame not ready | rxport not enabled, 'rack,rreq' ignored
   --          1       0    --> frame ready, frame data can be read, 'rack,rreq' accepted
   --          1       1    --> frame ready, frame data completely read, 'rack' accepted, 'rreq' ignored

   o.renasts(index) := ro.rclk(index).rxportena;
   -- note: 'rxportena' is the main rxport status flag (it works as an indicator of rxport status)
   -- note1: external read logic must use dedicated 'rready','reoframe' flags --> flags include
   -- rxportena status (via FSMrxportrd run state S2_0); in addition they respond on the same clock cycle when
   -- not-enable requests are applied

END LOOP;

end procedure;


--
-- Crossing clocks combinatorial procedure (edit)
--
-- clock domain: all clocks
--
procedure SubCrossingClocks
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

FOR index IN 1 TO rxport1_NPORTS LOOP

   --
   -- write side synchronizers
   -- 
   -- clk2 --> rclk(index) (send)                       
   -- rclk(index) --> clk2 (return)
   --

   -- write side enable request (send)
   r.rclk(index).rxportwrenaI := ro.clk2.rxportwrena(index);
   r.rclk(index).rxportwrenaII:= ro.rclk(index).rxportwrenaI;
   r.rclk(index).rxportwrena  := ro.rclk(index).rxportwrenaII;
   -- write side enable request (return)
   r.clk2.rxportwrenaretI(index) := ro.rclk(index).rxportwrena;
   r.clk2.rxportwrenaretII(index):= ro.clk2.rxportwrenaretI(index);
   r.clk2.rxportwrenaret(index)  := ro.clk2.rxportwrenaretII(index);
   -- note: round-trip always ON

   -- write side error flags (send) ...forse non serve...
   r.rclk(index).err_rxportwrfullI := ro.clk2.err_rxportwrfull(index);
   r.rclk(index).err_rxportwrfullII:= ro.rclk(index).err_rxportwrfullI;
   r.rclk(index).err_rxportwrfull  := ro.rclk(index).err_rxportwrfullII;
   -- ???? osservazione: per questi flags si applica solo la send perche' i drivers sono tutti registri che una volta
   -- ???? attivati rimangono bloccati fino alla rxport not-enable request (che invece applica una chain send/return completa)
   -- ???? se il flag err_rxportwrfull non e' di tipo bloccante allora occorre aggiungere il return path...

   --
   -- read side synchronizers
   -- 
   -- rclk(index) --> clk2 (send)                       
   -- clk2 --> rclk(index) (return)
   --

   -- read side enable command (send)
   r.clk2.rxportenaI(index) := ro.rclk(index).rxportena;
   r.clk2.rxportenaII(index):= ro.clk2.rxportenaI(index);
   r.clk2.rxportena(index)  := ro.clk2.rxportenaII(index);
   -- read side enable command (return)
   r.rclk(index).rxportenaretI := ro.clk2.rxportenaret(index);
   r.rclk(index).rxportenaretII:= ro.rclk(index).rxportenaretI;
   r.rclk(index).rxportenaret  := ro.rclk(index).rxportenaretII;
   -- note: round-trip return signal controlled by FSMrxportwr

   -- read side error flags (send)
   r.clk2.err_rxportrdemptyI(index)  := ro.rclk(index).rerrempty;
   r.clk2.err_rxportrdemptyII(index) := ro.clk2.err_rxportrdemptyI(index);
   r.clk2.err_rxportrdempty(index)   := ro.clk2.err_rxportrdemptyII(index);

END LOOP;

end procedure;

--
-- FSMrxportwr combinatorial procedure (edit)
--
-- clock domain: clk2
--
procedure SubFSMrxportwr
(
   variable i : in inputs_t;
   variable ri: in reglist2_t;
   variable ro: in reglist2_t;
   variable o : inout outputs_t;
   variable r : inout reglist2_t;
   variable n : inout netlist_t
) is

constant RXFIFOSIZE      : natural := 2**(allnets.rxfifo(1).outputs.wrusedw'length - 1);
constant RXPARAMFIFOSIZE : natural := 2**(allnets.rxparamfifo(1).outputs.wrusedw'length - 1);
-- note: size derived from component interface ('wrusedw' indicates true fifo length)

begin

FOR index IN 1 TO rxport1_NPORTS LOOP

   -- rxfifo defaults (write side, clock domain clk2)
   n.rxfifo(index).inputs.wrclk := i.clk2;
   n.rxfifo(index).inputs.aclr := i.rst2;
   n.rxfifo(index).inputs.wrreq := '0';
   n.rxfifo(index).inputs.data(7 downto 0) := i.wdata;

   -- rxparamfifo defaults (write side, clock domain clk2)
   n.rxparamfifo(index).inputs.wrclk := i.clk2;
   n.rxparamfifo(index).inputs.aclr := i.rst2;
   n.rxparamfifo(index).inputs.wrreq := '0';
   --
   n.rxparamfifo(index).inputs.data := (others => '0'); -- default: all zero
   -- 
   n.rxparamfifo(index).inputs.data(13 downto  0) := i.wdatalen; 
   --n.rxparamfifo(index).inputs.data(15 downto 14) -- 2bit msb reserved 
   n.rxparamfifo(index).inputs.data(23 downto 16) := x"ce"; --MODIFICATO
   n.rxparamfifo(index).inputs.data(27 downto 24) := x"2"; --MODIFICATO
   n.rxparamfifo(index).inputs.data(31)           := ro.err_rxportwrfull(index); -- wrfull error flag to read-side 
   n.rxparamfifo(index).inputs.data(63 downto 32) := i.wseqnum; 

   -- write interface: start of frame detector
   r.wframeok := i.wframeok;
   n.wframeok_pedge := '0';
   if i.wframeok = '1' and ro.wframeok = '0' then
      -- posedge detected (write op starts)
      n.wframeok_pedge := '1';
   end if;
   -- note: rxframe interface is a 'push-only' datapath, we wait for next frame when rxframe write loop
   -- yet in progress 
   
   -- rxport enable/disable control
   case ro.FSMrxportwr(index) is
   when S0 =>
      --
      -- reset state
      --
      r.FSMrxportwr(index) := S4; 
      -- note: we start assuming rxport-not-enable command in progress, FSMrxportwr will move to S1 
      -- when enable command received

   when S1 =>
      --
      -- init state (rxportenaret asserted)
      --
      if ro.rxportena(index) = '1' then
         -- rxport enabled
         if n.wframeok_pedge = '1' then
            -- write op detected
            if UINT(i.wdestport) = index then
               -- rxport(index) selected: continue  
               r.FSMrxportwr(index) := S1_1;
            else
               -- rxport(index) not selected: 
               null;
            end if;
            -- note: there is only one rxport selected (others ports remains into S1 state)  
         end if;
      else
         -- rxport not-enabled: flush operation in progress
         r.FSMrxportwr(index) := S4;
      end if;
      --
      -- note: rxportena round-trip is used to notify write-side fifos status to read-side 
      --
      -- rxportena = 0 --> flush operation in progress, read-side will see
      --                   rxportenaret = 0 only when flush operation done (see 'S4' when round-trip closed)
      -- rxportena = 1 --> rxport enabled, rxportenaret = 1 (round-trip open)  
      --

   when S1_1 =>
      --
      -- write op: srcfilter test, rxseqnum test (1st clock cycle before write loop)
      --
      if ro.rxportena(index) = '0' then
         -- rxport not-enabled: flush operation in progress
         r.FSMrxportwr(index) := S4;
      elsif ro.srcfilter_test(index) = '0' then
         -- srcaddr/port does not match: frame discarded, waiting for next frame 
         r.FSMrxportwr(index) := S1;
      elsif ro.rxseqnum_test(index) = '0' then 
         -- seqnum does not match: frame discarded, waiting for next frame
         r.FSMrxportwr(index) := S1;
      else
         -- srcfilter ok, seqnum ok: continue
         r.FSMrxportwr(index) := S1_2;
      end if;
      -- note: test logic needs 1 clock cycle to generate results --> all frame params 
      -- are valid when write-op detected so 'S1_1' will see true test results

   when S1_2 =>
      --
      -- write op: rxport test (2nd clock cycle before write loop)
      --
      if ro.rxportena(index) = '0' then
         -- rxport not-enabled: flush operation in progress
         r.FSMrxportwr(index) := S4;
      elsif n.rxparamfifo(index).outputs.wrfull = '1' or ro.rxfifofull_test(index) = '1' then
      --elsif ro.rxfifofull_test(index) = '1' then -- !! Debug !! wrfull error injected
         -- (rxparamfifo is full) | (rxfifo-free-space < frame-datalen): frame discarded, waiting for next frame
         r.FSMrxportwr(index) := S1;
      else
         -- write loop starts
         r.FSMrxportwr(index) := S2_0;
      end if;

   when S2_0 =>
      --
      -- write op: rxfifo/rxparamfifo write loop
      --
      if ro.rxportena(index) = '0' then
         -- rxport not-enabled: flush operation in progress
         r.FSMrxportwr(index) := S4;
      elsif i.wframeok = '0' or i.wframedone = '1' then
         -- end of frame detected: rxparamfifo write (note: for safety both flags have been tested)
         if n.rxparamfifo(index).outputs.wrfull = '0' then
            -- rxparamfifo write (note: final op after rxdata write loop)
            n.rxparamfifo(index).inputs.wrreq := '1';
            -- frame delivered to rxport: rxseqnum++
            r.rxseqnum(index) := SLV(SLV(ro.rxseqnum(index)) + 1, 32);
         else
            -- fifo full, write ignored, write error asserted
            n.rxparamfifo(index).inputs.wrreq := '0';
            r.err_rxportwrfull(index) := '1';
            -- note: this condition should never appear (rxparamfifo must have sufficient free space
            -- for current frame) --> fifos are not aligned, only flush operation can recover from
            -- this error so starting from now all frames will be loaded with err_rxportwrfull flag asserted
            -- (read side will discard all frames marked by wrfull error until flush op done)  
         end if;
         -- waiting for next frames
         r.FSMrxportwr(index) := S1;
      elsif i.wreq = '1' then
         -- write request
         if n.rxfifo(index).outputs.wrfull = '0' then
            -- indexed rxfifo write
            n.rxfifo(index).inputs.wrreq := '1';
         else
            -- fifo full, write ignored, error
            n.rxfifo(index).inputs.wrreq := '0';
            r.err_rxportwrfull(index) := '1';
            -- note: this condition should never appear (rxfifo must have sufficient free space
            -- for current frame) --> fifos are not aligned, only flush operation can recover from
            -- this error so starting from now all frames will be loaded with err_rxportwrfull flag asserted
            -- (read side will discard all frames marked by wrfull error until flush op done)   
         end if;
      end if;
      -- note: signal 'wreq' never overlapped with 'wframeok','wframedone' (if..elsif test operations are mutually exclusive)
--
--??? cosa succede se due FSM si attivano in contemporanea ??? index,wdestport double checked ??? 
--
   when S4 =>
      --
      -- flush operation in progress (flush op --> read side controlled)
      --
      if n.rxparamfifo(index).outputs.wrempty = '1' and n.rxfifo(index).outputs.wrempty = '1' then
         -- fifos are empty: rxportena will return back to read-side to notify 'flush operation completely done' (round-trip closed)    
         r.rxportenaret(index) := ro.rxportena(index);
         if ro.rxportena(index) = '1' then 
            -- rxport enable command: error flags cleared 
            r.err_rxportwrfull(index) := '0';
            -- rxport enable command: to idle state 
            r.FSMrxportwr(index) := S1;
         end if;
      else
         -- waiting for both fifos empty
         null;
      end if;

   end case;

   -- datalen test
   r.rxfifofull_test(index) := '0';
   if UINT(i.wdatalen) + UINT(n.rxfifo(index).outputs.wrusedw) >= RXFIFOSIZE then
      -- rxfifo free space not sufficient for current frame: rxfifo-full signaled
      r.rxfifofull_test(index) := '1';
   end if;

   -- rxseqnum test
   r.rxseqnum_test(index) := '0';
   if i.seqnumena(index) = '1' then
      -- seqnum filter ON
      if i.wseqnum = ro.rxseqnum(index) then
         -- seqnum test ok
         r.rxseqnum_test(index) := '1';
      else
         -- seqnum does not match
         null;
      end if;
   else
      -- seqnum filter OFF: any frame accepted
      r.rxseqnum_test(index) := '1';
   end if;

   -- srcfilter test
   r.srcfilter_test(index) := '0';
   if i.srcfilterena(index) = '1' then
      -- srcfilter ON
      if (i.wsrcaddr = i.srcfilteraddr(index)) and (i.wsrcport = i.srcfilterport(index)) then
         -- srcfilter test ok
         r.srcfilter_test(index) := '1';
      else
         -- srcaddr/port does not match
         null;
      end if;
   else
      -- srcfilter OFF: any frame accepted
      r.srcfilter_test(index) := '1';
   end if;

   -- rxseqnum reset logic
   if i.seqnumclr(index) = '1' then
      -- seqnumclr command registered (single register fifo)
      r.seqnumclr(index) := '1';
   end if;
   if ro.FSMrxportwr(index) = S1 or ro.FSMrxportwr(index) = S4 then
      -- seqnumclr command executed when idle/flush state (write loop not in progress) 
      if ro.seqnumclr(index) = '1' then
         r.seqnumclr(index) := '0';     
         r.rxseqnum(index) := SLV(0, 32);
      end if;
   end if;
   -- note: logic always ON, command applied in parallel to all selected ports

   -- !!!! osservazione: se arriva un comando seqnumclr ed e' gia' in corso una rxport write allora il comando 
   --                    viene solo registrato...la seqnumclr e' eseguita solo quando non ci sono frame in progress (S1,S4) ed e' indipendente
   --                    da rxportena (always ON)...durante il write loop rxseqnum rimane inalterato (se rxseqnum venisse azzerato mentre e' 
   --                    in corso una rxport write allora si presenterebbe la race_condition: rxseqnum test ok --> rxport write --> seqnumclr --> rxseqnum++
   --                    --> il valore finale rxseqnum = 1 indicherebbe che la frame 0 e' stata ricevuta correttamente anche se non e' mai arrivata!!!)  

   -- write-side status flags
   o.wready(index)    := ro.rxportena(index);
   o.werrempty(index) := ro.err_rxportrdempty(index);
   -- note: outputs 'wready,werrempty' are driven by read-side status flags 'rready,rerrempty'
   -- (see clock domain crossing logic) 
   o.werrfull(index)  := ro.err_rxportwrfull(index);

   -- rxport write level
   o.wfull(index)   := n.rxparamfifo(index).outputs.wrfull;
   o.wempty(index)  := n.rxparamfifo(index).outputs.wrempty;
   o.wframes(index) := n.rxparamfifo(index).outputs.wrusedw;

   -- rxport seqnum array
   o.rxseqnum(index) := ro.rxseqnum(index);

END LOOP;

end procedure;

--
-- Debug combinatorial procedure (edit)
--
-- clock domain: all clocks
--
procedure SubDebug
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

   o.rxfifo := n.rxfifo;
   o.rxparamfifo := n.rxparamfifo;

end procedure;

--**************************************************************
--
-- combinatorial description end
--
--**************************************************************

--
-- combinatorial process
--
variable i : inputs_t;
variable ri: reglist_t;
variable ro: reglist_t;
variable o : outputs_t;
variable r : reglist_t;
variable n : netlist_t;
begin
   -- read only variables
   i := inputs;
   ri := allregs.din;
   ro := allregs.dout;
   -- read/write variables
   o := allouts;
   r := allregs.dout;
   n := allnets;
   -- components outputs
   FOR index IN 1 TO rxport1_NPORTS LOOP
      n.rxfifo(index).outputs := allcmps.rxfifo(index).outputs;
      n.rxparamfifo(index).outputs := allcmps.rxparamfifo(index).outputs;
   END LOOP;

   --
   -- all procedures call (edit)
   --

   -- clock domain: clk2
   SubFSMrxportwrena(i, ri.clk2, ro.clk2, o, r.clk2, n);
   SubFSMrxportwr   (i, ri.clk2, ro.clk2, o, r.clk2, n);

   -- clock domain: all clocks
   SubFSMrxportrd   (i, ri, ro, o, r, n);
   SubCrossingClocks(i, ri, ro, o, r, n);

   SubDebug(i, ri, ro, o, r, n);

   -- allouts/regs/nets updates
   allouts <= o;
   allregs.din <= r;
   allnets <= n;

end process;

--**************************************************************
--**************************************************************

--
-- output connections (edit)
--
outputs <= allouts;

end rtl;
--**************************************************************
--
-- architecture rtl of rxport1
--
--**************************************************************


