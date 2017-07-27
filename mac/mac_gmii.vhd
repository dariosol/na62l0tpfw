--**************************************************************
--**************************************************************
--
-- Template file: comp_ck2.rec (new component, dual clk)
--
--**************************************************************
--**************************************************************
--
--
-- Component mac_gmii
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
-- note: components txport1,rxport1 are included at package level 
-- (read/write interfaces exported to upper levels)

package component_mac_gmii is

--**************************************************************
--
-- I/O section begin 
--
--**************************************************************

--
-- mac_gmii constants (edit)
--
-- constant mac_gmii_[constant_name] : [type] := [value];
--

--
-- mac_gmii typedefs (edit)
--
-- subtype mac_gmii_[name]_t is [type];
-- type mac_gmii_[name]_t is [type];
--

--
-- mac_gmii inputs (edit)
--
type mac_gmii_inputs_t is record

   -- clock list
   clk : std_logic;      -- Avalon-MM clock
   tx_clk : std_logic;   -- gmii tx clock
   rx_clk : std_logic;   -- gmii rx clock
   
   -- reset list
   reset_clk : std_logic;
   reset_tx_clk : std_logic;
   reset_rx_clk : std_logic;
   --
   -- NOTE: we assume all resets async asserted, sync deasserted by related clocks
   --

   -- gmii rx-interface (8bit, rx_clk single edge)
   grx_en : std_logic;
   grx_er : std_logic;
   grxd : std_logic_vector(7 downto 0);

   -- RegFile interface (Avalon-MM slave)
   mmaddress : std_logic_vector(3 downto 0);
   mmread : std_logic;
   mmwrite : std_logic;
   mmwritedata : std_logic_vector(31 downto 0);
   
   -- node params (quasi-static params, assumed synchronized to tx_clk)
   nodeaddr : std_logic_vector(7 downto 0);
   multicastaddr : std_logic_vector(7 downto 0);
   
   -- write interface: txport1_NPORTS clock domains
   wclk : std_logic_vector(1 to txport1_NPORTS);
   wrst : std_logic_vector(1 to txport1_NPORTS);

   -- write interface inputs (clock domain wclk(),wrst()) 
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

   -- read interface inputs (clock domain rclk(),rrst()) 
   rena : std_logic_vector(1 to rxport1_NPORTS);
   rreq : std_logic_vector(1 to rxport1_NPORTS);
   rack : std_logic_vector(1 to rxport1_NPORTS);

   -- CPU interface (0 --> interface OFF, 1..NPORTS --> interface ON)
   CPUtxport : std_logic_vector(3 downto 0);
   CPUrxport : std_logic_vector(3 downto 0);
   -- note: CPU interface inputs work as generic parameters (normally driven by constant values) 

end record;

--
-- mac_gmii outputs (edit)
--
type mac_gmii_outputs_t is record

   -- gmii tx-interface (8bit, tx_clk single edge)
   gtx_en : std_logic;
   gtx_er : std_logic;
   gtxd : std_logic_vector(7 downto 0);

   -- RegFile interface (Avalon-MM slave)
   mmreaddata : std_logic_vector(31 downto 0);
   mmreaddatavalid : std_logic;
   mmwaitrequest : std_logic;

   -- write interface outputs (clock domain wclk(),wrst()) 
   wready : std_logic_vector(1 to txport1_NPORTS);
   wempty : std_logic_vector(1 to txport1_NPORTS); 
   wfull : std_logic_vector(1 to txport1_NPORTS); 
   werror : std_logic_vector(1 to txport1_NPORTS);
   wdatalen : txport1_framelen_vector_t(1 to txport1_NPORTS);
   wframes : txport1_frames_vector_t(1 to txport1_NPORTS);

   -- read interface outputs (clock domain rclk(),rrst()) 
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

end record;

--**************************************************************
--
-- I/O section end
--
--**************************************************************

--**************************************************************
--**************************************************************

--
-- mac_gmii component common interface (constant)
--
type mac_gmii_t is record
   inputs : mac_gmii_inputs_t;
   outputs : mac_gmii_outputs_t;
end record;

--
-- mac_gmii vector type (constant)
--
type mac_gmii_vector_t is array(NATURAL RANGE <>) of mac_gmii_t;

--
-- mac_gmii component declaration (constant)
--
component mac_gmii
generic (
   instance : natural
); 
port (
   inputs : in mac_gmii_inputs_t;
   outputs : out mac_gmii_outputs_t
);
end component;

--
-- mac_gmii global signal to export range/width params (constant)
--
signal component_mac_gmii : mac_gmii_t;

end component_mac_gmii;

--
-- mac_gmii entity declaration
--

-- libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
--
-- use work.component_[name].all;
--
use work.component_mac_gmii.all;
use work.component_txrxint.all;
use work.component_regfile1.all;
use work.component_regsync1.all;
-- 
use work.component_txport1.all;
use work.component_rxport1.all;

-- mac_gmii entity (constant)
entity mac_gmii is
generic (
   instance : natural
); 
port (
   inputs : in mac_gmii_inputs_t;
   outputs : out mac_gmii_outputs_t
);
end mac_gmii;

--**************************************************************
--**************************************************************

--**************************************************************
--
--
-- Component Architecture
--
--
--**************************************************************

architecture rtl of mac_gmii is

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
-- clock domain wclk (edit)
--
type reglist_wclk_t is record

   -- end of list 
   eol : std_logic;

end record;
constant reglist_wclk_default : reglist_wclk_t :=
(
   eol => '0'
);
type reglist_wclk_vector_t is array(NATURAL RANGE <>) of reglist_wclk_t;

--
-- clock domain clk (edit)
--
type reglist_clk_t is record

   ---- FSM list
   --FSMmain : FSMmain_t;

   -- tx-write posedge detector 
   wreq_p : std_logic;
   wtxreq_p : std_logic;
   wtxclr_p : std_logic;

   -- rx-read posedge detector 
   rreq_p : std_logic;
   rack_p : std_logic;

   -- hwaddress input chain (quasi static external async input, synchronized by single ff)
   hwaddressI : std_logic_vector(7 downto 0); 

   -- end of list 
   eol : std_logic;

end record;
constant reglist_clk_default : reglist_clk_t :=
(
   --FSMmain => S0,
   wreq_p => '0',
   wtxreq_p => '0',
   wtxclr_p => '0',
   rreq_p => '0',
   rack_p => '0',
   hwaddressI => (others => '0'), 

   eol => '0'
);

--
-- clock domain tx_clk
--
type reglist_tx_clk_t is record

   -- end of list 
   eol : std_logic;

end record;
constant reglist_tx_clk_default : reglist_tx_clk_t :=
(
   eol => '0'
);

--
-- clock domain rx_clk
--
type reglist_rx_clk_t is record

   -- end of list 
   eol : std_logic;

end record;
constant reglist_rx_clk_default : reglist_rx_clk_t :=
(
   eol => '0'
);

--
-- all local registers (edit)
--
-- Notes: one record-element for each clock domain
--
type reglist_t is record
   clk : reglist_clk_t;
   tx_clk : reglist_tx_clk_t;
   rx_clk : reglist_rx_clk_t;
   wclk : reglist_wclk_vector_t(1 to txport1_NPORTS);
end record;

