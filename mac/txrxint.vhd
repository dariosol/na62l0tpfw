--**************************************************************
--**************************************************************
--
-- Template file: comp_ck1.rec (new component, single clk)
--
--**************************************************************
--**************************************************************
--
--
-- Component txrxint
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

-- libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
use work.component_txport1.all;
use work.component_rxport1.all;
use work.component_cmdctrl.all;
 
package component_txrxint is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- txrxint constants (edit)
--
-- constant txrxint_[constant_name] : [type] := [value];
--

--
-- txrxint typedefs (edit)
--
-- subtype txrxint_[name]_t is [type];
-- type txrxint_[name]_t is [type];
--

--
-- txrxint inputs (edit)
--
type txrxint_inputs_t is record

   -- common tx/rx clock domain
   clk2 : std_logic;
   rst2 : std_logic;
   
   -- write interface: TX_NPORTS clock domains
   wclk : std_logic_vector(1 to txport1_NPORTS);
   wrst : std_logic_vector(1 to txport1_NPORTS);
   --
   -- NOTE: we assume all resets async asserted, sync deasserted by related clocks
   --

   -- node params (clock domain clk2,rst2)
   nodeaddr : std_logic_vector(7 downto 0);
   multicastaddr : std_logic_vector(7 downto 0);

   -- write interface (clock domain wclk(),wrst()) 
   wena : std_logic_vector(1 to txport1_NPORTS);               
   wreq : std_logic_vector(1 to txport1_NPORTS);               
   wdata : txport1_wdata_vector_t(1 to txport1_NPORTS);        
   wframelen : txport1_framelen_vector_t(1 to txport1_NPORTS);
   wdestport : txport1_destport_vector_t(1 to txport1_NPORTS); 
   wdestaddr : txport1_destaddr_vector_t(1 to txport1_NPORTS);
   wmulticast : std_logic_vector(1 to txport1_NPORTS);
   wtxreq : std_logic_vector(1 to txport1_NPORTS);   
   wtxclr : std_logic_vector(1 to txport1_NPORTS);        

   -- read interface: RX_NPORTS clock domains
   rclk : std_logic_vector(1 to rxport1_NPORTS);
   rrst : std_logic_vector(1 to rxport1_NPORTS);
   --
   -- NOTE: we assume all resets async asserted, sync deasserted by related clocks
   --

   -- read interface (clock domain rclk(),rrst()) 
   rena : std_logic_vector(1 to rxport1_NPORTS);
   rreq : std_logic_vector(1 to rxport1_NPORTS);
   rack : std_logic_vector(1 to rxport1_NPORTS);

   -- external interface (clock domain clk2,rst2)
   ext_tport_enable_wr      : std_logic;
   ext_tport_ackenable_wr   : std_logic;
   ext_tport_timerenable_wr : std_logic;
   ext_tport_seqnumclr_wr   : std_logic;
   ext_tport_enable         : std_logic_vector(15 downto 0);
   ext_tport_ackenable      : std_logic_vector(15 downto 0);
   ext_tport_timerenable    : std_logic_vector(15 downto 0);
   ext_tport_seqnumclr      : std_logic_vector(15 downto 0);
   --
   ext_rport_enable_wr    : std_logic; 
   ext_rport_seqnumena_wr : std_logic;
   ext_rport_seqnumclr_wr : std_logic;
   ext_rport_enable       : std_logic_vector(15 downto 0);
   ext_rport_seqnumena    : std_logic_vector(15 downto 0);
   ext_rport_seqnumclr    : std_logic_vector(15 downto 0);
   -- srcfilter control
   ext_tport_srcfilterena    : std_logic_vector(15 downto 0);
   ext_tport_srcfilterena_wr : std_logic;
   --
   ext_tport_srcfilter       : std_logic_vector(3 downto 0);
   ext_tport_srcfilteraddr   : std_logic_vector(7 downto 0); 
   ext_tport_srcfilterport   : std_logic_vector(3 downto 0); 
   ext_tport_srcfilter_wr    : std_logic;
   --
   ext_rport_srcfilterena    : std_logic_vector(15 downto 0);
   ext_rport_srcfilterena_wr : std_logic;
   --
   ext_rport_srcfilter       : std_logic_vector(3 downto 0);
   ext_rport_srcfilteraddr   : std_logic_vector(7 downto 0); 
   ext_rport_srcfilterport   : std_logic_vector(3 downto 0); 
   ext_rport_srcfilter_wr    : std_logic;
   -- framegen control
   ext_fgen_ena         : std_logic;
   ext_fgen_loop        : std_logic;
   ext_fgen_trig        : std_logic_vector(15 downto 0);
   ext_fgen_wr          : std_logic;
   --
   ext_fgen_destaddr    : std_logic_vector(7 downto 0);
   ext_fgen_destport    : std_logic_vector(3 downto 0);
   ext_fgen_destaddr_wr : std_logic;
   --
   ext_fgen_destmode    : std_logic_vector(2 downto 0);
   ext_fgen_destmode_wr : std_logic;
   --
   ext_fgen_framelen    : std_logic_vector(10 downto 0);
   ext_fgen_framelen_wr : std_logic;
   -- maclut control (clock domain clk2,rst2)
   ext_maclut_sel  : std_logic_vector(2 downto 0);
   ext_maclut_data : std_logic_vector(7 downto 0);
   ext_maclut_addr : std_logic_vector(3 downto 0);
   ext_maclut_load : std_logic;
   ext_maclut_wr   : std_logic;
   ext_maclut_rd   : std_logic;

   -- gmii rx-interface (8bit, rxc single edge)
   grxc : std_logic;
   grx_rst : std_logic;
   grx_en : std_logic;
   grx_er : std_logic;
   grxd : std_logic_vector(7 downto 0);

end record;

