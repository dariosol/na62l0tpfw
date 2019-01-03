library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.NUMERIC_BIT.all;
use work.globals.all;

--Receive primitives form ethlink module and generate triggers.
--Triggers are sent back to ethlink module.

--SUBRECEIVE PROCEDURE:
--Writes primitive in RAMs for first realignment.
--The address of RAMs is generated using the time of the primitive.
--Granularity of RAMs is programmable, it can be modified changing the number
--of finetime bits used in the address.
--If bit 15 of a primitive is equal to 1: calibration primitive: it is stored
--in a fifo and directly written in the output without any check with masks.
--Worst case: only timestamp: 25ns granularity.
--Best case: 3.125 ns.
--Primitives closer than granularity ns are overwritten. Only the last one
--survive.
--AlignRAM: stores the primitives aligned with timestamp+finetime.
--REFERENCEFIFO: stores time of reference detector.
--CONTROLFIFO: stores time of control detector.
--CALIBFIFO: stores primitives coming from calibration.

--SUBSYNCH PROCEDURE
-- Never used. Bad implemented. Trigger are generated with periodic time and
-- sent to the output without latency. A better idea should be initialize a ram with default
-- values. Never done because SOB, EOB are considered "synchronization"
-- triggers. Knowing the SOB shift of one detector respect to another it is
-- possible to realign them.
-- WARNING: When the board is switched off, at the next cycle the SOB offset
-- changes. I don't know why.

--SUBPRIMITIVEINPACKET PROCEDURE
--When a packet is received, the procedure stores in fifos the number of primitive
--contained in the packet. In this way it is possible read back packet by
--packet, mataining the MTP structure.
--FIFOMTNUMREF: stores number of MTP packets received from reference detector.
--FIFOMTNUMCONTROL: stores number of MTP packets received from control detector.

--SUBREADFIFO PROCEDURE
--It merges CONTROLFIFO and REFERENCE FIFO reading first the one with the
--smaller time. When they contain the same time, the referecenfe fifo is preferred.
--MERGEDFIFO: meges the time of reference and control

--SUBREADRAM PROCEDURE
--Sends primitive in the LUT, reading the reference from MERGED FIFO.
--Reads slot N, N-1, N+1
--compare DT between Reference detector and the others. if DT is satisfied,
--data is sent to the LUT which check the masks.

--SUBCALIBRATION PROCEDURE
--Reads the primitives stored in calibration fifo and generate triggers.

--SUBTRIGGER PROCEDURE
--Reads the output from the LUT. Generate trigger signals.
--A control on timestamp has been added to skip first N timestamps from SOB.
--This permits to skip the first spike that we have at the extraction from SPS.
--Control trigger and pyisics triggers checked in parallel.
--Loop on all masks to select triggerflag.
--Downscaling is applied.
--Triggerword set at 1 for all masks
package component_trigger is

   type trigger_inputs_t is record
      --------------------------------- CLOCK DOMAINS
      clkin_125                      : std_logic;
      clkin_40                       : std_logic;
      rst125                         : std_logic;
      rst40                          : std_logic;
  
      --------------------------------- BURST
      RUN                            : std_logic;
      BURST                          : std_logic;
      internal_timestamp125          : std_logic_vector(31 downto 0);
      internal_timestamp             : std_logic_vector(31 downto 0);
								     
      --------------------------------- RECEIVED FROM ETHLINK: PRIMITIVES
      received_signal                : std_logic_vector(0 to ethlink_NODES-2);
      primitiveID                    : vector16bit_t(0 to ethlink_NODES - 2);
      reserved                       : vector8bit_t(0 to ethlink_NODES - 2);
      finetime                       : vector8bit_t(0 to ethlink_NODES - 2);
      timestamp                      : vector32bit_t(0 to ethlink_NODES - 2);
      
      --------------------------------- OTHER PARAMETERS FOR PACKET HANDLING
      packet_received                : std_logic;     
      MTPNUMREF                      : vector8bit_t(0 to ethlink_NODES -2);
      DeltaPacket                    : std_logic_vector(31 downto 0); 

      --------------------------------- TRIGGER MASKS
      enable_mask                    : std_logic_vector(nmask-1 downto 0);
      mask                           : mem;
      dontcare                       : mem; 
      control_mask                   : std_logic_vector(111 downto 0);
      control_dontcare               : std_logic_vector(111 downto 0);

      --------------------------------- DOWNSCALING
      downscaling_set                : vector32bit_t(0 to nmask-1);
      downscaling_reset              : std_logic_vector(31 downto 0);
      control_downscaling_set        : std_logic_vector(31 downto 0);         

      --------------------------------- ACTIVATE TRIGGERS
      activatecontroltrigger         : std_logic;	
      activatesynchtrigger           : std_logic;
      activatecalibtrigger           : std_logic;

      --------------------------------- ALIGN RAM HANDLING
      bit_finetime                   : std_logic_vector(31 downto 0);
      calib_triggerword              : std_logic_vector(7 downto 0);
      reference_detector             : std_logic_vector(31 downto 0);
      control_detector               : std_logic_vector(31 downto 0);

      --------------------------------- CUTS
      timecut                        : vector16bit_t(0 to ethlink_NODES -2);   
      delaydeliveryprimitive         : std_logic_vector(31 downto 0);
   end record;

   type trigger_outputs_t is record        
     -------------------------------------- OUTPUT TO ETHLINK (for sending them to pc farm)
      timestamp_out           : std_logic_vector(31 downto 0);
      finetime_ref_out        : std_logic_vector(7 downto 0);
      finetime0_out           : vector8bit_t(0 to  ethlink_NODES-2);
      finetime1_out           : vector8bit_t(0 to  ethlink_NODES-2);
      finetime2_out           : vector8bit_t(0 to  ethlink_NODES-2);
      finetime_calib_out      : vector8bit_t(0 to ethlink_NODES - 2);
      timestamp_calib_out     : vector32bit_t(0 to ethlink_NODES - 2);
      triggerword             : std_logic_vector(5 downto 0);
      triggerword_calib       : std_logic_vector (5 downto 0);
      triggerflag             : std_logic_vector(15 downto 0);
      
      ----------------------------------- TRIGGER GENERATED SIGNAL, USED BY ETHLINK
      trigger_signal          : std_logic;
      control_signal          : std_logic;
      synch_signal            : std_logic;
      calib_signal            : std_logic_vector (6 downto 0);
  
      -------------------------------------- PRIMITIVE IDs (_t: trigger, _c: calibration)
      primitiveID0_t          : vector16bit_t(0 to ethlink_NODES -2);
      primitiveID1_t          : vector16bit_t(0 to ethlink_NODES -2);
      primitiveID2_t          : vector16bit_t(0 to ethlink_NODES -2);
      primitiveID_c           : vector16bit_t(0 to ethlink_NODES -2);
      
      --------------------------------------- Outputs for USB interface, counters
      ntriggers_predownscaling          : vector32bit_t(0 to nmask-1);  -- Before downscaling
      ntriggers_predownscaling_control  : std_logic_vector(31 downto 0);-- Before downscaling
      ntriggers_postdownscaling         : vector32bit_t(0 to nmask-1);  -- After downscaling
      ntriggers_postdownscaling_control : std_logic_vector(31 downto 0);-- After downscaling

      -------------------------------------- DEBUG:
      TRIGGERERROR               : std_logic_vector(31 downto 0);
      delaydeliveryoutput     : std_logic_vector(31 downto 0);
      
   end record;

   type trigger_t is record
      inputs  : trigger_inputs_t;
      outputs : trigger_outputs_t;
   end record;

   type trigger_vector_t is array(NATURAL RANGE <>) of trigger_t;

   component trigger
      port (
	 inputs  : in trigger_inputs_t;
	 outputs : out trigger_outputs_t
	 );
   end component;

   signal component_trigger : trigger_t;

end component_trigger;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.globals.all;
use work.component_trigger.all;
use work.component_fifo2trigger.all;
use work.component_fifo1trigger.all;
use work.component_ram2trigger.all;
use work.component_ram1trigger.all;
use work.component_TriggerLUT.all;
use work.component_calibfifo.all;
use work.component_fifoMTPnum.all;

entity trigger is
   port (
      inputs : in trigger_inputs_t;
      outputs : out trigger_outputs_t
      );
end trigger;

architecture rtl of trigger is


--types----------------------------
   type FSMTwoState_t is (S0,S1);
   type FSMThreeState_t is (S0,S1,S2);
   type FSMReadRam_t is (
      ReadFifo,
      SetRamAddress1,SetDetector1,ReadRam1,
      SetDetector1_2,ReadRam1_2,
      SetDetector1_3,ReadRam1_3
      );

   type FSMReadFifo_t is (Wait1Packet,ReadFifo,SelectData);
   
   type FSMPrimitiveInPacket_t is (WaitPacket,Shift1Clock,Shift2Clock);
   type FSMReceive_vector_t is array(NATURAL RANGE <>) of FSMThreeState_t;
   type addressAlign_vector_t is array(NATURAL RANGE <>) of std_logic_vector(13 downto 0);
   type FSMCalib_vector_t is array(NATURAL RANGE <>) of FSMTwoState_t;

 

   type reglist_clk125_t is record
      
      BURST125                     : std_logic;
      RUN                          : std_logic;
      internal_timestamp           : std_logic_vector(31 downto 0);
      