--
-- all local nets (edit)
--
type netlist_t is record

   --
   -- component interface signals (edit)
   --
   -- [instance_name] : [component_name]_t;
   --
   txrx    : txrxint_t;
   rfile   : regfile1_t;
   wsync   : regsync1_vector_t(0 to 15);
   rsync   : regsync1_vector_t(0 to 15);

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
subtype inputs_t is mac_gmii_inputs_t;
subtype outputs_t is mac_gmii_outputs_t;

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
-- architecture rtl of mac_gmii
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

txrx : txrxint 
generic map
(
   instance => instance
)
port map
(
   inputs => allnets.txrx.inputs,
   outputs => allcmps.txrx.outputs
);

rfile : regfile1 port map
(
   inputs => allnets.rfile.inputs,
   outputs => allcmps.rfile.outputs
);

wsync : FOR index IN allnets.wsync'range GENERATE
wsync : regsync1 port map
(
   inputs => allnets.wsync(index).inputs,
   outputs => allcmps.wsync(index).outputs
);
END GENERATE;

rsync : FOR index IN allnets.rsync'range GENERATE
rsync : regsync1 port map
(
   inputs => allnets.rsync(index).inputs,
   outputs => allcmps.rsync(index).outputs
);
END GENERATE;

--**************************************************************
--
-- sequential logic
--
--
-- Notes: one record-type for each clock domain
--
--**************************************************************

--
-- clock domain: clk (edit)
--
process (inputs.clk, inputs.reset_clk)
begin
   if (inputs.reset_clk = '1') then
      allregs.dout.clk <= reglist_clk_default;
   elsif rising_edge(inputs.clk) then
      allregs.dout.clk <= allregs.din.clk;
   end if;
end process;

--
-- clock domain: tx_clk (edit)
--
process (inputs.tx_clk, inputs.reset_tx_clk)
begin
   if (inputs.reset_tx_clk = '1') then
      allregs.dout.tx_clk <= reglist_tx_clk_default;
   elsif rising_edge(inputs.tx_clk) then
      allregs.dout.tx_clk <= allregs.din.tx_clk;
   end if;
end process;

--
-- clock domain: rx_clk (edit)
--
process (inputs.rx_clk, inputs.reset_rx_clk)
begin
   if (inputs.reset_rx_clk = '1') then
      allregs.dout.rx_clk <= reglist_rx_clk_default;
   elsif rising_edge(inputs.rx_clk) then
      allregs.dout.rx_clk <= allregs.din.rx_clk;
   end if;
end process;

--
-- clock domain: wclk,wrst (edit)
--
process_wclk : FOR i IN 1 to txport1_NPORTS GENERATE

process (inputs.wclk(i), inputs.wrst(i))
begin
   if (inputs.wrst(i) = '1') then
      allregs.dout.wclk(i) <= reglist_wclk_default;
   elsif rising_edge(inputs.wclk(i)) then
      allregs.dout.wclk(i) <= allregs.din.wclk(i);
   end if;
 end process;

END GENERATE;

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
-- Main combinatorial procedure
--
-- all clock domains
--
procedure SubMain
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

   --
   -- Node params
   --
   n.txrx.inputs.nodeaddr      := i.nodeaddr(7 downto 0);
   n.txrx.inputs.multicastaddr := i.multicastaddr(7 downto 0);
   -- note: quasi-static params assumed synchronized to tx_clk = common tx/rx clock

   --
   -- Write interface
   --
   
   -- write interface: txport1_NPORTS clock domains
   n.txrx.inputs.wclk := i.wclk(1 to txport1_NPORTS);
   n.txrx.inputs.wrst := i.wrst(1 to txport1_NPORTS);

   -- write interface inputs (clock domain wclk(),wrst()) 
   n.txrx.inputs.wena       := i.wena(1 to txport1_NPORTS);
   n.txrx.inputs.wreq       := i.wreq(1 to txport1_NPORTS);
   n.txrx.inputs.wdata      := i.wdata(1 to txport1_NPORTS);
   n.txrx.inputs.wframelen  := i.wframelen(1 to txport1_NPORTS);
   n.txrx.inputs.wdestport  := i.wdestport(1 to txport1_NPORTS);
   n.txrx.inputs.wdestaddr  := i.wdestaddr(1 to txport1_NPORTS);
   n.txrx.inputs.wmulticast := i.wmulticast(1 to txport1_NPORTS);
   n.txrx.inputs.wtxreq     := i.wtxreq(1 to txport1_NPORTS);   
   n.txrx.inputs.wtxclr     := i.wtxclr(1 to txport1_NPORTS);        

   -- write interface outputs (clock domain wclk(),wrst()) 
   o.wready   := n.txrx.outputs.wready(1 to txport1_NPORTS);
   o.wempty   := n.txrx.outputs.wempty(1 to txport1_NPORTS); 
   o.wfull    := n.txrx.outputs.wfull(1 to txport1_NPORTS); 
   o.werror   := n.txrx.outputs.werror(1 to txport1_NPORTS);
   o.wdatalen := n.txrx.outputs.wdatalen(1 to txport1_NPORTS);
   o.wframes  := n.txrx.outputs.wframes(1 to txport1_NPORTS);

   --
   -- Read interface
   --

   -- read interface: RX_NPORTS clock domains
   n.txrx.inputs.rclk := i.rclk(1 to rxport1_NPORTS);
   n.txrx.inputs.rrst := i.rrst(1 to rxport1_NPORTS);

   -- read interface inputs (clock domain rclk(),rrst()) 
   n.txrx.inputs.rena := i.rena(1 to rxport1_NPORTS);
   n.txrx.inputs.rreq := i.rreq(1 to rxport1_NPORTS);
   n.txrx.inputs.rack := i.rack(1 to rxport1_NPORTS);

   -- read interface outputs (clock domain rclk(),rrst()) 
   o.renasts  := n.txrx.outputs.renasts(1 to rxport1_NPORTS);
   o.rdata    := n.txrx.outputs.rdata(1 to rxport1_NPORTS);
   o.rready   := n.txrx.outputs.rready(1 to rxport1_NPORTS);
   o.rempty   := n.txrx.outputs.rempty(1 to rxport1_NPORTS); 
   o.rfull    := n.txrx.outputs.rfull(1 to rxport1_NPORTS);
   o.rframes  := n.txrx.outputs.rframes(1 to rxport1_NPORTS);
   o.rsrcaddr := n.txrx.outputs.rsrcaddr(1 to rxport1_NPORTS);
   o.rsrcport := n.txrx.outputs.rsrcport(1 to rxport1_NPORTS);
   o.rdatalen := n.txrx.outputs.rdatalen(1 to rxport1_NPORTS);
   o.rdatacnt := n.txrx.outputs.rdatacnt(1 to rxport1_NPORTS);
   o.rseqnum  := n.txrx.outputs.rseqnum(1 to rxport1_NPORTS);
   o.reoframe := n.txrx.outputs.reoframe(1 to rxport1_NPORTS);
   --
   o.rerrfull  := n.txrx.outputs.rerrfull(1 to rxport1_NPORTS); 
   o.rerrempty := n.txrx.outputs.rerrempty(1 to rxport1_NPORTS); 

   --
   -- GMII tx interface
   --
   o.gtx_en := n.txrx.outputs.gtx_en;
   o.gtx_er := n.txrx.outputs.gtx_er;
   o.gtxd   := n.txrx.outputs.gtxd(7 downto 0);
   --
   n.txrx.inputs.clk2 := i.tx_clk;
   n.txrx.inputs.rst2 := i.reset_tx_clk;
   -- note: tx_clk is the main 'common tx/rx clock domain' --> gmii tx interface
   -- is clocked by tx_clk

   --
   -- GMII rx interface
   --
   n.txrx.inputs.grx_en := i.grx_en;
   n.txrx.inputs.grx_er := i.grx_er;
   n.txrx.inputs.grxd   := i.grxd(7 downto 0);
   --
   n.txrx.inputs.grxc    := i.rx_clk;
   n.txrx.inputs.grx_rst := i.reset_rx_clk;
   -- note: gmii rx interface is clocked by rx_clk  