--
-- txrxint outputs (edit)
--
type txrxint_outputs_t is record

   -- write interface status (clock domain wclk(),wrst()) 
   wready : std_logic_vector(1 to txport1_NPORTS);
   wempty : std_logic_vector(1 to txport1_NPORTS); 
   wfull : std_logic_vector(1 to txport1_NPORTS); 
   werror : std_logic_vector(1 to txport1_NPORTS);
   wdatalen : txport1_framelen_vector_t(1 to txport1_NPORTS);
   wframes : txport1_frames_vector_t(1 to txport1_NPORTS);

   -- read interface (clock domain rclk(),rrst()) 
   renasts : std_logic_vector(1 to rxport1_NPORTS);
   rdata : rxport1_rdata_vector_t(1 to rxport1_NPORTS);
   rready : std_logic_vector(1 to rxport1_NPORTS);
   rempty : std_logic_vector(1 to rxport1_NPORTS); 
   rfull : std_logic_vector(1 to rxport1_NPORTS);
   rframes : rxport1_frames_vector_t(1 to rxport1_NPORTS);
   rsrcaddr : rxport1_srcaddr_vector_t(1 to rxport1_NPORTS);
   rsrcport : rxport1_srcport_vector_t(1 to rxport1_NPORTS);
   rdatalen : rxport1_datalen_vector_t(1 to rxport1_NPORTS);
   rdatacnt : rxport1_datalen_vector_t(1 to rxport1_NPORTS);
   rseqnum  : rxport1_seqnum_vector_t(1 to rxport1_NPORTS);
   reoframe : std_logic_vector(1 to rxport1_NPORTS);
   --
   rerrfull : std_logic_vector(1 to rxport1_NPORTS); 
   rerrempty : std_logic_vector(1 to rxport1_NPORTS); 

   -- gmii tx-interface (8bit, txc single edge)
   gtxc : std_logic;
   gtx_rst : std_logic;
   gtx_en : std_logic;
   gtx_er : std_logic;
   gtxd : std_logic_vector(7 downto 0);

   -- tx/rx seqnum arrays (clock domain clk2,rst2)
   txseqnum : txport1_seqnum_vector_t(1 to txport1_NPORTS);
   rxseqnum : rxport1_seqnum_vector_t(1 to rxport1_NPORTS);

   -- external interface status (clock domain clk2,rst2)
   ext_tport_enable_sts      : std_logic_vector(15 downto 0);
   ext_tport_ackenable_sts   : std_logic_vector(15 downto 0);
   ext_tport_timerenable_sts : std_logic_vector(15 downto 0);
   ext_tport_renable_sts     : std_logic_vector(15 downto 0);
   ext_tport_rerror_sts      : std_logic_vector(15 downto 0);
   --
   ext_rport_enable_sts    : std_logic_vector(15 downto 0);
   ext_rport_seqnumena_sts : std_logic_vector(15 downto 0);
   ext_rport_wready_sts    : std_logic_vector(15 downto 0);
   ext_rport_werrempty_sts : std_logic_vector(15 downto 0); 
   ext_rport_werrfull_sts  : std_logic_vector(15 downto 0); 
   -- srcfilter status
   ext_tport_srcfilterena_sts  : std_logic_vector(15 downto 0);
   ext_tport_srcfilteraddr_sts : cmdctrl_byte_vector_t(1 to txport1_NPORTS); 
   ext_tport_srcfilterport_sts : cmdctrl_nibble_vector_t(1 to txport1_NPORTS); 
   --
   ext_rport_srcfilterena_sts  : std_logic_vector(15 downto 0);
   ext_rport_srcfilteraddr_sts : cmdctrl_byte_vector_t(1 to rxport1_NPORTS); 
   ext_rport_srcfilterport_sts : cmdctrl_nibble_vector_t(1 to rxport1_NPORTS); 
   -- framegen status
   ext_fgen_ena_sts      : std_logic;
   ext_fgen_loop_sts     : std_logic;
   ext_fgen_trig_sts     : std_logic_vector(15 downto 0);
   ext_fgen_framelen_sts : std_logic_vector(10 downto 0);
   ext_fgen_destaddr_sts : std_logic_vector(7 downto 0);
   ext_fgen_destport_sts : std_logic_vector(3 downto 0);
   ext_fgen_destmode_sts : std_logic_vector(2 downto 0);
   -- maclut status
   ext_maclut_data_sts  : cmdctrl_byte_vector_t(0 to 5);
   ext_maclut_addr_sts  : std_logic_vector(3 downto 0);
   ext_maclut_valid_sts : std_logic;

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- txrxint component common interface (constant)
--
type txrxint_t is record
   inputs : txrxint_inputs_t;
   outputs : txrxint_outputs_t;
end record;

--
-- txrxint vector type (constant)
--
type txrxint_vector_t is array(NATURAL RANGE <>) of txrxint_t;

--
-- txrxint component declaration (constant)
--
component txrxint
generic (
   instance : natural
); 
port (
   inputs : in txrxint_inputs_t;
   outputs : out txrxint_outputs_t
);
end component;

--
-- txrxint global signal to export range/width params (constant)
--
signal component_txrxint : txrxint_t;

end component_txrxint;

--
-- txrxint entity declaration
--

-- libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
--
-- use work.component_[name].all;
--
use work.component_txrxint.all;
use work.component_txport1.all;
use work.component_rxport1.all;
use work.component_cmdctrl.all;
use work.component_txframe1.all;
use work.component_rxframe1.all;
use work.component_framegen.all;
 
-- txrxint entity (constant)
entity txrxint is
generic (
   instance : natural
); 
port (
   inputs : in txrxint_inputs_t;
   outputs : out txrxint_outputs_t
);
end txrxint;

--**************************************************************
--**************************************************************

--**************************************************************
--
--
-- Component Architecture
--
--
--**************************************************************

architecture rtl of txrxint is

--**************************************************************
--
-- Architecture declaration begin 
--
--**************************************************************

--
-- local constants (edit)
--
-- constant [name] : [type] := [value];
--
--constant LLLLL : natural := 000;

--
-- state machines (edit)
--
-- type [FSMname]_t is (S0, S1, S2, S3 ...);
-- 

--
-- local registers (edit)
--
--
-- Notes: one record-type for each clock domain
--

--
-- clock domain: clk2
--
type reglist_clk2_t is record
   --
   -- FSM list
   --
   -- [FSMname] : [FSMname]_t;
   --

   -- end of list
   eol : std_logic;

end record;
constant reglist_clk2_default : reglist_clk2_t :=
(
   eol => '0'
);

--
-- all local registers (edit)
--
-- Notes: one record-element for each clock domain
--
type reglist_t is record
   clk2 : reglist_clk2_t;