-- FSM list-----------------    ---------------------------------------------------------------
      FSMReceive 		   : FSMReceive_vector_t(0 to ethlink_NODES-2);
      FSMReadRam                   : FSMReadRam_t;
      FSMPrimitiveInPacket         : FSMPrimitiveInPacket_t;
      FSMCalib                     : FSMCalib_vector_t(0 to ethlink_NODES-2);
      FSMResetCounters             : FSMTwoState_t;
      FSMReadFifo                  : FSMReadFifo_t;
      --counter registers-------------------------------------------------------------------
      nprimitiveref                    : integer; --for latency before read REFERENCEFIFO
      nprimitivecontrol                 : integer; --for latency before read REFERENCEFIFO
      nprimitivereffinish               : std_logic;
      nprimitivecontrolfinish           : std_logic;	
      ntriggers_predownscaling         : vector32bit_t(0 to nmask-1); --one for each mask
      ntriggers_predownscaling_control : std_logic_vector(31 downto 0);
      number_of_write_counter           : vector32bit_t(0 to 6);

      ntriggers_postdownscaling         : vector32bit_t(0 to nmask-1);
      ntriggers_postdownscaling_control : std_logic_vector(31 downto 0);
      control_detector_counter           : std_logic_vector(31 downto 0);
      reset_counters                     : std_logic;
      detector_triggering                : std_logic_vector(6 downto 0);
      
      alignreadaddressb_clear      : std_logic_vector(13 downto 0);
      TRIGGERERROR                    : std_logic_vector(31 downto 0);
      --RECEIVED PRIMITIVE FROM ETHLINK
      received_signal              : std_logic_vector(0 to ethlink_NODES-2);
      timestamp                    : vector32bit_t(0 to ethlink_NODES-2);
      finetime                     : vector8bit_t(0 to  ethlink_NODES-2);
      reserved                     : vector8bit_t(0 to  ethlink_NODES-2);
      primitiveID                  : vector16bit_t(0 to ethlink_NODES-2);

      control_signal               : std_logic;
      control_detector             : std_logic_vector(31 downto 0);

      activatecalibtrigger         : std_logic;
      --Downscaling
      downscaling                  : vector32bit_t(0 to nmask-1);
      downscaling_set              : vector32bit_t(0 to nmask-1);
      downscaling_reset            : std_logic_vector(31 downto 0);
      control_downscaling          : std_logic_vector(31 downto 0);
      control_downscaling_set      : std_logic_vector(31 downto 0);
      
      bit_finetime                 : std_logic_vector(31 downto 0);
      calib_triggerword            :  std_logic_vector(7 downto 0);
      
      reference_detector           : std_logic_vector(31 downto 0);
      old_timestamp                : std_logic_vector(31 downto 0);	
      old_trigger_timestamp        : std_logic_vector(31 downto 0);	
      primitiveID0                 : vector16bit_t(0 to  ethlink_NODES-2);
      primitiveID1                 : vector16bit_t(0 to  ethlink_NODES-2);
      primitiveID2                 : vector16bit_t(0 to  ethlink_NODES-2);
      finetime0                    : vector8bit_t(0 to  ethlink_NODES-2);
      finetime1                    : vector8bit_t(0 to  ethlink_NODES-2);
      finetime2                    : vector8bit_t(0 to  ethlink_NODES-2);
      
      trigger_signal               : std_logic;
      timestamp_out                : std_logic_vector(31 downto 0);
      triggerword                  : std_logic_vector(5 downto 0);
      finetime_ref_out             : std_logic_vector(7 downto 0);
      finetime0_out                : vector8bit_t(0 to  ethlink_NODES-2);
      finetime1_out                : vector8bit_t(0 to  ethlink_NODES-2);
      finetime2_out                : vector8bit_t(0 to  ethlink_NODES-2);
      
      primitiveID0_t               : vector16bit_t(0 to  ethlink_NODES-2);
      primitiveID1_t               : vector16bit_t(0 to  ethlink_NODES-2);
      primitiveID2_t               : vector16bit_t(0 to  ethlink_NODES-2);

      primitiveID_c                : vector16bit_t(0 to  ethlink_NODES-2);
      
      calib_signal                 : std_logic_vector (6 downto 0);
      triggerword_calib            : std_logic_vector (5 downto 0);
      finetime_calib_out           : vector8bit_t(0 to ethlink_NODES - 2);
      timestamp_calib_out          : vector32bit_t(0 to ethlink_NODES - 2);     
      
      packet_received              : std_logic;
      first_packet                 : std_logic;
      MTPNUMREF                    : vector8bit_t(0 to ethlink_NODES - 2);
 
      triggerflag                  : std_logic_vector(15 downto 0);
      ------LATENCY--------------------------------------
      
      latencycounter               : integer;

      errorchecktimestamp          : std_logic;
      DeltaPacket                  : std_logic_vector(31 downto 0);
      timetocompare                : vector16bit_t(0 to ethlink_NODES - 2);
      timecut                      : vector16bit_t(0 to ethlink_NODES - 2); 
      readfiforeference            : std_logic;
      readfifocontrol              : std_logic;
      oldaddress                   : std_logic_vector(13 downto 0);
      tmpfinetime_ref_in           : std_logic_vector(7 downto 0);
      delaydeliveryprimitive       : std_logic_vector(31 downto 0);
      delaydeliveryoutput          : std_logic_vector(31 downto 0);
      oldaddress_out               : std_logic_vector(32 downto 0);
      
   end record;

   constant reglist_clk125_default : reglist_clk125_t :=
      (
	 BURST125                  => '0',
	 RUN                       => '0',
-- FSM list--------------------------------------------------------------------------------	

	 FSMReceive   		 =>(others =>S0),
	 FSMReadFifo	         => Wait1Packet,
	 FSMReadRam              => ReadFifo,
	 FSMPrimitiveInPacket    => WaitPacket,
	 FSMCalib                => (others =>S0),
	 FSMResetCounters        => S0,

	 
	 --counters:
	 detector_triggering     => (others=>'0'),
	 
	 nprimitiveref           =>  0,
	 nprimitivecontrol       =>  0,
	 nprimitivereffinish     => '0',
	 nprimitivecontrolfinish => '0',
	 ntriggers_predownscaling          => (others=>"00000000000000000000000000000000"),
	 ntriggers_predownscaling_control  => (others=>'0'),
	 ntriggers_postdownscaling         => (others=>"00000000000000000000000000000000"),
	 ntriggers_postdownscaling_control => (others => '0'),
	 
	 alignreadaddressb_clear=> (others =>'0'),
	 TRIGGERERROR 		=> (others =>'0'),
	 reset_counters		=> '0',
	 timestamp  		=> (others=>"00000000000000000000000000000000"),
	 finetime   		=> (others =>"00000000"),
	 reserved   		=> (others =>"00000000"),
	 
	 received_signal         => (others=>'0'),
	 primitiveID		         => (others =>"0000000000000000"),
	 downscaling             => (others=>"00000000000000000000000000000000"),
	 downscaling_set         => (others=>"00000000000000000000000000000000"),
	 downscaling_reset       => (others=>'0'),
	 number_of_write_counter => (others=>"00000000000000000000000000000000"),
	 internal_timestamp      => (others=>'0'),
	 bit_finetime 	  	 => (others=>'0'),
         calib_triggerword       => (others=>'0'),
	 reference_detector      => (others=>'0'),
	 control_detector        => (others=>'0'),
	 control_downscaling_set => (others=>'0'),
	 control_downscaling     => (others=>'0'),
	 control_detector_counter=> (others=>'0'),

	 activatecalibtrigger    => '0',
      
	 old_timestamp           => (others=>'0'),
	 old_trigger_timestamp   => (others=>'0'),
	 primitiveID0            => (others=>"0000000000000000"),
	 primitiveID1            => (others=>"0000000000000000"),
	 primitiveID2            => (others=>"0000000000000000"),
	 finetime0               => (others=>"00000000"),
	 finetime1               => (others=>"00000000"),
	 finetime2               => (others=>"00000000"),

	 control_signal           => '0',
	 trigger_signal           =>'0',
	 timestamp_out            => (others=>'0'),
	 triggerword              => (others=>'0'),
	 finetime_ref_out         => (others=>'0'),

	 finetime0_out            => (others=>"00000000"),
	 finetime1_out            => (others=>"00000000"),
	 finetime2_out            => (others=>"00000000"),

	 primitiveID0_t           => (others=>"0000000000000000"),	
	 primitiveID1_t           => (others=>"0000000000000000"),	
	 primitiveID2_t           => (others=>"0000000000000000"),	

	 primitiveID_c            => (others=>"0000000000000000"),

	 calib_signal             => (others=>'0'),
	 triggerword_calib        => (others=>'0'),
	 finetime_calib_out       => (others=>"00000000"),
	 timestamp_calib_out      => (others=>"00000000000000000000000000000000"),
	 
	 packet_received          => '0',
	 first_packet             => '1',
	 MTPNUMREF                => (others =>"00000000"),
	 latencycounter           => 0,
	 triggerflag              => (others =>'0'),
	 
	 errorchecktimestamp      => '0',
	 DeltaPacket              => (othERS=>'0'),
	 timetocompare            => (others=>"0000000000000000"),
	 timecut                  => (others=>"0000000000000000"),
	 readfiforeference        => '1',
	 readfifocontrol          => '1',
	 oldaddress               => (others=>'0'),
	 tmpfinetime_ref_in       => (others=>'0'),
	 delaydeliveryprimitive   => (others=>'0'),
	 delaydeliveryoutput      => (others=>'0'),
	 oldaddress_out           => (others=>'0')
	 );


   type reglist_clk40_t is record 
      FSMSubSynch            : FSMTwoState_t;
      activatesynchtrigger   : std_logic;
      synchcounter           : std_logic_vector(31 downto 0);
      BURST40                : std_logic;
      synch_signal           : std_logic;	
      internal_timestamp     : std_logic_vector(31 downto 0);
	 

   end record;

   constant reglist_clk40_default : reglist_clk40_t :=
      (
	 FSMSubSynch             => S0,
	 activatesynchtrigger    => '0',
	 synchcounter            =>x"0000ABCD",
	 BURST40                 =>'0',
	 synch_signal            =>'0',
	 internal_timestamp => (others=>'0')
	 );
   type reglist_t is record
      clk40  : reglist_clk40_t;
      clk125 : reglist_clk125_t;
   end record;

   type resetlist_t is record
      clk40 	: std_logic;
      clk50 	: std_logic;
      clk125 	: std_logic;
   end record;

   type netlist_t is record
      clk125        : std_logic; -- for procedures with MAC
      clk40         : std_logic; -- for synch trigger
      clk50         : std_logic; 
      rst           : resetlist_t;
      REFERENCEFIFO : fifo2trigger_t; --fifo for saving timestamp
      MERGEDFIFO    : fifo2trigger_t; --fifo for saving timestamp
      CONTROLFIFO   : fifo2trigger_t; --fifo for saving timestamp
      alignRAM      : ram2trigger_vector_t(0 to ethlink_NODES - 2); -- ram for the realignment of primitives.
      LUT           : TriggerLUT_t;
      FIFOCALIB     : calibfifo_vector_t(0 to ethlink_NODES - 2); --Calibration Fifo
      FIFOMTPNUMREF : fifoMTPnum_t;
      FIFOMTPNUMCONTROL : fifoMTPnum_t;	
   end record;

   subtype inputs_t is trigger_inputs_t;
   subtype outputs_t is trigger_outputs_t;


   type allregs_t is record
      din : reglist_t;
      dout : reglist_t;
   end record;

   signal allregs : allregs_t;
   signal allnets : netlist_t;
   signal allouts : outputs_t;
   signal allcmps : netlist_t;