end procedure;


--
-- RegFile interface
--
-- NOTE: this procedure defines default RegFile behavior (all regs r/w)
-- !!! SubRegfile MUST precede all others procedures working on RegFile !!!
--
-- 
-- all clock domains
--
procedure SubRegFile
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

   --
   -- Register file: avalon slave clock domain --> clk
   --
   n.rfile.inputs.clk1 := i.clk;
   n.rfile.inputs.rst1 := i.reset_clk;

   -- avalon slave interface
   n.rfile.inputs.mmaddress   := i.mmaddress;
   n.rfile.inputs.mmread      := i.mmread;
   n.rfile.inputs.mmwrite     := i.mmwrite;
   n.rfile.inputs.mmwritedata := i.mmwritedata;
   --
   o.mmreaddata      := n.rfile.outputs.mmreaddata(31 downto 0);
   o.mmreaddatavalid := n.rfile.outputs.mmreaddatavalid;
   o.mmwaitrequest   := n.rfile.outputs.mmwaitrequest;

   -- Default: ALL regs r/w ('read-only'/'write-only' regs will be generated by subsequent assignments)
   n.rfile.inputs.rinvect := n.rfile.outputs.routvect;
   -- NOTE: default r/w datapath will be modified when 'read-only'/'write-only' registers are defined
   
   --
   -- Register file synchronizer (from clk to tx_clk)
   --    
   FOR index in n.wsync'range LOOP
      -- write clock domain: clk
      n.wsync(index).inputs.wclk := i.clk;
      n.wsync(index).inputs.wrst := i.reset_clk;
      -- write data default: all regs connected to synchronizer
      n.wsync(index).inputs.dreg := n.rfile.outputs.routvect(index);
      n.wsync(index).inputs.wreq := n.rfile.outputs.routwrpulse(index);
      -- read clock domain: tx_clk 
      n.wsync(index).inputs.rclk := i.tx_clk; 
      n.wsync(index).inputs.rrst := i.reset_tx_clk; 
      -- read data output: not connected (regs removed by synthesis when not used)
   END LOOP;

   --
   -- Register file syncrhonizer (from tx_clk to clk)
   --    
   FOR index in n.rsync'range LOOP
      -- write clock domain: tx_clk 
      n.rsync(index).inputs.wclk := i.tx_clk;
      n.rsync(index).inputs.wrst := i.reset_tx_clk;
      -- write data default: continuous write, all zero
      n.rsync(index).inputs.dreg := x"00000000";
      n.rsync(index).inputs.wreq := '1';
      -- read clock domain: clk 
      n.rsync(index).inputs.rclk := i.clk; 
      n.rsync(index).inputs.rrst := i.reset_clk; 
      -- read data output: not connected (regs removed by synthesis when not used)
   END LOOP;
   -- note: all regs are pre-built with synchronizers to/from 'tx_clk' clock domain
   --       - regs driving 'clk' domain are used directly ('wsync','rsync' logic removed by synthesis when not used)       
   --       - regs(rw) driving 'tx_clk' domain will use 'wsync' outputs (default r/w datapath unchanged) 
   --       - regs(r) getting data from 'tx_clk' domain are connected to 'rsync' outputs when assigned 
   --         (default r/w datapth is overwritten by rsync outputs)     

   --
   -- RegMap
   -- 
   -- 
   -- reg0  ------ (0x840)
   -- 
   -- reg0.0   (rw): wdata (8/16 bit)
   -- ..           :
   -- reg0.15  (rw):
   --
   -- reg0.16  (r) : wdatalen (11bit)
   -- ..           :
   -- reg0.26      :
   --
   -- reg0.27  (r) : wframes (5bit)
   -- ..           :
   -- reg0.31      : 
   --
   --
   -- reg1  ------ (0x844)
   --
   -- reg1.0   (rw): wframelen (11bit)
   -- ..           :
   -- reg1.10      :
   --
   -- reg1.11  (rw): wmulticast
   -- 
   -- reg1.12  (rw): wreq 
   -- reg1.13  (rw): wtxreq 
   -- reg1.14  (rw): wtxclr
   -- reg1.15  (rw): wena
   --
   -- reg1.16  (rw): wdestaddr (8bit) 
   -- ..           :
   -- reg1.23      :
   --
   -- reg1.24  (rw): wdestport (4bit)
   -- ..           :
   -- reg1.27      :
   --
   -- reg1.28  (r) : werror
   -- reg1.29  (r) : wfull
   -- reg1.30  (r) : wempty
   -- reg1.31  (r) : wready
   --
   -- 
   -- reg2  ------ (0x848)
   --
   -- reg2     (rw): tport common write mask/data (16bit low)
   --
   -- reg2.16  (rw): tport enable       (write pulse)
   -- reg2.17  (rw): tport ackenable    (write pulse)
   -- reg2.18  (rw): tport timerenable  (write pulse)
   -- reg2.19  (rw): tport seqnumclr    (write pulse)
   -- reg2.20  (rw): tport srcfilterena (write pulse)
   -- reg2.21  (rw): tport srcfilter_wr (write pulse)
   -- reg2.22  (rw): ----
   -- reg2.23  (rw): ---- 
   --
   -- reg2.24  (rw): ----
   -- ..           : ----
   -- reg2.27  (rw): ----
   --
   -- reg2.28  (rw): tport tmuxA selector (4bit)
   -- ..           : 
   -- reg2.31  (rw): 
   --
   --
   -- reg3  ------ (0x84C)
   -- 
   -- reg3     (r) : tport enable    status (16bit low) 
   -- reg3     (r) : tport ackenable status (16bit high) 
   --
   --
   -- reg4  ------ (0x850)
   -- 
   -- reg4     (r) : tport timerenable status       (16bit low) 
   -- reg4     (r) : tport srcfilterena status      (16bit high, tmuxA = 0)
   -- reg4     (r) : tport srcfilteraddr/port/index (16bit high, tmuxA = 1..15)
   --
   --
   -- reg5  ------ (0x854)
   --
   -- reg5     (r) : tport seqnum read (32bit, tmuxA controlled)
   --
   -- 
   -- reg6  ------ (0x858)
   -- 
   -- reg6     (rw): rport common mask/data (16bit low)
   --
   -- reg6.16  (rw): rport enable       (write pulse)
   -- reg6.17  (rw): rport seqnumena    (write pulse)
   -- reg6.18  (rw): ---
   -- reg6.19  (rw): rport seqnumclr    (write pulse)
   -- reg6.20  (rw): rport srcfilterena (write pulse)
   -- reg6.21  (rw): rport srcfilter_wr (write pulse)
   -- reg6.22  (rw): ----
   -- reg6.23  (rw): ----
   --
   -- reg6.24  (rw): ----
   -- ..           : ----
   -- reg6.27  (rw): ----
   --
   -- reg6.28  (rw): rport rmuxA selector (4bit)
   -- ..           : 
   -- reg6.31  (rw): 
   --
   -- 
   -- reg7  ------ (0x85C)
   -- 
   -- reg7     (r) : rport enable    status (16bit low) 
   -- reg7     (r) : rport seqnumena status (16bit high) 
   --
   --
   -- reg8  ------ (0x860) 
   --
   -- reg8     (r) : rport seqnum read (32bit, rmuxA controlled) 
   --
   -- 
   -- reg9  ------ (0x864) 
   --
   -- reg9     (r) : tport renable status (16bit low)
   -- reg9     (r) : tport rerror  status (16bit high)
   -- 
   --
   -- reg10 ------ (0x868) 
   --
   -- reg10    (r) : rport wready status            (16bit low)
   -- reg10    (r) : rport srcfilterena status      (16bit high, rmuxA = 0)
   -- reg10    (r) : rport srcfilteraddr/port/index (16bit high, rmuxA = 1..15)
   --
   --  
   -- reg11 ------ (0x86C) 
   --
   -- reg11    (r) : rport werrempty status (16bit low)
   -- reg11    (r) : rport werrfull  status (16bit high)
   --
   --
   -- reg12 ------ (0x870) 
   --
   -- reg12.0  (rw): Framegen continuous-loop
   --
   -- reg12.1  (rw): Framegen trigger bit 1..15
   -- ..           : 
   -- reg12.15 (rw): 
   --
   -- reg12.16 (rw): Framegen destaddr (8bit, fmux = 0) 
   -- ..           : 
   -- reg12.23 (rw): 
   --
   -- reg12.24 (rw): Framegen destport (4bit, fmux = 0)
   -- ..           :
   -- reg12.27 (rw):  
   --
   -- reg12.16 (rw): Framegen framelen (11bit, fmux = 1) 
   -- ..           : 
   -- reg12.26 (rw): 
   --
   -- reg12.28 (rw): Framegen fmux selector (1bit)
   -- reg12.29 (rw): ----
   -- reg12.30 (rw): Framegen write_flag
   -- reg12.31 (rw): Framegen enable
   --
   --
   -- reg13 ------ (0x874) 
   --  
   -- reg13    (r) : rseqnum of current received frame (32bit) 
   --
   -- 
   -- reg14 ------ (0x878) 
   --
   -- reg14.0  (r) : rdata (8bit)
   -- ..           :
   -- reg14.7      :
   --
   -- reg14.8  (r) : rsrcaddr (8bit)
   -- ..           :
   -- reg14.15     :
   --
   -- reg14.16 (r) : rsrcport (4bit)
   -- ..           :
   -- reg14.19     :
   --
   -- reg14.20 (r) : rdatacnt (11bit) --> note: rdatacnt up counter 
   -- ..           :
   -- reg14.30     :
   --
   -- reg14.31 (r) : reoframe --> note: eoframe=1 and rdatacnt=0 when rdatalen=zero, eoframe=1 and rdatacnt>=rdatalen>0 when last data is ready, eoframe=0 and rdatacnt=0 when data not valid, eoframe=0 and rdatacnt<>0 when data is valid... 
   --
   --
   -- reg15 ------ (0x87C) 
   -- 
   -- reg15.0  (r) : rdatalen (11bit)
   -- ..           :
   -- reg15.10     :
   --
   -- reg15.11 (r) : ----
   -- reg15.12 (rw): rreq
   -- reg15.13 (rw): rack 
   -- reg15.14 (rw): ----
   -- reg15.15 (rw): rena
   -- 
   -- reg15.16 (r) : rframes (5bit)
   -- ..           :
   -- reg15.20     :
   --
   -- reg15.21 (r) : ----
   -- reg15.22 (r) : ----
   -- reg15.23 (r) : ----
   -- reg15.24 (r) : ----
   --
   -- reg15.25 (r) : renasts
   -- reg15.26 (r) : rerrfull
   -- reg15.27 (r) : rerrempty
   -- reg15.28 (r) : rfull
   -- reg15.29 (r) : rempty
   -- reg15.30 (r) : reoframe
   -- reg15.31 (r) : rready
   --