end record;

--
-- all local nets (edit)
--
type netlist_t is record
   --
   -- component interface signals (edit)
   --
   -- [instance_name] : [component_name]_t;
   -- [instance_name] : [component_name]_vector_t([instance_range]);
   --
   txport : txport1_t;
   txframe : txframe1_t;
   rxframe : rxframe1_t;
   rxport : rxport1_t;
   ctrl   : cmdctrl_t;
   fgen : framegen_t;

end record;

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
subtype inputs_t is txrxint_inputs_t;
subtype outputs_t is txrxint_outputs_t;

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
-- architecture rtl of txrxint
--
--**************************************************************
begin

--**************************************************************
--
-- components instances (edit)
--
--**************************************************************

--[instance_name/label] : [component_name] port map
--(
--   inputs => allnets.[instance_name].inputs,
--   outputs => allcmps.[instance_name].outputs
--);

txport : txport1 port map
(
   inputs => allnets.txport.inputs,
   outputs => allcmps.txport.outputs
);

rxport : rxport1 port map
(
   inputs => allnets.rxport.inputs,
   outputs => allcmps.rxport.outputs
);

txframe : txframe1
generic map
(
   instance => instance
)
port map
(
   inputs => allnets.txframe.inputs,
   outputs => allcmps.txframe.outputs
);

rxframe : rxframe1
generic map
(
   instance => instance
)
port map
(
   inputs => allnets.rxframe.inputs,
   outputs => allcmps.rxframe.outputs
);

ctrl : cmdctrl port map
(
   inputs => allnets.ctrl.inputs,
   outputs => allcmps.ctrl.outputs
);

fgen : framegen port map
(
   inputs => allnets.fgen.inputs,
   outputs => allcmps.fgen.outputs
);

--**************************************************************
--
-- sequential logic
--
--
-- Notes: one record-type for each clock domain
--
--**************************************************************

--
-- clock domain: clk2,rst2 (edit)
--
process (inputs.clk2, inputs.rst2)
begin
   if (inputs.rst2 = '1') then
      allregs.dout.clk2 <= reglist_clk2_default;
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
-- Transmitting path
--
-- clock domain: clk2
--
procedure SubTXpath
(
   variable i : in inputs_t;
   variable ri: in reglist_clk2_t;
   variable ro: in reglist_clk2_t;
   variable o : inout outputs_t;
   variable r : inout reglist_clk2_t;
   variable n : inout netlist_t
) is
begin

   -- txport interface (clock domain wclk(), wrst())
   n.txport.inputs.wclk       := i.wclk(1 to txport1_NPORTS);
   n.txport.inputs.wrst       := i.wrst(1 to txport1_NPORTS);

   -- frame generator (clock domain wclk(), wrst())
   n.fgen.inputs.wclk         := i.wclk(1 to txport1_NPORTS);
   n.fgen.inputs.wrst         := i.wrst(1 to txport1_NPORTS);

   -- txport write interface (filtered by frame generator module)
   n.fgen.inputs.wena         := i.wena(1 to txport1_NPORTS);
   n.fgen.inputs.wreq         := i.wreq(1 to txport1_NPORTS);
   n.fgen.inputs.wdata        := i.wdata(1 to txport1_NPORTS);
   n.fgen.inputs.wframelen    := i.wframelen(1 to txport1_NPORTS);
   n.fgen.inputs.wdestport    := i.wdestport(1 to txport1_NPORTS);
   n.fgen.inputs.wdestaddr    := i.wdestaddr(1 to txport1_NPORTS);
   n.fgen.inputs.wmulticast   := i.wmulticast(1 to txport1_NPORTS);
   n.fgen.inputs.wtxreq       := i.wtxreq(1 to txport1_NPORTS);
   n.fgen.inputs.wtxclr       := i.wtxclr(1 to txport1_NPORTS);
   --
   n.txport.inputs.wena       := n.fgen.outputs.tport_wena(1 to txport1_NPORTS);
   n.txport.inputs.wreq       := n.fgen.outputs.tport_wreq(1 to txport1_NPORTS);
   n.txport.inputs.wdata      := n.fgen.outputs.tport_wdata(1 to txport1_NPORTS);
   n.txport.inputs.wframelen  := n.fgen.outputs.tport_wframelen(1 to txport1_NPORTS);
   n.txport.inputs.wdestport  := n.fgen.outputs.tport_wdestport(1 to txport1_NPORTS);
   n.txport.inputs.wdestaddr  := n.fgen.outputs.tport_wdestaddr(1 to txport1_NPORTS);
   n.txport.inputs.wmulticast := n.fgen.outputs.tport_wmulticast(1 to txport1_NPORTS);
   n.txport.inputs.wtxreq     := n.fgen.outputs.tport_wtxreq(1 to txport1_NPORTS);
   n.txport.inputs.wtxclr     := n.fgen.outputs.tport_wtxclr(1 to txport1_NPORTS);

   -- txport write interface status (filtered by frame generator module)
   n.fgen.inputs.tport_wready   := n.txport.outputs.wready(1 to txport1_NPORTS);
   n.fgen.inputs.tport_wempty   := n.txport.outputs.wempty(1 to txport1_NPORTS);
   n.fgen.inputs.tport_wfull    := n.txport.outputs.wfull(1 to txport1_NPORTS);
   n.fgen.inputs.tport_werror   := n.txport.outputs.werror(1 to txport1_NPORTS);
   n.fgen.inputs.tport_wdatalen := n.txport.outputs.wdatalen(1 to txport1_NPORTS);
   n.fgen.inputs.tport_wframes  := n.txport.outputs.wframes(1 to txport1_NPORTS);
   --
   o.wready   := n.fgen.outputs.wready(1 to txport1_NPORTS);
   o.wempty   := n.fgen.outputs.wempty(1 to txport1_NPORTS);
   o.wfull    := n.fgen.outputs.wfull(1 to txport1_NPORTS);
   o.werror   := n.fgen.outputs.werror(1 to txport1_NPORTS);
   o.wdatalen := n.fgen.outputs.wdatalen(1 to txport1_NPORTS);
   o.wframes  := n.fgen.outputs.wframes(1 to txport1_NPORTS);

   -- txseqnum array to output (txport read side, clock domain clk2,rst2)
   o.txseqnum := n.txport.outputs.rseqnum(1 to txport1_NPORTS);

   -- txframe interface (clock domain clk2,rst2)
   n.txport.inputs.clk2  := i.clk2;
   n.txport.inputs.rst2  := i.rst2;
   n.txframe.inputs.clk2 := i.clk2;
   n.txframe.inputs.rst2 := i.rst2;
   --
   n.txframe.inputs.enable      := '1'; -- note: always enabled
   n.txframe.inputs.txportreq   := n.txport.outputs.txportreq;
   n.txframe.inputs.txportaddr  := n.txport.outputs.txportaddr(3 downto 0);
   n.txframe.inputs.txdatalen   := n.txport.outputs.txdatalen(10 downto 0);
   n.txframe.inputs.txframelen  := n.txport.outputs.txframelen(10 downto 0);
   n.txframe.inputs.txdestport  := n.txport.outputs.txdestport(3 downto 0);
   n.txframe.inputs.txdestaddr  := n.txport.outputs. txdestaddr(7 downto 0);
   n.txframe.inputs.txmulticast := n.txport.outputs.txmulticast;
   n.txframe.inputs.txbroadcast := '0'; -- note: broadcast not used
   n.txframe.inputs.txdata      := n.txport.outputs.txdata(7 downto 0);
   n.txframe.inputs.txseqnum    := n.txport.outputs.txseqnum(31 downto 0);
   --
   n.txport.inputs.txportreqok := n.txframe.outputs.txportreqok;
   n.txport.inputs.txrdreq     := n.txframe.outputs.txrdreq;
   n.txport.inputs.txdone      := n.txframe.outputs.txframedone;
   -- 
   n.txframe.inputs.txnodeaddr := i.nodeaddr(7 downto 0);

   -- ieee MAC pause-frame transmission (note: not used)
   n.txframe.inputs.txpausereq := '0';
   n.txframe.inputs.txpausequanta := SLV(0, 16);

   -- ieee MAC pause-timer control (note: not used)
   n.txframe.inputs.pauseload := '0';
   n.txframe.inputs.pausequanta := SLV(0, 16);

   -- gmii tx-interface (8bit, txc single edge)
   o.gtxc    := i.clk2; 
   o.gtx_rst := i.rst2;
   -- gtxc    --> gmii tx-clock (common tx/rx clock domain: gmii tx-clock is 'clk2')
   -- gtx_rst --> gmii tx-reset (common tx/rx clock domain: gmii tx-reset is 'rst2')
   o.gtx_en  := n.txframe.outputs.gtx_en;
   o.gtx_er  := n.txframe.outputs.gtx_er;
   o.gtxd    := n.txframe.outputs.gtxd(7 downto 0);