begin

   LUT : TriggerLUT port map
      (
	 inputs => allnets.LUT.inputs,
	 outputs => allcmps.LUT.outputs
	 );
   
   REFERENCEFIFO: fifo2trigger port map
      (
	 inputs=>allnets.REFERENCEFIFO.inputs,
	 outputs=>allcmps.REFERENCEFIFO.outputs
	 );
   
   MERGEDFIFO: fifo2trigger port map
      (
	 inputs=>allnets.MERGEDFIFO.inputs,
	 outputs=>allcmps.MERGEDFIFO.outputs
	 );
   
   CONTROLFIFO: fifo2trigger port map
      (
	 inputs=>allnets.CONTROLFIFO.inputs,
	 outputs=>allcmps.CONTROLFIFO.outputs
	 );
   
   FIFOMTPNUMREF_init: fifOMTPnum port map
      (
	 inputs=>allnets.FIFOMTPNUMREF.inputs,
	 outputs=>allcmps.FIFOMTPNUMREF.outputs
	 );
   
   FIFOMTPNUMCONTROL_init: fifOMTPnum port map
      (
	 inputs=>allnets.FIFOMTPNUMCONTROL.inputs,
	 outputs=>allcmps.FIFOMTPNUMCONTROL.outputs
	 );
   
   
   alignRAM: FOR index IN 0 TO ethlink_NODES-2 GENERATE
      alignRAM: ram2trigger port map
	 (
	    inputs=>allnets.alignRAM(index).inputs,
	    outputs=>allcmps.alignRAM(index).outputs
	    );
   end generate;

   
   FIFOCALIB: FOR index IN 0 TO ethlink_NODES-2 GENERATE
      FIFOCALIB: calibfifo port map
	 (
	    inputs=>allnets.FIFOCALIB(index).inputs,
	    outputs=>allcmps.FIFOCALIB(index).outputs
	    );
   end generate;

------------------------------------------------------------------
   process (allnets.clk125, allnets.rst.clk125) --Update of registers 125 MHz
   begin
      if (allnets.rst.clk125 = '1') then
	 allregs.dout.clk125 <= reglist_clk125_default;
      elsif rising_edge(allnets.clk125) then
	 allregs.dout.clk125 <= allregs.din.clk125;
      end if;
   end process;

   process (allnets.clk40, allnets.rst.clk40)   --Update of registers 40 MHz
   begin
      if (allnets.rst.clk40 = '1') then
	 allregs.dout.clk40 <= reglist_clk40_default;
      elsif rising_edge(allnets.clk40) then--MOD
	 allregs.dout.clk40 <= allregs.din.clk40;
      end if;
   end process;


   process (inputs, allouts, allregs, allnets,allcmps)
--Sychronous reset
      
      procedure SubReset
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_t;
	    variable ro: in reglist_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 
	 n.rst.clk125 := i.rst125;
	 n.clk125     := i.clkin_125; --Internal Clock Domains.
	 
	 n.rst.clk40  := i.rst40;
	 n.clk40      := i.clkin_40; --external Clock Domains.
	 
      end procedure;


      procedure SubMain
--Set all registers in structs, it is called as first procedure each clock
--cycle. if the other procedures doesn't change the values of these registers,
--they are taken as default
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_t;
	    variable ro: in reglist_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_t;
	    variable n : inout netlist_t

	    ) is
      begin  
-----------------------------------------------------------------
--MAIN REGISTERED INPUTS           
	 r.clk40.BURST40                                  := i.BURST;
	 r.clk125.BURST125                                := i.BURST;
	 r.clk125.RUN                                     := i.RUN;
	 r.clk125.timecut                                 := i.timecut;             
	 r.clk40.activatesynchtrigger                     := i.activatesynchtrigger;
	 r.clk125.activatecalibtrigger                    := i.activatecalibtrigger;
	 r.clk125.downscaling_set                         := i.downscaling_set;
	 r.clk125.bit_finetime                            := i.bit_finetime;
         r.clk125.calib_triggerword                       := i.calib_triggerword;
	 r.clk125.reference_detector                      := i.reference_detector;
	 r.clk125.control_detector                        := i.control_detector;
	 r.clk125.control_downscaling_set                 := i.control_downscaling_set;
	 r.clk125.downscaling_reset            	          := i.downscaling_reset;
	 r.clk125.received_signal                         := i.received_signal;
	 r.clk40.internal_timestamp	                  := i.internal_timestamp;
	 r.clk125.internal_timestamp 	                  := i.internal_timestamp125;
	 r.clk125.packet_received                         := i.packet_received;
	 r.clk125.MTPNUMREF                               := i.MTPNUMREF; 
	 ---via eth
	 r.clk125.timestamp                               := i.timestamp;
	 r.clk125.finetime                                := i.finetime;	
	 r.clk125.reserved                                := i.reserved;
	 r.clk125.primitiveID                             := i.primitiveID;
	 r.clk125.DeltaPacket                             := i.DeltaPacket;
	 r.clk125.delaydeliveryprimitive                  := i.delaydeliveryprimitive;

	 --I should not reset downscaling during the run. the parameter should be 0.
	 --Nevertheless in 2016 data taking, the downscaling was reset
	 --every burst!
	  
	 if(ro.clk125.RUN='0') then
	    r.clk125.downscaling                  := (others=>"00000000000000000000000000000000");
	    r.clk125.control_downscaling          := (others=>'0');
	end if;	
	 ------------------------------------------------------------
	 --MAIN REGISTERED OUTPUTS
	 o.TRIGGERERROR                                      := ro.clk125.TRIGGERERROR;
	 
	 o.control_signal                                 := ro.clk125.control_signal; 
	 o.trigger_signal                                 := ro.clk125.trigger_signal;  
	 o.calib_signal                                   := ro.clk125.calib_signal;
	 o.synch_signal                                   := ro.clk40.synch_signal;

	 --Triggers without donwscaling cut
	 o.ntriggers_predownscaling                       := ro.clk125.ntriggers_predownscaling;
	 o.ntriggers_predownscaling_control               := ro.clk125.ntriggers_predownscaling_control;

	 --Triggers after dowscaling cut
	 o.ntriggers_postdownscaling                      := ro.clk125.ntriggers_postdownscaling; 
	 o.ntriggers_postdownscaling_control              := ro.clk125.ntriggers_postdownscaling_control; 
	 
	 o.timestamp_out                                  := ro.clk125.timestamp_out; 
	 o.timestamp_calib_out                            := ro.clk125.timestamp_calib_out;
	 
	 o.finetime0_out                                  := ro.clk125.finetime0_out;
	 o.finetime1_out                                  := ro.clk125.finetime1_out;
	 o.finetime2_out                                  := ro.clk125.finetime2_out;

	 o.finetime_ref_out                               := ro.clk125.finetime_ref_out;
	 o.finetime_calib_out                             := ro.clk125.finetime_calib_out;
	 
	 o.triggerword                                    := ro.clk125.triggerword(5 downto 0);
	 o.triggerword_calib                              := ro.clk125.triggerword_calib;
	 o.triggerflag                                    := ro.clk125.triggerflag;
	 
	 o.primitiveID0_t                                 := ro.clk125.primitiveID0_t;
	 o.primitiveID1_t                                 := ro.clk125.primitiveID1_t;
	 o.primitiveID2_t                                 := ro.clk125.primitiveID2_t;

	 o.primitiveID_c                                  := ro.clk125.primitiveID_c ;
	 o.delaydeliveryoutput                            := r.clk125.delaydeliveryoutput;	
	 --------------------------------------------------------
--MAIN LOOK UP TABLE	
	 
	 n.LUT.inputs.detector                           :=(others =>"0000000000000000");--N
	 n.LUT.inputs.primitiveID0                       :=(others =>"0000000000000000");--N
	 n.LUT.inputs.primitiveID1                       :=(others =>"0000000000000000");--N-1 
	 n.LUT.inputs.primitiveID2                       :=(others =>"0000000000000000");--N+1
	 n.LUT.inputs.timestamp_in                       := (others=>'0');
	 n.LUT.inputs.wena                               := '0';
	 n.LUT.inputs.clk                                := n.clk125;
	 n.LUT.inputs.reset                              := '0';
	 n.LUT.inputs.mask                               := i.mask;
	 n.LUT.inputs.control_detector_mask              := i.control_mask;
	 n.LUT.inputs.control_detector                   := "00";
	 n.LUT.inputs.finetime_ref_in                    := (others=>'0');
	 n.LUT.inputs.finetime_in0                       := (others=>"00000000");
	 n.LUT.inputs.finetime_in1                       := (others=>"00000000");
	 n.LUT.inputs.finetime_in2                       := (others=>"00000000");
	 n.LUT.inputs.enable_control_detector            := i.activatecontroltrigger;
	 n.LUT.inputs.enable_mask                        := i.enable_mask;
	 n.LUT.inputs.dontcare                           := i.dontcare;
	 n.LUT.inputs.control_detector_dontcare          := i.control_dontcare;
	 n.LUT.inputs.bit_finetime                       := i.bit_finetime(2 downto 0);
	 ------------------------------------------------------------