end procedure;


--
-- CPU interface
--
-- NOTE: procedure connects regfile to CPUtxport/CPUrxport (standard read/write interface
-- defined by SubMain is disconnected)  
-- !!! SubCPUinterface MUST be called after SubMain !!!
--
-- all clock domains
--
procedure SubCPUinterface
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
variable CPU_TXPORT : integer;
variable CPU_RXPORT : integer;
begin

   --
   -- CPU_TXPORT
   --

   CPU_TXPORT := UINT(i.CPUtxport);
   if CPU_TXPORT >= 1 and CPU_TXPORT <= txport1_NPORTS then

   -- CPU_TXPORT clock domain: clk
   n.txrx.inputs.wclk(CPU_TXPORT) := i.clk;  
   n.txrx.inputs.wrst(CPU_TXPORT) := i.reset_clk;
   -- note: all regs are used directly without synchronizers ('wsync','rsync' removed by synthesis when not used)

   --
   -- CPU_TXPORT: write interface
   --
   -- reg0.0   (rw): wdata (8/16 bit)
   -- ..           :
   -- reg0.15  (rw):
   --
   -- reg0.16  (r) : wdatalen (11bit)
   -- ..           :
   -- reg0.26      :
   --
   -- reg0.27  (r) : wframes (5bit)
   -- ..           :
   -- reg0.31      : 
   --
   n.txrx.inputs.wdata(CPU_TXPORT) := (others => '0'); 
   n.txrx.inputs.wdata(CPU_TXPORT)(7 downto 0) := n.rfile.outputs.routvect(0)(7 downto 0); 
   --
   n.rfile.inputs.rinvect(0)(26 downto 16) := n.txrx.outputs.wdatalen(CPU_TXPORT)(10 downto 0);  
   n.rfile.inputs.rinvect(0)(31 downto 27) := n.txrx.outputs.wframes (CPU_TXPORT)( 4 downto 0);
   --
   -- reg1.0   (rw): wframelen (11bit)
   -- ..           :
   -- reg1.10      :
   --
   -- reg1.11  (rw): wmulticast
   -- 
   -- reg1.12  (rw): wreq 
   -- reg1.13  (rw): wtxreq 
   -- reg1.14  (rw): wtxclr
   -- reg1.15  (rw): wena
   --
   -- reg1.16  (rw): wdestaddr (8bit) 
   -- ..           :
   -- reg1.23      :
   --
   -- reg1.24  (rw): wdestport (4bit)
   -- ..           :
   -- reg1.27      :
   --
   -- reg1.28  (r) : werror
   -- reg1.29  (r) : wfull
   -- reg1.30  (r) : wempty
   -- reg1.31  (r) : wready
   --
   n.txrx.inputs.wframelen (CPU_TXPORT) := n.rfile.outputs.routvect(1)(10 downto  0); 
   n.txrx.inputs.wmulticast(CPU_TXPORT) := n.rfile.outputs.routvect(1)(11); 
   -- CPU_TXPORT: write logic with posedge detectors
   r.clk.wreq_p   := n.rfile.outputs.routvect(1)(12);
   r.clk.wtxreq_p := n.rfile.outputs.routvect(1)(13);
   r.clk.wtxclr_p := n.rfile.outputs.routvect(1)(14);
   n.txrx.inputs.wreq  (CPU_TXPORT) := ri.clk.wreq_p   and not ro.clk.wreq_p; 
   n.txrx.inputs.wtxreq(CPU_TXPORT) := ri.clk.wtxreq_p and not ro.clk.wtxreq_p;
   n.txrx.inputs.wtxclr(CPU_TXPORT) := ri.clk.wtxclr_p and not ro.clk.wtxclr_p;
   --
   n.txrx.inputs.wena     (CPU_TXPORT) := n.rfile.outputs.routvect(1)(15); 
   n.txrx.inputs.wdestaddr(CPU_TXPORT) := n.rfile.outputs.routvect(1)(23 downto 16); 
   n.txrx.inputs.wdestport(CPU_TXPORT) := n.rfile.outputs.routvect(1)(27 downto 24); 
   --
   n.rfile.inputs.rinvect(1)(28) := n.txrx.outputs.werror(CPU_TXPORT); 
   n.rfile.inputs.rinvect(1)(29) := n.txrx.outputs.wfull (CPU_TXPORT); 
   n.rfile.inputs.rinvect(1)(30) := n.txrx.outputs.wempty(CPU_TXPORT); 
   n.rfile.inputs.rinvect(1)(31) := n.txrx.outputs.wready(CPU_TXPORT); 

   -- CPU_TXPORT disconnected
   o.wready(CPU_TXPORT) := '0';
   -- note: standard read/write interface forced to not-ready state --> regfile has full control over CPU_TXPORT  
   -- (external logic will see a CPU_TXPORT always OFF)

   end if;

   --
   -- CPU RX PORT
   --

   CPU_RXPORT := UINT(i.CPUrxport);
   if CPU_RXPORT >= 1 and CPU_RXPORT <= rxport1_NPORTS then

   -- CPU RX PORT clock domain: clk
   n.txrx.inputs.rclk(CPU_RXPORT) := i.clk;  
   n.txrx.inputs.rrst(CPU_RXPORT) := i.reset_clk;
   -- note: all regs are used directly without synchronizers ('wsync','rsync' removed by synthesis when not used)

   --
   -- CPU RX PORT: read interface
   --
   -- reg13    (r) : rseqnum of current received frame (32bit) 
   --
   --
   -- reg14.0  (r) : rdata (8bit)
   -- ..           :
   -- reg14.7      :
   --
   -- reg14.8  (r) : rsrcaddr (8bit)
   -- ..           :
   -- reg14.15     :
   --
   -- reg14.16 (r) : rsrcport (4bit)
   -- ..           :
   -- reg14.19     :
   --
   -- reg14.20 (r) : rdatacnt (11bit) --> note: rdatacnt up counter 
   -- ..           :
   -- reg14.30     :
   --
   -- reg14.31 (r) : reoframe --> note: eoframe=1 and rdatacnt=0 when rdatalen=zero, eoframe=1 and rdatacnt>=rdatalen>0 when last data is ready, eoframe=0 and rdatacnt=0 when data not valid, eoframe=0 and rdatacnt<>0 when data is valid... 
   --
   n.rfile.inputs.rinvect(13)(31 downto  0) := n.txrx.outputs.rseqnum (CPU_RXPORT)(31 downto  0);
   n.rfile.inputs.rinvect(14)( 7 downto  0) := n.txrx.outputs.rdata   (CPU_RXPORT)( 7 downto  0);
   n.rfile.inputs.rinvect(14)(15 downto  8) := n.txrx.outputs.rsrcaddr(CPU_RXPORT)( 7 downto  0);
   n.rfile.inputs.rinvect(14)(19 downto 16) := n.txrx.outputs.rsrcport(CPU_RXPORT)( 3 downto  0);
   n.rfile.inputs.rinvect(14)(30 downto 20) := n.txrx.outputs.rdatacnt(CPU_RXPORT)(10 downto  0);
   n.rfile.inputs.rinvect(14)(31)           := n.txrx.outputs.reoframe(CPU_RXPORT);
   -- 
   -- reg15.0  (r) : rdatalen (11bit)
   -- ..           :
   -- reg15.10     :
   --
   -- reg15.11 (r) : ----
   -- reg15.12 (rw): rreq
   -- reg15.13 (rw): rack 
   -- reg15.14 (rw): ----
   -- reg15.15 (rw): rena
   -- 
   n.rfile.inputs.rinvect(15)(10 downto  0) := n.txrx.outputs.rdatalen(CPU_RXPORT)(10 downto  0);
   n.rfile.inputs.rinvect(15)(11)           := '0';
   -- CPU RX PORT: read logic with posedge detector
   r.clk.rreq_p := n.rfile.outputs.routvect(15)(12);
   r.clk.rack_p := n.rfile.outputs.routvect(15)(13);
   n.txrx.inputs.rreq(CPU_RXPORT) := ri.clk.rreq_p and not ro.clk.rreq_p; 
   n.txrx.inputs.rack(CPU_RXPORT) := ri.clk.rack_p and not ro.clk.rack_p; 
   --
   n.txrx.inputs.rena(CPU_RXPORT) := n.rfile.outputs.routvect(15)(15);
   --
   -- reg15.16 (r) : rframes (5bit)
   -- ..           :
   -- reg15.20     :
   --
   -- reg15.21 (r) : ----
   -- reg15.22 (r) : ----
   -- reg15.23 (r) : ----
   -- reg15.24 (r) : ----
   --
   -- reg15.25 (r) : renasts  
   -- reg15.26 (r) : rerrfull
   -- reg15.27 (r) : rerrempty
   -- reg15.28 (r) : rfull
   -- reg15.29 (r) : rempty
   -- reg15.30 (r) : reoframe
   -- reg15.31 (r) : rready
   --
   n.rfile.inputs.rinvect(15)(20 downto 16) := n.txrx.outputs.rframes  (CPU_RXPORT)(4 downto 0);
   n.rfile.inputs.rinvect(15)(24 downto 21) := "0000";
   n.rfile.inputs.rinvect(15)(25)           := n.txrx.outputs.renasts  (CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(26)           := n.txrx.outputs.rerrfull (CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(27)           := n.txrx.outputs.rerrempty(CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(28)           := n.txrx.outputs.rfull    (CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(29)           := n.txrx.outputs.rempty   (CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(30)           := n.txrx.outputs.reoframe (CPU_RXPORT);
   n.rfile.inputs.rinvect(15)(31)           := n.txrx.outputs.rready   (CPU_RXPORT);

   -- CPU_RXPORT disconnected
   o.rready(CPU_RXPORT) := '0';
   -- note: standard read/write interface forced to not-ready state --> regfile has full control over CPU_RXPORT  
   -- (external logic will see a CPU_RXPORT always OFF)

   end if;

end procedure;


--
-- RegExt interface
--
-- all clock domains
--
procedure SubRegExt
(
   variable i : in inputs_t;
   variable ri: in reglist_t;
   variable ro: in reglist_t;
   variable o : inout outputs_t;
   variable r : inout reglist_t;
   variable n : inout netlist_t
) is
begin

   --
   -- EXT interface (clock domain: tx_clk)
   -- 
   -- note: regs(rw) are driven by 'wsync' outputs (default r/w datapath unchanged)
   --       regs(r)  are driven by 'rsync' outputs (default r/w datapath overwritten by 'rsync' outputs)
   --
   --
   -- reg2     (rw): tport common write mask/data (16bit low)
   --
   -- reg2.16  (rw): tport enable       (write pulse)
   -- reg2.17  (rw): tport ackenable    (write pulse)
   -- reg2.18  (rw): tport timerenable  (write pulse)
   -- reg2.19  (rw): tport seqnumclr    (write pulse)
   -- reg2.20  (rw): tport srcfilterena (write pulse)
   -- reg2.21  (rw): tport srcfilter_wr (write pulse)
   -- reg2.22  (rw): ----
   -- reg2.23  (rw): ---- 
   --
   -- reg2.24  (rw): ----
   -- ..           : ----
   -- reg2.27  (rw): ----
   --
   -- reg2.28  (rw): tport tmuxA selector (4bit)
   -- ..           : 
   -- reg2.31  (rw): 
   --
   -- 
   -- reg3     (r) : tport enable    status (16bit low) 
   -- reg3     (r) : tport ackenable status (16bit high) 
   -- 
   --
   -- reg4     (r) : tport timerenable status       (16bit low) 
   -- reg4     (r) : tport srcfilterena status      (16bit high, tmuxA = 0)
   -- reg4     (r) : tport srcfilteraddr/port/index (16bit high, tmuxA = 1..15)
   --
   --
   -- reg5     (r) : tport seqnum read (32bit, tmuxA controlled)
   --
   -- 
   -- reg6     (rw): rport common mask/data (16bit low)
   --
   -- reg6.16  (rw): rport enable       (write pulse)
   -- reg6.17  (rw): rport seqnumena    (write pulse)
   -- reg6.18  (rw): ---
   -- reg6.19  (rw): rport seqnumclr    (write pulse)
   -- reg6.20  (rw): rport srcfilterena (write pulse)
   -- reg6.21  (rw): rport srcfilter_wr (write pulse)
   -- reg6.22  (rw): ----
   -- reg6.23  (rw): ----
   --
   -- reg6.24  (rw): ----
   -- ..           : ----
   -- reg6.27  (rw): ----
   --
   -- reg6.28  (rw): rport rmuxA selector (4bit)
   -- ..           : 
   -- reg6.31  (rw): 
   --
   -- 
   -- reg7     (r) : rport enable    status (16bit low) 
   -- reg7     (r) : rport seqnumena status (16bit high) 
   --
   --
   -- reg8     (r) : rport seqnum read (32bit, rmuxA controlled) 
   --
   --
   -- reg9     (r) : tport renable status (16bit low)
   -- reg9     (r) : tport rerror  status (16bit high)
   --
   --
   -- reg10    (r) : rport wready status            (16bit low)
   -- reg10    (r) : rport srcfilterena status      (16bit high, rmuxA = 0)
   -- reg10    (r) : rport srcfilteraddr/port/index (16bit high, rmuxA = 1..15)
   --
   --
   -- reg11    (r) : rport werrempty status (16bit low)
   -- reg11    (r) : rport werrfull  status (16bit high)
   --

   --
   -- write path: from clk to tx_clk (tx_clk --> common tx/rx clock domain)
   --

   -- tport write bus controlled by reg2
   n.txrx.inputs.ext_tport_enable          := n.wsync(2).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_tport_ackenable       := n.wsync(2).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_tport_timerenable     := n.wsync(2).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_tport_seqnumclr       := n.wsync(2).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_tport_srcfilterena    := n.wsync(2).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_tport_srcfilteraddr   := n.wsync(2).outputs.qreg( 7 downto 0);
   n.txrx.inputs.ext_tport_srcfilterport   := n.wsync(2).outputs.qreg(11 downto 8);
   n.txrx.inputs.ext_tport_srcfilter       := n.wsync(2).outputs.qreg(15 downto 12);
   -- tport write request flags (note: write operations are triggered by posedge of ext_tport_NNNNNN_wr inputs) 
   n.txrx.inputs.ext_tport_enable_wr       := n.wsync(2).outputs.qreg(16);
   n.txrx.inputs.ext_tport_ackenable_wr    := n.wsync(2).outputs.qreg(17);
   n.txrx.inputs.ext_tport_timerenable_wr  := n.wsync(2).outputs.qreg(18);
   n.txrx.inputs.ext_tport_seqnumclr_wr    := n.wsync(2).outputs.qreg(19);
   n.txrx.inputs.ext_tport_srcfilterena_wr := n.wsync(2).outputs.qreg(20);
   n.txrx.inputs.ext_tport_srcfilter_wr    := n.wsync(2).outputs.qreg(21);

   -- rport write bus controlled by reg6
   n.txrx.inputs.ext_rport_enable          := n.wsync(6).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_rport_seqnumena       := n.wsync(6).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_rport_seqnumclr       := n.wsync(6).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_rport_srcfilterena    := n.wsync(6).outputs.qreg(15 downto 0);
   n.txrx.inputs.ext_rport_srcfilteraddr   := n.wsync(6).outputs.qreg( 7 downto 0);
   n.txrx.inputs.ext_rport_srcfilterport   := n.wsync(6).outputs.qreg(11 downto 8);
   n.txrx.inputs.ext_rport_srcfilter       := n.wsync(6).outputs.qreg(15 downto 12);
   -- rport write request flags (note: write operations are triggered by posedge of ext_rport_NNNNNN_wr inputs)
   n.txrx.inputs.ext_rport_enable_wr       := n.wsync(6).outputs.qreg(16);
   n.txrx.inputs.ext_rport_seqnumena_wr    := n.wsync(6).outputs.qreg(17);
   --                                      := n.wsync(6).outputs.qreg(18); -- not used 
   n.txrx.inputs.ext_rport_seqnumclr_wr    := n.wsync(6).outputs.qreg(19);
   n.txrx.inputs.ext_rport_srcfilterena_wr := n.wsync(6).outputs.qreg(20);
   n.txrx.inputs.ext_rport_srcfilter_wr    := n.wsync(6).outputs.qreg(21);
   -- note: rport controlled by reg6(16bit high) 

   --
   -- read path: from tx_clk to clk
   --
   n.rsync(3).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_tport_enable_sts;
   n.rsync(3).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_tport_ackenable_sts;
   --
   n.rsync(4).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_tport_timerenable_sts;
   n.rsync(4).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_tport_srcfilterena_sts;
   FOR index IN 1 TO txport1_NPORTS LOOP
      if index = UINT(n.wsync(2).outputs.qreg(31 downto 28)) then 
         n.rsync(4).inputs.dreg(23 downto 16) := n.txrx.outputs.ext_tport_srcfilteraddr_sts(index); 
         n.rsync(4).inputs.dreg(27 downto 24) := n.txrx.outputs.ext_tport_srcfilterport_sts(index);
         n.rsync(4).inputs.dreg(31 downto 28) := SLV(index, 4); 
      end if;
   END LOOP;
   -- note: tmuxA = zero | out-of-range --> reg4(31..16) = tport_srcfilterena_sts
   --       tmuxA = 1..NPORTS           --> reg4(31..16) = tport_srcfilter[addr/port/index]_sts
   --
   n.rsync(5).inputs.dreg(31 downto  0) := SLV(0, 32);
   FOR index IN 1 TO txport1_NPORTS LOOP
      if index = UINT(n.wsync(2).outputs.qreg(31 downto 28)) then 
         n.rsync(5).inputs.dreg(31 downto  0) := n.txrx.outputs.txseqnum(index);
      end if;
   END LOOP;
   -- note: tmuxA = zero | out-of-range --> reg5 = 0
   --       tmuxA = 1..NPORTS           --> reg5 = txseqnum(tmuxA)
   --
   n.rsync(7).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_rport_enable_sts;
   n.rsync(7).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_rport_seqnumena_sts;
   --
   n.rsync(8).inputs.dreg(31 downto  0) := SLV(0, 32);
   FOR index IN 1 TO rxport1_NPORTS LOOP
      if index = UINT(n.wsync(6).outputs.qreg(31 downto 28)) then 
         n.rsync(8).inputs.dreg(31 downto  0) := n.txrx.outputs.rxseqnum(index);
      end if;
   END LOOP;
   -- note: rmuxA = zero | out-of-range --> reg8 = 0
   --       rmuxA = 1..NPORTS           --> reg8 = rxseqnum(rmuxA)
   --
   n.rsync(9).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_tport_renable_sts;
   n.rsync(9).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_tport_rerror_sts;
   --
   n.rsync(10).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_rport_wready_sts;
   n.rsync(10).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_rport_srcfilterena_sts;
   FOR index IN 1 TO rxport1_NPORTS LOOP
      if index = UINT(n.wsync(6).outputs.qreg(31 downto 28)) then 
         n.rsync(10).inputs.dreg(23 downto 16) := n.txrx.outputs.ext_rport_srcfilteraddr_sts(index); 
         n.rsync(10).inputs.dreg(27 downto 24) := n.txrx.outputs.ext_rport_srcfilterport_sts(index);
         n.rsync(10).inputs.dreg(31 downto 28) := SLV(index, 4); 
      end if;
   END LOOP;
   -- note: rmuxA = zero | out-of-range --> reg10(31..16) = rport_srcfilterena_sts
   --       rmuxA = 1..NPORTS           --> reg10(31..16) = rport_srcfilter[addr/port/index]_sts
   --
   n.rsync(11).inputs.dreg(15 downto  0) := n.txrx.outputs.ext_rport_werrempty_sts;
   n.rsync(11).inputs.dreg(31 downto 16) := n.txrx.outputs.ext_rport_werrfull_sts;

   --
   -- read path: regfile input connections (read-only regs)
   --
   n.rfile.inputs.rinvect( 3)(31 downto  0) := n.rsync( 3).outputs.qreg(31 downto  0); 
   n.rfile.inputs.rinvect( 4)(31 downto  0) := n.rsync( 4).outputs.qreg(31 downto  0); 
   n.rfile.inputs.rinvect( 5)(31 downto  0) := n.rsync( 5).outputs.qreg(31 downto  0); 
   --
   n.rfile.inputs.rinvect( 7)(31 downto  0) := n.rsync( 7).outputs.qreg(31 downto  0);
   n.rfile.inputs.rinvect( 8)(31 downto  0) := n.rsync( 8).outputs.qreg(31 downto  0);
   n.rfile.inputs.rinvect( 9)(31 downto  0) := n.rsync( 9).outputs.qreg(31 downto  0);
   n.rfile.inputs.rinvect(10)(31 downto  0) := n.rsync(10).outputs.qreg(31 downto  0);
   n.rfile.inputs.rinvect(11)(31 downto  0) := n.rsync(11).outputs.qreg(31 downto  0);

   --
   -- Framegen control
   --
   --
   -- reg12.0  (rw): Framegen continuous-loop
   --
   -- reg12.1  (rw): Framegen trigger bit 1..15
   -- ..           : 
   -- reg12.15 (rw): 
   --
   -- reg12.16 (rw): Framegen destaddr (8bit, fmux = 0) 
   -- ..           : 
   -- reg12.23 (rw): 
   --
   -- reg12.24 (rw): Framegen destport (4bit, fmux = 0)
   -- ..           :
   -- reg12.27 (rw):  
   --
   -- reg12.16 (rw): Framegen destmode (3bit, fmux = 1) 
   -- ..           : 
   -- reg12.18 (rw): 
   --
   -- reg12.16 (rw): Framegen framelen (11bit, fmux = 2) 
   -- ..           : 
   -- reg12.26 (rw): 
   --
   -- reg12.28 (rw): Framegen fmux selector (2bit)
   -- reg12.29 (rw): 
   --
   -- reg12.30 (rw): Framegen write_flag
   -- reg12.31 (rw): Framegen enable
   --

   --
   -- write path: from clk to tx_clk (tx_clk --> common tx/rx clock domain)
   --

   -- framegen control flags
   n.txrx.inputs.ext_fgen_loop              := n.wsync(12).outputs.qreg(0);
   n.txrx.inputs.ext_fgen_trig(0)           := '0'; -- note: bit(0) reserved
   n.txrx.inputs.ext_fgen_trig(15 downto 1) := n.wsync(12).outputs.qreg(15 downto 1);  
   n.txrx.inputs.ext_fgen_ena               := n.wsync(12).outputs.qreg(31);
   -- framegen write request (note: write operations are triggered by posedge of ext_fgen_NNNNNN_wr inputs) 
   n.txrx.inputs.ext_fgen_wr := n.wsync(12).outputs.qupdate; 

   -- framegen params
   n.txrx.inputs.ext_fgen_destaddr := n.wsync(12).outputs.qreg(23 downto 16);
   n.txrx.inputs.ext_fgen_destport := n.wsync(12).outputs.qreg(27 downto 24);
   n.txrx.inputs.ext_fgen_framelen := n.wsync(12).outputs.qreg(26 downto 16);
   n.txrx.inputs.ext_fgen_destmode := n.wsync(12).outputs.qreg(18 downto 16);
   -- framegen params write request (note: write operations are triggered by posedge of ext_fgen_NNNNNN_wr inputs)
   n.txrx.inputs.ext_fgen_destaddr_wr := '0'; 
   n.txrx.inputs.ext_fgen_destmode_wr := '0'; 
   n.txrx.inputs.ext_fgen_framelen_wr := '0';
   if n.wsync(12).outputs.qreg(30) = '1' and n.wsync(12).outputs.qupdate = '1' then
      -- write enabled, write access: framegen params updated
      if UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 0 then
         n.txrx.inputs.ext_fgen_destaddr_wr := '1'; 
      elsif UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 1 then
         n.txrx.inputs.ext_fgen_destmode_wr := '1';
      elsif UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 2 then
         n.txrx.inputs.ext_fgen_framelen_wr := '1';
      else
         null;
      end if;
      -- note: fmux = 0 --> reg12(27..16) = fgen_dest[port/addr]
      --       fmux = 1 --> reg12(18..16) = fgen_destmode
      --       fmux = 2 --> reg12(26..16) = fgen_framelen
      --       fmux = 3 --> nop
   end if;

   --
   -- read path: from tx_clk to clk (status read)
   --
   n.rsync(12).inputs.dreg(0)               := n.txrx.outputs.ext_fgen_loop_sts;
   n.rsync(12).inputs.dreg(15 downto  1)    := n.txrx.outputs.ext_fgen_trig_sts(15 downto  1);
   if UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 0 then
      n.rsync(12).inputs.dreg(23 downto 16) := n.txrx.outputs.ext_fgen_destaddr_sts;
      n.rsync(12).inputs.dreg(27 downto 24) := n.txrx.outputs.ext_fgen_destport_sts;
   elsif UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 1 then
      n.rsync(12).inputs.dreg(18 downto 16) := n.txrx.outputs.ext_fgen_destmode_sts;
      n.rsync(12).inputs.dreg(27 downto 19) := "000000000";
   elsif UINT(n.wsync(12).outputs.qreg(29 downto 28)) = 2 then
      n.rsync(12).inputs.dreg(26 downto 16) := n.txrx.outputs.ext_fgen_framelen_sts;
      n.rsync(12).inputs.dreg(27)           := '0';
   else
      n.rsync(12).inputs.dreg(27 downto 16) := "000000000000";
   end if;
   -- n.rsync(12).inputs.dreg(28)           -- default r/w datapath unchanged
   -- n.rsync(12).inputs.dreg(29)           -- 
   -- n.rsync(12).inputs.dreg(30)           --
   n.rsync(12).inputs.dreg(31)              := n.txrx.outputs.ext_fgen_ena_sts;

   --
   -- read path: regfile input connections
   --
   n.rfile.inputs.rinvect(12)(27 downto 0) := n.rsync(12).outputs.qreg(27 downto  0);   
   --n.rfile.inputs.rinvect(12)(28)        -- default r/w datapath unchanged
   --n.rfile.inputs.rinvect(12)(29)        --
   --n.rfile.inputs.rinvect(12)(30)        --
   n.rfile.inputs.rinvect(12)(31)          := n.rsync(12).outputs.qreg(31);   
   -- note: reg12 is a special read/write register --> read path for all flags/params is driven by actual 
   -- framegen status (read access always reflects current framegen status) 

   --
   -- maclut control (note: reg2,reg3 are used for both tport/maclut control) 
   --
   --
   -- reg2  ------ (0x848)
   --
   -- reg2.0   (rw): maclut data (8bit)
   -- ..           :
   -- reg2.7   (rw): 
   --
   -- reg2.8   (rw): ----
   -- ..           : ----
   -- reg2.11  (rw): ----
   --
   -- reg2.12  (rw): maclut selector (4bit)
   -- ..           :
   -- reg2.15  (rw): 
   --
   -- reg2.16  (rw): ----
   -- ..           : ----
   -- reg2.23  (rw): ----
   --
   -- reg2.24  (rw): maclut_load (selected byte loaded)
   -- reg2.25  (rw): maclut_wr   (maclut write command)  
   -- reg2.26  (rw): maclut_rd   (maclut read command)
   -- reg2.27  (rw): ----
   --
   -- reg2.28  (rw): maclut address (4bit)
   -- ..           : 
   -- reg2.31  (rw):
   --
   --
   -- reg3  ------ (0x84C)
   -- 
   -- reg3     (r) : tport enable status    (16bit low,  maclut_rd = 0)
   -- reg3     (r) : tport ackenable status (16bit high, maclut_rd = 0)
   --
   -- reg3.0   (r) : maclut read status (8bit, maclut_rd = 1) 
   -- ..           :
   -- reg3.7   (r) :
   --
   -- reg3.8   (r) : ----
   -- ..           : ----
   -- reg3.11  (r) : ----
   --
   -- reg3.12  (r) : maclut read selector (4bit, maclut_rd = 1)
   -- ..       (r) : 
   -- reg3.15  (r) : 
   --  
   -- reg3.16  (r) : maclut status valid (1bit, maclut_rd = 1) 
   --
   -- reg3.17  (r) : ----
   -- ..           : ----
   -- reg3.27  (r) : ----
   --
   -- reg3.28  (r) : maclut read address (4bit, maclut_rd = 1)
   -- ..           :
   -- reg3.31  (r) :

   --
   -- write path: from clk to tx_clk (tx_clk --> common tx/rx clock domain)
   --

   -- maclut write/read bus controlled by reg2
   n.txrx.inputs.ext_maclut_data  := n.wsync(2).outputs.qreg(7 downto 0);
   n.txrx.inputs.ext_maclut_sel   := n.wsync(2).outputs.qreg(14 downto 12); -- note: 3bit selector
   n.txrx.inputs.ext_maclut_addr  := n.wsync(2).outputs.qreg(31 downto 28);
   -- maclut command request (note: command triggered by posedge of ext_maclut_wr/_rd/_load inputs) 
   n.txrx.inputs.ext_maclut_load  := n.wsync(2).outputs.qreg(24);
   n.txrx.inputs.ext_maclut_wr    := n.wsync(2).outputs.qreg(25);
   n.txrx.inputs.ext_maclut_rd    := n.wsync(2).outputs.qreg(26);

   --
   -- read path: from tx_clk to clk
   --

   -- maclut read status
   if n.wsync(2).outputs.qreg(26) = '1' then
      -- maclut read ON --> reg3 will return maclut status
      n.rsync(3).inputs.dreg := (others => '0'); -- maclut read default: all zero
      FOR index IN 0 to 5 LOOP
         if index = UINT(n.wsync(2).outputs.qreg(14 downto 12)) then
            -- selected byte to reg3
            n.rsync(3).inputs.dreg( 7 downto  0) := n.txrx.outputs.ext_maclut_data_sts(index);       
            n.rsync(3).inputs.dreg(15 downto 12) := SLV(index, 4);
         end if;
      END LOOP;
      n.rsync(3).inputs.dreg(16)           := n.txrx.outputs.ext_maclut_valid_sts;
      n.rsync(3).inputs.dreg(31 downto 28) := n.txrx.outputs.ext_maclut_addr_sts;
   end if;
   -- note: maclut_rd = 0 --> reg3 = tport_enable_sts, tport_ackenable_sts
   --       maclut_rd = 1 --> reg3 = maclut status (last macread data)
   --

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
   n.txrx.outputs := allcmps.txrx.outputs;
   n.rfile.outputs := allcmps.rfile.outputs;
   FOR index IN 0 to 15 LOOP 
      n.wsync(index).outputs := allcmps.wsync(index).outputs;
      n.rsync(index).outputs := allcmps.rsync(index).outputs;
   END LOOP;

   --
   -- all procedures call (edit)
   --
   -- all clock domains
   SubMain(i, ri, ro, o, r, n);
   SubRegFile(i, ri, ro, o, r, n);
   -- !!! SubRegfile MUST precede all others procedures working on RegFile !!!
   SubCPUinterface(i, ri, ro, o, r, n); 
   -- !!! SubCPUinterface MUST be called after SubMain !!!
   SubRegExt(i, ri, ro, o, r, n);
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
-- architecture rtl of mac_gmii
--
--**************************************************************