end procedure;

--
-- Receiving path
--
-- clock domain: clk2
--
procedure SubRXpath
(
   variable i : in inputs_t;
   variable ri: in reglist_clk2_t;
   variable ro: in reglist_clk2_t;
   variable o : inout outputs_t;
   variable r : inout reglist_clk2_t;
   variable n : inout netlist_t
) is
begin

   -- clock,reset list
   n.rxframe.inputs.clk2 := i.grxc;
   n.rxframe.inputs.rst2 := i.grx_rst;
   -- NOTE: rxframe.clk2/rst2 driven by gmii grxc/grx_rst (gmii rx-interface clock domain) 
   n.rxframe.inputs.clk1 := i.clk2;
   n.rxframe.inputs.rst1 := i.rst2;
   -- NOTE: rxframe.clk1/rst1 driven by clk2/rst2 (common tx/rx clock domain)

   -- gmii rx-interface (8bit, rxc single edge)
   n.rxframe.inputs.grx_en := i.grx_en;
   n.rxframe.inputs.grx_er := i.grx_er;
   n.rxframe.inputs.grxd   := i.grxd(7 downto 0);

   -- rxframe globals
   n.rxframe.inputs.enable        := '1'; -- note: always enabled
   n.rxframe.inputs.maxframelen   := SLV(6+6+2+1500+4, 14);
   n.rxframe.inputs.nodeaddr      := i.nodeaddr(7 downto 0);
   n.rxframe.inputs.multicastaddr := i.multicastaddr(7 downto 0);

   -- rxframe header filter modes
   n.rxframe.inputs.mode_destaddr_unicast   := '1';
   n.rxframe.inputs.mode_destaddr_multicast := '1';
   n.rxframe.inputs.mode_destaddr_broadcast := '1';
   n.rxframe.inputs.mode_pause              := '0'; -- note: pause frame ignored
   n.rxframe.inputs.mode_data               := '1';
   n.rxframe.inputs.mode_cmd                := '1';
   --
   -- mode_destaddr_unicast       ('1' destaddr=unicast recognized, '0' filtered out)
   -- mode_destaddr_multicast     ('1' destaddr=multicast recognized, '0' filtered out)
   -- mode_destaddr_broadcast     ('1' destaddr=broadcast recognized, '0' filtered out)
   -- mode_pause                  ('1' pause frame recognized, '0' filtered out)
   -- mode_data                   ('1' data  frame recognized, '0' filtered out)
   -- mode_cmd                    ('1' cmd   frame recognized, '0' filtered out)
   --

   -- rxport write interface (common tx/rx clock domain clk2,rst2)
   n.rxport.inputs.clk2 := i.clk2;
   n.rxport.inputs.rst2 := i.rst2;
   --
   n.rxport.inputs.wdata      := n.rxframe.outputs.rxdata(7 downto 0);
   n.rxport.inputs.wdatalen   := n.rxframe.outputs.rxdatalen(13 downto 0);
   n.rxport.inputs.wsrcaddr   := n.rxframe.outputs.rxsrcaddr(7 downto 0);
   n.rxport.inputs.wdestport  := n.rxframe.outputs.rxdestport(3 downto 0);
   n.rxport.inputs.wsrcport   := n.rxframe.outputs.rxsrcport(3 downto 0);
   n.rxport.inputs.wseqnum    := n.rxframe.outputs.rxseqnum(31 downto 0);
   n.rxport.inputs.wreq       := n.rxframe.outputs.rxwrreq;
   n.rxport.inputs.wframeok   := n.rxframe.outputs.rxframeok;
   n.rxport.inputs.wframedone := n.rxframe.outputs.rxframedone;
   --
   -- rxdata      --> frame data (8bit)
   -- rxdatalen   --> frame datafield length (13bit)
   -- rxdestaddr  --> param destaddr (8bit) -- not used
   -- rxmulticast --> param multicast ('1' rxdestaddr is a groupaddr, '0' rxdestaddr is a node address) -- not used
   -- rxsrcaddr   --> param srcaddr (8bit)
   -- rxdestport  --> param destport (4bit, valid range 1..15, destport = 0 reserved)
   -- rxsrcport   --> param srcport (4bit, valid range 1..15, destport = 0 reserved)
   -- rxseqnum    --> param seqnum (32bit)
   -- rxldata     --> param ldata (16bit) -- not used
   -- rxwrreq     --> rxport wrreq 
   -- rxframeok   --> rxport write in progress (level) 
   -- rxframedone --> rxdata write done (pulse, 1 clock)
   --