--MAIN FIFOS
	 n.REFERENCEFIFO.inputs.data                     := (others=>'0');
	 n.REFERENCEFIFO.inputs.aclr                     := '0';
	 n.REFERENCEFIFO.inputs.rdclk                    := n.clk125;
	 n.REFERENCEFIFO.inputs.wrclk                    := n.clk125;
	 n.REFERENCEFIFO.inputs.rdreq                    := '0';
	 n.REFERENCEFIFO.inputs.wrreq                    := '0';
	 
	 n.MERGEDFIFO.inputs.data                        := (others=>'0');
	 n.MERGEDFIFO.inputs.aclr                        := '0';
	 n.MERGEDFIFO.inputs.rdclk                       := n.clk125;
	 n.MERGEDFIFO.inputs.wrclk                       := n.clk125;
	 n.MERGEDFIFO.inputs.rdreq                       := '0';
	 n.MERGEDFIFO.inputs.wrreq                       := '0';
	 
	 n.CONTROLFIFO.inputs.data                       := (others=>'0');
	 n.CONTROLFIFO.inputs.aclr                       := '0';
	 n.CONTROLFIFO.inputs.rdclk                      := n.clk125;
	 n.CONTROLFIFO.inputs.wrclk                      := n.clk125;
	 n.CONTROLFIFO.inputs.rdreq                      := '0';
	 n.CONTROLFIFO.inputs.wrreq                      := '0';
	 
	 n.FIFOMTPNUMREF.inputs.data                     := (others=>'0');
	 n.FIFOMTPNUMREF.inputs.aclr                     := '0';
	 n.FIFOMTPNUMREF.inputs.rdclk                    := n.clk125;
	 n.FIFOMTPNUMREF.inputs.wrclk	                 := n.clk125;
	 n.FIFOMTPNUMREF.inputs.rdreq                    := '0';
	 n.FIFOMTPNUMREF.inputs.wrreq                    := '0';
	 

	 n.FIFOMTPNUMCONTROL.inputs.data                 := (others=>'0');
	 n.FIFOMTPNUMCONTROL.inputs.aclr                 := '0';
	 n.FIFOMTPNUMCONTROL.inputs.rdclk                := n.clk125;
	 n.FIFOMTPNUMCONTROL.inputs.wrclk	         := n.clk125;
	 n.FIFOMTPNUMCONTROL.inputs.rdreq                := '0';
	 n.FIFOMTPNUMCONTROL.inputs.wrreq                := '0';
	 
	 FOR index IN 0 to ethlink_NODES-2 LOOP  
	    n.alignRAM(index).inputs.clock_a                := n.clk125;
	    n.alignRAM(index).inputs.clock_b                := n.clk125;
	    n.alignRAM(index).inputs.address_a              := (others=>'0');--TSMP (8 LSBs)
	    n.alignRAM(index).inputs.address_b              := (others=>'0');
	    n.alignRAM(index).inputs.data_a                 := (others=>'0');
	    n.alignRAM(index).inputs.data_b                 := (others=>'0');
	    n.alignRAM(index).inputs.wren_a                 := '0';
	    n.alignRAM(index).inputs.wren_b                 := '0';
	    n.alignRAM(index).inputs.rden_a                 := '0';
	    n.alignRAM(index).inputs.rden_b                 := '0';		
	    
	    n.FIFOCALIB(index).inputs.data                  := (others=>'0');
	    n.FIFOCALIB(index).inputs.aclr                  := '0';
	    n.FIFOCALIB(index).inputs.rdclk                 := n.clk125;
	    n.FIFOCALIB(index).inputs.wrclk	            := n.clk125;
	    n.FIFOCALIB(index).inputs.rdreq                 := '0';
	    n.FIFOCALIB(index).inputs.wrreq                 := '0';
	 end loop;
	 
      end procedure;



      procedure SubReceive --forse andrebbe divisa, per ciascun rivelatore.
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin
	 n.REFERENCEFIFO.inputs.data      :=(others=>'0');
	 n.REFERENCEFIFO.inputs.aclr      :='0';
	 n.REFERENCEFIFO.inputs.wrclk     :=n.clk125;      
	 n.REFERENCEFIFO.inputs.wrreq     :='0';	
	 
	 n.CONTROLFIFO.inputs.data        :=(others=>'0');
	 n.CONTROLFIFO.inputs.aclr        :='0';
	 n.CONTROLFIFO.inputs.wrclk       :=n.clk125;      
	 n.CONTROLFIFO.inputs.wrreq       :='0';	
	 

	 FOR index IN 0 to ethlink_NODES-2 LOOP  
	    --Defaults alignRAM - write side.
	    n.alignRAM(index).inputs.clock_a   := n.clk125;
	    n.alignRAM(index).inputs.address_a := (others=>'0'); 
	    n.alignRAM(index).inputs.data_a    := (others=>'0');
	    n.alignRAM(index).inputs.wren_a    :='0';
	    n.FIFOCALIB(index).inputs.data     :=(others=>'0');
	    n.FIFOCALIB(index).inputs.aclr     :='0';
	    n.FIFOCALIB(index).inputs.wrclk	  :=n.clk125;
	    n.FIFOCALIB(index).inputs.wrreq    :='0';
	 end loop;

	 FOR index IN 0 to ethlink_NODES-2 LOOP  

---------REFERENCE DETECTOR-----------------
	    if ro.received_signal(to_integer(unsigned(ro.reference_detector))) ='1' then
	       if n.REFERENCEFIFO.outputs.wrfull ='0' then
		  n.REFERENCEFIFO.inputs.data(7 downto 0)   := ro.finetime(to_integer(unsigned(ro.reference_detector)));--FineTime TUTTI i bits MSB
		  n.REFERENCEFIFO.inputs.data(39 downto 8)  := ro.timestamp(to_integer(unsigned(ro.reference_detector)));   --TIMestamp 
		  n.REFERENCEFIFO.inputs.wrreq := '1';
	       else
		  r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(1,32);
	       end if;--full
	    end if; --reference signal
	    
---------CONTROL DETECTOR-----------------	
	    if ro.received_signal(to_integer(unsigned(ro.control_detector))) ='1' and i.activatecontroltrigger ='1' then
	       if n.CONTROLFIFO.outputs.wrfull ='0' then
		     n.CONTROLFIFO.inputs.data(7 downto 0)   := ro.fineTime(to_integer(unsigned(ro.control_detector)));  --FineTime TUTTI i bits MSB
		     n.CONTROLFIFO.inputs.data(39 downto 8)  := ro.timestamp(to_integer(unsigned(ro.control_detector))); --TIMestamp 
		     n.CONTROLFIFO.inputs.wrreq := '1';		  
	       else
		  r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(64,32);
	       end if;--full
	    end if; -- control signal


	    if ro.received_signal(index) ='1' then
	       if ro.primitiveID(index)(15) ='0' then --FISICA
		  --Data are realigned using 8 LSBs of TSTMP and 3 MSB of FT = 3.6 ns of precision. We have one ram for each input 
		  if UINT(ro.bit_finetime) = 3 then
		     n.alignRAM(index).inputs.address_a(13 downto 3):= ro.timestamp(index)(10 downto 0); --TSMP (11 LSBs)
		     n.alignRAM(index).inputs.address_a(2 downto 0) := ro.fineTime(index)(7 downto 5);   --FT (2 MSBs)	
		  elsif UINT(ro.bit_finetime) = 2 then
		     n.alignRAM(index).inputs.address_a(13 downto 2):= ro.timestamp(index)(11 downto 0); --TSMP (12 LSBs)
		     n.alignRAM(index).inputs.address_a(1 downto 0) := ro.fineTime(index)(7 downto 6);   --FT (2 MSBs)
		  elsif UINT(ro.bit_finetime) = 1 then
		     n.alignRAM(index).inputs.address_a(13 downto 1):= ro.timestamp(index)(12 downto 0); --TSMP (13 LSBs)
		     n.alignRAM(index).inputs.address_a(0) := ro.fineTime(index)(7);--FT (1 MSBs)	
		  else
		     n.alignRAM(index).inputs.address_a(13 downto 0):= ro.timestamp(index)(13 downto 0); --TSMP (14 LSBs)
		  end if; -- end finetime bits
		  
		  n.alignRAM(index).inputs.data_a (14 downto 0)  := ro.primitiveID(index)(14 downto 0); --PrimID
		  n.alignRAM(index).inputs.data_a (33 downto 15) := ro.timestamp(index)(29 downto 11); --TSTMP MSB
		  n.alignRAM(index).inputs.data_a (41 downto 34) := ro.fineTime(index); --finetime
		  
		  n.alignRAM(index).inputs.wren_a                :='1';
		  
		  
	       elsif ro.primitiveID(index)(15) ='1' then --CALIBRATION
		  if n.FIFOCALIB(index).outputs.wrfull ='0' then
		     n.FIFOCALIB(index).inputs.data(7 downto 0)   := ro.fineTime(index);--FineTime TUTTI i bits MSB
		     n.FIFOCALIB(index).inputs.data(39 downto 8)  := ro.timestamp(index);   --TIMestamp 
		     n.FIFOCALIB(index).inputs.data(55 downto 40) := ro.PrimitiveID(index);   --PrimitiveID of CalIBRATION 
		     n.FIFOCALIB(index).inputs.wrreq := '1';
		  else
		     r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(2,32);
		  end if;--full
	       end if; -- end primitive ID check
	    end if; -- end received signal 
	 end loop;
      end procedure;

      
      
      
      
      procedure SubSynch
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk40_t;
	    variable ro: in reglist_clk40_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk40_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 r.synch_signal :='0';
	 case ro.FSMSubSynch is
	    When S0=>
	       if ro.BURST40 = '1' then	 
		  if ro.activatesynchtrigger ='1' then
		     if ro.internal_timestamp < ro.synchcounter then
			r.synchcounter := SLV(UINT(ro.synchcounter)+1,32);
			r.FSMSubSynch := S0;
		     else
			r.synchcounter :=(others=>'0');
			r.FSMSubSynch := S1;
		     end if;
		  else
		     r.synchcounter :=x"0000ABCD";
		     r.FSMSubSynch := S0;
		  end if;
	       else
		  r.synchcounter :=x"0000ABCD";
		  r.FSMSubSynch  := S0;
	       end if;
	       
	    when S1 =>
	       r.synchcounter := SLV(UINT(ro.synchcounter)+x"10000",32);
	       r.synch_signal :='1';
	       r.FSMSubSynch := S0;
	 end case;
      end procedure;


      procedure SubPrimitiveInPacket
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 n.FIFOMTPNUMREF.inputs.data                  := (others=>'0');
	 n.FIFOMTPNUMREF.inputs.wrreq                 := '0';	 
	 n.FIFOMTPNUMREF.inputs.wrclk	              := n.clk125;
	 n.FIFOMTPNUMREF.inputs.aclr                  := '0';
	 
	 n.FIFOMTPNUMCONTROL.inputs.data              := (others=>'0');
	 n.FIFOMTPNUMCONTROL.inputs.wrreq             := '0';	 
	 n.FIFOMTPNUMCONTROL.inputs.wrclk	      := n.clk125;
	 n.FIFOMTPNUMCONTROL.inputs.aclr              := '0';

	 case ro.FSMPrimitiveInPacket is 

	    when WaitPacket=> 		
	       
	       if ro.packet_received ='1' then

		  n.FIFOMTPNUMREF.inputs.data := ro.MTPNUMREF(to_integer(unsigned(ro.reference_detector)));
		  n.FIFOMTPNUMCONTROL.inputs.data := ro.MTPNUMREF(to_integer(unsigned(ro.control_detector)));

		  
		  if n.FIFOMTPNUMREF.outputs.wrfull ='0' then	  
		     n.FIFOMTPNUMREF.inputs.wrreq := '1';
		  elsif n.FIFOMTPNUMREF.outputs.wrfull ='1' then
		     r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(4,32);
		  end if;
		  
		  if n.FIFOMTPNUMCONTROL.outputs.wrfull ='0' then	  
		     n.FIFOMTPNUMCONTROL.inputs.wrreq := '1';
		  elsif n.FIFOMTPNUMCONTROL.outputs.wrfull ='1' then
		     r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(32,32);
		  end if;
		  
		  r.FSMPrimitiveInPacket:= Shift1Clock;
	       else
		  r.FSMPrimitiveInPacket:= WaitPacket;	
	       end if;
	       
	    when Shift1Clock =>
	       r.FSMPrimitiveInPacket := Shift2Clock;
	       
	    when Shift2Clock =>
	       r.FSMPrimitiveInPacket := WaitPacket;
	       
	 end case;
      end procedure;

      procedure SubReadFifo  
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is

      begin		
	 --default REFERENCEFIFO read side
	 n.REFERENCEFIFO.inputs.aclr                  := '0';
	 n.REFERENCEFIFO.inputs.rdclk                 := n.clk125;    
	 n.REFERENCEFIFO.inputs.rdreq                 := '0';	
	 
	 n.CONTROLFIFO.inputs.aclr                    := '0';
	 n.CONTROLFIFO.inputs.rdclk                   := n.clk125;    
	 n.CONTROLFIFO.inputs.rdreq                   := '0';	
	 
	 
	 n.MERGEDFIFO.inputs.aclr                     := '0';
	 n.MERGEDFIFO.inputs.wrclk                    := n.clk125;    
	 n.MERGEDFIFO.inputs.wrreq                    := '0';	
	 
	 n.FIFOMTPNUMREF.inputs.aclr                  := '0';
	 n.FIFOMTPNUMREF.inputs.rdclk                 := n.clk125;
	 n.FIFOMTPNUMREF.inputs.rdreq                 := '0';
	 
	 n.FIFOMTPNUMCONTROL.inputs.aclr              := '0';
	 n.FIFOMTPNUMCONTROL.inputs.rdclk             := n.clk125;
	 n.FIFOMTPNUMCONTROL.inputs.rdreq             := '0';
	 
	 
	 case ro.FSMReadFifo is
	    
	    when Wait1Packet =>
	       --
	       -- Controllo di aver ricevuto un numero di pacchetti 
	       -- Pari a DeltaPacket.
	       -- Se e' cosi' leggo il primo pacchetto
	       -- ricevuto.
	       r.nprimitivereffinish     := '0';
	       r.nprimitivecontrolfinish := '0';
	       r.nprimitiveref           :=  0;
	       r.nprimitivecontrol       :=  0;
	       r.readfiforeference       := '1';
	       r.readfifocontrol         := '1';
	       
	       if UINT(n.FIFOMTPNUMREF.outputs.rdusedw) > UINT(ro.DeltaPacket) then -- reference detector
		  n.FIFOMTPNUMREF.inputs.rdreq     :='1'; --leggo le parole del pacchetto precedente
		  n.FIFOMTPNUMCONTROL.inputs.rdreq :='1'; --leggo le parole del pacchetto precedente
		  r.FSMReadFifo	:=ReadFifo;
	       else
		  r.FSMReadFifo	:=Wait1Packet;
	       end if;