--   n.rxport.inputs.????rxdestaddr  : std_logic_vector(7 downto 0); ??? perche' rxdestaddr non e' usato ???
--   ...perche' si assume gia' filtrato e uguale al nodeaddr
--
--   n.rxport.inputs.???rxmulticast : std_logic;......??? anche per il multicast in caso di multicast group
--   questo e' gia' uguale a i.multicastaddr e per il nodo non c'e' differenza tra una frame che arriva via
--   multicast e una che arriva in unicast.... 
--
--   n.rxport.inputs.rxldata     : std_logic_vector(15 downto 0);
--   !!! ldata non usato, si impiega 'datalen' !!!!

   -- rxseqnum array to output (common tx/rx clock domain clk2,rst2)
   o.rxseqnum := n.rxport.outputs.rxseqnum(1 to rxport1_NPORTS);

   -- rxport read interface: RX_NPORTS clock domains
   n.rxport.inputs.rclk := i.rclk(1 to rxport1_NPORTS);
   n.rxport.inputs.rrst := i.rrst(1 to rxport1_NPORTS);

   -- rxport read interface (clock domain rclk(),rrst()) 
   n.rxport.inputs.rena := i.rena(1 to rxport1_NPORTS);
   n.rxport.inputs.rreq := i.rreq(1 to rxport1_NPORTS);
   n.rxport.inputs.rack := i.rack(1 to rxport1_NPORTS);
   -- 
   o.renasts  := n.rxport.outputs.renasts(1 to rxport1_NPORTS);
   o.rdata    := n.rxport.outputs.rdata(1 to rxport1_NPORTS);
   o.rready   := n.rxport.outputs.rready(1 to rxport1_NPORTS);
   o.rempty   := n.rxport.outputs.rempty(1 to rxport1_NPORTS);
   o.rfull    := n.rxport.outputs.rfull(1 to rxport1_NPORTS);
   o.rframes  := n.rxport.outputs.rframes(1 to rxport1_NPORTS);
   o.rsrcaddr := n.rxport.outputs.rsrcaddr(1 to rxport1_NPORTS);
   o.rsrcport := n.rxport.outputs.rsrcport(1 to rxport1_NPORTS);
   o.rdatalen := n.rxport.outputs.rdatalen(1 to rxport1_NPORTS);
   o.rdatacnt := n.rxport.outputs.rdatacnt(1 to rxport1_NPORTS);
   o.rseqnum  := n.rxport.outputs.rseqnum(1 to rxport1_NPORTS);
   o.reoframe := n.rxport.outputs.reoframe(1 to rxport1_NPORTS);
   --
   o.rerrfull  := n.rxport.outputs.rerrfull(1 to rxport1_NPORTS);
   o.rerrempty := n.rxport.outputs.rerrempty(1 to rxport1_NPORTS);

end procedure;