--read reference fifo and control fifo-- 
	    when ReadFifo=>

	       if UINT(n.FIFOMTPNUMREF.outputs.q) = 0 then
		  r.nprimitivereffinish    := '1';	
	       end if;
	       
	       if UINT(n.FIFOMTPNUMCONTROL.outputs.q) = 0 then
		  r.nprimitivecontrolfinish    := '1';	
	       end if;
	       
	       
	       if (ro.nprimitiveref < UINT(n.FIFOMTPNUMREF.outputs.q)) and ro.readfiforeference='1' then 
		  r.nprimitiveref := ro.nprimitiveref +1; 
		  n.REFERENCEFIFO.inputs.rdreq :='1';
	       end if;
	       
	       if ro.nprimitivecontrol < UINT(n.FIFOMTPNUMCONTROL.outputs.q) and ro.readfifocontrol='1' then 
		  r.nprimitivecontrol := ro.nprimitivecontrol +1; 
		  n.CONTROLFIFO.inputs.rdreq :='1';
	       end if;
	       
	       if ro.nprimitivecontrolfinish ='1' and ro.nprimitivereffinish ='1' then
		  r.FSMReadFifo := Wait1Packet;

	       elsif  ro.nprimitivecontrolfinish ='0' and ro.nprimitivereffinish ='0' then 	 
		  r.FSMReadFifo	:=SelectData;

	       elsif  ro.nprimitivecontrolfinish ='0' and ro.nprimitivereffinish ='1' then
		  n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
		  n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
		  n.MERGEDFIFO.inputs.wrreq :='1';					
		  r.FSMReadFifo	:=SelectData;

	       elsif  ro.nprimitivecontrolfinish ='1' and ro.nprimitivereffinish ='0' then
		  n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
		  n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
		  n.MERGEDFIFO.inputs.wrreq :='1';					
		  r.FSMReadFifo	:=SelectData;
	       end if;
	        
	       ----------------1---------------------------------------------------
	       
	    when SelectData =>	
	       
	       if ro.nprimitiveref = UINT(n.FIFOMTPNUMREF.outputs.q) then
		  r.nprimitivereffinish  :='1';		 
	       end if;
	       
	       if ro.nprimitivecontrol = UINT(n.FIFOMTPNUMCONTROL.outputs.q) then
		  r.nprimitivecontrolfinish  :='1';		 
	       end if;

	       	if n.MERGEDFIFO.outputs.wrfull ='1' then
		   r.TRIGGERERROR := ro.TRIGGERERROR OR SLV(8,32);
		end if;
	       
	       