--
-- Control path
--
-- clock domain: clk2
--
procedure SubCTRLpath
(
   variable i : in inputs_t;
   variable ri: in reglist_clk2_t;
   variable ro: in reglist_clk2_t;
   variable o : inout outputs_t;
   variable r : inout reglist_clk2_t;
   variable n : inout netlist_t
) is
begin

   -- cmdctrl clock,reset (clock domain clk2,rst2)
   n.ctrl.inputs.clk2 := i.clk2;
   n.ctrl.inputs.rst2 := i.rst2;

   -- txport read-side status (clock domain clk2, rst2)
   n.ctrl.inputs.tport_renable := n.txport.outputs.renable(1 to txport1_NPORTS);
   n.ctrl.inputs.tport_rerror  := n.txport.outputs.rerror(1 to txport1_NPORTS);
   FOR index IN 1 to txport1_NPORTS LOOP
      n.ctrl.inputs.tport_rseqnum(index) := n.txport.outputs.rseqnum(index)(31 downto 0);
   END LOOP;
   --
   -- renable --> txport status (read side)
   -- rerror  --> write op when full | write op when not ready (read side, 'werror' sticky bit)
   -- rseqnum --> seqnum status (read side only, array 1..NPORTS of 32bit counters)
   --

   -- rxport write-side status (clock domain clk2, rst2)
   n.ctrl.inputs.rport_wready   := n.rxport.outputs.wready(1 to rxport1_NPORTS);
   FOR index IN 1 to rxport1_NPORTS LOOP
      n.ctrl.inputs.rport_rxseqnum(index) := n.rxport.outputs.rxseqnum(index)(31 downto 0);
   END LOOP;
   -- 
   n.ctrl.inputs.rport_werrempty := n.rxport.outputs.werrempty(1 to rxport1_NPORTS);
   n.ctrl.inputs.rport_werrfull  := n.rxport.outputs.werrfull(1 to rxport1_NPORTS);
   --
   -- wready   --> rxport ready (rready status to write-side)
   -- rxseqnum --> rxport seqnum (array 1..NPORTS of 32bit counters)
   -- 
   -- werrempty --> read-when-empty error (sticky bit, rerrempty status to write-side)
   -- werrfull  --> write-when-full error (sticky bit, write-side)
   --               note: sticky bits cleared when rxport re-enabled

   -- txframe status (clock domain clk2, rst2)
   n.ctrl.inputs.tx_enablests  := n.txframe.outputs.txenablests;
   n.ctrl.inputs.tx_cmddone    := n.txframe.outputs.txcmddone;
   n.ctrl.inputs.tx_cmdregfull := n.txframe.outputs.cmdregfull;
   --
   -- enablests  --> txframe enable status
   -- cmddone    --> txcmd short frame done (pulse, one clock) 
   -- cmdregfull --> cmd input fifo status (1 --> cmd loaded --> fifo full) 
   --

   -- rxframe status (clock domain clk2, rst2)
   n.ctrl.inputs.rx_enablests := n.rxframe.outputs.rxenablests;
   --
   -- enablests  --> rxframe enable status
   --

   -- rxframe command-interface (clock domain clk2,rst2)
   n.ctrl.inputs.rx_cmdready    := n.rxframe.outputs.cmdready;
   n.ctrl.inputs.rx_cmdsrcport  := n.rxframe.outputs.cmdsrcport(3 downto 0);
   n.ctrl.inputs.rx_cmddestaddr := n.rxframe.outputs.cmddestaddr(7 downto 0);
   n.ctrl.inputs.rx_cmdsrcaddr  := n.rxframe.outputs.cmdsrcaddr(7 downto 0);
   n.ctrl.inputs.rx_cmdcode     := n.rxframe.outputs.cmdcode(7 downto 0);
   n.ctrl.inputs.rx_cmdports    := n.rxframe.outputs.cmdports(7 downto 0);
   FOR index IN 0 TO 5 LOOP 
      n.ctrl.inputs.rx_cmdparams(index) := n.rxframe.outputs.cmdparams(index)(7 downto 0);
   END LOOP;
   n.ctrl.inputs.rx_cmddone     := n.rxframe.outputs.cmddone;
   --
   -- cmdready    --> command is ready (single register output fifo, showahead mode,
   --                 flag cleared when input 'cmdread' asserted) 
   -- cmdsrcport  --> cmd udp srcport (4bit)
   -- cmddestaddr --> cmd header(0): destaddr (8bit)
   -- cmdsrcaddr  --> cmd header(1): srcaddr (8bit)
   -- cmdcode     --> cmd header(2): code (8bit)
   -- cmdports    --> cmd header(3): ports (8bit)
   -- cmdparams   --> cmd header(4 to 9): params (6 x 8bit)
   -- cmddone     --> command frame received (pulse, 1 clock)
   --
   
   -- txport cmdctrl-interface (clock domain clk2,rst2)
   n.txport.inputs.enable      := n.ctrl.outputs.tport_enable(1 to txport1_NPORTS);
   n.txport.inputs.ackenable   := n.ctrl.outputs.tport_ackenable(1 to txport1_NPORTS);
   n.txport.inputs.timerenable := n.ctrl.outputs.tport_timerenable(1 to txport1_NPORTS);
   --
   n.txport.inputs.cmdseqnumclr   := n.ctrl.outputs.tport_cmdseqnumclr(1 to txport1_NPORTS);
   n.txport.inputs.cmdackreceived := n.ctrl.outputs.tport_cmdackreceived;
   n.txport.inputs.cmdackportaddr := n.ctrl.outputs.tport_cmdackportaddr(3 downto 0);
   n.txport.inputs.cmdackseqnum   := n.ctrl.outputs.tport_cmdackseqnum(31 downto 0);
   --
   -- enable  --> read side enable/discard request (level, cmdctrl driven)
   --             txport is enabled when both wena,enable are asserted
   --             ('enable = 0' stops transmission at the end of current frame,
   --             other loaded frames are discarded until txport is empty).  
   --
   -- ackenable      --> ackenable flags (level, cmdctrl driven)
   --                    0 --> 'datagram mode' (frame transmitted only once)
   --                    1 --> 'connection mode' (frame re-transmission until ack received)
   -- timerenable    --> txtimer enable flags (level, cmdctrl driven)
   --                    0 --> timer off (full speed transmission)
   --                    1 --> timer on  ('datagram mode': holdoff applied between transmissions) 
   --                                    ('connection mode': re-transmission holdoff applied until ack received) 
   --
   -- cmdseqnumclr   --> txseqnum(index) = 0 (pulse, 1 clock, cmdctrl driven)
   --                    index = 1..NPORTS --> command applied in parallel to all selected ports
   --
   -- cmdackreceived --> txseqnum(index)++ with frame-flush when 'ackseqnum(index) = txseqnum(index)' (pulse, 1 clock, cmdctrl driven)
   --                    index = cmdackportaddr --> command applied to selected port
   -- cmdackportaddr     cmdparam ackportaddr (1..NPORTS) 
   -- cmdackseqnum       cmdparam ackseqnum   (32bit)
   --

   -- rxport cmdctrl-interface (clock domain clk2,rst2)
   n.rxport.inputs.enable := n.ctrl.outputs.rport_enable(1 to rxport1_NPORTS);
   --
   n.rxport.inputs.seqnumena := n.ctrl.outputs.rport_seqnumena(1 to rxport1_NPORTS);
   n.rxport.inputs.seqnumclr := n.ctrl.outputs.rport_seqnumclr(1 to rxport1_NPORTS);
   --
   n.rxport.inputs.srcfilterena := n.ctrl.outputs.rport_srcfilterena(1 to rxport1_NPORTS);
   FOR index in 1 TO rxport1_NPORTS LOOP
      n.rxport.inputs.srcfilteraddr(index) := n.ctrl.outputs.rport_srcfilteraddr(index)(7 downto 0);
      n.rxport.inputs.srcfilterport(index) := n.ctrl.outputs.rport_srcfilterport(index)(3 downto 0);
   END LOOP;
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

   -- txframe command-interface (clock domain clk2,rst2)
   n.txframe.inputs.cmdwrite     := n.ctrl.outputs.tx_cmdwrite;
   n.txframe.inputs.cmddestport  := n.ctrl.outputs.tx_cmddestport(3 downto 0);
   n.txframe.inputs.cmddestaddr  := n.ctrl.outputs.tx_cmddestaddr(7 downto 0);
   n.txframe.inputs.cmdcode      := n.ctrl.outputs.tx_cmdcode(7 downto 0);
   n.txframe.inputs.cmdports     := n.ctrl.outputs.tx_cmdports(7 downto 0);
   FOR index IN 0 TO 5 LOOP
      n.txframe.inputs.cmdparams(index) := n.ctrl.outputs.tx_cmdparams(index)(7 downto 0);
   END LOOP;
   n.txframe.inputs.cmd_txreq    := n.ctrl.outputs.tx_cmd_txreq;
   n.txframe.inputs.cmd_macread  := n.ctrl.outputs.tx_cmd_macread;
   n.txframe.inputs.cmd_macwrite := n.ctrl.outputs.tx_cmd_macwrite;
   --
   -- cmdwrite    --> command write request (cmd written to single register input fifo, pulse, 1 clock) 
   -- cmddestport --> destport (4bit)
   -- cmddestaddr --> destaddr (8bit)
   -- cmdcode     --> code (8bit)
   -- cmdports    --> ports (8bit)
   -- cmdparams   --> params (6 x 8bit)
   -- cmd_txreq   --> exec flag ('1' command frame transmitted, '0' command does not need transmission)
   -- cmd_macread --> exec flag ('0' standard txcmd frame, '1' MAC-address-lut-read special frame)
   -- cmd_macwrite --> exec flag ('1' MAC-address-lut write) 
   --

   -- macread command
   FOR index IN 0 TO 5 LOOP
      n.ctrl.inputs.tx_macread_data(index) := n.txframe.outputs.macread_data(index)(7 downto 0);
   END LOOP;
   n.ctrl.inputs.tx_macread_addr := n.txframe.outputs.macread_addr(3 downto 0);
   n.ctrl.inputs.tx_macread_ok   := n.txframe.outputs.macread_ok;
   --
   -- macread_data --> data from last macread command (48bit mac)
   -- macread_addr --> addr from last macread command (4bit maclut index)
   -- macread_ok   --> macread data ok (pulse, one clock)
   --

   -- rxframe command-interface (clock domain clk2,rst2)
   n.rxframe.inputs.cmdread := n.ctrl.outputs.rx_cmdread; 
   --
   -- cmdread --> single register output fifo read ack (pulse, 1 clock) 
   --

   -- framegen control
   n.fgen.inputs.tx_clk       := i.clk2;
   n.fgen.inputs.reset_tx_clk := i.rst2;
   --
   n.fgen.inputs.fgen_wr   := n.ctrl.outputs.fgen_wr;
   --
   n.fgen.inputs.fgen_ena  := n.ctrl.outputs.fgen_ena;
   n.fgen.inputs.fgen_loop := n.ctrl.outputs.fgen_loop;
   n.fgen.inputs.fgen_trig := n.ctrl.outputs.fgen_trig(1 to txport1_NPORTS);
   -- 
   n.fgen.inputs.fgen_framelen := n.ctrl.outputs.fgen_framelen(10 downto 0);
   n.fgen.inputs.fgen_destaddr := n.ctrl.outputs.fgen_destaddr(7 downto 0);
   n.fgen.inputs.fgen_destport := n.ctrl.outputs.fgen_destport(3 downto 0);
   n.fgen.inputs.fgen_destmode := n.ctrl.outputs.fgen_destmode(2 downto 0);

   -- external interface (clock domain clk2,rst2)
   n.ctrl.inputs.ext_tport_enable_wr       := i.ext_tport_enable_wr;
   n.ctrl.inputs.ext_tport_ackenable_wr    := i.ext_tport_ackenable_wr;
   n.ctrl.inputs.ext_tport_timerenable_wr  := i.ext_tport_timerenable_wr;
   n.ctrl.inputs.ext_tport_seqnumclr_wr    := i.ext_tport_seqnumclr_wr;
   n.ctrl.inputs.ext_tport_enable          := i.ext_tport_enable(15 downto 0);
   n.ctrl.inputs.ext_tport_ackenable       := i.ext_tport_ackenable(15 downto 0);
   n.ctrl.inputs.ext_tport_timerenable     := i.ext_tport_timerenable(15 downto 0);
   n.ctrl.inputs.ext_tport_seqnumclr       := i.ext_tport_seqnumclr(15 downto 0);
   --
   n.ctrl.inputs.ext_rport_enable_wr       := i.ext_rport_enable_wr; 
   n.ctrl.inputs.ext_rport_seqnumena_wr    := i.ext_rport_seqnumena_wr;
   n.ctrl.inputs.ext_rport_seqnumclr_wr    := i.ext_rport_seqnumclr_wr;
   n.ctrl.inputs.ext_rport_enable          := i.ext_rport_enable(15 downto 0);
   n.ctrl.inputs.ext_rport_seqnumena       := i.ext_rport_seqnumena(15 downto 0);
   n.ctrl.inputs.ext_rport_seqnumclr       := i.ext_rport_seqnumclr(15 downto 0);
   -- srcfilter control
   n.ctrl.inputs.ext_tport_srcfilterena    := i.ext_tport_srcfilterena(15 downto 0);
   n.ctrl.inputs.ext_tport_srcfilterena_wr := i.ext_tport_srcfilterena_wr;
   --
   n.ctrl.inputs.ext_tport_srcfilter       := i.ext_tport_srcfilter(3 downto 0);
   n.ctrl.inputs.ext_tport_srcfilteraddr   := i.ext_tport_srcfilteraddr(7 downto 0); 
   n.ctrl.inputs.ext_tport_srcfilterport   := i.ext_tport_srcfilterport(3 downto 0); 
   n.ctrl.inputs.ext_tport_srcfilter_wr    := i.ext_tport_srcfilter_wr;
   --
   n.ctrl.inputs.ext_rport_srcfilterena    := i.ext_rport_srcfilterena(15 downto 0);
   n.ctrl.inputs.ext_rport_srcfilterena_wr := i.ext_rport_srcfilterena_wr;
   --
   n.ctrl.inputs.ext_rport_srcfilter       := i.ext_rport_srcfilter(3 downto 0);
   n.ctrl.inputs.ext_rport_srcfilteraddr   := i.ext_rport_srcfilteraddr(7 downto 0); 
   n.ctrl.inputs.ext_rport_srcfilterport   := i.ext_rport_srcfilterport(3 downto 0); 
   n.ctrl.inputs.ext_rport_srcfilter_wr    := i.ext_rport_srcfilter_wr;
   -- framegen control
   n.ctrl.inputs.ext_fgen_ena              := i.ext_fgen_ena;
   n.ctrl.inputs.ext_fgen_loop             := i.ext_fgen_loop;
   n.ctrl.inputs.ext_fgen_trig             := i.ext_fgen_trig(15 downto 0);
   n.ctrl.inputs.ext_fgen_wr               := i.ext_fgen_wr;
   --
   n.ctrl.inputs.ext_fgen_destaddr         := i.ext_fgen_destaddr(7 downto 0);
   n.ctrl.inputs.ext_fgen_destport         := i.ext_fgen_destport(3 downto 0);
   n.ctrl.inputs.ext_fgen_destaddr_wr      := i.ext_fgen_destaddr_wr;
   --
   n.ctrl.inputs.ext_fgen_destmode         := i.ext_fgen_destmode(2 downto 0);
   n.ctrl.inputs.ext_fgen_destmode_wr      := i.ext_fgen_destmode_wr;
   --
   n.ctrl.inputs.ext_fgen_framelen         := i.ext_fgen_framelen(10 downto 0);
   n.ctrl.inputs.ext_fgen_framelen_wr      := i.ext_fgen_framelen_wr;
   -- maclut control
   n.ctrl.inputs.ext_maclut_sel  := i.ext_maclut_sel(2 downto 0);
   n.ctrl.inputs.ext_maclut_data := i.ext_maclut_data(7 downto 0);
   n.ctrl.inputs.ext_maclut_addr := i.ext_maclut_addr(3 downto 0);
   n.ctrl.inputs.ext_maclut_load := i.ext_maclut_load;
   n.ctrl.inputs.ext_maclut_wr   := i.ext_maclut_wr;
   n.ctrl.inputs.ext_maclut_rd   := i.ext_maclut_rd;

   -- external interface status (clock domain clk2,rst2)
   o.ext_tport_enable_sts        := n.ctrl.outputs.ext_tport_enable_sts(15 downto 0);
   o.ext_tport_ackenable_sts     := n.ctrl.outputs.ext_tport_ackenable_sts(15 downto 0);
   o.ext_tport_timerenable_sts   := n.ctrl.outputs.ext_tport_timerenable_sts(15 downto 0);
   o.ext_tport_renable_sts       := n.ctrl.outputs.ext_tport_renable_sts(15 downto 0);
   o.ext_tport_rerror_sts        := n.ctrl.outputs.ext_tport_rerror_sts(15 downto 0);
   --
   o.ext_rport_enable_sts        := n.ctrl.outputs.ext_rport_enable_sts(15 downto 0);
   o.ext_rport_seqnumena_sts     := n.ctrl.outputs.ext_rport_seqnumena_sts(15 downto 0);
   o.ext_rport_wready_sts        := n.ctrl.outputs.ext_rport_wready_sts(15 downto 0);
   o.ext_rport_werrempty_sts     := n.ctrl.outputs.ext_rport_werrempty_sts(15 downto 0); 
   o.ext_rport_werrfull_sts      := n.ctrl.outputs.ext_rport_werrfull_sts(15 downto 0); 
   -- srcfilter status
   o.ext_tport_srcfilterena_sts  := n.ctrl.outputs.ext_tport_srcfilterena_sts(15 downto 0);
   o.ext_tport_srcfilteraddr_sts := n.ctrl.outputs.ext_tport_srcfilteraddr_sts(1 to txport1_NPORTS); 
   o.ext_tport_srcfilterport_sts := n.ctrl.outputs.ext_tport_srcfilterport_sts(1 to txport1_NPORTS); 
   --
   o.ext_rport_srcfilterena_sts  := n.ctrl.outputs.ext_rport_srcfilterena_sts(15 downto 0);
   o.ext_rport_srcfilteraddr_sts := n.ctrl.outputs.ext_rport_srcfilteraddr_sts(1 to rxport1_NPORTS); 
   o.ext_rport_srcfilterport_sts := n.ctrl.outputs.ext_rport_srcfilterport_sts(1 to rxport1_NPORTS); 
   -- framegen status
   o.ext_fgen_ena_sts  := n.ctrl.outputs.ext_fgen_ena_sts;
   o.ext_fgen_loop_sts := n.ctrl.outputs.ext_fgen_loop_sts;
   o.ext_fgen_trig_sts := n.ctrl.outputs.ext_fgen_trig_sts(15 downto 0);
   --
   o.ext_fgen_destaddr_sts := n.ctrl.outputs.ext_fgen_destaddr_sts(7 downto 0);
   o.ext_fgen_destport_sts := n.ctrl.outputs.ext_fgen_destport_sts(3 downto 0);
   o.ext_fgen_destmode_sts := n.ctrl.outputs.ext_fgen_destmode_sts(2 downto 0);
   --
   o.ext_fgen_framelen_sts := n.ctrl.outputs.ext_fgen_framelen_sts(10 downto 0);
   --
   o.ext_maclut_data_sts  := n.ctrl.outputs.ext_maclut_data_sts(0 to 5);
   o.ext_maclut_addr_sts  := n.ctrl.outputs.ext_maclut_addr_sts(3 downto 0);
   o.ext_maclut_valid_sts := n.ctrl.outputs.ext_maclut_valid_sts;

end procedure;


--
-- Debug combinatorial procedure (edit)
--
-- all clock domains
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

   null;

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
   n.txport.outputs := allcmps.txport.outputs;
   n.txframe.outputs := allcmps.txframe.outputs;
   n.rxframe.outputs := allcmps.rxframe.outputs;
   n.rxport.outputs := allcmps.rxport.outputs;
   n.ctrl.outputs := allcmps.ctrl.outputs;
   n.fgen.outputs := allcmps.fgen.outputs;
   
   --
   -- all procedures call (edit)
   --
   -- clock domain: clk2
   SubTXpath(i, ri.clk2, ro.clk2, o, r.clk2, n);
   SubRXpath(i, ri.clk2, ro.clk2, o, r.clk2, n);
   SubCTRLpath(i, ri.clk2, ro.clk2, o, r.clk2, n);

   -- all clock domains
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
-- architecture rtl of txrxint
--
--**************************************************************