--loop to set the address (equal to the reference) of the ram--	 
	       
	       if ro.nprimitivereffinish ='0' and ro.nprimitivecontrolfinish ='0' then 
		  if(UINT(ro.bit_finetime)=3) then
		     if UINT(n.REFERENCEFIFO.outputs.q(37 downto 5)) < UINT(n.CONTROLFIFO.outputs.q(37 downto 5)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '0';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 5)) < UINT(n.REFERENCEFIFO.outputs.q(37 downto 5)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '0';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 5)) = UINT(n.REFERENCEFIFO.outputs.q(37 downto 5)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "11";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
		     end if;
		     
		  elsif (UINT(ro.bit_finetime)=2) then
		     if n.REFERENCEFIFO.outputs.q(37 downto 6) < n.CONTROLFIFO.outputs.q(37 downto 6) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '0';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 6)) < UINT(n.REFERENCEFIFO.outputs.q(37 downto 6)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '0';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 6)) = UINT(n.REFERENCEFIFO.outputs.q(37 downto 6)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "11";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
		     end if;
		     
		     
		  elsif (UINT(ro.bit_finetime)=1) then
		     if n.REFERENCEFIFO.outputs.q(37 downto 7) < n.CONTROLFIFO.outputs.q(37 downto 7) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '0';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 7)) < UINT(n.REFERENCEFIFO.outputs.q(37 downto 7)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '0';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 7)) = UINT(n.REFERENCEFIFO.outputs.q(37 downto 7)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "11";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
		     end if;
		     
		     
		  elsif (UINT(ro.bit_finetime)=0) then
		     if UINT(n.REFERENCEFIFO.outputs.q(37 downto 8)) < UINT(n.CONTROLFIFO.outputs.q(37 downto 8)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '0';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 8)) < UINT(n.REFERENCEFIFO.outputs.q(37 downto 8)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '0';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
			
		     elsif UINT(n.CONTROLFIFO.outputs.q(37 downto 8)) = UINT(n.REFERENCEFIFO.outputs.q(37 downto 8)) then
			n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
			n.MERGEDFIFO.inputs.data(39 downto 38) := "11";
			n.MERGEDFIFO.inputs.wrreq :='1';
			r.readfiforeference := '1';
			r.readfifocontrol := '1';
			r.FSMReadFifo := ReadFifo;
		     end if;
		  end if; --number of write
		  
	       elsif ro.nprimitivereffinish ='1' and ro.nprimitivecontrolfinish='0' then 
		  n.MERGEDFIFO.inputs.data(37 downto 0) := n.CONTROLFIFO.outputs.q(37 downto 0);
		  n.MERGEDFIFO.inputs.data(39 downto 38) := "10";
		  n.MERGEDFIFO.inputs.wrreq :='1';
		  r.readfiforeference := '0';
		  r.readfifocontrol := '1';
		  r.FSMReadFifo := ReadFifo;
		  
		  
	       elsif ro.nprimitivereffinish ='0' and ro.nprimitivecontrolfinish='1' then 
		  n.MERGEDFIFO.inputs.data(37 downto 0) := n.REFERENCEFIFO.outputs.q(37 downto 0);
		  n.MERGEDFIFO.inputs.data(39 downto 38) := "01";
		  n.MERGEDFIFO.inputs.wrreq :='1';
		  r.readfiforeference := '1';
		  r.readfifocontrol := '0';
		  r.FSMReadFifo := ReadFifo;
		  
	       elsif ro.nprimitivereffinish ='1' and ro.nprimitivecontrolfinish='1' then
		  r.FSMReadFifo := Wait1Packet;
	       end if;
	 end case;
      end procedure;	
      
      
      
      -- Read Ram

      procedure SubReadRam  
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is

      begin		
	 for index in 0 to ethlink_NODES -2 loop
	    --Defaults alignRAM - read side.
	    n.alignRAM(index).inputs.clock_b   := n.clk125;--mod
	    n.alignRAM(index).inputs.address_b := (others=>'0');
	    n.alignRAM(index).inputs.data_b    := (others=>'0');
	    n.alignRAM(index).inputs.wren_b    :='0';
	    n.alignRAM(index).inputs.rden_b    :='0';
	 end loop;

--Default LUT
	 
	 n.LUT.inputs.detector               :=(others=>"0000000000000000");
	 n.LUT.inputs.primitiveID0           :=(others=>"0000000000000000");
	 n.LUT.inputs.primitiveID1           :=(others=>"0000000000000000");
	 n.LUT.inputs.primitiveID2           :=(others=>"0000000000000000");

	 n.LUT.inputs.timestamp_in           := (others=>'0');
	 n.LUT.inputs.finetime_ref_in        := (others=>'0');
	 n.LUT.inputs.finetime_in0           := (others=>"00000000");
	 n.LUT.inputs.finetime_in1           := (others=>"00000000");
	 n.LUT.inputs.finetime_in2           := (others=>"00000000");
	 n.LUT.inputs.wena                   := '0';
	 n.LUT.inputs.clk                    := n.clk125;
	 n.LUT.inputs.reset                  := '0';
	 n.LUT.inputs.control_detector       := "00";
	 
	 --default REFERENCEFIFO read side
	 n.MERGEDFIFO.inputs.aclr            := '0';
	 n.MERGEDFIFO.inputs.rdclk           := n.clk125;    
	 n.MERGEDFIFO.inputs.rdreq           := '0';	
	 
	 
	 
	 case ro.FSMReadRam is
	    
	    when ReadFifo =>
	       if n.MERGEDFIFO.outputs.rdempty ='0' then
		  n.MERGEDFIFO.inputs.rdreq :='1';
		  r.FSMReadRam	:=SetRamAddress1;
	       else
		  r.FSMReadRam	:=ReadFifo;
	       end if;
	       
	       
	    when SetRamAddress1 =>
	       
--SAME CONVENTION AS IN ANALYSIS FRAMEWORK:          
--position 0: slot N: same slot of reference time.
--position 1: slot N-1
--position 2: slot N+1
	       
	       r.primitiveID0     := (others=>"0000000000000000");
	       r.primitiveID1     := (others=>"0000000000000000");
	       r.primitiveID2     := (others=>"0000000000000000");
	       r.finetime0        := (others=>"00000000");
	       r.finetime1        := (others=>"00000000");
	       r.finetime2        := (others=>"00000000");
	       r.timetocompare    := (others=>"0000000000000000");

	       
--loop to set the address (coming from MERGEDFIFO) of the ram.
--address depends on granularity.
--control on oldtimestamp avoiding to read 2 times the same address.
	       
	       for index in 0 to ethlink_NODES - 2 loop

                  if UINT(ro.bit_finetime)=3 then
		     if n.MERGEDFIFO.outputs.q(18 downto 5) /= ro.oldaddress then
			n.alignRAM(index).inputs.address_b := n.MERGEDFIFO.outputs.q(18 downto 5);
			r.oldaddress:=n.MERGEDFIFO.outputs.q(18 downto 5);
			r.FSMReadRam :=SetDetector1;
			n.alignRAM(index).inputs.rden_b :='1';
		     else
			r.FSMReadRam :=ReadFifo;
		     end if;


		  elsif UINT(ro.bit_finetime)=2 then
		     if n.MERGEDFIFO.outputs.q(19 downto 6) /= ro.oldaddress then
			n.alignRAM(index).inputs.address_b := n.MERGEDFIFO.outputs.q(19 downto 6);
			r.oldaddress:=n.MERGEDFIFO.outputs.q(19 downto 6);
			r.FSMReadRam :=SetDetector1;
			n.alignRAM(index).inputs.rden_b :='1';	
		     else
			r.FSMReadRam :=ReadFifo;
		     end if;

		     
		  elsif UINT(ro.bit_finetime)=1 then
		     if n.MERGEDFIFO.outputs.q(20 downto 7) /= ro.oldaddress then				
			n.alignRAM(index).inputs.address_b := n.MERGEDFIFO.outputs.q(20 downto 7);
			r.oldaddress:=n.MERGEDFIFO.outputs.q(20 downto 7);
			r.FSMReadRam :=SetDetector1;
			n.alignRAM(index).inputs.rden_b                 :='1';			
		     else
			r.FSMReadRam :=ReadFifo;
		     end if;
		     
		  else
		     if n.MERGEDFIFO.outputs.q(21 downto 8) /= ro.oldaddress then				
			n.alignRAM(index).inputs.address_b := n.MERGEDFIFO.outputs.q(21 downto 8);
			r.oldaddress:=n.MERGEDFIFO.outputs.q(21 downto 8);
			r.FSMReadRam :=SetDetector1;
			n.alignRAM(index).inputs.rden_b                 :='1';			
		     else
			r.FSMReadRam :=ReadFifo;
		     end if;
		  end if;
	       end loop;
	       

	    when SetDetector1 => --Position N
	       --set registers to compare DT between reference and other detectors
	       for index in 0 to Ethlink_NODES- 2 loop
               --MSB timestamp shoud be equal (Taurock's trick):
		  if n.alignRAM(index).outputs.q_b(33 downto 15) = n.MERGEDFIFO.outputs.q(37 downto 19) then

		     if UINT(ro.bit_finetime)=3 then
			r.timetocompare(index) := ro.oldaddress(10 downto 0) & n.alignRAM(index).outputs.q_b(38 downto 34); --FINETIME + LSB timestamp
		     elsif  UINT(ro.bit_finetime)=2 then
		        r.timetocompare(index) := ro.oldaddress(9 downto 0)  & n.alignRAM(index).outputs.q_b(39 downto 34); --FINETIME + LSB timestamp
		     elsif  UINT(ro.bit_finetime)=1 then
		        r.timetocompare(index) := ro.oldaddress(8 downto 0)  & n.alignRAM(index).outputs.q_b(40 downto 34); --FINETIME + LSB timestamp
		     else
			r.timetocompare(index) := ro.oldaddress(7 downto 0)  & n.alignRAM(index).outputs.q_b(41 downto 34); --FINETIME + LSB timestamp
		     end if;
		     
		     r.primitiveID0(index) := '0' &  n.alignRAM(index).outputs.q_b(14 downto 0); 
		     r.finetime0(index) := n.alignRAM(index).outputs.q_b(41 downto 34);
		     r.detector_triggering(index)        := '1';
		  else 
		     r.primitiveID0(index) := (others =>'0');
		     r.detector_triggering(index)        := '0';
		     r.finetime0(index) := (others =>'0');
		  end if;
	       end loop;
	       
	       r.FSMReadRam       :=ReadRam1;
	       
	       
	    when ReadRam1 =>
	       -- Set LUT inputs. LUT contains a shift register to share the outputs.
	       --LUT passes in outputs all the infos of the trigger: primIDs and time
	       --Only 30 bits of timestamp are used.
	       --Absolute value applied.
	       --n.MERGEDFIFO.outputs.q(39)==1: data comes from CONTROLFIFO
	       --n.MERGEDFIFO.outputs.q(38)==1: data comes form REFERENCEFIFO
	       --if control and reference are in the same timeslot,
	       --refecence time is the one used.
	       

	       n.LUT.inputs.wena         :='1';
	       n.LUT.inputs.timestamp_in(31 downto 30) :="00";
	       n.LUT.inputs.timestamp_in(29 downto 0) := n.MERGEDFIFO.outputs.q(37 downto 8);
	       
	       n.LUT.inputs.primitiveID0 := ro.primitiveID0;
	       n.LUT.inputs.primitiveID1 := ro.primitiveID1;
	       n.LUT.inputs.primitiveID2 := ro.primitiveID2;

	       n.LUT.inputs.finetime_in0 := ro.finetime0;
	       n.LUT.inputs.finetime_in1 := ro.finetime1;
	       n.LUT.inputs.finetime_in2 := ro.finetime2;

	       --If control detector is not in the same slot of reference:
	       --reference time: reference detector.
	       if n.MERGEDFIFO.outputs.q(39) = '0' and n.MERGEDFIFO.outputs.q(38) = '1' then 
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  n.LUT.inputs.finetime_ref_in  :=  n.alignRAM(to_integer(unsigned(ro.reference_detector))).outputs.q_b(41 downto 34);
		  r.tmpfinetime_ref_in := n.alignRAM(to_integer(unsigned(ro.reference_detector))).outputs.q_b(41 downto 34);
		  
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed( ro.timetocompare(to_integer(unsigned(ro.reference_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0'& n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;

		  --If reference detector is not in the same slot of control:
		  --reference time: control detector.

	       elsif n.MERGEDFIFO.outputs.q(39) = '1' and n.MERGEDFIFO.outputs.q(38) = '0' then
		  --reference where not in the same slot of control
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  n.LUT.inputs.finetime_ref_in  :=  n.alignRAM(to_integer(unsigned(ro.control_detector))).outputs.q_b(41 downto 34);
		  r.tmpfinetime_ref_in := n.alignRAM(to_integer(unsigned(ro.control_detector))).outputs.q_b(41 downto 34);

		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed(ro.timetocompare(to_integer(unsigned(ro.control_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;

		  --If reference detector is in the same slot of control:
		  --Reference time: reference detector.
		  --NOTA: this create a critical behavior in setting time
		  --in the RawHeader of the Analysis Framework: Sometime
		  --the control trigger, flagged as DataTye==0x10 has the
		  --reference time coming from reference detector also if
		  --the trigger is a control one. This because reference
		  --detector was in the same time slot (depends on
		  --granularity). of the ram.
		  
	       elsif n.MERGEDFIFO.outputs.q(39) = '1' and n.MERGEDFIFO.outputs.q(38) = '1' then
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  n.LUT.inputs.finetime_ref_in  :=  n.alignRAM(to_integer(unsigned(ro.reference_detector))).outputs.q_b(41 downto 34);
		  r.tmpfinetime_ref_in := n.alignRAM(to_integer(unsigned(ro.reference_detector))).outputs.q_b(41 downto 34);
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed(ro.timetocompare(to_integer(unsigned(ro.reference_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)  := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;
		  
		  
	       end if;
	       
	       r.detector_triggering         := (others=>'0');

 	       
	       for index in 0 to ethlink_NODES - 2 loop
		  --Between this if and the next elsif there are no
		  --difference, this structure is due to old version.
		  --Maybe can be changed.
		  if n.MERGEDFIFO.outputs.q(38)= '1' then
		     if UINT(ro.bit_finetime)=3 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(18 downto 5))- 1,14);
		     elsif UINT(ro.bit_finetime)=2 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(19 downto 6))- 1,14);
		     elsif UINT(ro.bit_finetime)=1 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(20 downto 7))- 1,14);
		     else
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(21 downto 8))- 1,14);
		     end if;
		     n.alignRAM(index).inputs.rden_b                 :='1';
		     
		     
		  elsif n.MERGEDFIFO.outputs.q(39 downto 38)="10" then
		     if UINT(ro.bit_finetime)=3 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(18 downto 5)) - 1,14);
		     elsif UINT(ro.bit_finetime)=2 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(19 downto 6)) - 1,14);
		     elsif UINT(ro.bit_finetime)=1 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(20 downto 7)) - 1,14);
		     else
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(21 downto 8)) - 1,14);
		     end if;
		     n.alignRAM(index).inputs.rden_b                 :='1';
		     
		  end if;
		  
	       end loop;
	       
	       r.FSMReadRam       :=SetDetector1_2;
	       
	       
	    when SetDetector1_2 =>
	       for index in 0 to Ethlink_NODES- 2 loop
		  if n.alignRAM(index).outputs.q_b(33 downto 15) = n.MERGEDFIFO.outputs.q(37 downto 19) then

		     if n.MERGEDFIFO.outputs.q(39 downto 38)="10" then
			   if index /= UINT(ro.control_detector) then

			      if UINT(ro.bit_finetime)=3 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(10 downto 0))-1,11) & n.alignRAM(index).outputs.q_b(38 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=2 then
 				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(9 downto 0))-1,10) & n.alignRAM(index).outputs.q_b(39 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=1 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(8 downto 0))-1,9) & n.alignRAM(index).outputs.q_b(40 downto 34); --FINETIME + LSB timestamp
			      else
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(7 downto 0))-1,8) & n.alignRAM(index).outputs.q_b(41 downto 34); --FINETIME + LSB timestamp
			      end if;
		    
			   else
			      r.timetocompare(index) := ro.timetocompare(index);
			   end if; --index
			else --merged fifo
			   if index /= UINT(ro.reference_detector) then
			      if UINT(ro.bit_finetime)=3 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(10 downto 0))-1,11) & n.alignRAM(index).outputs.q_b(38 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=2 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(9 downto 0))-1,10) & n.alignRAM(index).outputs.q_b(39 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=1 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(8 downto 0))-1,9) & n.alignRAM(index).outputs.q_b(40 downto 34); --FINETIME + LSB timestamp
			      else
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(7 downto 0))-1,8) & n.alignRAM(index).outputs.q_b(41 downto 34); --FINETIME + LSB timestamp
			      end if;
		    
			   else
			      r.timetocompare(index) := ro.timetocompare(index);
			   end if; --index
			end if;--merged fifo

		     r.detector_triggering(index)        := '1';
		     r.primitiveID1(index) := '0' & n.alignRAM(index).outputs.q_b(14 downto 0);
		     r.finetime1(index) := n.alignRAM(index).outputs.q_b(41 downto 34);
		  else --out of time
		     r.detector_triggering(index)        := '0';
		  end if;
	       end loop;
	       
	       r.FSMReadRam       :=ReadRam1_2;
	       
	       
	       
	    when ReadRam1_2 =>
	       
	       n.LUT.inputs.wena         :='1';
	       n.LUT.inputs.timestamp_in(31) :='0';
	       n.LUT.inputs.timestamp_in(29 downto 0) := n.MERGEDFIFO.outputs.q(37 downto 8);
	       
	       n.LUT.inputs.primitiveID0 := ro.primitiveID0;
	       n.LUT.inputs.primitiveID1 := ro.primitiveID1;
	       n.LUT.inputs.primitiveID2 := ro.primitiveID2;

	       n.LUT.inputs.finetime_in0 := ro.finetime0;
	       n.LUT.inputs.finetime_in1 := ro.finetime1;
	       n.LUT.inputs.finetime_in2 := ro.finetime2;
	       n.LUT.inputs.finetime_ref_in  :=  ro.tmpfinetime_ref_in;


	       if n.MERGEDFIFO.outputs.q(39) = '0' and n.MERGEDFIFO.outputs.q(38) = '1' then 
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed( ro.timetocompare(to_integer(unsigned(ro.reference_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;
		  
	       elsif n.MERGEDFIFO.outputs.q(39) = '1' and n.MERGEDFIFO.outputs.q(38) = '0' then
		  
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed(ro.timetocompare(to_integer(unsigned(ro.control_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;
		  
	       elsif n.MERGEDFIFO.outputs.q(39) = '1' and n.MERGEDFIFO.outputs.q(38) = '1' then
		  
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed(ro.timetocompare(to_integer(unsigned(ro.reference_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		  end loop;
		  
		  
	       end if;
	       
	       r.detector_triggering         := (others=>'0');

	       
	       for index in 0 to ethlink_NODES - 2 loop     
		  if n.MERGEDFIFO.outputs.q(38)= '1' then
		     if UINT(ro.bit_finetime)=3 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(18 downto 5))+ 1,14);
		     elsif UINT(ro.bit_finetime)=2 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(19 downto 6))+ 1,14);
		     elsif UINT(ro.bit_finetime)=1 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(20 downto 7))+ 1,14);
		     else
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(21 downto 8))+ 1,14);
		     end if;
		     n.alignRAM(index).inputs.rden_b                 :='1';
		     
		  elsif n.MERGEDFIFO.outputs.q(39 downto 38)="10" then
		     if UINT(ro.bit_finetime)=3 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(18 downto 5))+ 1,14);
		     elsif UINT(ro.bit_finetime)=2 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(19 downto 6))+ 1,14);
		     elsif UINT(ro.bit_finetime)=1 then
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(20 downto 7))+ 1,14);
		     else
			n.alignRAM(index).inputs.address_b := SLV(UINT(n.MERGEDFIFO.outputs.q(21 downto 8))+ 1,14);
		     end if;
		     n.alignRAM(index).inputs.rden_b                 :='1';
		  end if;
		  
	       end loop;
	       
-----------

	       r.FSMReadRam       := SetDetector1_3;



	    when SetDetector1_3 =>
	       for index in 0 to Ethlink_NODES- 2 loop
		  if n.alignRAM(index).outputs.q_b(33 downto 15) = n.MERGEDFIFO.outputs.q(37 downto 19) then
		     
			if n.MERGEDFIFO.outputs.q(39 downto 38)="10" then
			   if index /= UINT(ro.control_detector) then
			      if UINT(ro.bit_finetime)=3 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(10 downto 0))+1,11) & n.alignRAM(index).outputs.q_b(38 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=2 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(9 downto 0))+1,10) & n.alignRAM(index).outputs.q_b(39 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=1 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(8 downto 0))+1,9) & n.alignRAM(index).outputs.q_b(40 downto 34); --FINETIME + LSB timestamp
			      else
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(7 downto 0))+1,8) & n.alignRAM(index).outputs.q_b(41 downto 34); --FINETIME + LSB timestamp
			      end if;
		    
			   else
			      r.timetocompare(index) := ro.timetocompare(index);
			   end if; --index
			else --merged fifo
			   if index /= UINT(ro.reference_detector) then
			      if UINT(ro.bit_finetime)=3 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(10 downto 0))+1,11) & n.alignRAM(index).outputs.q_b(38 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=2 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(9 downto 0))+1,10) & n.alignRAM(index).outputs.q_b(39 downto 34); --FINETIME + LSB timestamp
			      elsif  UINT(ro.bit_finetime)=1 then
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(8 downto 0))+1,9) & n.alignRAM(index).outputs.q_b(40 downto 34); --FINETIME + LSB timestamp
			      else
				 r.timetocompare(index) := SLV(UINT(ro.oldaddress(7 downto 0))+1,8) & n.alignRAM(index).outputs.q_b(41 downto 34); --FINETIME + LSB timestamp
			      end if;
		    
			   else
			      r.timetocompare(index) := ro.timetocompare(index);
			   end if; --index
			end if;--merged fifo
		     
		     r.detector_triggering(index)        := '1';
		     r.primitiveID2(index) := '0' & n.alignRAM(index).outputs.q_b(14 downto 0);
		     r.finetime2(index) := n.alignRAM(index).outputs.q_b(41 downto 34);
		  else --out of time
		     r.detector_triggering(index)        := '0';
		  end if;
	       end loop;
	       
	       
	       r.FSMReadRam       :=ReadRam1_3;
	       

	       
	    when ReadRam1_3 =>

	       n.LUT.inputs.wena  :='1';
	       n.LUT.inputs.timestamp_in(31) :='0';
	       n.LUT.inputs.timestamp_in(29 downto 0) := n.MERGEDFIFO.outputs.q(37 downto 8);

	       n.LUT.inputs.primitiveID0 := ro.primitiveID0;
	       n.LUT.inputs.primitiveID1 := ro.primitiveID1;
	       n.LUT.inputs.primitiveID2 := ro.primitiveID2;

	       n.LUT.inputs.finetime_in0 := ro.finetime0;
	       n.LUT.inputs.finetime_in1 := ro.finetime1;
	       n.LUT.inputs.finetime_in2 := ro.finetime2;
	       n.LUT.inputs.finetime_ref_in  :=  ro.tmpfinetime_ref_in;

	       
	       if n.MERGEDFIFO.outputs.q(39 downto 38) = "01" or n.MERGEDFIFO.outputs.q(39 downto 38) = "11" then 
		  n.LUT.inputs.control_detector :=  n.MERGEDFIFO.outputs.q(39 downto 38);
		  
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed(ro.timetocompare(to_integer(unsigned(ro.reference_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		     
		     r.timetocompare(i):=(others=>'0');
		  end loop;
		  
	       else
		  
		  n.LUT.inputs.control_detector := n.MERGEDFIFO.outputs.q(39 downto 38);
		  
		  for i in ro.detector_triggering'range loop
		     if ro.detector_triggering(i) ='1' then
			if abs(signed(ro.timetocompare(i))-signed( ro.timetocompare(to_integer(unsigned(ro.control_detector))))) < SIGNED(ro.timecut(i)) then 
			   n.LUT.inputs.detector(i)      := '0' & n.alignRAM(i).outputs.q_b(14 downto 0); -- i.e. chod muv lav
			end if;
		     end if;
		     r.timetocompare(i):=(others=>'0');
		  end loop;
		  
	       end if;
	       
	       r.detector_triggering := (others=>'0');
	       r.primitiveID0        := (others=>"0000000000000000");
	       r.primitiveID1        := (others=>"0000000000000000");
	       r.primitiveID2        := (others=>"0000000000000000");
	       r.finetime0           := (others=>"00000000");
	       r.finetime1           := (others=>"00000000");
	       r.finetime2           := (others=>"00000000");
	       r.tmpfinetime_ref_in  :=(others=>'0');
	       
	       if n.MERGEDFIFO.outputs.rdempty ='0' then
		  n.MERGEDFIFO.inputs.rdreq :='1';
		  r.FSMReadRam	:=SetRamAddress1;
	       else
		  r.FSMReadRam	:=ReadFifo;
	       end if;
	       
	 end case;

      end procedure;

      
      
      
      -- calibration

      procedure SubCalibration
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 --Reads calibration fifo and generates output triggers. A bit dangerous
	 --because there is no control of trigger generation time. Unknown
	 --behavior if there is physics_signal and calib_signal equal to 1 at
	 --the same time
	 
	 r.primitiveID_c       :=(others=>"0000000000000000");
	 r.finetime_calib_out  :=(others=>"00000000");
	 r.timestamp_calib_out :=(others=>"00000000000000000000000000000000");
	 r.triggerword_calib   :=(others=>'0');
	 r.calib_signal        :=(others=>'0');

	 
	 FOR index IN 0 to ethlink_NODES-2 LOOP  
	    n.FIFOCALIB(index).inputs.aclr     :='0';
	    n.FIFOCALIB(index).inputs.rdclk	  :=n.clk125;
	    n.FIFOCALIB(index).inputs.rdreq    :='0';
	 end loop;

	 
	 FOR index IN 0 to ethlink_NODES-2 LOOP  
	    case ro.FSMCalib(index) is
	       when S0 =>	  
		  if ro.BURST125 ='1' then
		     if ro.activatecalibtrigger='1' then
			if n.FIFOCALIB(index).outputs.rdempty ='1' then
			   r.FSMCalib(index) :=S0;
			else
			   n.FIFOCALIB(index).inputs.rdreq := '1';	
			   r.FSMCalib(index) :=S1;
			end if;
		     else 
			r.FSMCalib(index) :=S0;
		     end if;--activate
		  else
		     r.FSMCalib(index) :=S0;
		  end if;--burst
	       when S1 =>
		  r.timestamp_calib_out(index)  := n.FIFOCALIB(index).outputs.q(39 downto 8);
		  r.finetime_calib_out(index)   := n.FIFOCALIB(index).outputs.q(7 downto 0);
		  r.calib_signal(index)         :='1';
		  r.triggerword_calib           :=ro.calib_triggerword(5 downto 0); --Provvisoria, uguale per tutti
		  r.FSMCalib(index)             :=S0;
		  r.primitiveID(index)          :=n.FIFOCALIB(index).outputs.q(55 downto 40);
		  
	    end case;
	 end looP;
      end procedure;
--
      procedure SubTrigger
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is

      begin
	 ----Default ---------------------- 
	 n.LUT.inputs.clk   := n.clk125;	
	 
	 r.timestamp_out    := (others=>'0'); 
	 r.triggerword      := (others=>'0');
	 r.triggerflag      := (others=>'0');
	 
	 r.primitiveID0_t    := (others=>"0000000000000000");
	 r.primitiveID1_t    := (others=>"0000000000000000");
	 r.primitiveID2_t    := (others=>"0000000000000000");

	 r.finetime0_out     := (others=>"00000000");
	 r.finetime1_out     := (others=>"00000000");
	 r.finetime2_out     := (others=>"00000000");

	 r.finetime_ref_out := (others=>'0');
	 
	 r.trigger_signal   := '0';
	 
	 if ro.BURST125 ='1' then

	    r.alignreadaddressb_clear:=(others=>'0');

	    -------------------------
	    --I am checking that the new trigger does not come from the two
	    --previous reference ram slots. This because, if they belong to the
	    --same timestamp, I am overwriting the conditions in the PC-Farm RAM.
	    -- if n.LUT.outputs.rdready ='1'  and ro.internal_timestamp > ro.delaydeliveryprimitive and ro.oldaddress_out /= SLV(UINT(n.LUT.outputs.address_ref) - 1,33) and ro.oldaddress_out /= SLV(UINT(n.LUT.outputs.address_ref) - 2,33) then

	     if n.LUT.outputs.rdready ='1'  and ro.internal_timestamp > ro.delaydeliveryprimitive and n.LUT.outputs.timestamp_out /= ro.old_trigger_timestamp then
	       
	       
	       for index in 0 to nmask-1 loop --LOOP ON MASKS
		  
		  --X1: comes from REFERENCEFIFO
		  --It's a trigger of physics. the index is used
		  --to set the correct trigger flag.
		  --Downscaling is applyied.
		  --No infos about triggerword: for all masks
		  --is set at 1.
		  --Check previous timestamp: it should avoid a second trigger
		  --in 25 ns. Physics triggers should be sorted by construction
		  --because coming from the same RAM for alignment, which is
		  --sorted. It means that I should always reject the second
		  --trigger coming from that RAM.

		  ---------WARNING CHECK IT!!!
		  if n.LUT.outputs.n_of_trigger(index) ='1' and n.LUT.outputs.control_detector_out(0) = '1' then --MASKS
		     
		     r.ntriggers_predownscaling(index)     :=SLV(UINT(ro.ntriggers_predownscaling(index))+1,32);--Before downscaling

		     if ro.downscaling(index) = ro.downscaling_set(index) then 
			r.trigger_signal            :='1';
			r.triggerflag(index)        :='1';
			r.triggerword               :="000001" or r.triggerword;
			r.ntriggers_postdownscaling(index)  :=SLV(UINT(ro.ntriggers_postdownscaling(index))+1,32);--after downscaling		
			r.downscaling(index)        :=(others=>'0');
			r.oldaddress_out            := n.LUT.outputs.address_ref;
			r.old_trigger_timestamp     := n.LUT.outputs.timestamp_out;
			
		     else--downscaling
			r.downscaling(index) := SLV(UINT(ro.downscaling(index))+1,32);
		     end if; --fine controllo downscaling
		  end if; -- fine controllo indice
	       end loop; --fine controllo loop

	       
	       if n.LUT.outputs.control_detector_out(1) = '1'  then --CONTROL
		  r.ntriggers_predownscaling_control := SLV(UINT(ro.ntriggers_predownscaling_control)+1,32); --before downscaling
		  
		  if ro.control_downscaling = ro.control_downscaling_set then 
		     r.control_signal            :='1';
		     r.triggerword               :="010000" or r.triggerword;     
		     r.ntriggers_postdownscaling_control   :=SLV(UINT(ro.ntriggers_postdownscaling_control)+1,32);--after downscaling			
		     r.control_downscaling       :=(others=>'0');	     
		     r.oldaddress_out            := n.LUT.outputs.address_ref;
		     r.old_trigger_timestamp     := n.LUT.outputs.timestamp_out;
		  else--downscaling
		     r.control_downscaling := SLV(UINT(ro.control_downscaling)+1,32);
		  end if; --fine controllo downscaling
	       end if;
	       
	       r.timestamp_out    := n.LUT.outputs.timestamp_out; 
	       r.finetime_ref_out := n.LUT.outputs.finetime_ref_out;
	       r.finetime0_out    := n.LUT.outputs.finetime_out0;	  
	       r.finetime1_out    := n.LUT.outputs.finetime_out1;	  
	       r.finetime2_out    := n.LUT.outputs.finetime_out2;	  
	       r.primitiveID0_t   := n.LUT.outputs.primitiveID_t_OUT0;
	       r.primitiveID1_t   := n.LUT.outputs.primitiveID_t_OUT1;
	       r.primitiveID2_t   := n.LUT.outputs.primitiveID_t_OUT2;

	       
	       
	       
	    elsif  ro.internal_timestamp < ro.delaydeliveryprimitive then
	       --Waiting to skip first spike
	       r.delaydeliveryoutput := SLV(UINT(ro.delaydeliveryoutput)+1,32);
	       r.timestamp_out    :=(others=>'0'); 
	       r.triggerword      :=(others=>'0');
	       
	       r.primitiveID0_t    :=(others=>"0000000000000000");
	       r.primitiveID1_t    :=(others=>"0000000000000000");
	       r.primitiveID2_t    :=(others=>"0000000000000000");
	       
	       r.finetime0_out     :=(others=>"00000000");
	       r.finetime1_out     :=(others=>"00000000");
	       r.finetime2_out     :=(others=>"00000000");

	       r.finetime_ref_out :=(others=>'0');
	       r.trigger_signal   :='0';		
	       r.control_signal   :='0';		
	       
	    else
	       r.timestamp_out     :=(others=>'0'); 
	       r.triggerword       :=(others=>'0');
	       
	       r.primitiveID0_t    :=(others=>"0000000000000000");
	       r.primitiveID1_t    :=(others=>"0000000000000000");
	       r.primitiveID2_t    :=(others=>"0000000000000000");
	       
	       r.finetime0_out     :=(others=>"00000000");
	       r.finetime1_out     :=(others=>"00000000");
	       r.finetime2_out     :=(others=>"00000000");

	       r.finetime_ref_out  :=(others=>'0');
	       r.trigger_signal    :='0';		
	       r.control_signal    :='0';		
	      
	    end if;
	    

	    
	 else --If I'm out of BURST... Reset RAMs:
	    n.REFERENCEFIFO.inputs.aclr		          :='1';
	    n.CONTROLFIFO.inputs.aclr		    	  :='1';
	    n.MERGEDFIFO.inputs.aclr			  :='1';
	    if ro.alignreadaddressb_clear < "11111111111111" then
	       r.alignreadaddressb_clear := SLV(UINT(ro.alignreadaddressb_clear)+1,14);
	       for index in 0 to ethlink_NODES - 2 loop
		  n.alignRAM(index).inputs.address_b := ro.alignreadaddressb_clear;
		  n.alignRAM(index).inputs.data_b    := (others=>'0');
		  n.alignRAM(index).inputs.wren_b    :='1'; --Clean RAM
	       end loop;
	       
	    end if;
	 end if;
      end procedure; 


      procedure ResetCounters
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_Clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_Clk125_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 
	 case ro.FSMResetCounters is
	    
	    when S0=>
	       if ro.BURST125 ='1' then
		  r.control_detector_counter         := (others=>'0');
		  r.nprimitivecontrol                := 0;
		  r.ntriggers_predownscaling         := (others=>"00000000000000000000000000000000");
		  r.ntriggers_predownscaling_control := (others=>'0');
		  r.ntriggers_postdownscaling        := (others=>"00000000000000000000000000000000");
		  r.ntriggers_postdownscaling_control:= (others=>'0');
                  
		  r.TRIGGERERROR                 := (others=>'0');
		  
		  r.finetime0                    := (others=>"00000000");
		  r.finetime1                    := (others=>"00000000");
		  r.finetime2                    := (others=>"00000000");
		  r.primitiveID0                 := (others=>"0000000000000000");
		  r.primitiveID1                 := (others=>"0000000000000000");
		  r.primitiveID2                 := (others=>"0000000000000000");
		  r.oldaddress_out               := (others=>'0');
		  r.readfiforeference            := '1';
		  r.readfifocontrol              := '1';
		  r.first_packet                 := '1';
		  n.REFERENCEFIFO.inputs.aclr    := '1';
		  n.MERGEDFIFO.inputs.aclr       := '1';
		  n.CONTROLFIFO.inputs.aclr      := '1';
		  
		  r.FSMResetCounters             := S1;
		  r.old_timestamp                := (others=>'0');
		  n.FIFOMTPNUMREF.inputs.aclr    := '1';
		  n.FIFOMTPNUMCONTROL.inputs.aclr:= '1';
		  n.LUT.inputs.reset             := '1';
		  r.nprimitiveref                := 0;
		  r.latencycounter               := 0;
		  r.oldaddress                   := (others=>'0');
		  r.delaydeliveryoutput          := (others=>'0');
		  r.old_trigger_timestamp        := (others=>'0');
	       else
		  r.FSMResetCounters :=S0;
	       end if;

	    when s1=>
	       
	       if ro.BURST125 ='0' then
		  r.FSMResetCounters :=S0;
	       else
		  r.FSMResetCounters :=S1;
	       end if;
	 end case;
      end procedure;

      
      
      
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

      for index in 0 to ethlink_NODES-2 loop
	 n.FIFOCALIB(index).outputs := allcmps.FIFOCALIB(index).outputs;
	 n.alignRAM(index).outputs := allcmps.alignRAM(index).outputs;
      end loop;

      n.LUT.outputs               := allcmps.LUT.outputs;
      n.REFERENCEFIFO.outputs     := allcmps.REFERENCEFIFO.outputs ; 
      n.MERGEDFIFO.outputs        := allcmps.MERGEDFIFO.outputs ; 
      n.CONTROLFIFO.outputs       := allcmps.CONTROLFIFO.outputs ; 
      n.FIFOMTPNUMREF.outputs     := allcmps.FIFOMTPNUMREF.outputs ; 
      n.FIFOMTPNUMCONTROL.outputs := allcmps.FIFOMTPNUMCONTROL.outputs ; 

      
      --SubMain(i, ri, ro, o, r, n, ro.clk125,ro.clk250);
      SubMain(i, ri, ro, o, r, n);
      SubReset(i, ri, ro, o, r, n);
      
      -- clock domain: clk50
      SubReceive(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReadFifo(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReadRam(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubPrimitiveInPacket(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubSynch(i, ri.clk40, ro.clk40, o, r.clk40, n);
      SubCalibration(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubTrigger(i, ri.clk125, ro.clk125, o, r.clk125, n);
      RESetCounters(i, ri.clk125, ro.clk125, o, r.clk125, n);

      -- allouts/regs/nets updates
      allouts     <= o;
      allregs.din <= r;
      allnets     <= n;

   end process;

--**************************************************************
--**************************************************************
   outputs <= allouts;

end rtl;
