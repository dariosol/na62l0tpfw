library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;
------------------------------
--This module receive primitives from the ethernet. It is developed by
--Stefano Chiozzi's project used for GTK. The MAC interface is considered
--a black box. It's just extract 1 byte every 8 ns (Clock used: 125 MHz).
--To extract 1 complete primitive: 8ns x 8 bytes: 64 ns: 15.26 MHz.

--SGMII protocol: implemented on 4 default etherent port of DE4.
--RGMII protocol: implemented on 4 ehternet added with mezzanines.

--Everything about CPU is not used. L0TP doesn't have any internal CPU. 

--SUBRECEIVE (SUBRECEIVERGMII) PROCEDURE:
--It receives primitives from detectors.

--SGMII ports used:
--0: CHOD
--1: RICH
--2: LAV12
--3: USED TO SEND DATA TO PC-FARM

--RGMII ports used:
--0: MUV3
--1: IRC (NewCHOD)
--2: TALK (never used)
--3: LKr

--Detector Vectors goes from 0 to 6: (CHOD,RICH,LAV12,MUV3,IRC,TALK,LKr),
--ignoring port 3 used to send data to PC farm

--every byte extracted the end of frame is controlled avoiding uncomplete packets.
--Extracted primitives are written in FIFODELAY buffers. It is possible because
--primitives are sent in packets every 6.4 us. 
--FIFODELAY: fifos used to wait detectors with a big delay respect to the
--reference one. They store primitives up to the arrive of the first non-empty
--packet from max delay detector. The first packets of detector in delay are
--empty (except for the header) and they are skipped. Skipping a packet means to skip 6.4 us.

--The MSB of FIFODELAY data inidicates the header. A string of 0xFFFFFFFFF (end-of-packet word) is
--written at the end of packet. In this way the packet structure is manteined.

-- SubReadFIFODelay PROCEDURE:
--Reads fifos. It skips packets (at least the header) in a number equal to the
--one set by user (register fifODELAY_set). To skip the packet the procedure
--controls the header and the end-of-packet word.
--if all packets have been skipped, the extraction of non-empty data can start.
--Packets are read after a latency of 1.6 us.
--When the packet equal to fifODELAY_set of the maximum delay detector arrives,
--The first packet is read from the buffers. In this way packet are realigned.
--All the infos of the primitives are sent to the Trigger Module.

-- SUBSENDBUFFER PROCEDURE:
-- it receives trigger signals from Trigger Module (except for CHOKE/ERROR,
-- SOB/EOB) and stores all the output infos in a big buffer (SendRAM). Send Ram
-- is written address by address starting from 0.
-- At the same time, also LATENCYRAM is written, which is the ram for generate
-- the latency. LATENCYTAM is addressed by the time of the trigger (25 ns
-- granularity). It contains also the address of SendRAM data, in order to
-- reach them during the reading process.

--SubGeneratePackets PROCEDURE:
--It0s a FIFO that generate packet for ethernet adding also the header of the
--event. All the infos are taken from SENDRAM of from the registers of special
--events.

--SubSendDetectors PROCEDURE:
--send triggers to detectors checking if they are special (no latency).
--To generate the latency a counter start at SOB counts up to the latency set.
--then the reading pointer of the ram reads address by address every 25 ns.
--Being addressed by timestamp, position N is read after N+latency clocks.


--EOB SENT AS STAND ALONE PACKET: TO FIT WITH THE DIMENSION OF 16 MASKS

--NEW MTP FORMAT IMPLEMENTED - 32 bit:
--MTP HEADER:
--first 8 bytes:
--Source ID(31 downto 24)
--Primitive timestamp high(24 downto 0)
--second 8 bytes:
--Sub Source ID (31 downto 24)
--Number of Primitives in MTP
--Total MTP length


package component_ethlink is

   constant SGMII_NODES : natural := 4; -- Default;
   constant RGMII_NODES : natural := 4; -- Mezzanines;

--
   constant CPU_IS_PRESENT : natural := 0;
--
   constant PCIE_CLOCK_IS_PRESENT : natural := 0;

--
-- ethlink inputs (edit)
--
   type ethlink_inputs_t is record
--------------------------------- CLOCK DOMAINS
      clkin_40  			  : std_logic;--
      clkin_50  			  : std_logic;--
      clkin_125 			  : std_logic;--
      -- reset list------------------
      cpu_resetn : std_logic;--

      -- USER dip switch (SW6, CMOS inputs)
      USER_DIPSW : std_logic_vector(7 downto 0);--
      
      -- sgmii rx
      rxp : std_logic_vector(0 to SGMII_NODES - 1);--
      
      
      --
      -- rgmii inputs (enet interface)
      --
      -- rgmii rx 
      enet_rx_clk : std_logic_vector(0 to RGMII_NODES - 1);--
      enet_rx_dv  : std_logic_vector(0 to RGMII_NODES - 1);--
      enet_rx_er  : std_logic_vector(0 to RGMII_NODES - 1);--
      enet_rx_d   : vector8bit_t(0 to RGMII_NODES - 1);--
      
       BURST: std_logic; --FROM TTC--
      --------------------------------- USB input                         
      MEPEventNumber    : std_logic_vector(31 downto 0);--

      active_triggers       : std_logic_vector(31 downto 0);--for the online debug 
      activate_clock20MHz   : std_logic                    ;--
      activate_synch        : std_logic                    ;--
      activate_SOBEOBtrigger: std_logic                   ;--
      activate_primitives   : std_logic                    ;--
      
      ------------------------------- TIMESTAMP
      internal_timestamp      : std_logic_vector(31 downto 0); --FROM TTC--
      internal_timestamp125   : std_logic_vector(31 downto 0); --FROM TTC--
      timestamp_physics       : std_logic_vector(31 downto 0); --FROM Primitives--
      timestamp_calib         : vector32bit_t(0 to ethlink_NODES - 2); --    
      ----------------FINETIME                                                 
      finetime_physics_ref    : std_logic_vector(7 downto 0)         ;--
      finetime_physics0        : vector8bit_t(0 to ethlink_NODES - 2) ;--slot N
      finetime_physics1        : vector8bit_t(0 to ethlink_NODES - 2) ;--slot N-1
      finetime_physics2        : vector8bit_t(0 to ethlink_NODES - 2) ;--slot N+1

      finetime_calib          : vector8bit_t(0 to ethlink_NODES - 2) ;--
      ---trigger primitives                                                  
      primitiveID_t0           : vector16bit_t(0 to ethlink_NODES -2) ;-- N
      primitiveID_t1           : vector16bit_t(0 to ethlink_NODES -2) ;-- N-1
      primitiveID_t2           : vector16bit_t(0 to ethlink_NODES -2) ;-- N+1
      
      --calib primitives                                                   
      primitiveID_c           : vector16bit_t(0 to ethlink_NODES -2) ;--
      -----------------TRIGGERWORD        
      periodic_triggerword0   : std_logic_vector(5 downto 0)         ;--	
      periodic_triggerword1   : std_logic_vector(5 downto 0)         ;--	
      random_triggerword      : std_logic_vector(5 downto 0)         ;--	
      
      triggerword        	   : std_logic_vector(5 downto 0)         ;  -- FROM TRIGGER MODULE - OUT OF LUT-- 
      triggerword_calib       : std_logic_vector (5 downto 0)        ;--
      calib_latency           : std_logic_vector(31 downto 0)        ;
      calibration_nim         : std_logic                            ;--        
      calib_direction         : std_logic                            ;
      -------------------SIGNAL EVENT HAPPENED        
      trigger_signal     	   : std_logic                       ;	-- FROM TRIGGER MODULE--
      periodic_signal0        : std_logic                            ;	-- FROM TRIGGER MODULE--
      periodic_signal1        : std_logic                            ;	-- FROM TRIGGER MODULE--
      random_signal           : std_logic                            ;
      calib_signal            : std_logic_vector (6 downto 0)        ;--
      synch_signal            : std_logic                            ;--		        
      control_signal          : std_logic;
      
      --CHOKE ERROR
      CHOKE_signal            : std_logic_vector(13 downto 0)        ;--
      ERROR_signal            : std_logic_vector(13 downto 0)        ;--	                                                                     
      CHOKE_OFF               : std_logic                            ;--
      CHOKE_ON                : std_logic                            ;--
      ERROR_ON                : std_logic                            ;--
      ERROR_OFF               : std_logic                            ;--
      
      --------------------------------------------------------                  
      Fixed_Latency           : std_logic_vector(31 downto 0)        ;--	                                                                        
      enable_mask             : std_logic_vector(nmask-1 downto 0);
      activate_controltrigger : std_logic;
      downscaling             : vector32bit_t(0 to nmask-1);

      ntriggers_predownscaling          : vector32bit_t(0 to nmask-1);
      ntriggers_postdownscaling	        : vector32bit_t(0 to nmask-1);
      ntriggers_postdownscaling_control : std_logic_vector(31 downto 0);
      ntriggers_predownscaling_control  : std_logic_vector(31 downto 0);

      mask                    : mem;
      dontcare                : mem;
      triggerflag             : std_logic_vector(15 downto 0);  
      reference_detector      : std_logic_vector(31 downto 0);
      control_detector        : std_logic_vector(31 downto 0);
      finetime_bits           : std_logic_vector(31 downto 0);
      delay_set               : vector32bit_t(0 to 6);
      maximum_delay_detector  : std_logic_vector(31 downto 0);	
      primitiveDT             : std_logic_vector(31 downto 0);
      
      control_trigger_downscaling: std_logic_vector(31 downto 0);
      readchokefifooff        : std_logic;
      readerrorfifooff        : std_logic;
      readchokefifoon         : std_logic;
      readerrorfifoon         : std_logic;
      dataformat              : std_logic_vector(0 to ethlink_NODES-2);
      temperature             : std_logic_vector(7 downto 0);
 
--------------- Stefan signal
      rit_port       : std_logic;
	
   end record;

--
-- ethlink outputs (edit)
--
   type ethlink_outputs_t is record
 
      -- sgmii phy reset
      resetn : std_logic;
      
      -- sgmii tx
      txp : std_logic_vector(0 to SGMII_NODES - 1);
      
      -- rgmii phy reset
      enet_resetn : std_logic_vector(0 to RGMII_NODES - 1);
      
      -- rgmii tx
      enet_gtx_clk : std_logic_vector(0 to RGMII_NODES - 1);
      enet_tx_en   : std_logic_vector(0 to RGMII_NODES - 1);
      enet_tx_er   : std_logic_vector(0 to RGMII_NODES - 1);
      enet_tx_d    : vector8bit_t(0 to RGMII_NODES - 1);
      
    
      ----------------------LTU PIN OUT
      LTU0 : std_logic;
      LTU1 : std_logic;
      LTU2 : std_logic;
      LTU3 : std_logic;
      LTU4 : std_logic;
      LTU5 : std_logic;
      LTU_TRIGGER : std_logic;
      ------------------------ COUNTERS
      MEPNum                      : std_logic_vector(31 downto 0);
      number_of_primitives        : vector32bit_t(0 to ethlink_NODES -2);
      
      ETHLINKERROR                : std_logic_vector(31 downto 0);
      ---------------------- RECEPTION OUTPUT
      received_signal             : std_logic_vector(0 to ethlink_NODES-2);
      primitiveID 	          : vector16bit_t(0 to ethlink_NODES - 2);
      reserved    	          : vector8bit_t(0 to ethlink_NODES - 2);
      finetime    	          : vector8bit_t(0 to ethlink_NODES - 2);
      timestamp                   : vector32bit_t(0 to ethlink_NODES - 2);
      MTPTimestamp                : vector24bit_t(0 to ethlink_NODES - 2);
      Fixed_Latency_o             : std_logic_vector(31 downto 0);
      CounterLTU                  : std_logic_vector(31 downto 0);
      CounterCHOKE                : std_logic_vector(31 downto 0);
      CounterERROR                : std_logic_vector(31 downto 0);
      periodicrandomtriggercounter: std_logic_vector(31 downto 0);
      randomtriggercounter        : std_logic_vector(31 downto 0);
      rst40                       : std_logic;
      rst125                      : std_logic;
      packet_received             : std_logic;
      MTPNUMREF                   : vector8bit_t(0 to ethlink_NODES-2);
      outchokefifoon              : std_logic_vector(31 downto 0);
      outchokefifooff             : std_logic_vector(31 downto 0);
      outerrorfifooff             : std_logic_vector(31 downto 0);
      outerrorfifoon              : std_logic_vector(31 downto 0);
   end record;

   type ethlink_t is record
      inputs : ethlink_inputs_t;
      outputs : ethlink_outputs_t;
   end record;

   type ethlink_vector_t is array(NATURAL RANGE <>) of ethlink_t;

   component ethlink
      port (
	 inputs : in ethlink_inputs_t;
	 outputs : out ethlink_outputs_t
	 );
   end component;

   signal component_ethlink : ethlink_t;

end component_ethlink;


-- libraries (edit)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.mac_globals.all;
use work.globals.all;

----
use work.component_ethlink.all;
use work.component_syncrst1.all;
use work.component_mac_sgmii.all;
use work.component_mac_rgmii.all;
use work.component_sendram.all;
use work.component_fifodetectorfarm.all;
use work.component_fifopackets.all;
use work.component_fifodelay.all;
use work.component_latencyram_2.all;
use work.component_txport1.all;
use work.component_fifo1trigger.all;

-- ethlink entity (constant)
entity ethlink is
   port (
      inputs : in ethlink_inputs_t;
      outputs : out ethlink_outputs_t
      );
end ethlink;

architecture rtl of ethlink is

   type FSMReceive32bit_t is (S0,S1, S2, S3_1,S3_2,S3_3,S3_4,S3_loop,S4);
   type FSMReceive32bit_vector_t is array(NATURAL RANGE <>) of FSMReceive32bit_t;
   type FSMReceive64bit_t is (S0,S1, S2, S3_1,S3_2,S3_3,S3_4,S3_5,S3_6,S3_7,S3_8,S3_loop,S4,S5_header,S5_write);
   type FSMReceive64bit_vector_t is array(NATURAL RANGE <>) of FSMReceive64bit_t;
   
   type FSMPackets_t is (Idle,WriteEvent,SetFarmAddress,Deadtime_0,Deadtime_1,Deadtime_2);
   type FSMDelay_t is (skipdata,waitdata,waitcontrol,waitfinish,endofframe,readdata,waitoutput);
   type FSMDelay_vector_t is array(NATURAL RANGE <>) of FSMDelay_t; 
   type FSMoutputdata_t is (Idle,SetFarmAddress, WriteEvent);
   type FSMtxtrigger_t is (S0, S1, S2, S3_0, S3_1);
   type FSMtxtrigger_vector_t is array(NATURAL RANGE <>) of FSMtxtrigger_t; 
   type FSMResetCounters_t is (s0,s1);
   type FSMSend_t is (Idle,PacketHeader,PacketHeaderEOB,EventHeader,
		      Data_0,Data_1,Data_2,Data_3,Data_4,Data_5,Data_6,Data_7,Data_8, --common data
		      Data_9,Data_10,Data_11,Data_12,Data_13,Data_14,       -- masks
		      Data_15,IdleDebug,Debug0,Debug1,Debug2,Debug3,Debug4,Debug5,Debug6,Debug7,Debug8,
		      Debug9,Debug10,Debug11,Debug12,Debug13,Debug14,Debug15,Debug16,Debug17); --loop
   
   type FSMSendDebug_t is(Idle,Debug0,Debug1,Debug2,Debug3,Debug4,Debug5,Debug6,Debug7,Debug8,
			Debug9,Debug10,Debug11,Debug12,Debug13,Debug14,Debug15,Debug16,Debug17);
   type FSMSendDetectors_t is (S0_0,S0,S1,S2,S3);

   type reglist_clk40_t is record
      
      LTU0 			: std_logic;
      LTU1 			: std_logic;
      LTU2 			: std_logic;
      LTU3 			: std_logic;
      LTU4 			: std_logic;
      LTU5 			: std_logic;
      LTU_TRIGGER 		: std_logic;

      div2 			: std_logic;
      FSMSendDetectors          : FSMSendDetectors_t;
      latencyreadaddressb       :  signed(29 downto 0);
      oldlatencyreadaddressb    :  signed(29 downto 0);
      latencycounter            :  integer;
      ClockDiv  		:  natural range 0 to 1;
      EOB 	    	        :  std_logic;
      Fixed_Latency             : std_logic_vector(31 downto 0);
      counterLTU                : std_logic_vector(31 downto 0);
      counterCHOKE              : std_logic_vector(31 downto 0);
      counterERROR              : std_logic_vector(31 downto 0);	
      TriggerSTOP               : std_logic;

      activate_synch            : std_logic;
      activate_clock20MHz       : std_logic;
      activate_SOBEOBtrigger    : std_logic;
  
      write_ev40                : std_logic;
      sob_ev40                  : std_logic;
      eob_ev40                  : std_logic;
      ecounter40                : std_logic_vector(15 downto 0);
      BURST40                   : std_logic;
      synch_signal              : std_logic;
      internal_timestamp        : std_logic_vector(31 downto 0);
      primitiveDT               : std_logic_vector(31 downto 0);
      CHOKE_ON                  : std_logic;
      CHOKE_OFF                 : std_logic;
      ERROR_ON                  : std_logic;
      ERROR_OFF                 : std_logic;
      sentCHOKE_ON              : std_logic;
      sentCHOKE_OFF             : std_logic;
      sentERROR_ON              : std_logic;
      sentERROR_OFF             : std_logic;
      chokeOn_ev40              : std_logic;
      chokeOff_ev40             : std_logic;
      errorOn_ev40              : std_logic;
      errorOff_ev40             : std_logic;
      ETHLINKERROR              : std_logic_vector(31 downto 0);
      MACReady                  : std_logic;
      ERROR_ON_Delay            : std_logic_vector(2 downto 0);
      CHOKE_ON_Delay            : std_logic_vector(2 downto 0);
      delayafterchoke           : std_logic_vector(31 downto 0);
      RESTART                   : std_logic;
      safedistance              : std_logic_vector(3 downto 0);
   end record;
 
   constant reglist_clk40_default : reglist_clk40_t :=
      (

	 LTU0 			=> '0'           ,
	 LTU1 			=> '0'           ,
	 LTU2 			=> '0'           ,
	 LTU3 			=> '0'           ,
	 LTU4 			=> '0'           ,
	 LTU5 			=> '0'           ,
	 LTU_TRIGGER     	=> '0'           ,
	 div2                  	=> '0'           ,
	 ClockDiv              	=> 0             ,
	 FSMSendDetectors      	=> S0_0          ,
	 latencyreadaddressb   	=> (others=>'0') ,
	 oldlatencyreadaddressb	=> (others=>'0') ,
	 latencycounter        	=> 0  		 ,
	 EOB 		        => '0'		 ,
	 FIxed_Latency           => (others =>'0'),
	 counterLTU              => (others =>'0'),
	 counterCHOKE            => (others =>'0'),
	 counterERROR            => (others =>'0'),
	 TriggerSTOP 	 	 => '0'           ,
	 activate_synch          => '0'           ,
	 activate_SOBEOBtrigger  => '0'           ,
	 activate_clock20MHz     => '0'           ,	
	 write_ev40              => '0'           ,
	 ecounter40              => (others =>'0'),
	 sob_ev40                => '0'           ,
	 eob_ev40                => '0'           ,
	 BURST40                 => '0'	          ,
	 synch_signal            => '0'           ,
	 internal_timestamp      => (others=>'0') ,
	 primitiveDT             =>(others => '0'),
	 CHOKE_OFF               => '0'           ,
	 CHOKE_ON                => '0'           ,
	 ERROR_OFF               => '0'           ,
	 ERROR_ON                => '0'           ,
	 sentCHOKE_OFF           => '1'           ,
	 sentCHOKE_ON            => '0'           ,
	 sentERROR_ON            => '0'           ,
	 sentERROR_OFF           => '1'           ,
	 chokeOn_ev40            => '0'           ,
	 chokeOff_ev40           => '0'           ,
	 errorOn_ev40            => '0'           ,
	 errorOff_ev40           => '0'		  ,
         ETHLINKERROR            => (others =>'0'),
         MACReady                => '1'           ,
         ERROR_ON_Delay          => (others =>'0'),
         CHOKE_ON_Delay          => (others =>'0'),
	 delayafterchoke         =>  (others =>'0'),
	 RESTART                 => '0',
	 safedistance            => SLV(3,4)
	 );

--
-- clock domain clk50
--
   type reglist_clk50_t is record

      -- register list
      div2 : std_logic;
      wena : std_logic_vector(0 to SGMII_NODES - 1);
      rena : std_logic_vector(0 to SGMII_NODES - 1);
      wena_rgmii : std_logic_vector(0 to RGMII_NODES - 1);
      rena_rgmii : std_logic_vector(0 to RGMII_NODES - 1);

      -- end of list
      eol : std_logic;

   end record;
   constant reglist_clk50_default : reglist_clk50_t :=
      (
	 div2       => '0',
	 wena       => (others => '0'),
	 rena       => (others => '0'),
	 wena_rgmii => (others => '0'),
	 rena_rgmii => (others => '0'),
	 eol        => '0'
	 );


   type reglist_clk125_t is record
------------ Stefan part

      s_rit  : std_logic;
----------------------
      errorchecktimestamp : std_logic_vector(0 to ethlink_NODES-1);
      fifodelay           : vector32bit_t(0 to ethlink_NODES -2);
      fifodelay_set       : vector32bit_t(0 to ethlink_NODES -2);
      start_latency       : std_logic_vector(31 downto 0);
      MEPEventNumber    : std_logic_vector(7 downto 0);

-- FSM list--------------------------------------------------------------------------------
      FSMDelay            : FSMDelay_vector_t(0 to ethlink_NODES-2);
      FSMReceive64bit     : FSMReceive64bit_vector_t(0 to SGMII_NODES-2);
      FSMReceive32bit     : FSMReceive32bit_vector_t(0 to SGMII_NODES-2);	
      FSMSend             : FSMsend_t;
      FSMResetCounters    : FSMResetCounters_t;
      enet_FSMReceive32bit: FSMReceive32bit_vector_t(0 to RGMII_NODES- 1);
      enet_FSMReceive64bit: FSMReceive64bit_vector_t(0 to RGMII_NODES- 1);
      FSMoutputdata       : FSMoutputdata_t;
      FSMSendDebug        : FSMSendDebug_t;
      -- register list
      --
      dataformat           : std_logic_vector(0 to ethlink_NODES-2);
      -- RGMII interface IMPORTANTE!!!!
      enet_rena            : std_logic_vector(0 to RGMII_NODES - 1);
    
      enet_data0           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data1           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data2           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data3           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data4           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data5           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data6           : vector8bit_t(0 to RGMII_NODES - 1);
      enet_data7           : vector8bit_t(0 to RGMII_NODES - 1);
      
      enet_olddata1        : vector8bit_t(0 to RGMII_NODES - 1);
      --MTP header RGMII
      enet_headermode      : std_logic_vector(0 to RGMII_NODES-1);
      enet_headerreceived  : std_logic_vector(0 to RGMII_NODES-1);
      enet_MTPSourceID     : vector8bit_t(0 to     RGMII_NODES-1);
      enet_MTPTimestampH   : vector24bit_t(0 to    RGMII_NODES-1);
      --MTP header SGMII
      headermode           : std_logic_vector(0 to SGMII_NODES-2);
      headerreceived       : std_logic_vector(0 to SGMII_NODES-2);
      MTPSourceID          : vector8bit_t(0 to SGMII_NODES-2);
      MTPTimestampH        : vector24bit_t(0 to SGMII_NODES-2);
      MTPNUMREF            : vector8bit_t(0 to ethlink_NODES-2);
      ----------------------------------------------------------------------------------------
      data0                : vector8bit_t(0 to SGMII_NODES-2); -- mac output data registers
      data1                : vector8bit_t(0 to SGMII_NODES-2);
      data2                : vector8bit_t(0 to SGMII_NODES-2);
      data3                : vector8bit_t(0 to SGMII_NODES-2);
      data4                : vector8bit_t(0 to SGMII_NODES-2);
      data5                : vector8bit_t(0 to SGMII_NODES-2);
      data6                : vector8bit_t(0 to SGMII_NODES-2);
      data7                : vector8bit_t(0 to SGMII_NODES-2);
     
      olddata1             : vector8bit_t(0 to SGMII_NODES - 2);
      ---------------------------------------------------------------------   	
      --MEP header
      MEPeventNum           : std_logic_vector(23 downto 0);
      MEPheader125          : std_logic;
      MEPsourceID           : std_logic_vector(7 downto 0);
      MEPsourceSubID        : std_logic_vector(7 downto 0);
      MEPnum 	            : std_logic_vector(31 downto 0);
      MEPLen 	            : std_logic_vector(15 downto 0);
      MEPLenEOB             : std_logic_vector(15 downto 0);
------------------------------------------------------------------------------
      wena                 : std_logic_vector(0 to ethlink_NODES-1); -- Setting for MAC
      rena                 : std_logic_vector(0 to ethlink_NODES-1);
      hwaddress            : std_logic_vector(7 downto 0);
      eol                  : std_logic;
      timer 		   : integer; --before reset
      timerdebug           : integer; --before sending debug packet
--counter registers------------------------------------------------------------
      number_of_primitives     : vector32bit_t(0 to ethlink_NODES-2);
      old_number_of_primitives : vector32bit_t(0 to ethlink_NODES-2);
      
      number_of_CHOKE          : std_logic_vector(31 downto 0);
      number_of_ERROR          : std_logic_vector(31 downto 0);
      -----------------------------------------------------------
      sendSOB                  : std_logic;
      sendEOB                  : std_logic;
      ETHLINKERROR             : std_logic_vector(31 downto 0);
      sendCHOKE_OFF            : std_logic; 
      sendCHOKE_ON             : std_logic;
      sendERROR_OFF            : std_logic;
      sendERROR_ON	       : std_logic;
      -----------------------------------------------------------
      old_timestamp            : std_logic_vector(31 downto 0);
      old_tw                   : std_logic_vector(5 downto 0);
      periodicrandomtriggercounter: std_logic_vector(31 downto 0);
      randomtriggercounter     : std_logic_vector(31 downto 0);
      calib_direction          : std_logic;
      calib_latency            : std_logic_vector(31 downto 0);
      periodic_triggerword0    : std_logic_vector(5 downto 0);
      periodic_triggerword1    : std_logic_vector(5 downto 0);
      random_triggerword       : std_logic_vector(5 downto 0);
      activate_primitives      : std_logic;
      active_triggers          : std_logic_vector(31 downto 0);
      sob_data125              : std_logic_vector(191 downto 0);
      data_send                : std_logic;
      sob_data_send            : std_logic;
      eob_data_send            : std_logic;
      eob_data125              : std_logic_vector(191 downto 0);
      ecounter125              : std_logic_vector(15 downto 0);
      sob_ev125                : std_logic;
      eob_ev125                : std_logic;
      write_ev125              : std_logic;
      chokeOn_ev125            : std_logic;
      chokeOff_ev125           : std_logic;
      errorOn_ev125            : std_logic;
      errorOff_ev125           : std_logic;
      
      sent                     : std_logic;
      debugsent                : std_logic;
      BURST125                 : std_logic;
      internal_timestamp       : std_logic_vector(31 downto 0);
      
      ---------------------------------------------------------------
      --INPUT 125 MHZ                    
      -------------------------------- TIMESTAMP
      tmptimestamp            : std_logic_vector(31 downto 0)        ;
      timestamp_physics       : std_logic_vector(31 downto 0)        ;
      timestamp_calib         : vector32bit_t(0 to ethlink_NODES - 2);
      ----------------FINETIME                                        
      tmpfinetime0             : vector8bit_t(0 to ethlink_NODES - 2) ;
      tmpfinetime1             : vector8bit_t(0 to ethlink_NODES - 2) ;
      tmpfinetime2             : vector8bit_t(0 to ethlink_NODES - 2) ;
      
      tmpfinetime_ref         : std_logic_vector(7 downto 0)         ;
      finetime_physics_ref    : std_logic_vector(7 downto 0)         ;
      finetime_physics0        : vector8bit_t(0 to ethlink_NODES - 2) ;
      finetime_physics1        : vector8bit_t(0 to ethlink_NODES - 2) ;
      finetime_physics2        : vector8bit_t(0 to ethlink_NODES - 2) ;

      finetime_calib           : vector8bit_t(0 to ethlink_NODES - 2) ;
      ---trigger primitives                                           
      primitiveID_t0           : vector16bit_t(0 to ethlink_NODES -2) ;--
      primitiveID_t1           : vector16bit_t(0 to ethlink_NODES -2) ;--
      primitiveID_t2           : vector16bit_t(0 to ethlink_NODES -2) ;--
      tmpprimitiveID0          : vector16bit_t(0 to ethlink_NODES -2) ;--
      tmpprimitiveID1          : vector16bit_t(0 to ethlink_NODES -2) ;--
      tmpprimitiveID2          : vector16bit_t(0 to ethlink_NODES -2) ;--
      
      --calib primitives                                              
      primitiveID_c           : vector16bit_t(0 to ethlink_NODES -2) ;--
      -------------TRIGGERWORD        
      triggerword             : std_logic_vector(5 downto 0)         ;
      tmptriggerword          : std_logic_vector(5 downto 0)         ;
      triggerword_calib       : std_logic_vector (5 downto 0)        ;
      calibration_nim         : std_logic                            ;

      tmpdatatype             : std_logic_vector (7 downto 0)        ;     
      tmptriggerflag          : std_logic_vector (15 downto 0)       ;

      enable_mask             : std_logic_vector(nmask-1 downto 0);
      
--------------------SIGNAL EVENT HAPPENED        
      trigger_signal          : std_logic                            ;
      control_signal          : std_logic                            ;
      periodic_signal0        : std_logic                            ;
      periodic_signal1        : std_logic                            ;
      random_signal           : std_logic                            ;
      calib_signal            : std_logic_vector (6 downto 0)        ;
      CHOKE_signal            : std_logic_vector(13 downto 0)        ;
      ERROR_signal            : std_logic_vector(13 downto 0)        ;
      
      CHOKE_ON                : std_logic; 
      CHOKE_OFF               : std_logic;  
      ERROR_ON                : std_logic;
      ERROR_OFF               : std_logic; 
      
      chokeOn_data125         : std_logic_vector(191 downto 0)   ;
      chokeOff_data125        : std_logic_vector(191 downto 0)   ;
      errorOn_data125         : std_logic_vector(191 downto 0)   ;
      errorOff_data125        : std_logic_vector(191 downto 0)   ;	
      chokeOn_data_send       : std_logic                        ;
      chokeOff_data_send      : std_logic                        ;
      errorOn_data_send       : std_logic                        ;
      errorOff_data_send      : std_logic                        ;
      -------EOB-------------------------------------------------
      internal_timestamp_eob  : std_logic_vector(31 downto 0);	
      downscaling     	      : vector32bit_t(0 to nmask-1);
      control_trigger_downscaling: std_logic_vector(31 downto 0);
      ntriggers_predownscaling 	        : vector32bit_t(0 to nmask-1);
      ntriggers_postdownscaling         : vector32bit_t(0 to nmask-1);
      ntriggers_postdownscaling_control : std_logic_vector(31 downto 0);
      ntriggers_predownscaling_control  : std_logic_vector(31 downto 0);   
      maskindex               : natural;
      maskindexdebug          : natural;	
      calibration_trigger     : std_logic_vector(31 downto 0);
      mask                    : mem;
      dontcare                : mem;
      triggerflag              : std_logic_vector(15 downto 0);
      finetime_bits           : std_logic_vector(31 downto 0);
      reference_detector      : std_logic_vector(31 downto 0);
      control_detector        : std_logic_vector(31 downto 0);
      fixed_Latency125        : std_logic_vector(31 downto 0);
      MEPEventRead            : std_logic_vector(7 downto 0);
      MEPEventWritten         : std_logic_vector(7 downto 0);
      FSMPackets              : FSMPackets_t;
      framelen                : std_logic_vector(10 downto 0);
      maximum_delay_detector  : std_logic_vector(31 downto 0);
      readdetector            : std_logic_vector(6 downto 0);
      addressfarm             : signed(11 downto 0);
      MACReady                : std_logic;
      temperature             : std_logic_vector(7 downto 0);
      MTPTimestamp_out        : vector24bit_t(0 to ethlink_NODES -2);
      
   end record;
   
   
   constant reglist_clk125_default : reglist_clk125_t :=
      (

-- Stefan default
          s_rit =>'0',
	
------------------------------  

	 errorchecktimestamp     => (others=>'0'),
	 fifODELAY               => (others=>"00000000000000000000000000000000"),
	 fifODELAY_set           => (others=>"00000000000000000000000000000000"),
	 MEPEventNumber        => (others =>'0'),

-- FSM list--------------------------------------------------------------------------------	
	 FSMPackets             =>Idle,
	 FSMReceive32bit        =>(others =>S0),
	 enet_FSMReceive32bit   =>(others =>S0),
	 FSMReceive64bit        =>(others =>S0),
	 enet_FSMReceive64bit   =>(others =>S0),
	 FSMDelay               =>(others=>skipdata),
	 FSMSend	        => Idle,
	 FSMResetCounters       => S0,
	 FSMoutputdata          => Idle,
	 FSMSendDebug           => Idle,
	 --------------------------------------                  
	 dataformat             =>(others=>'0'),

	 data0                  =>(others=>"00000000"),
	 data1                  =>(others=>"00000000"),
	 data2                  =>(others=>"00000000"),
	 data3                  =>(others=>"00000000"),
	 data4                  =>(others=>"00000000"),
	 data5                  =>(others=>"00000000"),
	 data6                  =>(others=>"00000000"),
	 data7                  =>(others=>"00000000"),
	 
         olddata1               =>(others=>"00000000"),
	 --MTP header                  
	 headermode             => (others =>'1'),
	 headerreceived         => (others =>'0'),
	 MTPSourceID            => (others=>"00000000"),
	 MTPTimestampH          => (others=>"000000000000000000000000") ,
	 MTPNUMREF              =>(others=>"00000000"),
--------------------------------------  
	 enet_data0             =>(others=>"00000000"),
	 enet_data1             =>(others=>"00000000"),
	 enet_data2             =>(others=>"00000000"),
	 enet_data3             =>(others=>"00000000"),
	 enet_data4             =>(others=>"00000000"),
	 enet_data5             =>(others=>"00000000"),
	 enet_data6             =>(others=>"00000000"),
	 enet_data7             =>(others=>"00000000"),
	 enet_olddata1          =>(others=>"00000000"),
	 --MTP header 
	 enet_headermode        => (others =>'1'),
	 enet_headerreceived    => (others=>'0'),
	 enet_MTPSourceID       => (others=>"00000000"),
	 enet_MTPTimestampH     => (others=>"000000000000000000000000") ,

	 --MEP header 
	 timer 	                => 0,
	 timerdebug             => 0,
	 MEPeventNum 	        => (others=>'0'),
	 MEPheader125 	        =>'1',
	 MEPsourceID 	        =>(others=>'0'),
	 MEPsourceSubID         =>(others=>'0'),
	 MEPnum 	        =>(others=>'0'),
	 MEPLen 	        =>(others=>'0'),
	 MEPLenEOB 	        =>(others=>'0'),	
	 --------------------------------------  
	 wena                   => (others => '0'),
	 rena                   => (others => '0'),	
	 enet_rena              => (others => '0'),	
	 
	 hwaddress              => "00000000",
	 eol                    => '0',
	 -------------------------------------- 
	 
	 number_of_primitives   =>(others=>"00000000000000000000000000000000"),
         old_number_of_primitives   =>(others=>"00000000000000000000000000000000"),
	 
	 ETHLINKERROR             =>(others=>'0'),
	 number_of_CHOKE          =>(others =>'0'),
	 number_of_ERROR          =>(others =>'0'),
	 old_tw                   =>(others=>'0'),
	 old_timestamp            =>(others=>'0'),
	 sendEOB                  =>'0',
	 periodicrandomtriggercounter =>(others =>'0'),
	 randomtriggercounter     =>(others =>'0'),
	 calib_direction          => '0',
	 calib_latency            => (others =>'0'),
	 periodic_triggerword0    =>(others=>'0'),
	 periodic_triggerword1    =>(others=>'0'),
	 random_triggerword       =>(others=>'0'),

	 sendSOB                  => '1',
	 activate_primitives      => '0',
	 active_triggers          => (others =>'0'),
	 sob_data_send            => '0',
	 data_send                => '0',
	 eob_data_send            => '0',
	 chokeOn_data_send        => '0',
	 chokeOff_data_send       => '0',
	 errorOn_data_send        => '0',
	 errorOff_data_send       => '0',
	 
	 sob_data125             =>(others=>'0'),
	 eob_data125             =>(others=>'0'),
	 
	 sendCHOKE_OFF           => '0',
	 sendCHOKE_ON            => '1'                                 ,
	 sendERROR_ON            => '1'                                 ,
	 sendERROR_OFF           => '0'                                 ,
	 chokeOn_data125         => (others=>'0')                       ,
	 chokeOff_data125        => (others=>'0')                       ,
	 errorOn_data125         => (others=>'0')                       ,
	 errorOff_data125        => (others=>'0')                       ,

	 write_ev125             => '0'				        ,
	 ecounter125             =>  (others=>'0')                      ,
	 sob_ev125               =>'0'		                        ,
	 eob_ev125               =>'0'					,
	 chokeOn_ev125           =>'0'					,
	 chokeOff_ev125          =>'0'					,
	 errorOn_ev125           =>'0'					,
	 errorOff_ev125          =>'0'					,
	 
	 
	 sent                    =>'1'					,
	 debugsent               =>'0'					,
	 internal_timestamp      => (OTHERS=>'0')		        ,
	 BURST125              	 => '0'                                 ,
	 ----------------------------------INPUT 125
	 -------------------------------- TIMESTAMP
	 timestamp_physics        => (OTHERS=>'0')                      ,
	 tmptimestamp             => (OTHERS=>'0')                      ,
	 timestamp_calib          => (OTHERS=>"00000000000000000000000000000000"),
	 ----------------FINETIME                                        
	 finetime_physics0         => (OTHERS=>"00000000"),
	 finetime_physics1         => (OTHERS=>"00000000"),
	 finetime_physics2         => (OTHERS=>"00000000"),

	 tmpfinetime0              => (OTHERS=>"00000000"),
	 tmpfinetime1              => (OTHERS=>"00000000"),
	 tmpfinetime2              => (OTHERS=>"00000000"),

	 tmpfinetime_ref          => (OTHERS=>'0'),
	 finetime_physics_ref     => (OTHERS=>'0'),	
	 finetime_calib           => (OTHERS=>"00000000"),
	 ---trigger primitives                                          
	 primitiveID_t0           => (others => "0000000000000000"),
	 primitiveID_t1           => (others => "0000000000000000"),
	 primitiveID_t2           => (others => "0000000000000000"),

	 tmpprimitiveID0          => (others => "0000000000000000"),
	 tmpprimitiveID1          => (others => "0000000000000000"),
	 tmpprimitiveID2          => (others => "0000000000000000"),
	 
	 --calib primitives                                             
	 primitiveID_c           => (others => "0000000000000000"),
	 
	 ------------------TRIGGERWORD       
	 triggerword             => (others => '0'),
	 triggerword_calib       => (others => '0'),
	 tmptriggerword          => (others => '0'),
	 tmpdatatype             => (others => '0'),
	 tmptriggerflag          => (others => '0'),
	 
	 calibration_nim         => '0',
	 --------------------SIGNAL EVENT HAPPENED       
	 trigger_signal          => '0',
	 control_signal          => '0',
	 periodic_signal0        => '0',
	 periodic_signal1        => '0',
	 random_signal           => '0',
	 calib_signal            => (others => '0'),
	 CHOKE_signal            => (others => '0'),
	 ERROR_signal            => (others => '0'),
	 
	 CHOKE_OFF                => '0',
	 CHOKE_ON                 => '0',
	 ERROR_ON                 => '0',
	 ERROR_OFF                => '0',
	 --------------------------------------------------------       	
	 internal_timestamp_eob   => (others => '0'),
	 ntriggers_predownscaling => (others => "00000000000000000000000000000000"),	
         ntriggers_predownscaling_control   => (others=> '0'),   
         downscaling              => (others => "00000000000000000000000000000000"),	
	 control_trigger_downscaling => (others=>'0'),
	 enable_mask                 => (others =>'0'),
	 ntriggers_postdownscaling   => (others => "00000000000000000000000000000000"),
	 ntriggers_postdownscaling_control  => (others=> '0'),
	 
	 maskindex                => 0,
	 maskindexdebug           => 0,             
	 calibration_trigger      => (others =>'0'),
	 mask                     => (others =>"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),
	 dontcare                 => (others =>"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),
	 triggerflag              => (others =>'0'),
	 reference_detector       => (others =>'0'),
	 control_detector         => (others =>'0'),
	 finetime_bits            => (others =>'0'),
	 fixed_Latency125         => (others=>'0'),

	 MEPEventRead             =>(others=>'0'),
	 MEPEventWritten          =>(others=>'0'),
	 framelen                 =>(others=>'0'),
	 maximum_delay_detector   =>(others =>'0'),
	 start_latency            =>(others => '0'),
	 readdetector             =>(others => '0'),
	 addressfarm              => (others=>'0'),
         MACReady                 => '1',
	 temperature              => (others =>'0'),
         MTPTimestamp_out         => (others => "000000000000000000000000")
	 );

   type reglist_t is record
      clk40  : reglist_clk40_t;
      clk50  : reglist_clk50_t;
      clk125 : reglist_clk125_t;
   end record;

--
-- all local resets (edit)
--
-- Notes: one record-element for each clock domain
--
   type resetlist_t is record
      main   : std_logic;
      clk40  : std_logic;
      clk50  : std_logic;
      clk125 : std_logic;
   end record;

--
-- all local nets (edit)
--
   type netlist_t is record
      -- internal clocks
      clk125           : std_logic;
      clk40            : std_logic;
      -- resets (all clock domains)
      rst              : resetlist_t;
      SyncRST          : syncrst1_t;
      MAC              : mac_sgmii_vector_t(0 to SGMII_NODES - 1);
      enet_MAC         : mac_rgmii_vector_t(0 to RGMII_NODES - 1);   
      SENDRAM          : sendram_t; -- Fifo in which triggerwords are stored before sending them back
      FIFOPACKETS      : fifopackets_t; -- Fifo in which triggerwords are stored before sending them back
      FIFODETECTORFARM : fifodetectorfarm_t;
      LATENCYRAM       : LATENCYRAM_2_t;
      FIFODELAY        : FIFODELAY_vector_t(0  to ethlink_NODES - 2);
      CHOKEFIFOON      : fifo1trigger_t;
      ERRORFIFOON      : fifo1trigger_t;
      CHOKEFIFOOFF     : fifo1trigger_t;
      ERRORFIFOOFF     : fifo1trigger_t;
      
   end record;

   subtype inputs_t is ethlink_inputs_t;
   subtype outputs_t is ethlink_outputs_t;

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

begin


   SyncRST : syncrst1 port map
      (
	 inputs => allnets.SyncRST.inputs,
	 outputs => allcmps.SyncRST.outputs
	 );



   MAC : FOR index IN 0 TO SGMII_NODES - 1 GENERATE
      MAC : mac_sgmii 
	 generic map
	 (
	    instance => index
	    -- note: SGMII nodes mapped to range 0..3
	    )
	 port map
	 (
	    inputs => allnets.MAC(index).inputs,
	    outputs => allcmps.MAC(index).outputs
	    );
   END GENERATE;

   enet_MAC : FOR index IN 0 TO RGMII_NODES - 1 GENERATE
      enet_MAC : mac_rgmii
	 generic map
	 (
	    instance => (index+4)
	    -- note: RGMII nodes mapped to range 4..7
	    )
	 port map
	 (
	    inputs => allnets.enet_MAC(index).inputs,
	    outputs => allcmps.enet_MAC(index).outputs
	    );
   END GENERATE;



   fifodelay_inst : FOR index IN 0 TO ethlink_NODES - 2 GENERATE
      fifoDelay_inst : fifoDELAY port map
	 (
	    inputs => allnets.FIFODELAY(index).inputs,
	    outputs => allnets.FIFODELAY(index).outputs
	    );
   END GENERATE;


   SENDRAM_inst: sendram port map
      (
	 inputs=>allnets.SENDRAM.inputs,
	 outputs=>allnets.SENDRAM.outputs
	 ); 
   
   FIFODETECTORFARM_inst: fifodetectorfarm port map
      (
	 inputs=>allnets.FIFODETECTORFARM.inputs,
	 outputs=>allnets.FIFODETECTORFARM.outputs
	 ); 
   
   FIFOPACKETS_inst: fifopackets port map
      (
	 inputs=>allnets.FIFOPACKETS.inputs,
	 outputs=>allnets.FIFOPACKETS.outputs
	 ); 
   
   CHOKEFIFOON_inst: fifo1trigger port map
      (
	 inputs=>allnets.CHOKEFIFOON.inputs,
	 outputs=>allnets.CHOKEFIFOON.outputs
	 ); 
   
   ERRORFIFOON_inst: fifo1trigger port map
      (
	 inputs=>allnets.ERRORFIFOON.inputs,
	 outputs=>allnets.ERRORFIFOON.outputs
	 ); 
   
   
   CHOKEFIFOOFF_inst: fifo1trigger port map
      (
	 inputs=>allnets.CHOKEFIFOOFF.inputs,
	 outputs=>allnets.CHOKEFIFOOFF.outputs
	 ); 
   
   ERRORFIFOOFF_inst: fifo1trigger port map
      (
	 inputs=>allnets.ERRORFIFOOFF.inputs,
	 outputs=>allnets.ERRORFIFOOFF.outputs
	 ); 
   
   
   LatencyRam_inst: latencyram_2 port map
      (
	 inputs=>allnets.LATENCYRAM.inputs,
	 outputs=>allnets.LATENCYRAM.outputs
	 );
   
   
   process (inputs.clkin_50, allnets.rst.clk50)
   begin
      if (allnets.rst.clk50 = '1') then
	 allregs.dout.clk50 <= reglist_clk50_default;
      elsif rising_edge(inputs.clkin_50) then
	 allregs.dout.clk50 <= allregs.din.clk50;
      end if;
   end process;

   process (allnets.clk40, allnets.rst.clk40)
   begin
      if (allnets.rst.clk40 = '1') then
	 allregs.dout.clk40 <= reglist_clk40_default;
      elsif rising_edge(allnets.clk40) then
	 allregs.dout.clk40 <= allregs.din.clk40;
      end if;
   end process;

   process (allnets.clk125, allnets.rst.clk125)
   begin
      if (allnets.rst.clk125 = '1') then
	 allregs.dout.clk125 <= reglist_clk125_default;
      elsif rising_edge(allnets.clk125) then
	 allregs.dout.clk125 <= allregs.din.clk125;
      end if;
   end process;

   process (inputs, allouts, allregs, allnets, allcmps)


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
	 n.clk125  := i.clkin_125; --Internal Clock Domains.
	 n.clk40   := i.clkin_40;
	 --

	 
	 n.SyncRST.inputs.clk(1) := i.clkin_50;
	 n.SyncRST.inputs.clr(1) := not(i.cpu_resetn);
	 n.rst.main := n.SyncRST.outputs.rst(1);
	 
	 --
	 -- clock domain clk125    
	 -- level 2 
	 --
	 n.SyncRST.inputs.clk(2) := n.clk125;   
	 n.SyncRST.inputs.clr(2) := n.rst.main;
	 n.rst.clk125 := n.SyncRST.outputs.rst(2);

	 --
	 -- clock domain rxclock
	 -- level 3 
	 --
	 n.SyncRST.inputs.clk(3) := '0';   
	 n.SyncRST.inputs.clr(3) := '1';
	 --n.rst.clk50 := n.SyncRST.outputs.rst(3);
	 if PCIE_CLOCK_IS_PRESENT = 0 then
	    -- !! Debug !! PCIe 'rxclock' not present --> SyncRst section 3 not used 
	    n.rst.clk125 := n.rst.clk125; 
	 end if;

	 --
	 -- clock domain clk40
	 -- level 4
	 --
	 n.SyncRST.inputs.clk(4) := n.clk40;
	 n.SyncRST.inputs.clr(4) := n.rst.clk125;
	 n.rst.clk40 := n.SyncRst.outputs.rst(4);
	 
	 --
	 -- clock domain clk50
	 -- level 5 (min priority: deasserted last)
	 --
	 n.SyncRST.inputs.clk(5) := i.clkin_50;
	 n.SyncRST.inputs.clr(5) := n.rst.clk40;
	 n.rst.clk50 := n.SyncRst.outputs.rst(5);

	 --
	 -- Unused SyncRst section 
	 --
	 n.SyncRst.inputs.clk(6) := '0';
	 n.SyncRst.inputs.clr(6) := '1';

	 --
	 -- Unused SyncRst section 
	 --
	 n.SyncRst.inputs.clk(7) := '0';
	 n.SyncRst.inputs.clr(7) := '1';

	 --
	 -- Unused SyncRst section 
	 --
	 n.SyncRst.inputs.clk(8) := '0';
	 n.SyncRst.inputs.clr(8) := '1';

	 o.rst40 := n.rst.clk40;
	 o.rst125:= n.rst.clk125;

      end procedure;


--
-- SubMain combinatorial procedure (edit)
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
        
	 r.clk50.div2                     := not(ro.clk50.div2);
	 r.clk125.hwaddress               := i.USER_DIPSW(7 downto 0);
	 r.clk125.MEPEventNumber          := i.MEPEventNumber(7 downto 0);
	 
	 r.clk40.internal_timestamp       := i.internal_timestamp;
	 r.clk125.internal_timestamp      := i.internal_timestamp125;
	 
	 r.clk40.BURST40                  := i.BURST;
	 r.clk125.BURST125                := i.BURST;
	 r.clk40.primitiveDT              := i.primitiveDT;
	 r.clk125.dataformat              := i.dataformat(0 to ethlink_NODES-2);
	 
	 n.SENDRAM.inputs.address_a       := (others=>'0'); 
	 n.SENDRAM.inputs.data_a          := (others=>'0');
	 n.SENDRAM.inputs.address_b       := (others=>'0'); 
	 n.SENDRAM.inputs.data_b          := (others=>'0');
	 n.SENDRAM.inputs.wren_a          := '0';
	 n.SENDRAM.inputs.wren_b          := '0';
	 n.SENDRAM.inputs.rden_a          := '0';
	 n.SENDRAM.inputs.rden_b          := '0';
	 n.SENDRAM.inputs.clock_a         := n.clk125;
	 n.SENDRAM.inputs.clock_b         := n.clk125; 
	 
	 
	 n.FIFOPACKETS.inputs.data        := (others=>'0');
	 n.FIFOPACKETS.inputs.aclr        := '0';
	 n.FIFOPACKETS.inputs.rdclk       := n.clk125;
	 n.FIFOPACKETS.inputs.wrclk       := n.clk125;
	 n.FIFOPACKETS.inputs.rdreq       := '0';
	 n.FIFOPACKETS.inputs.wrreq       := '0';
	 
	 n.FIFODETECTORFARM.inputs.data   := (others=>'0');
	 n.FIFODETECTORFARM.inputs.aclr   := '0';
	 n.FIFODETECTORFARM.inputs.rdclk  := n.clk125;
	 n.FIFODETECTORFARM.inputs.wrclk  := n.clk40;
	 n.FIFODETECTORFARM.inputs.rdreq  := '0';
	 n.FIFODETECTORFARM.inputs.wrreq  := '0';
	 
	 
	 n.CHOKEFIFOON.inputs.wrclk         := n.clk125     ;
	 n.CHOKEFIFOON.inputs.rdclk         := n.clk125     ;
	 n.CHOKEFIFOON.inputs.data          := (others=>'0');
	 n.CHOKEFIFOON.inputs.aclr          := '0'          ;
	 n.CHOKEFIFOON.inputs.wrreq         := '0'          ;
	 n.CHOKEFIFOON.inputs.rdreq         := '0'          ;
	 
	 
	 n.ERRORFIFOON.inputs.wrclk         := n.clk125     ;
	 n.ERRORFIFOON.inputs.rdclk         := n.clk125     ;
	 n.ERRORFIFOON.inputs.data          := (others=>'0');
	 n.ERRORFIFOON.inputs.aclr          := '0'          ;
	 n.ERRORFIFOON.inputs.wrreq         := '0'          ;
	 n.ERRORFIFOON.inputs.rdreq         := '0'          ;
	 
	 
	 n.CHOKEFIFOOFF.inputs.wrclk         := n.clk125     ;
	 n.CHOKEFIFOOFF.inputs.rdclk         := n.clk125     ;
	 n.CHOKEFIFOOFF.inputs.data          := (others=>'0');
	 n.CHOKEFIFOOFF.inputs.aclr          := '0'          ;
	 n.CHOKEFIFOOFF.inputs.wrreq         := '0'          ;
	 n.CHOKEFIFOOFF.inputs.rdreq         := '0'          ;
	 
	 
	 n.ERRORFIFOOFF.inputs.wrclk         := n.clk125     ;
	 n.ERRORFIFOOFF.inputs.rdclk         := n.clk125     ;
	 n.ERRORFIFOOFF.inputs.data          := (others=>'0');
	 n.ERRORFIFOOFF.inputs.aclr          := '0'          ;
	 n.ERRORFIFOOFF.inputs.wrreq         := '0'          ;
	 n.ERRORFIFOOFF.inputs.rdreq         := '0'          ;
	 
	 n.LATENCYRAM.inputs.address_a    := (others=>'0'); 
	 n.LATENCYRAM.inputs.data_a       := (others=>'0');
	 n.LATENCYRAM.inputs.address_b    := (others=>'0'); 
	 n.LATENCYRAM.inputs.data_b       := (others=>'0');
	 n.LATENCYRAM.inputs.wren_a       := '0';
	 n.LATENCYRAM.inputs.wren_b       := '0';
	 n.LATENCYRAM.inputs.rden_a       := '0';
	 n.LATENCYRAM.inputs.rden_b       := '0';
	 n.LATENCYRAM.inputs.clock_a      := n.clk125;
	 n.LATENCYRAM.inputs.clock_b      := n.clk40;

	 
	 
	 --AutoCHOKE:
	 --if the ethernet to send data to PC-Farm is amlost full (3 frames)
         --L0TP autoenables the CHOKE.
         if(n.MAC(3).outputs.wframes(FF_PORT) > SLV(3,5)) then 
	    r.clk125.MACReady:='0';
         end if;

         if(ro.clk125.MACReady='0') then
           if(n.MAC(3).outputs.wframes(FF_PORT) > SLV(0,5)) then
             r.clk125.MACReady:='0';
           else
             r.clk125.MACReady:='1';
           end if;
         end if;
 
	 r.clk40.MACReady                 := ro.clk125.MACReady;
	 o.ETHLINKERROR                   := ro.clk125.ETHLINKERROR or ro.clk40.ETHLINKERROR;
	 o.MEPNum                         := ro.clk125.MEPNum                      ;
	 o.number_of_primitives           := ro.clk125.number_of_primitives        ;
	 o.counterLTU                     := ro.clk40.counterLTU                   ;
	 r.clk125.number_of_CHOKE         := ro.clk40.counterCHOKE                 ;     
	 r.clk125.number_of_ERROR         := ro.clk40.counterERROR                 ;     
	 o.counterCHOKE                   := ro.clk40.counterCHOKE                 ;
	 o.counterERROR                   := ro.clk40.counterERROR                 ;
	 o.periodicrandomtriggercounter   := ro.clk125.periodicrandomtriggercounter;
	 o.randomtriggercounter           := ro.clk125.randomtriggercounter        ;
	 o.Fixed_Latency_o                := ro.clk40.fixed_latency                ;
	 
	 o.LTU0                           := ro.clk40.LTU0       ;
	 o.LTU1                           := ro.clk40.LTU1       ;
	 o.LTU2                           := ro.clk40.LTU2       ;
	 o.LTU3                           := ro.clk40.LTU3       ;
	 o.LTU4                           := ro.clk40.LTU4       ;
	 o.LTU5                           := ro.clk40.LTU5       ;
	 o.LTU_TRIGGER                    := ro.clk40.LTU_TRIGGER;
	 
	 r.clk40.activate_synch           := i.activate_synch      ;
	 r.clk40.activate_clock20MHz      := i.activate_clock20MHz ;
	 r.clk40.fixed_latency            := i.Fixed_Latency       ;
	 
	 r.clk40.synch_signal             := i.synch_signal        ;  
         r.clk40.CHOKE_ON                 := i.CHOKE_ON or (not(ro.clk125.MACReady));
         r.clk40.CHOKE_OFF                := i.CHOKE_OFF  and ro.clk125.MACReady;
	 r.clk40.ERROR_ON                 := i.ERROR_ON            ;
	 r.clk40.ERROR_OFF                := i.ERROR_OFF           ;

	 r.clk125.active_triggers         := i.active_triggers     ;
	 r.clk125.calib_direction         := i.calib_direction     ;
	 r.clk125.calib_latency           := i.calib_latency       ;
	 r.clk125.activate_primitives     := i.activate_primitives ;
	 
	 r.clk125.periodic_triggerword0   := i.periodic_triggerword0;
	 r.clk125.periodic_triggerword1   := i.periodic_triggerword1;
	 r.clk125.random_triggerword      := i.random_triggerword   ;
	 
	 r.clk125.triggerword             := i.triggerword         ; 	
	 r.clk125.triggerword_calib       := i.triggerword_calib   ;  
	 
	 ----------------------------------------------------------
	 r.clk125.timestamp_physics        := i.timestamp_physics   ;  
	 r.clk125.timestamp_calib          := i.timestamp_calib     ;
	 
	 r.clk125.finetime_physics0         := i.finetime_physics0    ;
	 r.clk125.finetime_physics1         := i.finetime_physics1    ;
	 r.clk125.finetime_physics2         := i.finetime_physics2    ;
	 
	 
	 r.clk125.finetime_physics_ref     := i.finetime_physics_ref;  
	 r.clk125.finetime_calib           := i.finetime_calib      ;  
	 
	 r.clk125.primitiveID_t0           := i.primitiveID_t0    ;  
	 r.clk125.primitiveID_t1           := i.primitiveID_t1    ;  
	 r.clk125.primitiveID_t2           := i.primitiveID_t2    ;  
	 r.clk125.primitiveID_c            := i.primitiveID_c    ;  
	 
	 r.clk40.activate_SOBEOBtrigger     := i.activate_SOBEOBtrigger;
	 r.clk125.calibration_nim          := i.calibration_nim    ;  
	 r.clk125.trigger_signal     	   := i.trigger_signal     ;
	 r.clk125.control_signal     	   := i.control_signal     ;  
	 r.clk125.periodic_signal0     	   := i.periodic_signal0   ;	
	 r.clk125.periodic_signal1     	   := i.periodic_signal1   ;	
	 r.clk125.random_signal     	   := i.random_signal      ;	
	 r.clk125.calib_signal             := i.calib_signal       ;  
	 r.clk125.CHOKE_signal             := i.CHOKE_signal       ;  
	 r.clk125.ERROR_signal             := i.ERROR_signal       ;  
	 
	 r.clk125.CHOKE_OFF                := i.CHOKE_OFF and  ro.clk125.MACReady;    
	 r.clk125.CHOKE_ON                 := i.CHOKE_ON  or (not(ro.clk125.MACReady));    
	 r.clk125.ERROR_ON                 := i.ERROR_ON          ;  
	 r.clk125.ERROR_OFF                := i.ERROR_OFF         ;  
	 
	 
	 r.clk125.ntriggers_predownscaling           := i.ntriggers_predownscaling; --NO CUT (75 ns or less) 
	 r.clk125.ntriggers_postdownscaling          := i.ntriggers_postdownscaling; --(>75 ns)
	 r.clk125.ntriggers_postdownscaling_control  := i.ntriggers_postdownscaling_control;
	 r.clk125.ntriggers_predownscaling_control   := i.ntriggers_predownscaling_control;
	 r.clk125.temperature                        := i.temperature;
         
	 for index in 0 to nmask-1 loop
	    if i.enable_mask(index)='0' then
	       r.clk125.downscaling(index)  := (others=>'0')           ;
	       r.clk125.enable_mask(index):='0';
	    elsif i.enable_mask(index)='1' then
	       r.clk125.downscaling(index) := SLV(UINT(i.downscaling(index))+1,32);
	       r.clk125.enable_mask(index):='1';
	    end if;
	 end loop;

	 if i.activate_controltrigger = '0' then
	    r.clk125.control_trigger_downscaling :=(others=>'0');
	 else
	    r.clk125.control_trigger_downscaling := SLV(UINT(i.control_trigger_downscaling)+1,32);
	 end if;
	 
	 
	 for index in 0 to ethlink_NODES -2 loop
	    
	    n.FIFODELAY(index).inputs.data  :=(others=>'0');
	    n.FIFODELAY(index).inputs.aclr  :='0';
	    n.FIFODELAY(index).inputs.rdclk :=n.clk125;
	    n.FIFODELAY(index).inputs.wrclk :=n.clk125;
	    n.FIFODELAY(index).inputs.rdreq :='0';
	    n.FIFODELAY(index).inputs.wrreq :='0';
	 end loop; 


	 r.clk125.fifODELAY_set                  :=i.delay_set;
	 r.clk125.maximum_delay_detector         :=i.maximum_delay_detector;
	 
	 r.clk125.mask                           := i.mask;
	 r.clk125.dontcare                       := i.dontcare;
	 r.clk125.triggerflag                    := i.triggerflag;
	 r.clk125.finetime_bits                  := i.finetime_bits;
	 r.clk125.reference_detector             := i.reference_detector;
	 r.clk125.control_detector               := i.control_detector;
	 r.clk125.fixed_Latency125               := i.fixed_Latency;
	 r.clk125.write_ev125                    := ro.clk40.write_ev40 ;
	 r.clk125.ecounter125                    := ro.clk40.ecounter40 ;
	 
	 r.clk125.sob_ev125                      := ro.clk40.sob_ev40;
	 r.clk125.eob_ev125                      := ro.clk40.eob_ev40;  
	 
	 r.clk125.chokeOn_ev125                  := ro.clk40.chokeOn_ev40;
	 r.clk125.chokeOff_ev125                 := ro.clk40.chokeOff_ev40;
	 r.clk125.errorOn_ev125                  := ro.clk40.errorOn_ev40;
	 r.clk125.errorOff_ev125                 := ro.clk40.errorOff_ev40;
         
	 
	 FOR index IN 0 to SGMII_NODES-1 loop
	  
	    -- Note: there are some limitations about bidirectional buffers: bidir components
	    -- must be localized into top level entity so we create an i/o bus with sin/sout/sena  
	    
	    -- MAC clock, reset
	    n.MAC(index).inputs.ref_clk := n.clk125;         -- SGMII 1000 --> n.clk125
	    n.MAC(index).inputs.rst     := not i.cpu_resetn; -- async --> syncrst embedded into MAC
	    
	    -- MAC Avalon interface (indexed)
	    
	       n.MAC(index).inputs.clk := i.clkin_50; -- avalon bus clock (also CPU_PORT clock)
	       n.MAC(index).inputs.mmaddress   := (others=>'0');
	       n.MAC(index).inputs.mmread      := '0';
	       n.MAC(index).inputs.mmwrite     := '0';
	       n.MAC(index).inputs.mmwritedata := (others=>'0');
	     

	    -- MAC hardware address (indexed)
	    n.MAC(index).inputs.nodeaddr := ro.clk125.hwaddress;
	    n.MAC(index).inputs.nodeaddr(1 downto 0) := SLV(index, 2); -- !! DEBUG !! constant address indexed (0..3)
	    -- MAC multicast address (not used)
	    n.MAC(index).inputs.multicastaddr := "00000000";
	    
	    -- MAC CPU interface (0 --> interface OFF, 1..NPORTS --> interface ON)
	    n.MAC(index).inputs.CPUtxport := "0000";
	    n.MAC(index).inputs.CPUrxport := "0000";
	 
	    -- sgmii inputs (eth interface)
	    n.MAC(index).inputs.rxp := i.rxp(index);
	    
	    -- sgmii outputs (eth interface)
	    o.txp(index) := n.MAC(index).outputs.txp;
	    
	    -- sgmii phy async reset -- 
	    o.resetn := i.cpu_resetn;

	 END LOOP;

	 --
	 -- 'RGMII_NODES' interfaces 
	 -- 
	 FOR index IN 0 to RGMII_NODES-1 LOOP

	    n.enet_MAC(index).inputs.ref_clk := n.clk125;         -- RGMII 1000 --> n.clk125
	    n.enet_MAC(index).inputs.rst     := not i.cpu_resetn; -- async --> syncrst embedded into MAC
	    
	    n.enet_MAC(index).inputs.clk         := i.clkin_50; -- avalon bus clock (also CPU_PORT clock)
	    n.enet_MAC(index).inputs.mmaddress   := (others=>'0');
	    n.enet_MAC(index).inputs.mmread      := '0';
	    n.enet_MAC(index).inputs.mmwrite     :='0';
	    n.enet_MAC(index).inputs.mmwritedata := (others=>'0');
	  
	    -- MAC hardware address (indexed)
	    n.enet_MAC(index).inputs.nodeaddr := SLV(UINT(ro.clk125.hwaddress) + 4, 8); -- RGMII maps to hwaddress + 4 (max 4 + 4 nodes)
	    n.enet_MAC(index).inputs.nodeaddr(1 downto 0) := SLV(index, 2); -- !! DEBUG !! constant address indexed (0..3)
	    -- MAC multicast address (not used)
	    n.enet_MAC(index).inputs.multicastaddr := "00000000";

	    -- MAC CPU interface (0 --> interface OFF, 1..NPORTS --> interface ON)
	    n.enet_MAC(index).inputs.CPUtxport := "0000";
	    n.enet_MAC(index).inputs.CPUrxport := "0000";
	 
	    
	    -- rgmii inputs (enet interface)
	    n.enet_MAC(index).inputs.rxc := i.enet_rx_clk(index);
	    n.enet_MAC(index).inputs.rx_ctl := i.enet_rx_dv(index);
	    n.enet_MAC(index).inputs.rd := i.enet_rx_d(index)(3 downto 0);
	    -- rgmii --> i.enet_rx_d(7 downto 4) not used
	    -- rgmii --> i.enet_rx_er not used
	    
	    -- rgmii outputs (enet interface)
	    o.enet_gtx_clk(index) := n.enet_MAC(index).outputs.txc;
	    o.enet_tx_en(index)   := n.enet_MAC(index).outputs.tx_ctl;
	    o.enet_tx_er(index)   := '0';                            -- rgmii --> tx_er = gnd
	    o.enet_tx_d(index)(3 downto 0) := n.enet_MAC(index).outputs.td; 
	    o.enet_tx_d(index)(7 downto 4) := "0000";                -- rgmii --> td_d(7..4) = gnd
	    
	    -- rgmii phy async reset -- ...da fare: logica di reset pulse 1s...
	    o.enet_resetn(index) := i.cpu_resetn;

	 END LOOP;

	 -- SGMII MAC inputs default values (wclk,wrst applied for Framegen operations)
	 FOR index IN 0 to SGMII_NODES - 1 LOOP
	    FOR p IN 1 to RX_NPORTS LOOP
	       n.MAC(index).inputs.rack(p) := '0';
	       n.MAC(index).inputs.rreq(p) := '0';
	       n.MAC(index).inputs.rena(p) := '0';
	       n.MAC(index).inputs.rclk(p) := '0';
	       n.MAC(index).inputs.rrst(p) := '0';
	    END LOOP;
	    --
	    FOR p IN 1 to TX_NPORTS LOOP
	       n.MAC(index).inputs.wtxclr(p)     := '0';
	       n.MAC(index).inputs.wtxreq(p)     := '0';
	       n.MAC(index).inputs.wmulticast(p) := '0';
	       n.MAC(index).inputs.wdestaddr(p)  := "00000000";
	       n.MAC(index).inputs.wdestport(p)  := "0000";
	       n.MAC(index).inputs.wframelen(p)  := "00000000000";
	       n.MAC(index).inputs.wdata(p)      := (others => '0');
	       n.MAC(index).inputs.wreq(p)       := '0';
	       n.MAC(index).inputs.wena(p)       := '0';
	       n.MAC(index).inputs.wclk(p)       := n.clk125;
	       n.MAC(index).inputs.wrst(p)       := n.rst.clk125;
	    END LOOP;     
	 END LOOP;
	 
	 -- RGMII MAC inputs default values (wclk,wrst applied for Framegen operations)
	 FOR index IN 0 to RGMII_NODES - 1 LOOP
	    FOR p IN 1 to RX_NPORTS LOOP
	       n.enet_MAC(index).inputs.rack(p) := '0';
	       n.enet_MAC(index).inputs.rreq(p) := '0';
	       n.enet_MAC(index).inputs.rena(p) := '0';
	       n.enet_MAC(index).inputs.rclk(p) := '0';
	       n.enet_MAC(index).inputs.rrst(p) := '0';
	    END LOOP;
	    --
	    FOR p IN 1 to TX_NPORTS LOOP
	       n.enet_MAC(index).inputs.wtxclr(p)     := '0';
	       n.enet_MAC(index).inputs.wtxreq(p)     := '0';
	       n.enet_MAC(index).inputs.wmulticast(p) := '0';
	       n.enet_MAC(index).inputs.wdestaddr(p)  := "00000000";
	       n.enet_MAC(index).inputs.wdestport(p)  := "0000";
	       n.enet_MAC(index).inputs.wframelen(p)  := "00000000000";
	       n.enet_MAC(index).inputs.wdata(p)      := (others => '0');
	       n.enet_MAC(index).inputs.wreq(p)       := '0';
	       n.enet_MAC(index).inputs.wena(p)       := '0';
	       n.enet_MAC(index).inputs.wclk(p)       := n.clk125;
	       n.enet_MAC(index).inputs.wrst(p)       := n.rst.clk125;
	    END LOOP;     
	 END LOOP;


-- Parte Stefan test registro

            r.clk125.s_rit  := i.rit_port;
	 
      end procedure;
--
-- Rxdata procedure (edit)
--SGMII
-- clock domain: 125MHz
--
--DATAFORMAT:

      -- MTP Header: SourceID (31 downto 24) | MTP timestamp high (24 downto 0)
      --             SubSourceID (31 downto 24) | #primitives (23 downto 16) | MTPlength (15 downto 0)
      --TimestampWord: 0x00000000 | Primitive timestamp high
      --PrimitiveDaeta: PrimitiveID (31 downto 16)| Timestamp low (15 downto 8) | finetime (7 downto 0)
      
      procedure SubReceive32bit
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin

	 FOR index IN 0 to SGMII_NODES-2 LOOP  --(indici 0, 1, 2)ehternet port 3 usata per spedire e non per ricevere
	    
	    n.FIFODELAY(index).inputs.data           :=(others=>'0');
	    n.FIFODELAY(index).inputs.aclr           :='0';
	    n.FIFODELAY(index).inputs.wrclk          :=n.clk125;
	    n.FIFODELAY(index).inputs.wrreq          :='0';
	    
	    
	    n.MAC(index).inputs.wframelen(FF_PORT)  := SLV(1472, 11); -- UDP payload max = (46..1500)-(IP(20)+UDP(8)) = 18..1472 byte
	    n.MAC(index).inputs.wmulticast(FF_PORT) := '0';
	    
	    n.MAC(index).outputs.rsrcport(FF_PORT):= SLV(2,4);
	    if index =0 then
	       n.MAC(index).outputs.rsrcaddr(FF_PORT)  :=SLV(4,8);
	    end if;
	    if index =1 then
	       n.MAC(index).outputs.rsrcaddr(FF_PORT) :=SLV(5,8);
	    end if;
	    if index =2 then
	       n.MAC(index).outputs.rsrcaddr(FF_PORT)   :=SLV(6,8);
	    end if;
	    
	    -- Rx FF_PORT defaults
	    n.MAC(index).inputs.rack(FF_PORT)       := '0';
	    n.MAC(index).inputs.rreq(FF_PORT)       := '0';
	    n.MAC(index).inputs.rena(FF_PORT)       := ro.rena(index);
	    n.MAC(index).inputs.rclk(FF_PORT)       := n.clk125;
	    n.MAC(index).inputs.rrst(FF_PORT)       := n.rst.clk125;
	 end loop;
	 
	 FOR index IN 0 to SGMII_NODES-2 LOOP  
	    case ro.FSMReceive32bit(index) is
	       when S0 =>
		  if(ro.dataformat(index)='0') then
		     r.FSMReceive32bit(index) := S0;
		  else
		     r.FSMReceive32bit(index) := S1;
		  end if;
	       when S1 =>
		  r.rena(index):='1';
		  r.FSMReceive32bit(index) := S2;
	       when S2 =>
		  
		  -----	waiting for new frame:
		  if n.MAC(index).outputs.rready(FF_PORT) = '1' then
		     if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
			n.MAC(index).inputs.rreq(FF_PORT) := '1'; --Read request to get the first byte
			r.headermode(index) :='1';
			r.headerreceived(index):='0';
			r.FSMReceive32bit(index) := S3_1;
		     else
			if n.FIFODELAY(index).outputs.wrfull ='0' then
			   n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			   n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			   r.FSMReceive32bit(index) := S4;
			else
			   r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(1,32);
			   r.FSMReceive32bit(index) := S4;
			end if; --fifo full
		     end if;--EOF
		  else
		     null;      
		  end if; --MAC not Ready
		  
	       when S3_1 =>
		  r.data0(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 0
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1';    
		     r.FSMReceive32bit(index):=S3_2;
		  else
		     
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive32bit(index) := S4;
		     else
			r.FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		     r.FSMReceive32bit(index) := S2;
		  end if;
		  
	       when S3_2 =>
		  r.data1(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 1	
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive32bit(index):=S3_3;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive32bit(index) := S4;
		     else
			r.FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;

		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive32bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
	       when S3_3 =>
		  r.data2(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 2
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive32bit(index):=S3_4;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive32bit(index) := S4;
		     else
			r.FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive32bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
		  
	     
	   	when S3_4 =>

		  if ro.headermode(index) ='1' then
		     r.headerreceived(index) := '1';
		     r.headermode(index) :='0';
		     r.MTPTimestampH(index)(23 downto 16):=ro.data2(index);
		     r.MTPTimestampH(index)(15 downto 8) :=ro.data1(index);
		     r.MTPTimestampH(index)(7 downto 0)  :=ro.data0(index);
		     r.MTPSourceID(index):= n.MAC(index).outputs.rdata(FF_PORT);
		     r.FSMReceive32bit(index) := S3_loop;
		  
		  else
                    if(ro.headerreceived(index)='1') then
			r.headerreceived(index):='0';                        
			---------STO SCRIVENDO L'HEADER-------------------------------
			if ro.activate_primitives ='1' then
			   if n.FIFoDELAY(index).outputs.wrfull = '0' then
			      n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto i dati	
			      n.FIFODELAY(index).inputs.data(63):='1'; --mi dice che
								    --e' un header
			      n.FIFODELAY(index).inputs.data(62 downto 56):= n.MAC(index).outputs.rdata(FF_PORT)(6 downto 0);--subid   
			      n.FIFODELAY(index).inputs.data(55 downto 48):= ro.data2(index); --#primitive   
			      n.FIFODELAY(index).inputs.data(47 downto 40):= ro.data1(index); --length 
			      n.FIFODELAY(index).inputs.data(39 downto 32):= ro.data0(index); --length
			      n.FIFODELAY(index).inputs.data(31 downto 24):= ro.MTPSourceID(index);
			      n.FIFODELAY(index).inputs.data(23 downto 16):= ro.MTPTimestampH(index)(23 downto 16); --timestamp
			      n.FIFODELAY(index).inputs.data(15 downto 8) := ro.MTPTimestampH(index)(15 downto 8); --timestamp
			      n.FIFODELAY(index).inputs.data(7 downto 0)  := ro.MTPTimestampH(index)(7 downto 0); --timestamp
			      r.FSMReceive32bit(index) := S3_loop;
			   else --FIFO PIENA
			      r.FSMReceive32bit(index) := S3_loop;
			      r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			   end if;--wrfull
			end if;--activate primitives;
	             else --it is not header
			--------SONO PRIMITIVE, NO HEADER---------------------------------
			if ro.activate_primitives ='1' then
			   if n.MAC(index).outputs.rdata(FF_PORT) /= "00000000" then --primitive ID valid.
			      r.number_of_primitives(index) := SLV(UINT(ro.number_of_primitives(index))+1,32);
			      if n.FIFoDELAY(index).outputs.wrfull = '0' then
				 n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto i dati	
				 n.FIFODELAY(index).inputs.data(63):='0'; --mi dice che sono dati				  
				 n.FIFODELAY(index).inputs.data(62 downto 32):= ro.MTPTimestampH(index)(22 downto 0) &  ro.data1(index); --timestamp
				 n.FIFODELAY(index).inputs.data(31 downto 24):= n.MAC(index).outputs.rdata(FF_PORT);--primID 
				 n.FIFODELAY(index).inputs.data(23 downto 16):= ro.data2(index); --primID   
				 n.FIFODELAY(index).inputs.data(15 downto 8) := (others=>'0');--reserved
				 n.FIFODELAY(index).inputs.data(7 downto 0)  := ro.data0(index); --finetime 
				 r.FSMReceive32bit(index) := S3_loop;
			      else --FIFO PIENA
				 r.FSMReceive32bit(index) := S3_loop;
				 r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			      end if;--wrfull
			   else --primitive ID invalid
			       r.MTPTimestampH(index) := ro.data2(index) & ro.data1(index) & ro.data0(index);
			      r.FSMReceive32bit(index) := S3_loop;
			   end if; --primitiveID
			else
			   r.FSMReceive32bit(index) := S3_loop;
			end if;--activate primitive
		     end if;-- header received
                  end if;--header mode

		  
	       when S3_loop =>
		 	 
		  if n.MAC(index).outputs.reoframe(FF_PORT)='0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1';
		     r.FSMReceive32bit(index) := S3_1;
		  else 		   
		     if ro.activate_primitives ='1' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF			
			r.FSMReceive32bit(index) := S4; 
		     else
			r.FSMReceive32bit(index) := S4; 
		     end if;
		  end if;
		  
		  if n.MAC(index).outputs.rready(FF_PORT) ='0' then
		     r.FSMReceive32bit(index) := S2;
		  end if;		  
		     
	       when S4 => --END OF FRAME
		  if n.MAC(index).outputs.rready(FF_PORT) = '1' then  
		     n.MAC(index).inputs.rack(FF_PORT) := '1';
		  else
		     null;
		  end if;
		  r.FSMReceive32bit(index) := S1;
	    end case;
	 END LOOP;
      end procedure;
      
      
--
-- Rxdata procedure (edit)
--
-- clock domain: rxclock
--
      procedure SubReceiveRGMII32bit
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin

	 
		 FOR index IN 0 to RGMII_NODES-1 LOOP  --(4-7)ehternet port 3 usata per spedire e non per ricevere
	    
	    n.FIFODELAY(index+3).inputs.data           :=(others=>'0');
	    n.FIFODELAY(index+3).inputs.aclr           :='0';
	    n.FIFODELAY(index+3).inputs.wrclk          :=n.clk125;
	    n.FIFODELAY(index+3).inputs.wrreq          :='0';
	    
	    n.enet_MAC(index).inputs.wframelen(FF_PORT)  := SLV(1472, 11); -- UDP payload max = (46..1500)-(IP(20)+UDP(8)) = 18..1472 byte
	    n.enet_MAC(index).inputs.wmulticast(FF_PORT) := '0';
	    n.enet_MAC(index).outputs.rsrcport(FF_PORT):= SLV(2,4);

	    if index = 0 then
	       n.enet_MAC(index).outputs.rsrcaddr(FF_PORT)  :=SLV(8,8);
	    end if;
	    if index = 1 then
	       n.enet_MAC(index).outputs.rsrcaddr(FF_PORT) :=SLV(9,8);
	    end if;
	    if index = 2 then
	       n.enet_MAC(index).outputs.rsrcaddr(FF_PORT)   :=SLV(10,8);
	    end if;
	    if index = 3 then
	       n.enet_MAC(index).outputs.rsrcaddr(FF_PORT)   :=SLV(11,8);
	    end if;
	    -- Rx FF_PORT defaults
	    n.enet_MAC(index).inputs.rack(FF_PORT)       := '0';
	    n.enet_MAC(index).inputs.rreq(FF_PORT)       := '0';
	    n.enet_MAC(index).inputs.rena(FF_PORT)       := ro.enet_rena(index);
	    n.enet_MAC(index).inputs.rclk(FF_PORT)       := n.clk125;
	    n.enet_MAC(index).inputs.rrst(FF_PORT)       := n.rst.clk125;
	 end loop;
	 
	 FOR index IN 0 to RGMII_NODES-1 LOOP  
	    case ro.enet_FSMReceive32bit(index) is
	        when S0 =>
		  if(ro.dataformat(index)='0') then --Data Format:
						    --0: 64 bit;
						    --1: 32 bit.
		     
		     r.enet_FSMReceive32bit(index) := S0;
		  else
		     r.enet_FSMReceive32bit(index) := S1;
		  end if;
		  
	       when S1 =>
		  r.enet_rena(index):='1';
		  r.enet_FSMReceive32bit(index) := S2;
		  
	       when S2 =>
		  -----	waiting for new frame:
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '1' then
		     if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
			n.enet_MAC(index).inputs.rreq(FF_PORT) := '1'; --Read request to get the first byte
			r.enet_headermode(index) :='1'; --First 8 bytes: header.
		        r.enet_headerreceived(index):='0'; -- To continue from
							   -- 4 to 8 bytes of
							   -- the header.
			r.enet_FSMReceive32bit(index) := S3_1;
		     else
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive32bit(index) := S4;
		     end if;
		  else
		     null;      
		  end if; 
		  
	       when S3_1 =>
		  r.enet_data0(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 0
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1';    
		     r.enet_FSMReceive32bit(index):=S3_2;
		  else
		     
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive32bit(index) := S4;
		     else			
			r.enet_FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		     
		  end if;
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive32bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_2 =>
		  r.enet_data1(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 1
		  
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive32bit(index):=S3_3;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive32bit(index) := S4;
		     else			
			r.enet_FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive32bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_3 =>
		  r.enet_data2(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 2
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive32bit(index):=S3_4;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive32bit(index) := S4;
		     else			
			r.enet_FSMReceive32bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive32bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       	  
	       when S3_4 =>

		 if ro.enet_headermode(index) ='1' then
		     r.enet_headerreceived(index) := '1';
		     r.enet_headermode(index) :='0';
		     r.enet_MTPTimestampH(index)(23 downto 16):=ro.enet_data2(index);
		     r.enet_MTPTimestampH(index)(15 downto 8) :=ro.enet_data1(index);
		     r.enet_MTPTimestampH(index)(7 downto 0)  :=ro.enet_data0(index);
		     r.enet_MTPSourceID(index):=  n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 2
		     r.enet_FSMReceive32bit(index) := S3_loop;   
                 else
                   
		      if(ro.enet_headerreceived(index)='1') then
			r.enet_headerreceived(index):='0';
			if ro.activate_primitives ='1' then
			   if n.FIFODELAY(index+3).outputs.wrfull = '0' then
			      n.FIFODELAY(index+3).inputs.wrreq :='1'; -- data written
			      n.FIFODELAY(index+3).inputs.data(63):='1'; -- header
								      -- tagger							  
			   --sub id is written without the MSB, in order to
			   --save space for the header tagger
			      n.FIFODELAY(index+3).inputs.data(62 downto 56):= n.enet_MAC(index).outputs.rdata(FF_PORT)(6 downto 0); --subid 
			      n.FIFODELAY(index+3).inputs.data(55 downto 48):= ro.enet_data2(index); --#primitive  
			      n.FIFODELAY(index+3).inputs.data(47 downto 40):= ro.enet_data1(index); --length 
			      n.FIFODELAY(index+3).inputs.data(39 downto 32):= ro.enet_data0(index); --length
			      n.FIFODELAY(index+3).inputs.data(31 downto 24):= ro.enet_MTPSourceID(index);
			      n.FIFODELAY(index+3).inputs.data(23 downto 16):= ro.enet_MTPTimestampH(index)(23 downto 16); --timestamp
			      n.FIFODELAY(index+3).inputs.data(15 downto 8) := ro.enet_MTPTimestampH(index)(15 downto 8); --timestamp
			      n.FIFODELAY(index+3).inputs.data(7 downto 0)  := ro.enet_MTPTimestampH(index)(7 downto 0); --timestamp
			      r.enet_FSMReceive32bit(index) := S3_loop;
			   else
			      r.enet_FSMReceive32bit(index) := S3_loop;
			      r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			   end if;--wrfull
			end if;--activate primitives
			
	             else --header received ='0'
                           ------STO SCRIVENDO LE PRIMITIVE
			if ro.activate_primitives ='1' then
			   if n.enet_MAC(index).outputs.rdata(FF_PORT) /="00000000" then --primitive ID /=0
			      r.number_of_primitives(index+3) := SLV(UINT(ro.number_of_primitives(index+3))+1,32);
			      if n.FIFODELAY(index+3).outputs.wrfull = '0' then
				 n.FIFODELAY(index+3).inputs.wrreq   :='1'; --ho scritto i dati	
				 n.FIFODELAY(index+3).inputs.data(63):='0'; --header tagger		  
				 n.FIFODELAY(index+3).inputs.data(62 downto 32):= ro.enet_MTPTimestampH(index)(22 downto 0) &  ro.enet_data1(index); --timestamp
				 n.FIFODELAY(index+3).inputs.data(31 downto 24):= n.enet_MAC(index).outputs.rdata(FF_PORT); --primID
				 n.FIFODELAY(index+3).inputs.data(23 downto 16):= ro.enet_data2(index); --primID   
				 n.FIFODELAY(index+3).inputs.data(15 downto 8) := (others=>'0'); --reserved
				 n.FIFODELAY(index+3).inputs.data(7 downto 0)  := ro.enet_data0(index); --finetime 
				 r.enet_FSMReceive32bit(index) := S3_loop;
			      else
				 r.enet_FSMReceive32bit(index) := S3_loop;
				 r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			      end if;--wrfull
			   else -- primitive invalid
                              r.enet_MTPTimestampH(index) := ro.enet_data2(index) & ro.enet_data1(index) & ro.enet_data0(index);
			      r.enet_FSMReceive32bit(index) := S3_loop;
			   end if;	---primitiveID
			else --primitive not active
			   r.enet_FSMReceive32bit(index) := S3_loop;
			end if;--activate primitive
                       end if;--header received
		     end if;-- header mode
		      
		

	       when S3_loop =>
		 	  
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT)='0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1';
		     r.enet_FSMReceive32bit(index) := S3_1;
		  else 		   
 		     if ro.activate_primitives ='1' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF			
			r.enet_FSMReceive32bit(index) := S4; 
		     else
			r.enet_FSMReceive32bit(index) := S4; 
		     end if;
		  end if; 
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) ='0' then
		     r.enet_FSMReceive32bit(index) := S2;
		  end if;
		  
	       		
			
	       when S4 => --END OFF RAME
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '1' then  
		     n.enet_MAC(index).inputs.rack(FF_PORT) := '1';
		  else
		     null;
		  end if;
		  r.enet_FSMReceive32bit(index) := S1;
	    end case;
	 END LOOP;
      end procedure;


      --------64 bit receiving logic:----------
            procedure SubReceive64bit
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin
--I default sono gia' messi nella procedura a 32 bit

	 FOR index IN 0 to SGMII_NODES-2 LOOP  
	    case ro.FSMReceive64bit(index) is
	       when S0 =>
		  if(ro.dataformat(index)='0') then
		     r.FSMReceive64bit(index) := S1;
		  else
		     r.FSMReceive64bit(index) := S0;
		  end if;
	       when S1 =>
		  r.rena(index):='1';
		  r.FSMReceive64bit(index) := S2;
	       when S2 =>
		  
		  -----	waiting for new frame:
		  if n.MAC(index).outputs.rready(FF_PORT) = '1' then
		     if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
			n.MAC(index).inputs.rreq(FF_PORT) := '1'; --Read request to get the first byte
			r.headermode(index) :='1';
			r.FSMReceive64bit(index) := S3_1;
		     else
			if n.FIFODELAY(index).outputs.wrfull ='0' then
			   n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			   n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			   r.FSMReceive64bit(index) := S4;
			else
			   r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(1,32);
			   r.FSMReceive64bit(index) := S4;
			end if;
		     end if;
		  else
		     null;      
		  end if; 
		  
	       when S3_1 =>
		  r.data0(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 0
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1';    
		     r.FSMReceive64bit(index):=S3_2;
		  else
		     
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		     r.FSMReceive64bit(index) := S2;
		  end if;
		  
	       when S3_2 =>
		  r.data1(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 1	
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_3;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;

		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
	       when S3_3 =>
		  r.data2(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 2
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_4;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
		  
	       when S3_4 =>
		  r.data3(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 3
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_5;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
		  
	       when S3_5 =>
		  r.data4(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 4
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_6;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		     
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
		  
	       when S3_6 =>
		  r.data5(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 5
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_7;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
		  
	       when S3_7 =>
		  r.data6(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 6
		  if n.MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.FSMReceive64bit(index):=S3_8;
		  else
		     if n.FIFODELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF		
			r.FSMReceive64bit(index) := S4;
		     else
			r.FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2,32);
		  end if;
	       when S3_8 =>
		  r.data7(index) := n.MAC(index).outputs.rdata(FF_PORT); --byte 7
		  if ro.headermode(index) ='1' then
		     r.FSMReceive64bit(index) := S5_header;
		  else
		     r.FSMReceive64bit(index) := S5_write;
		  end if;
		  
	       when S5_header=> --registers for saving header data
		  if ro.activate_primitives ='1' then
		     if n.FIFoDELAY(index).outputs.wrfull ='0' then
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'header	
			n.FIFODELAY(index).inputs.data(63):='1'; --mi dice che e' un header
			n.FIFODELAY(index).inputs.data(62 downto 56):=ro.data7(index)(6 downto 0);
			n.FIFODELAY(index).inputs.data(55 downto 48):=ro.data6(index);
			n.FIFODELAY(index).inputs.data(47 downto 40):=ro.data5(index);
			n.FIFODELAY(index).inputs.data(39 downto 32):=ro.data4(index);
			n.FIFODELAY(index).inputs.data(31 downto 24):=ro.data3(index);
			n.FIFODELAY(index).inputs.data(23 downto 16):=ro.data2(index);
			n.FIFODELAY(index).inputs.data(15 downto 8) :=ro.data1(index);
			n.FIFODELAY(index).inputs.data(7 downto 0)  :=ro.data0(index);
			r.FSMReceive64bit(index) := S3_loop;
		     else
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
			r.FSMReceive64bit(index) := S3_loop;
		     end if;

		  else
		     r.FSMReceive64bit(index) := S3_loop;
		  end if;--activate_primitives

		  
	       when S3_loop =>
		  r.headermode(index) :='0';	 
		  if n.MAC(index).outputs.reoframe(FF_PORT)='0' then
		     n.MAC(index).inputs.rreq(FF_PORT):='1';
		     r.FSMReceive64bit(index) := S3_1;
		  else 		   
		     if ro.activate_primitives ='1' then
			n.FIFODELAY(index).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto l'EOF			
			r.FSMReceive64bit(index) := S4; 
		     else
			r.FSMReceive64bit(index) := S4; 
		     end if;
		  end if;
		  
		  if n.MAC(index).outputs.rready(FF_PORT) ='0' then
		     r.FSMReceive64bit(index) := S2;
		  end if;
		  
	       when S5_write =>-----------------LI SCRIVO 1 ----------------
		  
		  r.number_of_primitives(index) := SLV(UINT(ro.number_of_primitives(index))+1,32);

		  if ro.activate_primitives ='1' then
		     if ro.data3(index)/="00000000" or ro.data2(index)/="00000000" then --primitive ID /=0
			if n.FIFoDELAY(index).outputs.wrfull = '0' then
			   n.FIFODELAY(index).inputs.wrreq :='1'; --ho scritto i dati	
			   n.FIFODELAY(index).inputs.data(63):='0'; --mi dice che sono dati
			   n.FIFODELAY(index).inputs.data(62 downto 56):=ro.data7(index)(6 downto 0); --timestamp
			   n.FIFODELAY(index).inputs.data(55 downto 48):=ro.data6(index); --timestamp
			   n.FIFODELAY(index).inputs.data(47 downto 40):=ro.data5(index); --timestamp
			   n.FIFODELAY(index).inputs.data(39 downto 32):=ro.data4(index); --timestamp
			   n.FIFODELAY(index).inputs.data(31 downto 24):=ro.data3(index); --primID   
			   n.FIFODELAY(index).inputs.data(23 downto 16):=ro.data2(index); --primID   
			   n.FIFODELAY(index).inputs.data(15 downto 8) :=ro.data1(index); --reserved 
			   n.FIFODELAY(index).inputs.data(7 downto 0)  :=ro.data0(index); --finetime 
			   r.FSMReceive64bit(index) := S3_loop;
			else
			   r.FSMReceive64bit(index) := S3_loop;
			   r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			end if;--wrfull
		     else
			r.FSMReceive64bit(index) := S3_loop;
		     end if;	---primitiveID
		  else
		     r.FSMReceive64bit(index) := S3_loop;
		  end if;--activate primitive

	       when S4 => --END OF FRAME
		  if n.MAC(index).outputs.rready(FF_PORT) = '1' then  
		     n.MAC(index).inputs.rack(FF_PORT) := '1';
		  else
		     null;
		  end if;
		  r.FSMReceive64bit(index) := S1;
	    end case;
	 END LOOP;
      end procedure;
      
      
--
-- Rxdata procedure (edit)
--
-- clock domain: rxclock
--
      procedure SubReceiveRGMII64bit
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin
	 
	 FOR index IN 0 to RGMII_NODES-1 LOOP  
	    case ro.enet_FSMReceive64bit(index) is
	        when S0 =>
		  if(ro.dataformat(index)='0') then
		     r.enet_FSMReceive64bit(index) := S1;
		  else
		     r.enet_FSMReceive64bit(index) := S0;
		  end if;
		  
	       when S1 =>
		  r.enet_rena(index):='1';
		  r.enet_FSMReceive64bit(index) := S2;
		  
	       when S2 =>
		  -----	waiting for new frame:
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '1' then
		     if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
			n.enet_MAC(index).inputs.rreq(FF_PORT) := '1'; --Read request to get the first byte
			r.enet_headermode(index) :='1';
			r.enet_FSMReceive64bit(index) := S3_1;
		     else
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     end if;
		  else
		     null;      
		  end if; 
		  
	       when S3_1 =>
		  r.enet_data0(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 0
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1';    
		     r.enet_FSMReceive64bit(index):=S3_2;
		  else
		     
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		     
		  end if;
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_2 =>
		  r.enet_data1(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 1
		  
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_3;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_3 =>
		  r.enet_data2(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 2
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_4;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_4 =>
		  r.enet_data3(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 3
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_5;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);	
		     r.enet_FSMReceive64bit(index) := S2;
		  end if;
		  
	       when S3_5 =>
		  r.enet_data4(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 4
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_6;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_6 =>
		  r.enet_data5(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 5
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_7;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.enet_FSMReceive64bit(index) := S2;
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		  end if;
		  
	       when S3_7 =>
		  r.enet_data6(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 6
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT) = '0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1'; 
		     r.enet_FSMReceive64bit(index):=S3_8;
		  else
		     if n.FIFODELAY(index+3).outputs.wrfull ='0' then
			n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF
			r.enet_FSMReceive64bit(index) := S4;
		     else			
			r.enet_FSMReceive64bit(index) := S4;
			r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		  end if;
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '0' then
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4,32);
		     r.enet_FSMReceive64bit(index) := S2;
		  end if;
		  
	       when S3_8 =>
		  r.enet_data7(index) := n.enet_MAC(index).outputs.rdata(FF_PORT); --byte 7
		  if ro.enet_headermode(index) ='1' then
		     r.enet_FSMReceive64bit(index) := S5_header;
		  else
		     r.enet_FSMReceive64bit(index) := S5_write;
		  end if;
		  
	       when S5_header=> --registers for saving header data

		  if ro.activate_primitives ='1' then	
		     if n.FIFODELAY(index+3).outputs.wrfull = '0' then
			n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'header	
			n.FIFODELAY(index+3).inputs.data(63):='1'; --mi dice che e' un header
			n.FIFODELAY(index+3).inputs.data(62 downto 56):=ro.enet_data7(index)(6 downto 0); --SubSourceID
			n.FIFODELAY(index+3).inputs.data(55 downto 48):=ro.enet_data6(index);--number of primitives
			n.FIFODELAY(index+3).inputs.data(47 downto 40):=ro.enet_data5(index);--Length
			n.FIFODELAY(index+3).inputs.data(39 downto 32):=ro.enet_data4(index);--Length 
			n.FIFODELAY(index+3).inputs.data(31 downto 24):=ro.enet_data3(index);--SourceID
			n.FIFODELAY(index+3).inputs.data(23 downto 16):=ro.enet_data2(index);--timestampH
			n.FIFODELAY(index+3).inputs.data(15 downto 8) :=ro.enet_data1(index);--timestampH 
			n.FIFODELAY(index+3).inputs.data(7 downto 0)  :=ro.enet_data0(index);--timestampH 
			r.enet_FSMReceive64bit(index) := S3_loop;
		     else
			r.enet_FSMReceive64bit(index) := S3_loop;
			r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
		     end if;
		     
		  else
		     r.enet_FSMReceive64bit(index) := S3_loop;				
		  end if;
		  
	       when S3_loop =>
		  
		  r.enet_headermode(index) :='0';
		  
		  --in questo modo escludo tutte le parti del pacchetto IP dopo i dati
		  if n.enet_MAC(index).outputs.reoframe(FF_PORT)='0' then
		     n.enet_MAC(index).inputs.rreq(FF_PORT):='1';
		     r.enet_FSMReceive64bit(index) := S3_1;
		  else
		     
		     n.FIFODELAY(index+3).inputs.data :=("0111111111111111111111111111111111111111111111111111111111111111");
		     n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto l'EOF	
		     r.enet_FSMReceive64bit(index) := S4; 
		  end if;
		  
		  if n.enet_MAC(index).outputs.rready(FF_PORT) ='0' then
		     r.enet_FSMReceive64bit(index) := S2;
		  end if;
		  
	       when S5_write =>-----------------LI SCRIVO 1 ----------------
		  
		  r.number_of_primitives(index+3) := SLV(UINT(ro.number_of_primitives(index+3))+1,32);
		  
		  if ro.activate_primitives ='1' then 
		     if ro.enet_data3(index) /="00000000" or ro.enet_data2(index) /="00000000" then
			if n.FIFODELAY(index+3).outputs.wrfull = '0' then
			   n.FIFODELAY(index+3).inputs.wrreq :='1'; --ho scritto i dati	
			   n.FIFODELAY(index+3).inputs.data(63):='0'; --mi dice che sono dati
			   n.FIFODELAY(index+3).inputs.data(62 downto 56):=ro.enet_data7(index)(6 downto 0); --timestamp
			   n.FIFODELAY(index+3).inputs.data(55 downto 48):=ro.enet_data6(index); --timestamp
			   n.FIFODELAY(index+3).inputs.data(47 downto 40):=ro.enet_data5(index); --timestamp
			   n.FIFODELAY(index+3).inputs.data(39 downto 32):=ro.enet_data4(index); --timestamp
			   n.FIFODELAY(index+3).inputs.data(31 downto 24):=ro.enet_data3(index); --primID         
			   n.FIFODELAY(index+3).inputs.data(23 downto 16):=ro.enet_data2(index); --primID     
			   n.FIFODELAY(index+3).inputs.data(15 downto 8) :=ro.enet_data1(index); --reserved    
			   n.FIFODELAY(index+3).inputs.data(7 downto 0)  :=ro.enet_data0(index); --finetime    
			   r.enet_FSMReceive64bit(index) := S3_loop;
			else
			   r.enet_FSMReceive64bit(index) := S3_loop;
			   r.ETHLINKERROR:=ro.ETHLINKERROR OR SLV(1,32);
			end if;--wrfull
		     else
			r.enet_FSMReceive64bit(index) := S3_loop;
		     end if;--primitive ID
		  else
		     r.enet_FSMReceive64bit(index) := S3_loop;
		  end if;	--activate_primitives
		  
	       when S4 => --END OFF RAME
		  if n.enet_MAC(index).outputs.rready(FF_PORT) = '1' then  
		     n.enet_MAC(index).inputs.rack(FF_PORT) := '1';
		  else
		     null;
		  end if;
		  r.enet_FSMReceive64bit(index) := S1;
	    end case;
	 END LOOP;
      end procedure;


--Delay logic: To align packets 
      procedure SubReadFIFODelay
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    
	    ) is
      begin

	 o.MTPNUMREF                     :=(others=>"00000000");
	 o.packet_received            :='0';

	 for index in 0 to ethlink_NODES-2 loop

	    o.received_signal(index)     := '0';
	    o.timestamp(index)           := "00000000000000000000000000000000";	
	    o.finetime(index)            := "00000000";
	    o.primitiveID(index)   	 := "0000000000000000";										
	    o.reserved(index)        	 := "00000000";
	    o.MTPTimestamp(index)        := "000000000000000000000000";
            
	    n.FIFODELAY(index).inputs.aclr           :='0';
	    n.FIFODELAY(index).inputs.rdclk          :=n.clk125;
	    n.FIFODELAY(index).inputs.rdreq          :='0';
	    
	    case ro.FSMDelay(index) is
	       
	       when skipdata => 

		  if ro.BURST125 ='1' then
		     
		     if (ro.fifODELAY(index) = ro.fifODELAY_set(index)) then -- skippa un certo numero di pacchetti
			r.FSMDelay(index) := waitfinish;		
		     else
			if n.FIFODELAY(index).outputs.rdempty ='0' then            --se voglio skippare n pacchetti, incremento fifodelay 
			   n.FIFODELAY(index).inputs.rdreq :='1'; 		   -- dentro questo IF. in questo modo imposto il ritardo come
			   r.FSMDelay(index) := waitcontrol;
			else
			   r.FSMDelay(index) := skipdata;		 
			end if; --end rdempty 		
		     end if;	
		  else
		     r.FSMDelay(index) := skipdata; --NON IN BURST
		  end if;	--end BURST
		  


	       when waitcontrol =>
		  if ro.BURST125 ='1' then
		     if n.FIFODelay(index).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" then  
			r.fifODELAY(index) := SLV(UINT(ro.fifodelay(index))+1,32);-- numero di pacchetti
		     end if;	  
		     r.FSMDelay(index) := skipdata;
		  else
		     r.FSMDelay(index) := skipdata;
		  end if;



	       when waitfinish =>
		  if ro.BURST125 ='1' then
		     if (ro.fifODELAY(0)  = ro.fifODELAY_set(0))
			and (ro.fifODELAY(1) = ro.fifODELAY_set(1))
			and (ro.fifODELAY(2) = ro.fifODELAY_set(2))
			and (ro.fifODELAY(3) = ro.fifODELAY_set(3))
			and (ro.fifODELAY(4) = ro.fifODELAY_set(4))
			and (ro.fifODELAY(5) = ro.fifODELAY_set(5))
			and (ro.fifODELAY(6) = ro.fifODELAY_set(6))
		     then
			r.FSMDelay(index) := waitdata;
		     else
			r.FSMDelay(index) := waitfinish;
		     end if;
		     
		  else
		     r.FSMDelay(index) := skipdata;
		  end if;



	       when waitdata =>
		  if ro.BURST125 ='1' then
		     if (ro.fifODELAY(0)  = ro.fifODELAY_set(0))
			and (ro.fifODELAY(1) = ro.fifODELAY_set(1))
			and (ro.fifODELAY(2) = ro.fifODELAY_set(2))
			and (ro.fifODELAY(3) = ro.fifODELAY_set(3))
			and (ro.fifODELAY(4) = ro.fifODELAY_set(4))
			and (ro.fifODELAY(5) = ro.fifODELAY_set(5))
			and (ro.fifODELAY(6) = ro.fifODELAY_set(6))
		     then
			if UINT(ro.maximum_delay_detector)=0 then 
			   if n.FIFODELAY(0).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then -- serve
								    -- per il
								    -- possibile
								    -- gitter
								    -- tra pacchetti
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;
			   
			elsif UINT(ro.maximum_delay_detector)=1 then 
			   if n.FIFODELAY(1).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;
			   
			elsif UINT(ro.maximum_delay_detector)=2 then 
			   if n.FIFODELAY(2).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;
			   
			elsif UINT(ro.maximum_delay_detector)=3 then 
			   if n.FIFODELAY(3).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;
			   
			elsif UINT(ro.maximum_delay_detector)=4 then 
			   if n.FIFODELAY(4).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;
			   
			elsif UINT(ro.maximum_delay_detector)=5 then 
			   if n.FIFODELAY(5).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if; --rd empty
			   
			elsif UINT(ro.maximum_delay_detector)=6 then 
			   if n.FIFODELAY(6).outputs.rdempty ='0' then
			      if UINT(ro.start_latency) = 200  then
				 r.start_latency:=(others=>'0');
				 n.FIFODELAY(index).inputs.rdreq :='1';
				 r.FSMDelay(index) := readdata;
			      else
				 r.start_latency :=SLV(UINT(ro.start_latency)+1,32);
				 r.FSMDelay(index) := waitdata;
			      end if;  
			   else
			      r.FSMDelay(index) := waitdata;
			   end if;--rd empty	
			end if;--maximum_delay_detector	
			
		     else
			r.FSMDelay(index) := waitdata;
		     end if; --coincidence
		     
		  else
		     r.FSMDelay(index) := skipdata; --end BURST	
		  end if;
		  
		  
	       when endofframe =>
		  if ro.BURST125 ='1' then
		     if n.FIFODelay(index).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(index).outputs.q=SLV(0,64)--end of packet 
		     then
			r.FSMDelay(index) :=waitoutput;
		     else  
			if n.FIFODELAY(index).outputs.rdempty ='0' then
			   n.FIFODELAY(index).inputs.rdreq :='1';  
			   r.FSMDelay(index) := readdata;
			else
			   r.FSMDelay(index) := endofframe;  
			end if;
		     end if;
		     
		  else
		     r.FSMDelay(index) := skipdata;
		  end if;
		  
		  
	       when readdata =>
		  
		  if ro.BURST125 ='1' then
		     
		     if n.FIFODelay(index).outputs.q(63) = '1' then --header
			r.MTPNUMREF(index)                     := n.FIFODELAY(index).outputs.q(55 downto 48);
			o.received_signal(index)               :='0';
                        r.MTPTimestamp_out(index)              := n.FIFODELAY(index).outputs.q(23 downto 0);
			r.FSMDelay(index) := endofframe;
			
		     elsif n.FIFODelay(index).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" then --end of packet
			r.FSMDelay(index) :=endofframe;
			o.received_signal(index)               :='0';	
		     elsif n.FIFODelay(index).outputs.q = "0000000000000000000000000000000000000000000000000000000000000000" then
			r.FSMDelay(index) :=endofframe;
			o.received_signal(index)               :='0';	
			
		     else	
			
			r.FSMDelay(index) := endofframe;
			
		
			if (to_integer(signed(ro.internal_timestamp(30 downto 0)))-(to_integer(signed(n.FIFODELAY(index).outputs.q(62 downto 32))))) > to_integer(signed(ro.fixed_latency125))-768 then
			   o.received_signal(index)     :='0';
			   r.errorchecktimestamp(index) :='1';
			   r.MTPNUMREF(index)           := SLV(UINT(ro.MTPNUMREF(index))-1,8);
			else	
			   r.errorchecktimestamp(index) :='0';
			   o.received_signal(index)      :='1';	
			   
			   o.timestamp(index)     	:= '0' &
			                                   n.FIFODELAY(index).outputs.q(62 downto 56) &
							   n.FIFODELAY(index).outputs.q(55 downto 48) &
							   n.FIFODELAY(index).outputs.q(47 downto 40) &
							   n.FIFODELAY(index).outputs.q(39 downto 32) ;
			   
			   o.finetime(index)        := n.FIFODELAY(index).outputs.q(7 downto 0);
			   o.primitiveID(index)     := n.FIFODELAY(index).outputs.q(31 downto 24) &
						       n.FIFODELAY(index).outputs.q(23 downto 16);
			   o.reserved(index)        := n.FIFODELAY(index).outputs.q(15 downto 8);
                           o.MTPTimestamp(index)    := ro.MTPTimestamp_out(index);
			end if; --controllo timestamp 
		     end if;--controllo dati
		  else
		     r.FSMDelay(index) := skipdata;
		  end if;	 


	       when waitoutput =>    
		  if ( n.FIFODelay(0).outputs.q =    "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(0).outputs.q=SLV(0,64))
		     and (n.FIFODelay(1).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(1).outputs.q=SLV(0,64))
		     and (n.FIFODelay(2).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(2).outputs.q=SLV(0,64))    
		     and (n.FIFODelay(3).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(3).outputs.q=SLV(0,64))    
		     and (n.FIFODelay(4).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(4).outputs.q=SLV(0,64))    
		     and (n.FIFODelay(5).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(5).outputs.q=SLV(0,64))    
		     and (n.FIFODelay(6).outputs.q = "0111111111111111111111111111111111111111111111111111111111111111" or n.FIFODelay(6).outputs.q=SLV(0,64))    
		  then
		     
		     r.readdetector(index) :='0';
		     
		     if ro.errorchecktimestamp(index) = '1' then
			-------Bit 15 alzato per segnalare l'errore, piu' il bit meno significativi
			-------Per identificare la board.
			if (index=6) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(32768,32);end if;--LKr
			if (index=5) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(16384,32);end if;--TALK
			if (index=4) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(8192,32) ;end if; --NewCHOD
			if (index=3) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(4096,32) ;end if; --MUV3
			if (index=2) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(2048,32) ;end if; --LAV
			if (index=1) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(1024,32) ;end if; --RICH
			if (index=0) then r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(512,32)  ;end if; --CHOD
			
		     end if;
		     
		     o.packet_received :='1';
		     o.MTPNUMREF          := ro.MTPNUMREF;
		     r.FSMDelay(index) := waitdata;

		  else
		     
		     o.packet_received :='0';
		     r.FSMDelay(index) := waitoutput;
		  end if;
	    end case;
	 end loop;

      end procedure;
      
      
      
      procedure SubSendBuffer
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
	 n.LATENCYRAM.inputs.clock_a   :=n.clk125;
	 n.LATENCYRAM.inputs.wren_a    :='0';	
	 n.LATENCYRAM.inputs.rden_a    :='0';	
	 
	 n.SENDRAM.inputs.clock_a      :=n.clk125;
	 n.SENDRAM.inputs.rden_a       :='0';
	 n.SENDRAM.inputs.wren_a       :='0';
	 
	 n.CHOKEFIFOON.inputs.data(31 downto 0):= ro.internal_timestamp;
	 n.CHOKEFIFOON.inputs.wrreq            := '0'                  ;
	 n.CHOKEFIFOON.inputs.wrclk            := n.clk125             ;
	 
	 n.ERRORFIFOON.inputs.data(31 downto 0):= ro.internal_timestamp;
	 n.ERRORFIFOON.inputs.wrreq            := '0'                  ;
	 n.ERRORFIFOON.inputs.wrclk            := n.clk125             ;
	 
	 n.CHOKEFIFOOFF.inputs.data(31 downto 0):= ro.internal_timestamp;
	 n.CHOKEFIFOOFF.inputs.wrreq            := '0'                  ;
	 n.CHOKEFIFOOFF.inputs.wrclk            := n.clk125             ;
	 
	 n.ERRORFIFOOFF.inputs.data(31 downto 0):= ro.internal_timestamp;
	 n.ERRORFIFOOFF.inputs.wrreq            := '0'                  ;
	 n.ERRORFIFOOFF.inputs.wrclk            := n.clk125             ;
	 
	 
	 --Burst Check
	 if ro.BURST125 ='1' then

	    r.internal_timestamp_eob        := ro.internal_timestamp;
	    r.sendEOB:='1';
	    
	    if ro.sendSOB = '1' then
	       r.sendSOB                       := '0'                  ;
	       r.sob_data125(191 downto 160)   := ro.internal_timestamp;
	       r.sob_data125(159 downto 152)   := (others=>'0')        ;
	       r.sob_data125(151 downto 146)   := "100010"             ; --TW
	       r.sob_data125(145 downto  34)   := (others=>'0')        ;			
	       r.sob_data125(33 downto 18)     := ("0000000000100010") ; -- event triggerword
	       r.sob_data125(17 downto 10)     := "00100010"           ; --data type		
	    end if; --end sob
	    
	    
	    if ro.CHOKE_ON= '1' and ro.CHOKE_OFF ='0' and ro.sendCHOKE_ON = '1' then
	       
	       if n.CHOKEFIFOON.outputs.wrfull='0' then
		  n.CHOKEFIFOON.inputs.data(31 downto 0)         := ro.internal_timestamp;
		  n.CHOKEFIFOON.inputs.wrreq                     := '1'                  ;
	       end if;
	       
	       r.sendCHOKE_ON                               := '0'                  ;
	       r.sendCHOKE_OFF                              := '1'                  ;
	       r.chokeOn_data125(191 downto 160)            := ro.internal_timestamp;
	       r.chokeOn_data125(159 downto 152)            := (others=>'0')        ; 
	       r.chokeOn_data125(151 downto 146)            := "100100"             ; --TW
	       r.chokeOn_data125(145 downto  34)            := (others=>'0')        ;			
	       r.chokeOn_data125(33 downto 18)              := SLV(ro.CHOKE_signal,16); -- event triggerword
	       r.chokeOn_data125(17 downto 10)              := X"A1"                ; --data type		
	       
	    end if; --end choke on

	    if ro.CHOKE_OFF = '1' and ro.CHOKE_ON = '0' and ro.sendCHOKE_OFF ='1' then
	       
	       if n.CHOKEFIFOOFF.outputs.wrfull='0' then
		  n.CHOKEFIFOOFF.inputs.data(31 downto 0)         := ro.internal_timestamp;
		  n.CHOKEFIFOOFF.inputs.wrreq                     := '1'                  ;
	       end if;
	       
	       r.sendCHOKE_OFF   := '0';
	       r.sendCHOKE_ON    := '1';
	       r.chokeOff_data125(191 downto 160)   := ro.internal_timestamp  ;
	       r.chokeOff_data125(159 downto 152)   := (others=>'0')          ;
	       r.chokeOff_data125(151 downto 146)   := "100101"               ; --TW
	       r.chokeOff_data125(145 downto  34)   := (others=>'0')          ;			
	       r.chokeOff_data125(33 downto 18)     := SLV(ro.CHOKE_signal,16); -- event triggerword
	       r.chokeOff_data125(17 downto 10)     := X"A0"                  ; --data type		
	    end if; --end choke off
	    
	    if ro.ERROR_ON = '1' and ro.ERROR_OFF ='0' and ro.sendERROR_ON   = '1' then
	       
	       if n.ERRORFIFOON.outputs.wrfull='0' then
		  n.ERRORFIFOON.inputs.data(31 downto 0)         := ro.internal_timestamp;
		  n.ERRORFIFOON.inputs.wrreq                     := '1'                  ;
	       end if;
	       
	       r.sendERROR_ON    := '0';
	       r.sendERROR_OFF   := '1';				
	       r.errorOn_data125(191 downto 160)   := ro.internal_timestamp ;
	       r.errorOn_data125(159 downto 152)   := (others=>'0')          ;
	       r.errorOn_data125(151 downto 146)   := "100110"               ; --TW
	       r.errorOn_data125(145 downto  34)   := (others=>'0')          ;			
	       r.errorOn_data125(33 downto 18)     := SLV(ro.ERROR_signal,16); -- event triggerword
	       r.errorOn_data125(17 downto 10)     := X"C1"                  ; --data type		
	    end if; --end error
	    
	    if ro.ERROR_OFF = '1' and ro.ERROR_ON ='0' and ro.sendERROR_OFF   = '1' then
	       if n.ERRORFIFOOFF.outputs.wrfull='0' then
		  n.ERRORFIFOOFF.inputs.data(31 downto 0)         := ro.internal_timestamp;
		  n.ERRORFIFOOFF.inputs.wrreq                     := '1'                  ;
	       end if;

	       r.sendERROR_OFF   := '0';
	       r.sendERROR_ON    := '1';
	       r.errorOff_data125(191 downto 160)   := ro.internal_timestamp   ;
	       r.errorOff_data125(159 downto 152)   := (others=>'0')           ;
	       r.errorOff_data125(151 downto 146)   := "100111"                ; --TW
	       r.errorOff_data125(145 downto  34)   := (others=>'0')           ;			
	       r.errorOff_data125(33 downto 18)     := SLV(ro.ERROR_signal,16) ; -- event triggerword
	       r.errorOff_data125(17 downto 10)     := X"C0"                   ; --data type		
	    end if; --end sob

  	    
	 else --Se sono fuori dal Burst...
	    if ro.sendEOB ='1' then			
	       r.sendEOB    :='0';
	       r.sendSOB    :='1';	
	       r.eob_data125(191 downto 160)   := ro.internal_timestamp_eob;
	       r.eob_data125(159 downto 152)   := (others=>'0');
	       r.eob_data125(151 downto 146)   := "100011"     ; --TW
	       r.eob_data125(145 downto 130)   := (others=>'0');
	       r.eob_data125(129 downto 114)   := (others=>'0');
	       r.eob_data125(113 downto 98)    := (others=>'0');
	       r.eob_data125(97 downto  82)    := (others=>'0');
	       r.eob_data125(81 downto  66)    := (others=>'0');
	       r.eob_data125(65 downto  50)    := (others=>'0');
	       r.eob_data125(49 downto  34)    := (others=>'0');         		
	       r.eob_data125(33 downto 18)     := (others=>'0');
	       r.eob_data125(17 downto 10)     := "00100011"     ; --data type
	    end if;
	    r.addressfarm   :=(others=>'0');
	    r.sendCHOKE_OFF :='0';
	    r.sendERROR_OFF :='0';
	    r.sendCHOKE_ON  :='1';
	    r.sendERROR_ON  :='1';
	    r.errorOff_data125 := (others=>'0');
	    r.errorOn_data125  := (others=>'0');
	    r.chokeOn_data125  := (others=>'0');
	    r.chokeOff_data125 := (others=>'0');
	    
	 end if; --end controllo sul Burst

	 case ro.FSMoutputdata is

	    when Idle => 

--VAI LEGGI L'INDIRIZZO E VAI ALLO STATO SUCCESSIVO( avendo memorizzato i valori )

	       if ro.trigger_signal ='1' and ro.control_signal ='0' then
		  n.LATENCYRAM.inputs.rden_a     := '1'                                            ;
		  n.LATENCYRAM.inputs.address_a  :=ro.timestamp_physics(14 downto 0)               ;
		  r.FSMoutputdata                :=SetFarmAddress                                  ;
		  r.tmptimestamp                 :=ro.timestamp_physics                            ;
		  r.tmptriggerword               :=ro.triggerword                                  ;
		  r.tmpdatatype                  :=X"01"                                           ; --data type physics
		  r.tmpprimitiveID0               :=ro.primitiveID_t0                              ; --location N
		  r.tmpprimitiveID1               :=ro.primitiveID_t1                              ; --location N-1
		  r.tmpprimitiveID2               :=ro.primitiveID_t2                              ; --location N+1

		  r.tmptriggerflag                :=ro.triggerflag                                 ;
		  r.tmpfinetime_ref               :=ro.finetime_physics_ref                        ;
		  r.tmpfinetime0                  :=ro.finetime_physics0                           ; --location N
		  r.tmpfinetime1                  :=ro.finetime_physics1                           ; --location N-1
		  r.tmpfinetime2                  :=ro.finetime_physics2                           ; --location N+1
		  
	       elsif ro.control_signal ='1' and ro.trigger_signal ='0' then
		  n.LATENCYRAM.inputs.rden_a      := '1'                                           ;
		  n.LATENCYRAM.inputs.address_a  := ro.timestamp_physics(14 downto 0)              ;
		  r.FSMoutputdata                :=SetFarmAddress                                  ;
		  r.tmptimestamp                 :=ro.timestamp_physics                            ;
		  r.tmptriggerword               :=ro.triggerword                                  ;
		  r.tmpdatatype                  :=X"10"                                           ; --data type physics
		  r.tmpprimitiveID0              :=ro.primitiveID_t0                              ; --location N
		  r.tmpprimitiveID1              :=ro.primitiveID_t1                              ; --location N-1
		  r.tmpprimitiveID2              :=ro.primitiveID_t2                              ; --location N+1
		  r.tmptriggerflag               :=(others=>'0')                                  ;
		  r.tmpfinetime_ref              :=ro.finetime_physics0(to_integer(unsigned(ro.control_detector))); --MOD
		  r.tmpfinetime0                 :=ro.finetime_physics0                           ; --location N
		  r.tmpfinetime1                 :=ro.finetime_physics1                           ; --location N-1
		  r.tmpfinetime2                 :=ro.finetime_physics2                           ; --location N+1
		  
	       elsif ro.control_signal ='1' and ro.trigger_signal ='1' then
		  n.LATENCYRAM.inputs.rden_a      := '1'                                           ;
		  n.LATENCYRAM.inputs.address_a   := ro.timestamp_physics(14 downto 0)             ;
		  r.FSMoutputdata                 :=SetFarmAddress                                 ;
		  r.tmptimestamp                  :=ro.timestamp_physics                           ;
		  r.tmptriggerword                :=ro.triggerword                                 ;
		  r.tmpdatatype                   :=X"11"                                          ; --data type physics
		  r.tmpprimitiveID0               :=ro.primitiveID_t0                              ; --location N
		  r.tmpprimitiveID1               :=ro.primitiveID_t1                              ; --location N-1
		  r.tmpprimitiveID2               :=ro.primitiveID_t2                              ; --location N+1
		  r.tmptriggerflag                :=ro.triggerflag                                 ;
		  r.tmpfinetime_ref               :=ro.finetime_physics_ref                        ;
		  r.tmpfinetime0                  :=ro.finetime_physics0                           ; --location N
		  r.tmpfinetime1                  :=ro.finetime_physics1                           ; --location N-1
		  r.tmpfinetime2                  :=ro.finetime_physics2                           ; --location N+1


               elsif ro.random_signal ='1' then 
		  n.LATENCYRAM.inputs.rden_a     := '1'                              ;
		  n.LATENCYRAM.inputs.address_a  :=ro.internal_timestamp(14 downto 0);
		  r.FSMoutputdata                :=SetFarmAddress                    ;
		  
		  r.randomtriggercounter :=SLV(UINT(ro.randomtriggercounter) +1,32); --contatore trigger periodici
		  r.tmptimestamp                 :=ro.internal_timestamp                           ; 
		  r.tmptriggerword               :=ro.random_triggerword;
		  r.tmpdatatype                  :=X"20"                                 ; --data type random
		  r.tmpprimitiveID0               :=ro.primitiveID_t0                    ;
		  r.tmpprimitiveID1               :=ro.primitiveID_t1                    ;
		  r.tmpprimitiveID2               :=ro.primitiveID_t2                    ;
		  r.tmptriggerflag                :=(others=>'0')                        ;
		  r.tmpfinetime_ref               :=(others=>'0')                        ;
		  r.tmpfinetime0                  :=(others=>"00000000")                 ;
		  r.tmpfinetime1                  :=(others=>"00000000")                 ;
		  r.tmpfinetime2                  :=(others=>"00000000")                 ;
		     

	       elsif ro.periodic_signal0 ='1' or ro.periodic_signal1 ='1'  then 
		  n.LATENCYRAM.inputs.rden_a     := '1'                              ;
		  n.LATENCYRAM.inputs.address_a  :=ro.internal_timestamp(14 downto 0);
		  r.FSMoutputdata                :=SetFarmAddress                    ;
		  
		  r.periodicrandomtriggercounter :=SLV(UINT(ro.periodicrandomtriggercounter) +1,32); --contatore trigger periodici
		  r.tmptimestamp                 :=ro.internal_timestamp                           ; 
		  r.tmptriggerword               :=ro.periodic_triggerword0 or ro.periodic_triggerword1;
		  r.tmpdatatype                  :=X"02"                                 ; --data type periodics
		  r.tmpprimitiveID0               :=ro.primitiveID_t0                    ;
		  r.tmpprimitiveID1               :=ro.primitiveID_t1                    ;
		  r.tmpprimitiveID2               :=ro.primitiveID_t2                    ;
		  r.tmptriggerflag                :=(others=>'0')                        ;
		  r.tmpfinetime_ref              :=(others=>'0')                         ;
		  r.tmpfinetime0                 :=(others=>"00000000")                  ;
		  r.tmpfinetime1                 :=(others=>"00000000")                  ;
		  r.tmpfinetime2                 :=(others=>"00000000")                  ;
		  


		--Parte Stefan------------------------------------------

               elsif ro.s_rit='1' then
                 --    elsif ro.s_new_trigger='1' then
                 n.LATENCYRAM.inputs.rden_a     := '1'                                ;
                 n.LATENCYRAM.inputs.address_a  :=ro.internal_timestamp(14 downto 0)  ;
                 r.FSMoutputdata                :=SetFarmAddress                      ;
                 
                 
                 r.tmptimestamp                 :=ro.internal_timestamp; 
                 r.tmptriggerword               :="111111"           ; --TO BE CHECKED 
                 r.tmpdatatype                  :=X"20"              ;
                 r.tmpprimitiveID0              :=ro.primitiveID_t0  ;
                 r.tmpprimitiveID1              :=ro.primitiveID_t1  ;
                 r.tmpprimitiveID2              :=ro.primitiveID_t2  ;
                 r.tmptriggerflag               :=(others=>'0')      ;
                 r.tmpfinetime_ref              :=(others=>'0')       ;
                 r.tmpfinetime0                 :=(others=>"00000000");
                 r.tmpfinetime1                 :=(others=>"00000000");
                 r.tmpfinetime2                 :=(others=>"00000000");
                 
--------------------------------------------------------                 







		  
	       elsif ro.calib_signal /="0000000" and ro.trigger_signal ='0' then 
		  n.LATENCYRAM.inputs.rden_a     :='1'                                   ;
		  r.FSMoutputdata                :=SetFarmAddress                        ;
		  r.calibration_trigger  := SLV(UINT(ro.calibration_trigger)+1,32)       ;
		  r.tmptriggerword       :=ro.triggerword_calib                          ;
		  r.tmpdatatype          :=X"04"                                         ; --data type calibration 
		  r.tmpprimitiveID0       :=ro.primitiveID_c                             ;
		  r.tmpprimitiveID1       :=(others=>"0000000000000000")                 ;
		  r.tmpprimitiveID2       :=(others=>"0000000000000000")                 ;
		  r.tmptriggerflag        :=SLV(ro.calib_signal,16)                      ; --event word
		  r.tmpfinetime0          := ro.finetime_calib                           ;
		  r.tmpfinetime1          :=(others=>"00000000")                  ;
		  r.tmpfinetime2          :=(others=>"00000000")                  ;
		  
		  if ro.calib_signal    ="0000001" then
		     r.tmptimestamp         :=ro.timestamp_calib(0)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(0)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(0)(14 downto 0)  ;
		  elsif ro.calib_signal ="0000010" then             
		     r.tmptimestamp         :=ro.timestamp_calib(1)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(1)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(1)(14 downto 0)  ;
		  elsif ro.calib_signal ="0000100" then             
		     r.tmptimestamp         :=ro.timestamp_calib(2)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(2)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(2)(14 downto 0)  ;
		  elsif ro.calib_signal ="0001000" then             
		     r.tmptimestamp         :=ro.timestamp_calib(3)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(3)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(3)(14 downto 0)  ;
		  elsif ro.calib_signal ="0010000" then             
		     r.tmptimestamp         :=ro.timestamp_calib(4)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(4)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(4)(14 downto 0)  ;
		  elsif ro.calib_signal ="0100000" then             
		     r.tmptimestamp         :=ro.timestamp_calib(5)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(5)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(5)(14 downto 0)  ;
		  elsif ro.calib_signal ="1000000" then             
		     r.tmptimestamp         :=ro.timestamp_calib(6)                       ; 
		     r.tmpfinetime_ref      := ro.finetime_calib(6)                       ;
		     n.LATENCYRAM.inputs.address_a := ro.timestamp_calib(6)(14 downto 0)  ;
		  else             
		     r.tmptimestamp         :=(others=>'0')                               ;
		     r.tmpfinetime0          :=(others=>"00000000")                       ;
		  end if; --fine calibrazione
		  
		  
	       elsif ro.calibration_nim ='1' then	
		  r.FSMoutputdata                :=SetFarmAddress                 ;
		  r.tmpfinetime0                 := (others=>"00000000")          ;
		  r.tmpfinetime1                 := (others=>"00000000")          ;
		  r.tmpfinetime2                 := (others=>"00000000")          ;

		  r.tmpfinetime_ref             := (others=>'0')                  ;
		  r.tmpdatatype                 := X"08"                          ;
		  r.tmptriggerflag               := (others=>'0')                 ;
		  r.tmptriggerword              := ro.triggerword_calib           ; --TW
		  
		  if ro.calib_latency =X"00000000" then
		     r.tmptimestamp := ro.internal_timestamp                      ; --bit meno significativi timestamp
		  else
		     
		     if ro.calib_direction = '0' then
			r.tmptimestamp :=SLV(UINT(ro.internal_timestamp)+UINT(ro.calib_latency),32)   ;
			n.LATENCYRAM.inputs.address_a := SLV(UINT(ro.internal_timestamp(14 downto 0))+UINT(ro.calib_latency),15); --bit meno significativi timestamp
			n.LATENCYRAM.inputs.rden_a    :='1';
		     else
			r.tmptimestamp :=SLV(UINT(ro.internal_timestamp)-UINT(ro.calib_latency),32);
			n.LATENCYRAM.inputs.address_a := SLV(UINT(ro.internal_timestamp(14 downto 0))-UINT(ro.calib_latency),15); --bit meno significativi timestamp
			n.LATENCYRAM.inputs.rden_a    :='1';
		     end if; --calib direction
		  end if; -- calib latency
		  
	       else

		  r.FSMoutputdata := Idle;
		  
	       end if; --end check data type	
	       
	       
	 when SetFarmAddress =>
	       	--I read latency ram, to see if it is not empty.
	       --if not empty, it means that there were two different types of
	       --triggers in the same timestamp.
	       --then I carry the same address of the send ram and replace the word already written
	       --with the new words doing the OR of Triggerword, TriggerFlag and Event type.
	       --if the location of latency ram was empty, it continues as if nothing had happened.
	       
	       if n.LATENCYRAM.outputs.q_a /= "00000000000000000" then  	
		  n.SENDRAM.inputs.address_a                := n.LATENCYRAM.outputs.q_a(15 downto 6); -- leggo la ram
		  n.SENDRAM.inputs.rden_a                   := '1' 	 ;
		  n.LATENCYRAM.inputs.address_a             := ro.tmptimestamp(14 downto 0)                ; --bit meno significativi timestamp
		  n.LATENCYRAM.inputs.data_a(5 downto 0)    := ro.tmptriggerword OR n.LATENCYRAM.outputs.q_a(5 downto 0);
		  n.LATENCYRAM.inputs.data_a(16 downto 6)   := n.LATENCYRAM.outputs.q_a(16 downto 6)       ;		      
		  n.LATENCYRAM.inputs.wren_a                :='1';	
		  
	       else
		  n.SENDRAM.inputs.address_a                := std_logic_vector(ro.addressfarm(9 downto 0));
		  n.LATENCYRAM.inputs.address_a             := ro.tmptimestamp(14 downto 0)                ; --bit meno significativi timestamp
		  n.LATENCYRAM.inputs.data_a(5 downto 0)    := ro.tmptriggerword;
		  n.LATENCYRAM.inputs.data_a(16 downto 6)   := std_logic_vector(ro.addressfarm(10 downto 0));		      
		  n.LATENCYRAM.inputs.wren_a                :='1'; 				 
	       end if;
	       
	       r.FSMoutputdata := WriteEvent;
	       
	    when WriteEvent =>
	       
	       if n.LATENCYRAM.outputs.q_a /= "00000000000000000" and ro.tmpdatatype(0)= '0' then
		  --if it is non physics trigger (calib, periodics, control, random...),
		  --I have to maintain the trigger infos of
		  --physics, without overwrite the ram
		  r.addressfarm := ro.addressfarm; 			
		  n.SENDRAM.inputs.address_a    := n.LATENCYRAM.outputs.q_a(15 downto 6); -- leggo la ram

		  n.SENDRAM.inputs.data_a(151 downto 146)   := ro.tmptriggerword OR n.SENDRAM.outputs.q_a(151 downto 146);
		  n.SENDRAM.inputs.data_a(33 downto 18)     := ro.tmptriggerflag OR n.SENDRAM.outputs.q_a(33 downto 18);					
		  n.SENDRAM.inputs.data_a(17 downto 10)     := ro.tmpdatatype    OR n.SENDRAM.outputs.q_a(17 downto 10);

		  n.SENDRAM.inputs.data_a(575 downto 152)   :=  n.SENDRAM.outputs.q_a(575 downto 152);
		  n.SENDRAM.inputs.data_a(145 downto 34)    :=  n.SENDRAM.outputs.q_a(145 downto 34);
		  n.SENDRAM.inputs.data_a(9 downto 0)       :=  n.SENDRAM.outputs.q_a(9 downto 0);
		  
		  
		  n.SENDRAM.inputs.wren_a                   :='1';		
		  
	       elsif n.LATENCYRAM.outputs.q_a /= "00000000000000000" and ro.tmpdatatype(0)= '1' then
		  --if it is a physiscs trigger, I have to overwrite infos. So,
		  --if I have control OR periodics OR random in the same
		  --timestamp of physics, the winner is physics.
		  --PROBLEM: if I have 2 different physics trigger in the same
		  --timestamp, but in different time slot due to a granularity
		  --lower than 25 ns, what i have to do ??? which trigger
		  --should be sent? the first one and the second discarded?
		  --SOLUTION: It is discarded in Trigger.vhd, at the output of
		  --the LUT. I cannot have two different triggers coming from
		  --adiacent RAM time slots. It is counted in the dead time.
		  
		  r.addressfarm := ro.addressfarm; 			
		  n.SENDRAM.inputs.address_a    := n.LATENCYRAM.outputs.q_a(15 downto 6); -- leggo la ram
		  n.SENDRAM.inputs.data_a(151 downto 146)   := ro.tmptriggerword OR n.SENDRAM.outputs.q_a(151 downto 146);
		  n.SENDRAM.inputs.data_a(33 downto 18)     := ro.tmptriggerflag OR n.SENDRAM.outputs.q_a(33 downto 18);					
		  n.SENDRAM.inputs.data_a(17 downto 10)     := ro.tmpdatatype    OR n.SENDRAM.outputs.q_a(17 downto 10);--data type
		  n.SENDRAM.inputs.data_a(7 downto 0)       := ro.tmpprimitiveID2(0)(15 downto 8); --location N +1
	          n.SENDRAM.inputs.data_a(575 downto 568)   := ro.tmpprimitiveID2(0)(7 downto 0); --location N +1
		  
		  n.SENDRAM.inputs.data_a(567 downto 552)     := ro.tmpprimitiveID2(1); --location N +1
		  n.SENDRAM.inputs.data_a(551 downto 536)     := ro.tmpprimitiveID2(2); --location N +1
		  n.SENDRAM.inputs.data_a(535 downto  520)    := ro.tmpprimitiveID2(3); --location N +1
		  n.SENDRAM.inputs.data_a(519 downto  504)    := ro.tmpprimitiveID2(4); --location N +1
		  n.SENDRAM.inputs.data_a(503 downto  488)    := ro.tmpprimitiveID2(5); --location N +1
		  n.SENDRAM.inputs.data_a(487 downto  472)    := ro.tmpprimitiveID2(6); --location N +1


		  n.SENDRAM.inputs.data_a(471 downto 456)     := ro.tmpprimitiveID1(0); --location N -1
		  n.SENDRAM.inputs.data_a(455 downto 440)     := ro.tmpprimitiveID1(1); --location N -1
		  n.SENDRAM.inputs.data_a(439 downto 424)     := ro.tmpprimitiveID1(2); --location N -1
		  n.SENDRAM.inputs.data_a(423 downto  408)    := ro.tmpprimitiveID1(3); --location N -1
		  n.SENDRAM.inputs.data_a(407 downto  392)    := ro.tmpprimitiveID1(4); --location N -1
		  n.SENDRAM.inputs.data_a(391 downto  376)    := ro.tmpprimitiveID1(5); --location N -1
		  n.SENDRAM.inputs.data_a(375 downto  360)    := ro.tmpprimitiveID1(6); --location N -1

		  
		  n.SENDRAM.inputs.data_a(359 downto 352)   := ro.tmpfinetime2(6);--location N +1
		  n.SENDRAM.inputs.data_a(351 downto 344)   := ro.tmpfinetime2(5);--location N +1
		  n.SENDRAM.inputs.data_a(343 downto 336)   := ro.tmpfinetime2(4);--location N +1
		  n.SENDRAM.inputs.data_a(335 downto 328)   := ro.tmpfinetime2(3);--location N +1
		  n.SENDRAM.inputs.data_a(327 downto 320)   := ro.tmpfinetime2(2);--location N +1
		  n.SENDRAM.inputs.data_a(319 downto 312)   := ro.tmpfinetime2(1);--location N +1
		  n.SENDRAM.inputs.data_a(311 downto 304)   := ro.tmpfinetime2(0);--location N +1
		  
		  
		  n.SENDRAM.inputs.data_a(303 downto 296)   := ro.tmpfinetime1(6);--location N -1
		  n.SENDRAM.inputs.data_a(295 downto 288)   := ro.tmpfinetime1(5);--location N -1
		  n.SENDRAM.inputs.data_a(287 downto 280)   := ro.tmpfinetime1(4);--location N -1
		  n.SENDRAM.inputs.data_a(279 downto 272)   := ro.tmpfinetime1(3);--location N -1
		  n.SENDRAM.inputs.data_a(271 downto 264)   := ro.tmpfinetime1(2);--location N -1
		  n.SENDRAM.inputs.data_a(263 downto 256)   := ro.tmpfinetime1(1);--location N -1
		  n.SENDRAM.inputs.data_a(255 downto 248)   := ro.tmpfinetime1(0);--location N -1
		  
		  
		  n.SENDRAM.inputs.data_a(247 downto 240)   := ro.tmpfinetime0(6); --location N
		  n.SENDRAM.inputs.data_a(239 downto 232)   := ro.tmpfinetime0(5); --location N
		  n.SENDRAM.inputs.data_a(231 downto 224)   := ro.tmpfinetime0(4); --location N
		  n.SENDRAM.inputs.data_a(223 downto 216)   := ro.tmpfinetime0(3); --location N
		  n.SENDRAM.inputs.data_a(215 downto 208)   := ro.tmpfinetime0(2); --location N
		  n.SENDRAM.inputs.data_a(207 downto 200)   := ro.tmpfinetime0(1); --location N
		  n.SENDRAM.inputs.data_a(199 downto 192)   := ro.tmpfinetime0(0); --location N
		  
		  n.SENDRAM.inputs.data_a(191 downto 160)   := ro.tmptimestamp;
		  n.SENDRAM.inputs.data_a(159 downto 152)   := ro.tmpfinetime_ref;
		  
		  n.SENDRAM.inputs.data_a(145 downto 130)   := ro.tmpprimitiveID0(0) ; --location N
		  n.SENDRAM.inputs.data_a(129 downto 114)   := ro.tmpprimitiveID0(1) ; --location N
		  n.SENDRAM.inputs.data_a(113 downto 98)    := ro.tmpprimitiveID0(2) ; --location N
		  n.SENDRAM.inputs.data_a(97 downto  82)    := ro.tmpprimitiveID0(3) ; --location N
		  n.SENDRAM.inputs.data_a(81 downto  66)    := ro.tmpprimitiveID0(4) ; --location N
		  n.SENDRAM.inputs.data_a(65 downto  50)    := ro.tmpprimitiveID0(5) ; --location N
		  n.SENDRAM.inputs.data_a(49 downto  34)    := ro.tmpprimitiveID0(6) ; --location N

		  n.SENDRAM.inputs.wren_a                   :='1';		
		  
		  
	       else
		  r.addressfarm				  := ro.addressfarm + 1;
		  n.SENDRAM.inputs.data_a(151 downto 146) := ro.tmptriggerword;
		  n.SENDRAM.inputs.data_a(33 downto 18)	  := ro.tmptriggerflag;
		  n.SENDRAM.inputs.data_a(17 downto 10)	  := ro.tmpdatatype;  --n.SENDRAM.outputs.q_a(17 downto 12); --data type
		  n.SENDRAM.inputs.address_a		  := std_logic_vector(ro.addressfarm(9 downto 0));

		  n.SENDRAM.inputs.wren_a := '1';
	       
	       
		  n.SENDRAM.inputs.data_a(7 downto 0)     := ro.tmpprimitiveID2(0)(15 downto 8);  --location N +1
		  n.SENDRAM.inputs.data_a(575 downto 568) := ro.tmpprimitiveID2(0)(7 downto 0);  --location N +1

		  n.SENDRAM.inputs.data_a(567 downto 552) := ro.tmpprimitiveID2(1);  --location N +1
	          n.SENDRAM.inputs.data_a(551 downto 536) := ro.tmpprimitiveID2(2);  --location N +1
	          n.SENDRAM.inputs.data_a(535 downto 520) := ro.tmpprimitiveID2(3);  --location N +1
	          n.SENDRAM.inputs.data_a(519 downto 504) := ro.tmpprimitiveID2(4);  --location N +1
	          n.SENDRAM.inputs.data_a(503 downto 488) := ro.tmpprimitiveID2(5);  --location N +1
	          n.SENDRAM.inputs.data_a(487 downto 472) := ro.tmpprimitiveID2(6);  --location N +1
	          
	          
	          n.SENDRAM.inputs.data_a(471 downto 456) := ro.tmpprimitiveID1(0);  --location N -1
	          n.SENDRAM.inputs.data_a(455 downto 440) := ro.tmpprimitiveID1(1);  --location N -1
	          n.SENDRAM.inputs.data_a(439 downto 424) := ro.tmpprimitiveID1(2);  --location N -1
	          n.SENDRAM.inputs.data_a(423 downto 408) := ro.tmpprimitiveID1(3);  --location N -1
	          n.SENDRAM.inputs.data_a(407 downto 392) := ro.tmpprimitiveID1(4);  --location N -1
	          n.SENDRAM.inputs.data_a(391 downto 376) := ro.tmpprimitiveID1(5);  --location N -1
	          n.SENDRAM.inputs.data_a(375 downto 360) := ro.tmpprimitiveID1(6);  --location N -1
	          
	          
	          n.SENDRAM.inputs.data_a(359 downto 352) := ro.tmpfinetime2(6);  --location N +1
	          n.SENDRAM.inputs.data_a(351 downto 344) := ro.tmpfinetime2(5);  --location N +1
	          n.SENDRAM.inputs.data_a(343 downto 336) := ro.tmpfinetime2(4);  --location N +1
	          n.SENDRAM.inputs.data_a(335 downto 328) := ro.tmpfinetime2(3);  --location N +1
	          n.SENDRAM.inputs.data_a(327 downto 320) := ro.tmpfinetime2(2);  --location N +1
	          n.SENDRAM.inputs.data_a(319 downto 312) := ro.tmpfinetime2(1);  --location N +1
	          n.SENDRAM.inputs.data_a(311 downto 304) := ro.tmpfinetime2(0);  --location N +1
	          
	          
	          n.SENDRAM.inputs.data_a(303 downto 296) := ro.tmpfinetime1(6);  --location N -1
	          n.SENDRAM.inputs.data_a(295 downto 288) := ro.tmpfinetime1(5);  --location N -1
	          n.SENDRAM.inputs.data_a(287 downto 280) := ro.tmpfinetime1(4);  --location N -1
	          n.SENDRAM.inputs.data_a(279 downto 272) := ro.tmpfinetime1(3);  --location N -1
	          n.SENDRAM.inputs.data_a(271 downto 264) := ro.tmpfinetime1(2);  --location N -1
	          n.SENDRAM.inputs.data_a(263 downto 256) := ro.tmpfinetime1(1);  --location N -1
	          n.SENDRAM.inputs.data_a(255 downto 248) := ro.tmpfinetime1(0);  --location N -1
	          
	          
	          n.SENDRAM.inputs.data_a(247 downto 240) := ro.tmpfinetime0(6);  --location N
	          n.SENDRAM.inputs.data_a(239 downto 232) := ro.tmpfinetime0(5);  --location N
	          n.SENDRAM.inputs.data_a(231 downto 224) := ro.tmpfinetime0(4);  --location N
	          n.SENDRAM.inputs.data_a(223 downto 216) := ro.tmpfinetime0(3);  --location N
	          n.SENDRAM.inputs.data_a(215 downto 208) := ro.tmpfinetime0(2);  --location N
	          n.SENDRAM.inputs.data_a(207 downto 200) := ro.tmpfinetime0(1);  --location N
	          n.SENDRAM.inputs.data_a(199 downto 192) := ro.tmpfinetime0(0);  --location N
	          
	          n.SENDRAM.inputs.data_a(191 downto 160) := ro.tmptimestamp;
	          n.SENDRAM.inputs.data_a(159 downto 152) := ro.tmpfinetime_ref;
	          
	          n.SENDRAM.inputs.data_a(145 downto 130) := ro.tmpprimitiveID0(0);  --location N
	          n.SENDRAM.inputs.data_a(129 downto 114) := ro.tmpprimitiveID0(1);  --location N
	          n.SENDRAM.inputs.data_a(113 downto 98)  := ro.tmpprimitiveID0(2);  --location N
	          n.SENDRAM.inputs.data_a(97 downto 82)   := ro.tmpprimitiveID0(3);  --location N
	          n.SENDRAM.inputs.data_a(81 downto 66)   := ro.tmpprimitiveID0(4);  --location N
	          n.SENDRAM.inputs.data_a(65 downto 50)   := ro.tmpprimitiveID0(5);  --location N
	          n.SENDRAM.inputs.data_a(49 downto 34)   := ro.tmpprimitiveID0(6);  --location N
	    end if;

	       
	       
	       r.tmpfinetime0      := (others =>"00000000");
	       r.tmpfinetime1      := (others =>"00000000");
	       r.tmpfinetime2      := (others =>"00000000");
	       r.tmptimestamp      := (others =>'0');
	       r.tmpfinetime_ref   := (others =>'0');
	       r.tmptriggerword    := (others =>'0');
	       r.tmpprimitiveID0   := (others =>"0000000000000000");
	       r.tmpprimitiveID1   := (others =>"0000000000000000");
	       r.tmpprimitiveID2   := (others =>"0000000000000000");
	       r.tmptriggerflag    := (others =>'0'); 
	       r.tmpdatatype       := (others =>'0');

	       r.FSMoutputdata     := Idle;
	       
	 end case;	
      end procedure;	  


------------------------------------------------------------------------------------------------------------- 

      procedure SubGeneratePackets
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk125_t;
	    variable ro: in reglist_clk125_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk125_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 n.SENDRAM.inputs.clock_b         :=n.clk125;      
	 n.SENDRAM.inputs.rden_b          :='0';
	 n.SENDRAM.inputs.wren_b          :='0';
	 
	 n.FIFOPACKETS.inputs.aclr        :='0';
	 n.FIFOPACKETS.inputs.wrclk       :=n.clk125;      
	 n.FIFOPACKETS.inputs.wrreq       :='0';
	 n.FIFOPACKETS.inputs.data        :=(OTHERS=>'0');
	 
	 n.FIFODETECTORFARM.inputs.rdclk  :=n.clk125;
	 n.FIFODETECTORFARM.inputs.rdreq  :='0';
	 
	 -------------------Event header-------------------------------------------------------------------------
	 -- 1) SOB
	 
	 case ro.FSMPackets is
	    
	    when idle =>
	       
	       if ro.sob_ev125 ='1'  then      -- SOB (il segnale dura 25 ns)
		  r.sob_data_send :='1';
		  r.FSMPackets := deadtime_1;
		  r.errorchecktimestamp         := (others =>'0'); 
		  
	       elsif ro.write_ev125 ='1' then --DATA			  		
		  r.data_send :='1';
		  r.FSMPackets := deadtime_1;
		  
	       elsif ro.chokeOn_ev125 ='1' then 
		  r.chokeOn_data_send :='1';
		  r.FSMPackets := deadtime_1;
		  
	       elsif ro.chokeOff_ev125 ='1' then
		  r.chokeOff_data_send :='1';
		  r.FSMPackets := deadtime_1;
		  
	       elsif ro.errorOn_ev125 ='1' then
		  r.errorOn_data_send :='1';
		  r.FSMPackets := deadtime_1;
		  
	       elsif ro.errorOff_ev125 ='1' then
		  r.errorOff_data_send :='1';
		  r.FSMPackets := deadtime_1;
		  
	       else
		  r.FSMPackets := Idle;
	       end if;
	       


	    when deadtime_1 => --+8ns
	       
	       
	       if ro.errorOff_data_send  ='1' OR
		  ro.errorOn_data_send  ='1'  OR
		  ro.chokeOff_data_send ='1'  OR
		  ro.chokeOn_data_send  ='1'  OR
		  ro.sob_data_send      ='1'   then
		  
		  r.FSMPackets := SetFarmAddress;
		  
	       elsif n.FIFODETECTORFARM.outputs.rdempty ='0' then --DATA
		  n.FIFODETECTORFARM.inputs.rdreq :='1';
		  r.FSMPackets := SetFarmAddress;
	       else
		  r.FSMPackets := deadtime_1;
	       end if;	   



	    when SetFarmAddress=> --+8ns
	       
	       if ro.errorOff_data_send   ='1'OR
		  ro.errorOn_data_send  ='1'  OR
		  ro.chokeOff_data_send ='1'  OR
		  ro.chokeOn_data_send  ='1'  OR
		  ro.sob_data_send      ='1'   then        
		  r.FSMPackets := deadtime_2;
		  
	       else
		  
		  n.SENDRAM.inputs.address_b := n.FIFODETECTORFARM.outputs.q(9 downto 0);
		  n.SENDRAM.inputs.rden_b :='1';
		  r.FSMPackets := deadtime_2;

	       end if;

	    when deadtime_2 => --+8ns
	       
	       r.FSMPackets := WriteEvent;


	    when WriteEvent =>
	       
	       --SOB
	       
	       if ro.sob_data_send = '1' then --SOB
		  r.old_tw :=	ro.sob_data125(151 downto 146);--TW HW 
		  r.old_timestamp:=ro.sob_data125(191 downto 160);
		  r.sob_data_send :='0';
                  r.old_number_of_primitives := ro.number_of_primitives;
                  
		  if n.FIFOPACKETS.outputs.wrfull='0' then 			

		     --Data_3
		     n.FIFOPACKETS.inputs.data( 703 downto  256) := (others=>'0');
                     
		     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := ro.sob_data125(33 downto 26)   ; --EVENT                                    
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := ro.sob_data125(25 downto 18)   ; --TW                           
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)               ;                                   
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(ro.sob_data125(151 downto 146),8);--TW HW                       
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  := ro.old_timestamp(31 downto 24)  ;                           
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  := ro.old_timestamp(23 downto 16)  ;                   
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  := ro.old_timestamp(15 downto 8)   ;                      
		     n.FIFOPACKETS.inputs.data(199  downto  192)  := ro.old_timestamp(7 downto 0)    ;                       
		     
		     --Data_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := ro.sob_data125(49 downto 42);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := ro.sob_data125(41 downto 34);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := ro.sob_data125(65 downto 58);  --prim ID F 
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := ro.sob_data125(57 downto 50);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := ro.sob_data125(81 downto 74);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := ro.sob_data125(73 downto 66);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= ro.sob_data125(97 downto 90);  --prim ID D
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := ro.sob_data125(89 downto 82);  --prim ID D

		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)  := ro.sob_data125(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)  := ro.sob_data125(105 downto 98) ;   --prim ID C
		     n.FIFOPACKETS.inputs.data( 111 downto  104)  := ro.sob_data125(129 downto 122);   --prim ID B	
		     n.FIFOPACKETS.inputs.data( 103 downto  96)   := ro.sob_data125(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)    := ro.sob_data125(145 downto 138);   --prim ID A	
		     n.FIFOPACKETS.inputs.data( 87 downto  80)    := ro.sob_data125(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)   := ro.sob_data125(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)    := ro.sob_data125(159 downto 152);   --FINETIME
		     
		     
		     -- EVENT HEADER
		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := ro.sob_data125(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := ro.sob_data125(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := ro.sob_data125(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := ro.sob_data125(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENT FLAG
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event	
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo		     
		  end if;
		  
		  --CHOKE ON
		  
		  
	       elsif ro.chokeOn_data_send ='1' then
		  r.old_tw :=	ro.chokeOn_data125(151 downto 146);--TW HW 
		  r.old_timestamp:=ro.chokeOn_data125(191 downto 160);
		  r.chokeOn_data_send  :='0';
		  r.old_number_of_primitives := ro.number_of_primitives;
                  
		  if n.FIFOPACKETS.outputs.wrfull='0' then 			
		     
		     --Data_3
                     n.FIFOPACKETS.inputs.data( 655 downto  256) := (others=>'0');
                     n.FIFOPACKETS.inputs.data( 703 downto  688) := (others=>'0');

		     if UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)) < 255 then 
			n.FIFOPACKETS.inputs.data( 663 downto 656) :=SLV(UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)),8);--CHOD
		     else
			n.FIFOPACKETS.inputs.data( 663 downto 656) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)) < 255 then 
			n.FIFOPACKETS.inputs.data( 671 downto 664) :=SLV(UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)),8);--RICH
		     else
			n.FIFOPACKETS.inputs.data( 671 downto 664) := SLV(255,8);
		     end if;
								    
		     if UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)) < 255 then 
			n.FIFOPACKETS.inputs.data( 679 downto 672) :=SLV(UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)),8);--MUV3
		     else
			n.FIFOPACKETS.inputs.data( 679 downto 672) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)) < 255 then 
			n.FIFOPACKETS.inputs.data( 687 downto 680) :=SLV(UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)),8);--NewCHOD
		     else
			n.FIFOPACKETS.inputs.data( 687 downto 680) := SLV(255,8);
		     end if;

                     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := ro.chokeOn_data125(33 downto 26)   ; --EVENT                                    
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := ro.chokeOn_data125(25 downto 18)   ; --TW                           
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)               ;                                   
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(ro.chokeOn_data125(151 downto 146),8);--TW HW                       
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  :=ro.old_timestamp(31 downto 24)  ;                           
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  :=ro.old_timestamp(23 downto 16)  ;                   
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  :=ro.old_timestamp(15 downto 8)   ;                      
		     n.FIFOPACKETS.inputs.data(199  downto  192)  :=ro.old_timestamp(7 downto 0)    ;                       
		     
		     --Data_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := ro.chokeOn_data125(49 downto 42);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := ro.chokeOn_data125(41 downto 34);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := ro.chokeOn_data125(65 downto 58);  --prim ID F 
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := ro.chokeOn_data125(57 downto 50);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := ro.chokeOn_data125(81 downto 74);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := ro.chokeOn_data125(73 downto 66);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= ro.chokeOn_data125(97 downto 90);  --prim ID D
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := ro.chokeOn_data125(89 downto 82);  --prim ID D
		     
		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)  := ro.chokeOn_data125(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)  := ro.chokeOn_data125(105 downto 98) ;   --prim ID C
		     n.FIFOPACKETS.inputs.data( 111 downto  104)  := ro.chokeOn_data125(129 downto 122);   --prim ID B	
		     n.FIFOPACKETS.inputs.data( 103 downto  96)   := ro.chokeOn_data125(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)    := ro.chokeOn_data125(145 downto 138);   --prim ID A	
		     n.FIFOPACKETS.inputs.data( 87 downto  80)    := ro.chokeOn_data125(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)   := ro.chokeOn_data125(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)    := ro.chokeOn_data125(159 downto 152);   --FINETIME
		     
		     
		     -- EVENT HEADER
		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := ro.chokeOn_data125(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := ro.chokeOn_data125(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := ro.chokeOn_data125(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := ro.chokeOn_data125(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENT FLAG
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event	
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo
		  end if;
		  
		  -- CHOKE OFF
		  
	       elsif ro.chokeOff_data_send ='1' then
		  r.old_tw :=	ro.chokeOff_data125(151 downto 146);--TW HW 
		  r.old_timestamp:=ro.chokeOff_data125(191 downto 160);
		  r.chokeOff_data_send :='0';
     	          r.old_number_of_primitives := ro.number_of_primitives;  	  

		  if n.FIFOPACKETS.outputs.wrfull='0' then
                    -- Data 3
		     n.FIFOPACKETS.inputs.data( 655 downto  256) := (others=>'0');
                     n.FIFOPACKETS.inputs.data( 703 downto  688) := (others=>'0');
		     if UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)) < 255 then 
			n.FIFOPACKETS.inputs.data( 663 downto 656) :=SLV(UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)),8);--CHOD
		     else
			n.FIFOPACKETS.inputs.data( 663 downto 656) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)) < 255 then 
			n.FIFOPACKETS.inputs.data( 671 downto 664) :=SLV(UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)),8);--RICH
		     else
			n.FIFOPACKETS.inputs.data( 671 downto 664) := SLV(255,8);
		     end if;
								    
		     if UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)) < 255 then 
			n.FIFOPACKETS.inputs.data( 679 downto 672) :=SLV(UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)),8);--MUV3
		     else
			n.FIFOPACKETS.inputs.data( 679 downto 672) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)) < 255 then 
			n.FIFOPACKETS.inputs.data( 687 downto 680) :=SLV(UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)),8);--NewCHOD
		     else
			n.FIFOPACKETS.inputs.data( 687 downto 680) := SLV(255,8);
		     end if;

		     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := ro.chokeOff_data125(33 downto 26)   ; --EVENT                                    
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := ro.chokeOff_data125(25 downto 18)   ; --TW                           
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)               ;                                   
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(ro.chokeOff_data125(151 downto 146),8);--TW HW                       
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  :=ro.old_timestamp(31 downto 24)  ;                           
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  :=ro.old_timestamp(23 downto 16)  ;                   
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  :=ro.old_timestamp(15 downto 8)   ;                      
		     n.FIFOPACKETS.inputs.data(199  downto  192)  :=ro.old_timestamp(7 downto 0)    ;                       
		     
		     --Data_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := ro.chokeOff_data125(49 downto 42);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := ro.chokeOff_data125(41 downto 34);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := ro.chokeOff_data125(65 downto 58);  --prim ID F 
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := ro.chokeOff_data125(57 downto 50);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := ro.chokeOff_data125(81 downto 74);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := ro.chokeOff_data125(73 downto 66);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= ro.chokeOff_data125(97 downto 90);  --prim ID D
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := ro.chokeOff_data125(89 downto 82);  --prim ID D
		     
		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)  := ro.chokeOff_data125(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)  := ro.chokeOff_data125(105 downto 98) ;   --prim ID C
		     n.FIFOPACKETS.inputs.data( 111 downto  104)  := ro.chokeOff_data125(129 downto 122);   --prim ID B	
		     n.FIFOPACKETS.inputs.data( 103 downto  96)   := ro.chokeOff_data125(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)    := ro.chokeOff_data125(145 downto 138);   --prim ID A	
		     n.FIFOPACKETS.inputs.data( 87 downto  80)    := ro.chokeOff_data125(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)   := ro.chokeOff_data125(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)    := ro.chokeOff_data125(159 downto 152);   --FINETIME
		     
		     
		     -- EVENT HEADER
		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := ro.chokeOff_data125(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := ro.chokeOff_data125(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := ro.chokeOff_data125(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := ro.chokeOff_data125(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENT FLAG
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event	
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo
		     
		  end if;
		  
		  
		  -- ERROR ON
		  
	       elsif ro.errorOn_data_send ='1' then
		  r.old_tw :=	ro.errorOn_data125(151 downto 146);--TW HW 
		  r.old_timestamp:=ro.errorOn_data125(191 downto 160);
		  r.errorOn_data_send  :='0';
		  r.old_number_of_primitives := ro.number_of_primitives;
                  
		  if n.FIFOPACKETS.outputs.wrfull='0' then 			
		     
		     --Data_3
                     n.FIFOPACKETS.inputs.data( 655 downto  256) := (others=>'0');
                     n.FIFOPACKETS.inputs.data( 703 downto  688) := (others=>'0');

		     if UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)) < 255 then 
			n.FIFOPACKETS.inputs.data( 663 downto 656) :=SLV(UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)),8);--CHOD
		     else
			n.FIFOPACKETS.inputs.data( 663 downto 656) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)) < 255 then 
			n.FIFOPACKETS.inputs.data( 671 downto 664) :=SLV(UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)),8);--RICH
		     else
			n.FIFOPACKETS.inputs.data( 671 downto 664) := SLV(255,8);
		     end if;
								    
		     if UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)) < 255 then 
			n.FIFOPACKETS.inputs.data( 679 downto 672) :=SLV(UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)),8);--MUV3
		     else
			n.FIFOPACKETS.inputs.data( 679 downto 672) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)) < 255 then 
			n.FIFOPACKETS.inputs.data( 687 downto 680) :=SLV(UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)),8);--NewCHOD
		     else
			n.FIFOPACKETS.inputs.data( 687 downto 680) := SLV(255,8);
		     end if;

                     
		     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := ro.errorOn_data125(33 downto 26)   ; --EVENT                                    
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := ro.errorOn_data125(25 downto 18)   ; --TW                           
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)               ;                                   
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(ro.errorOn_data125(151 downto 146),8);--TW HW                       
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  :=ro.old_timestamp(31 downto 24)  ;                           
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  :=ro.old_timestamp(23 downto 16)  ;                   
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  :=ro.old_timestamp(15 downto 8)   ;                      
		     n.FIFOPACKETS.inputs.data(199  downto  192)  :=ro.old_timestamp(7 downto 0)    ;                       
		     
		     --Data_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := ro.errorOn_data125(49 downto 42);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := ro.errorOn_data125(41 downto 34);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := ro.errorOn_data125(65 downto 58);  --prim ID F 
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := ro.errorOn_data125(57 downto 50);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := ro.errorOn_data125(81 downto 74);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := ro.errorOn_data125(73 downto 66);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= ro.errorOn_data125(97 downto 90);  --prim ID D
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := ro.errorOn_data125(89 downto 82);  --prim ID D
		     
		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)  := ro.errorOn_data125(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)  := ro.errorOn_data125(105 downto 98) ;   --prim ID C
		     n.FIFOPACKETS.inputs.data( 111 downto  104)  := ro.errorOn_data125(129 downto 122);   --prim ID B	
		     n.FIFOPACKETS.inputs.data( 103 downto  96)   := ro.errorOn_data125(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)    := ro.errorOn_data125(145 downto 138);   --prim ID A	
		     n.FIFOPACKETS.inputs.data( 87 downto  80)    := ro.errorOn_data125(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)   := ro.errorOn_data125(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)    := ro.errorOn_data125(159 downto 152);   --FINETIME
		     
		     
		     -- EVENT HEADER
		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := ro.errorOn_data125(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := ro.errorOn_data125(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := ro.errorOn_data125(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := ro.errorOn_data125(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENT FLAG
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event	
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo
		  end if;
		  
		  --ERROR OFF
		  
	       elsif ro.errorOff_data_send ='1' then
		  r.old_tw :=	ro.errorOff_data125(151 downto 146);--TW HW 
		  r.old_timestamp:=ro.errorOff_data125(191 downto 160);
		  r.errorOff_data_send :='0';
                  r.old_number_of_primitives := ro.number_of_primitives;
                  
		  if  n.FIFOPACKETS.outputs.wrfull='0' then 			
		     
		     --Data_3
		     n.FIFOPACKETS.inputs.data( 655 downto  256) := (others=>'0');
                     n.FIFOPACKETS.inputs.data( 703 downto  688) := (others=>'0');
                     		     if UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)) < 255 then 
			n.FIFOPACKETS.inputs.data( 663 downto 656) :=SLV(UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)),8);--CHOD
		     else
			n.FIFOPACKETS.inputs.data( 663 downto 656) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)) < 255 then 
			n.FIFOPACKETS.inputs.data( 671 downto 664) :=SLV(UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)),8);--RICH
		     else
			n.FIFOPACKETS.inputs.data( 671 downto 664) := SLV(255,8);
		     end if;
								    
		     if UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)) < 255 then 
			n.FIFOPACKETS.inputs.data( 679 downto 672) :=SLV(UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)),8);--MUV3
		     else
			n.FIFOPACKETS.inputs.data( 679 downto 672) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)) < 255 then 
			n.FIFOPACKETS.inputs.data( 687 downto 680) :=SLV(UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)),8);--NewCHOD
		     else
			n.FIFOPACKETS.inputs.data( 687 downto 680) := SLV(255,8);
		     end if;

  
		     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := ro.errorOff_data125(33 downto 26)   ; --EVENT                                    
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := ro.errorOff_data125(25 downto 18)   ; --TW                           
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)               ;                                   
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(ro.errorOff_data125(151 downto 146),8);--TW HW                       
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  :=ro.old_timestamp(31 downto 24)  ;                           
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  :=ro.old_timestamp(23 downto 16)  ;                   
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  :=ro.old_timestamp(15 downto 8)   ;                      
		     n.FIFOPACKETS.inputs.data(199  downto  192)  :=ro.old_timestamp(7 downto 0)    ;                       
		     
		     --Data_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := ro.errorOff_data125(49 downto 42);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := ro.errorOff_data125(41 downto 34);  --prim ID G
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := ro.errorOff_data125(65 downto 58);  --prim ID F 
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := ro.errorOff_data125(57 downto 50);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := ro.errorOff_data125(81 downto 74);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := ro.errorOff_data125(73 downto 66);  --prim ID E 
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= ro.errorOff_data125(97 downto 90);  --prim ID D
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := ro.errorOff_data125(89 downto 82);  --prim ID D
		     
		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)  := ro.errorOff_data125(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)  := ro.errorOff_data125(105 downto 98) ;   --prim ID C
		     n.FIFOPACKETS.inputs.data( 111 downto  104)  := ro.errorOff_data125(129 downto 122);   --prim ID B	
		     n.FIFOPACKETS.inputs.data( 103 downto  96)   := ro.errorOff_data125(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)    := ro.errorOff_data125(145 downto 138);   --prim ID A	
		     n.FIFOPACKETS.inputs.data( 87 downto  80)    := ro.errorOff_data125(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)   := ro.errorOff_data125(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)    := ro.errorOff_data125(159 downto 152);   --FINETIME
		     
		     
		     -- EVENT HEADER
		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := ro.errorOff_data125(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := ro.errorOff_data125(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := ro.errorOff_data125(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := ro.errorOff_data125(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENT FLAG
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event	
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo
		  end if;
		  
		  
		  -- 2) DATA--------------------------------------
		  
	       elsif ro.data_send = '1' then 		--DATA		
		  
		  r.old_tw :=	n.SENDRAM.outputs.q_b(151 downto 146);-- TW
		  r.old_timestamp:=n.SENDRAM.outputs.q_b(191 downto 160);      
		  r.data_send :='0';
		  r.old_number_of_primitives := ro.number_of_primitives;
                  
		  if  n.FIFOPACKETS.outputs.wrfull ='0' then 
  
		     --Data_9
		     
		     n.FIFOPACKETS.inputs.data( 703 downto  688)  := (others=>'0');     
		     if UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)) < 255 then 
			n.FIFOPACKETS.inputs.data( 663 downto 656) :=SLV(UINT(ro.number_of_primitives(0))-UINT(ro.old_number_of_primitives(0)),8);--CHOD
		     else
			n.FIFOPACKETS.inputs.data( 663 downto 656) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)) < 255 then 
			n.FIFOPACKETS.inputs.data( 671 downto 664) :=SLV(UINT(ro.number_of_primitives(1))-UINT(ro.old_number_of_primitives(1)),8);--RICH
		     else
			n.FIFOPACKETS.inputs.data( 671 downto 664) := SLV(255,8);
		     end if;
								    
		     if UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)) < 255 then 
			n.FIFOPACKETS.inputs.data( 679 downto 672) :=SLV(UINT(ro.number_of_primitives(3))-UINT(ro.old_number_of_primitives(3)),8);--MUV3
		     else
			n.FIFOPACKETS.inputs.data( 679 downto 672) := SLV(255,8);
		     end if;

		     if UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)) < 255 then 
			n.FIFOPACKETS.inputs.data( 687 downto 680) :=SLV(UINT(ro.number_of_primitives(4))-UINT(ro.old_number_of_primitives(4)),8);--NewCHOD
		     else
			n.FIFOPACKETS.inputs.data( 687 downto 680) := SLV(255,8);
		     end if;

                    

                     n.FIFOPACKETS.inputs.data( 655 downto  640)  := n.SENDRAM.outputs.q_b(487 downto  472)       ; --primitive 2 G
		     
		     --Data_8
		     
		     n.FIFOPACKETS.inputs.data( 639 downto  624)  := n.SENDRAM.outputs.q_b(503 downto  488)       ; --primitive 2 F  
		     n.FIFOPACKETS.inputs.data( 623 downto  608)  := n.SENDRAM.outputs.q_b(519 downto  504)      ; --primitive 2 E  
		     n.FIFOPACKETS.inputs.data( 607 downto  592)  := n.SENDRAM.outputs.q_b(535 downto  520)       ; --primitive 2 D  
		     n.FIFOPACKETS.inputs.data( 591 downto  576)  := n.SENDRAM.outputs.q_b(551 downto 536)       ; --primitive 2 C  


		     --Data_7
		     
		     n.FIFOPACKETS.inputs.data( 575 downto  560)  := n.SENDRAM.outputs.q_b(567 downto 552)       ; --primitive 2 B  
		     n.FIFOPACKETS.inputs.data( 559 downto  544)  := n.SENDRAM.outputs.q_b(7 downto 0) & n.SENDRAM.outputs.q_b(575 downto 568)      ; --primitive 2 A  
		     n.FIFOPACKETS.inputs.data( 543 downto  528)  := n.SENDRAM.outputs.q_b(375 downto  360)       ; --primitive 1 G  
		     n.FIFOPACKETS.inputs.data( 527 downto  512)  := n.SENDRAM.outputs.q_b(391 downto  376)       ; --primitive 1 F  


                    --Data_6
		     n.FIFOPACKETS.inputs.data( 511 downto  496)  := n.SENDRAM.outputs.q_b(407 downto  392)       ; --primitive 1 E  
		     n.FIFOPACKETS.inputs.data( 495 downto  480)  := n.SENDRAM.outputs.q_b(423 downto  408)      ; --primitive 1 D  
		     n.FIFOPACKETS.inputs.data( 479 downto  464)  := n.SENDRAM.outputs.q_b(439 downto 424)       ; --primitive 1 C  
		     n.FIFOPACKETS.inputs.data( 463 downto  448)  := n.SENDRAM.outputs.q_b(455 downto 440)       ; --primitive 1 B  
		     
		     --Data_5
		     n.FIFOPACKETS.inputs.data( 447 downto  432)  := n.SENDRAM.outputs.q_b(471 downto 456)       ; --primitive 1 A  
		     n.FIFOPACKETS.inputs.data( 431 downto  424)  := (others=>'0')                               ;-- reserved           
		     n.FIFOPACKETS.inputs.data( 423 downto  416)  := n.SENDRAM.outputs.q_b(359 downto 352)       ; --FT G 2        	                                                   
		     n.FIFOPACKETS.inputs.data( 415 downto  408)  := n.SENDRAM.outputs.q_b(351 downto 344)       ; --FT F 2   
		     n.FIFOPACKETS.inputs.data( 407 downto  400)  := n.SENDRAM.outputs.q_b(343 downto 336)       ; --FT E 2
		     n.FIFOPACKETS.inputs.data( 399 downto  392)  := n.SENDRAM.outputs.q_b(335 downto 328)       ; --FT D 2
		     n.FIFOPACKETS.inputs.data(391  downto  384)  := n.SENDRAM.outputs.q_b(327 downto 320)       ; --FT C 2
		     
		     

		     --Data_4
		     n.FIFOPACKETS.inputs.data( 383 downto  376)  := n.SENDRAM.outputs.q_b(319 downto 312)       ; --FT B 2                                                    
		     n.FIFOPACKETS.inputs.data( 375 downto  368)  := n.SENDRAM.outputs.q_b(311 downto 304)       ; --FT A 2   
		     n.FIFOPACKETS.inputs.data( 367 downto  360)  := n.SENDRAM.outputs.q_b(303 downto 296)       ; --FT G 1              
		     n.FIFOPACKETS.inputs.data( 359 downto  352)  := n.SENDRAM.outputs.q_b(295 downto 288)       ; --FT F 1        	                                                   
		     n.FIFOPACKETS.inputs.data( 351 downto  344)  := n.SENDRAM.outputs.q_b(287 downto 280)       ; --FT E 1   
		     n.FIFOPACKETS.inputs.data( 343 downto  336)  := n.SENDRAM.outputs.q_b(279 downto 272)       ; --FT D 1
		     n.FIFOPACKETS.inputs.data( 335 downto  328)  := n.SENDRAM.outputs.q_b(271 downto 264)       ; --FT C 1
		     n.FIFOPACKETS.inputs.data(327  downto  320)  := n.SENDRAM.outputs.q_b(263 downto 256)       ; --FT B 1


		     --Data_3
		     n.FIFOPACKETS.inputs.data( 319 downto  312)  := n.SENDRAM.outputs.q_b(255 downto 248)       ; --FT A 1                   
		     n.FIFOPACKETS.inputs.data( 311 downto  304)  := n.SENDRAM.outputs.q_b(247 downto 240)       ; --FT G 0   
		     n.FIFOPACKETS.inputs.data( 303 downto  296)  := n.SENDRAM.outputs.q_b(239 downto 232)       ; --FT F 0              
		     n.FIFOPACKETS.inputs.data( 295 downto  288)  := n.SENDRAM.outputs.q_b(231 downto 224)       ; --FT E 0        	                                                   
		     n.FIFOPACKETS.inputs.data( 287 downto  280)  := n.SENDRAM.outputs.q_b(223 downto 216)       ; --FT D 0   
		     n.FIFOPACKETS.inputs.data( 279 downto  272)  := n.SENDRAM.outputs.q_b(215 downto 208)       ; --FT C 0
		     n.FIFOPACKETS.inputs.data( 271 downto  264)  := n.SENDRAM.outputs.q_b(207 downto 200)       ; --FT B 0
		     n.FIFOPACKETS.inputs.data(263  downto  256)  := n.SENDRAM.outputs.q_b(199 downto 192)       ; --FT A 0
		     
		     --Data_2
		     n.FIFOPACKETS.inputs.data( 255 downto  248)  := n.SENDRAM.outputs.q_b(33 downto 26)         ; --EV TW
		     n.FIFOPACKETS.inputs.data( 247 downto  240)  := n.SENDRAM.outputs.q_b(25 downto 18)         ; --EV TW 
		     n.FIFOPACKETS.inputs.data( 239 downto  232)  := SLV(ro.old_tw,8)                           ;       
		     n.FIFOPACKETS.inputs.data( 231 downto  224)  := SLV(n.SENDRAM.outputs.q_b(151 downto 146),8);-- TW                                                      
		     n.FIFOPACKETS.inputs.data( 223 downto  216)  := ro.old_timestamp(31 downto 24)             ;       
		     n.FIFOPACKETS.inputs.data( 215 downto  208)  := ro.old_timestamp(23 downto 16)             ; 
		     n.FIFOPACKETS.inputs.data( 207 downto  200)  := ro.old_timestamp(15 downto 8)              ; 
		     n.FIFOPACKETS.inputs.data(199  downto  192)  := ro.old_timestamp(7 downto 0)               ; 
		     
		     --DATA_1
		     n.FIFOPACKETS.inputs.data(191  downto  184) := n.SENDRAM.outputs.q_b(49 downto 42);  --prim ID G 	
		     n.FIFOPACKETS.inputs.data( 183 downto  176) := n.SENDRAM.outputs.q_b(41 downto 34);  --prim ID G		
		     n.FIFOPACKETS.inputs.data( 175 downto  168) := n.SENDRAM.outputs.q_b(65 downto 58);  --prim ID F
		     n.FIFOPACKETS.inputs.data( 167 downto  160) := n.SENDRAM.outputs.q_b(57 downto 50);  --prim ID F		
		     n.FIFOPACKETS.inputs.data( 159 downto  152) := n.SENDRAM.outputs.q_b(81 downto 74);  --prim ID E      
		     n.FIFOPACKETS.inputs.data( 151 downto  144) := n.SENDRAM.outputs.q_b(73 downto 66);  --prim ID E
		     n.FIFOPACKETS.inputs.data( 143 downto   136):= n.SENDRAM.outputs.q_b(97 downto 90);  --prim ID D			
		     n.FIFOPACKETS.inputs.data( 135 downto  128) := n.SENDRAM.outputs.q_b(89 downto 82);  --prim ID D
		     
		     --Data_0
		     n.FIFOPACKETS.inputs.data(127  downto  120)   := n.SENDRAM.outputs.q_b(113 downto 106);   --prim ID C
		     n.FIFOPACKETS.inputs.data( 119 downto  112)   := n.SENDRAM.outputs.q_b(105 downto 98);    --prim ID C 
		     n.FIFOPACKETS.inputs.data( 111 downto  104)   := n.SENDRAM.outputs.q_b(129 downto 122);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 103 downto  96)    := n.SENDRAM.outputs.q_b(121 downto 114);   --prim ID B
		     n.FIFOPACKETS.inputs.data( 95 downto  88)     := n.SENDRAM.outputs.q_b(145 downto 138);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 87 downto  80)     := n.SENDRAM.outputs.q_b(137 downto 130);   --prim ID A
		     n.FIFOPACKETS.inputs.data( 79 downto   72)    := n.SENDRAM.outputs.q_b(17 downto 10)  ;   --Data type
		     n.FIFOPACKETS.inputs.data( 71 downto  64)     := n.SENDRAM.outputs.q_b(159 downto 152);   --FINETIME

-- EVENT HEADER 

		     n.FIFOPACKETS.inputs.data( 63 downto  56)  := n.SENDRAM.outputs.q_b(191 downto 184);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 55 downto  48)  := n.SENDRAM.outputs.q_b(183 downto 176);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 47 downto  40)  := n.SENDRAM.outputs.q_b(175 downto 168);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 39 downto  32)  := n.SENDRAM.outputs.q_b(167 downto 160);   --timestamp;
		     n.FIFOPACKETS.inputs.data( 31 downto  24)  := "00000000";--EVENTFLAG("10000000"for EOB)
		     n.FIFOPACKETS.inputs.data( 23 downto  16)  := (others =>'0'); --reserved x me
		     n.FIFOPACKETS.inputs.data( 15 downto  8)   := SLV(0,8); --Length of event
		     n.FIFOPACKETS.inputs.data( 7 downto  0)    := SLV(96,8);--Length of event
		     n.FIFOPACKETS.inputs.wrreq := '1';
		     r.MEPeventWritten:=SLV(UINT(ro.MEPEventWritten)+1,8); --mi dice che ho scritto un nuovo evento nella fifo

		  else
		     
		     r.ETHLINKERROR :=	ro.ETHLINKERROR OR SLV(65536,32); 
		  end if;
	       end if; --dati o sob
	       
	       r.FSMPackets := deadtime_0;

	       
	    when deadtime_0 => --+8ns
	       r.FSMPackets := Idle;
	       if ro.MEPeventWritten = ro.MEPEventNumber(7 downto 0) then
		  r.MEPeventWritten:=(others =>'0');
	       end if;		
	       
	 end case;
      end procedure;


      procedure SubSendDetectors
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk40_t;
	    variable ro: in reglist_clk40_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_clk40_t;
	    variable n : inout netlist_t
	    ) is
      begin
	 
	 n.LATENCYRAM.inputs.clock_b :=n.clk40;
	 n.LATENCYRAM.inputs.address_b   :=std_logic_vector(ro.latencyreadaddressb(14 downto 0));
	 n.LATENCYRAM.inputs.rden_b      :='0';
	 n.LATENCYRAM.inputs.wren_b      :='0';
	 
	 n.FIFODETECTORFARM.inputs.wrreq :='0';
	 n.FIFODETECTORFARM.inputs.data  :=(others=>'0');
	 n.FIFODETECTORFARM.inputs.wrclk :=n.clk40;
	 n.FIFODETECTORFARM.inputs.aclr  :='0';
	 
	 r.LTU0            := '0';
	 r.LTU1            := '0';
	 r.LTU2            := '0';
	 r.LTU3            := '0';
	 r.LTU4            := '0';
	 r.LTU5            := '0';
	 r.LTU_TRIGGER     := '0';
	 
	 r.write_ev40      :='0';
	 r.sob_ev40        :='0';
	 r.chokeOn_ev40    :='0';
	 r.chokeOff_ev40   :='0';
	 r.errorOn_ev40    :='0';
	 r.errorOff_ev40   :='0';
	 
	 case ro.FSMSendDetectors is
	    when S0_0 =>
	       r.latencycounter:=0;
	       r.FSMSendDetectors :=S0;
	    when S0 => 
	       if ro.BURST40='1' and ro.activate_SOBEOBtrigger = '1' then --SOB
		  r.LTU0             := '0';
		  r.LTU1             := '1';
		  r.LTU2             := '0';
		  r.LTU3             := '0';
		  r.LTU4             := '0';
		  r.LTU5             := '1';
		  r.LTU_TRIGGER      := '1';
		  r.TriggerStop      := '1'; --per non inviare di nuovo l'eob mentre resetto la ram
		  r.FSMSendDetectors := S1;  --Vado in stato di latenza
		  r.sob_ev40         := '1'; --invia i dati di sob anche alla farm
		  r.ecounter40       := SLV(UINT(ro.ecounter40)+1,16);
		  
		  r.counterLTU       := SLV(1,32);
		  r.counterCHOKE     := SLV(0,32);
		  r.counterERROR     := SLV(0,32);
		  
		  r.sentCHOKE_OFF    := '1';
		  r.sentERROR_OFF    := '1';
		  r.sentCHOKE_ON     := '0';
		  r.sentERROR_ON     := '0';
		  
	       else --if out of BURST40
		  r.oldlatencyreadaddressb  := (others =>'0');
		  r.latencyreadaddressb     := (others =>'0');
		  r.latencycounter          :=0;
		  r.FSMSendDetectors        :=S0;
		  r.sentCHOKE_OFF           := '1';
		  r.sentERROR_OFF           := '1';
		  r.sentCHOKE_ON            := '0';
		  r.sentERROR_ON            := '0';
	       end if;
	       
	    when S1 => --Latency 
	       
	       if ro.activate_synch ='1' then
		  r.FSMSendDetectors        := S2;
	       else
		  if ro.latencycounter < UINT(ro.Fixed_Latency) - 3 then 
		     r.latencycounter            := ro.latencycounter+1;	   	
		     r.latencyreadaddressb       := (others =>'0');
		     r.oldlatencyreadaddressb    := (others =>'0');
		     r.FSMSendDetectors          := S1;
		  else --Fine Latency
		     n.LATENCYRAM.inputs.rden_b  :='1';
		     r.latencycounter            := 0;
		     r.FSMSendDetectors          := S2;
		  end if; --if latency
	       end if; -- if synchronization
	       
	    when S2 =>		  
	       --------------------------------------------------------------
	       r.latencyreadaddressb    := ro.latencyreadaddressb+1;		-- incremented clock by clock (25 ns)
	       --------------------------------------------------------------
	       n.LATENCYRAM.inputs.rden_b    := '1';
	       n.LATENCYRAM.inputs.address_b := std_logic_vector(ro.latencyreadaddressb(14 downto 0));
	       n.LATENCYRAM.inputs.wren_b    := '1'; --Because it is a TDP ram, RDW done calling old data --PERMETTE DI RESETTARE
	       n.LATENCYRAM.inputs.data_b    := (others =>'0');
	       --------------------------------------------------------------
	       
	       if ro.BURST40 ='1' then --Se sono in BURST	

	--If synch signal: NO LATENCY; !!!!!NO DATA SENT TO PCFARM !!!!	  
		  if ro.activate_synch ='1' then
		     if ro.synch_signal = '1' then
			r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);
			r.LTU0 := '0';
			r.LTU1 := '0';
			r.LTU2 := '0';
			r.LTU3 := '0';
			r.LTU4 := '0';
			r.LTU5 := '1';
			r.LTU_TRIGGER :='1';					
		     end if; --synch signal		
		     
		  else	 
		     if ro.CHOKE_ON = '1' and ro.sentCHOKE_ON ='0' then
			---------CHOKE ON-------------------
                       r.RESTART        := '0';
                       --Wait 3 timestamp avoiding deltas
                       if(UINT(ro.CHOKE_ON_Delay) = 3) then
                         r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);
                         r.LTU0           := '0';
                         r.LTU1           := '0';
                         r.LTU2           := '1';
                         r.LTU3           := '0';
                         r.LTU4           := '0';
                         r.LTU5           := '1';
                         r.LTU_TRIGGER    := '1';		
                         r.sentCHOKE_ON   := '1';
                         r.sentCHOKE_OFF  := '0';
                         r.chokeOn_ev40   := '1';
                         r.counterCHOKE   := SLV(UINT(ro.counterCHOKE) +1,32);
                         r.write_ev40     := '0'; --scrivi sul mac_sgmii
                         r.CHOKE_ON_Delay := (others =>'0');
                         r.delayafterchoke := (others => '0');
                         r.safedistance   := (others => '0');
                        else
                          r.CHOKE_ON_Delay := SLV(UINT(ro.CHOKE_ON_Delay)+1,3);
                        end if;     

                     elsif ro.ERROR_ON = '1' and ro.sentERROR_ON ='0'  then
                       r.RESTART        := '0';
                       ---------ERROR ON-------------------
                       --Wait 3 timestamp avoiding deltas
                       if(UINT(ro.ERROR_ON_Delay) = 3) then
                        r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);                          
			r.LTU0           := '0';
			r.LTU1           := '1';
			r.LTU2           := '1';
			r.LTU3           := '0';
			r.LTU4           := '0';
			r.LTU5           := '1';
			r.LTU_TRIGGER    := '1';		
			r.sentERROR_ON   := '1';
			r.sentERROR_OFF  := '0';
			r.errorOn_ev40   := '1';
			r.counterERROR   := SLV(UINT(ro.counterERROR) +1,32);
			r.write_ev40     := '0'; --scrivi sul mac_sgmii
                        r.ERROR_ON_Delay := (others =>'0');
			r.safedistance   := (others => '0');
                        r.delayafterchoke := (others => '0');
                        
                       else
                          r.ERROR_ON_Delay := SLV(UINT(ro.ERROR_ON_Delay)+1,3);
                       end if;

		       --Generate a delay in order to avoid timing missmatch 
		     elsif ro.CHOKE_OFF = '1' and ro.sentCHOKE_OFF ='0' and ro.RESTART = '0' then
			if UINT(ro.delayafterchoke) =  UINT(ro.Fixed_Latency) then
			   r.RESTART := '1';
			   r.delayafterchoke := (others => '0');
			else
			   r.RESTART := '0';
			   r.delayafterchoke := SLV(UINT(ro.delayafterchoke) + 1, 32);
			end if;


		      elsif ro.ERROR_OFF = '1' and ro.sentERROR_OFF ='0' and ro.RESTART = '0' then
			if UINT(ro.delayafterchoke) =  UINT(ro.Fixed_Latency) then
			   r.RESTART := '1';
			   r.delayafterchoke := (others => '0');
			else
			   r.RESTART := '0';
			   r.delayafterchoke := SLV(UINT(ro.delayafterchoke) + 1, 32);
			end if;
                    


			
		     elsif ro.CHOKE_OFF = '1' and ro.sentCHOKE_OFF ='0' and ro.RESTART = '1' then
			---------CHOKE OFF-------------------
			r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);
			r.LTU0           := '1';
			r.LTU1           := '0';
			r.LTU2           := '1';
			r.LTU3           := '0';
			r.LTU4           := '0';
			r.LTU5           := '1';
			r.LTU_TRIGGER    := '1';			
			r.sentCHOKE_ON   := '0';
			r.sentCHOKE_OFF  := '1';
			r.chokeOff_ev40  := '1';
			r.write_ev40     := '0'; --scrivi sul mac_sgmii
			
			
                     elsif ro.ERROR_OFF = '1'  and ro.sentERROR_OFF ='0' and ro.RESTART = '1' then
			---------ERROR OFF-------------------
			r.counterLTU     := SLV(UINT(ro.counterLTU)+1,32);
			r.LTU0           := '1';
			r.LTU1           := '0';
			r.LTU2           := '1';
			r.LTU3           := '0';
			r.LTU4           := '0'; 
			r.LTU5           := '1';
			r.LTU_TRIGGER    := '1';			
			r.sentERROR_ON   := '0';
			r.sentERROR_OFF  := '1';
			r.errorOff_ev40  := '1';
			r.write_ev40     := '0'; --scrivi sul mac_sgmii
	

                     elsif ro.sentCHOKE_OFF  = '1' and ro.sentERROR_OFF= '1' and  UINT(ro.safedistance) /= 3  and ro.RESTART = '1'  then
                         r.safedistance := SLV(UINT(ro.safedistance) +1,4);
                      

		     elsif n.LATENCYRAM.outputs.q_b(5 downto 0) /="000000"  and ro.ERROR_ON ='0' and ro.CHOKE_ON ='0' and ro.sentCHOKE_OFF  = '1' and ro.sentERROR_OFF= '1' and UINT(ro.safedistance) = 3 then --SOLO PRIM	
			
			if (abs(ro.latencyreadaddressb - ro.oldlatencyreadaddressb)) > UINT(ro.primitiveDT) + 1  then --controllo timestamp
			   r.oldlatencyreadaddressb    := ro.latencyreadaddressb - 1;
			   
			   if n.FIFODETECTORFARM.outputs.wrfull ='0' then   				    
			      r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);
			      ----------PHYSICAL OR CALIB TRIGGERS-------------------
			      r.LTU0 := n.LATENCYRAM.outputs.q_b(0); 
			      r.LTU1 := n.LATENCYRAM.outputs.q_b(1);
			      r.LTU2 := n.LATENCYRAM.outputs.q_b(2);
			      r.LTU3 := n.LATENCYRAM.outputs.q_b(3);
			      r.LTU4 := n.LATENCYRAM.outputs.q_b(4);
			      r.LTU5 := n.LATENCYRAM.outputs.q_b(5);
			      r.LTU_TRIGGER :='1';		
			     	      
			      n.FIFODETECTORFARM.inputs.data := n.LATENCYRAM.outputs.q_b(16 downto 6);
			      n.FIFODETECTORFARM.inputs.wrreq :='1';
			      
			      r.ecounter40    := SLV(UINT(ro.ecounter40)+1,16); --conta quanti dati stai scrivendo sul MAC
			      r.write_ev40    := '1'; --scrivi sul mac_sgmii
			   else
			       r.ETHLINKERROR :=	ro.ETHLINKERROR OR SLV(65536,32); 
			   end if; --controllo fifo piena. se e' piena non spedire ne' alla farm ne' ai detector
			   
			end if; --controllo timestamp
			
		     end if;--fine controllo latency ram	
		     
		  end if; --fine controllo synch			     	 
		  
		  r.FSMSendDetectors :=S2; --SONO ANCORA NEL BURST
		  
	       elsif	ro.BURST40 ='0'  then--arriva l'EOB 
		  
		  if ro.activate_SOBEOBtrigger='1' then
		     r.counterLTU  := SLV(UINT(ro.counterLTU)+1,32);
		     r.LTU0        := '1';
		     r.LTU1        := '1';
		     r.LTU2        := '0';
		     r.LTU3        := '0';
		     r.LTU4        := '0';
		     r.LTU5        := '1';
		     r.LTU_TRIGGER := '1'; 
		     r.eob_ev40    := '1'; -- manda l'eob
 		     r.FSMSendDetectors :=S3; 
		  else           
		     r.FSMSendDetectors :=S3; 
		  end if;
		  
	       end if;
	       
	    when S3=>--DOPO EOB
	       ------------------------------------------------------
	       r.latencyreadaddressb := ro.latencyreadaddressb+1;		 
	       --------------------------------------------------------------
	       n.LATENCYRAM.inputs.rden_b    :='0';
	       n.LATENCYRAM.inputs.address_b := std_logic_vector(ro.latencyreadaddressb(14 downto 0));
	       n.LATENCYRAM.inputs.wren_b    :='1'; --Because it is a TDP ram, RDW done calling old data --PERMETTE DI RESETTARE
	       n.LATENCYRAM.inputs.data_b    :=(others =>'0');
	       n.SENDRAM.inputs.address_b := std_logic_vector(ro.latencyreadaddressb(9 downto 0));
	       n.SENDRAM.inputs.data_b    := (others =>'0');
	       r.sentCHOKE_ON   := '0';
	       r.sentCHOKE_OFF  := '1';
               r.sentERROR_ON   := '0';
	       r.sentERROR_OFF  := '1';
	       --------------------------------------------------------------
	       if ro.latencycounter /= UINT(ro.Fixed_Latency)+ 40000 then --Rimani qui per il tempo della latenza per resettare la ram
		  r.latencycounter := ro.latencycounter+1;
		  r.FSMSendDetectors :=S3;
	       else
	          r.delayafterchoke              := (others => '0');
		  r.RESTART                      := '0';
		  r.safedistance                 := SLV(3,4);
		  r.eob_ev40                     := '0'; -- manda l'eob
		  r.latencyreadaddressb          := (others=>'0');	
		  r.oldlatencyreadaddressb       := (others=>'0');
                  r.ETHLINKERROR                 := (others=>'0'); 
		  r.latencycounter               := 0;
		  r.FSMSendDetectors             := S0_0;
		  r.ecounter40                   := (others=>'0');
		  r.write_ev40                   :='0';
                  n.FIFODETECTORFARM.inputs.aclr :='1';   
	       end if;
	 end case;
      end procedure; 


      ---------------------------------------------------------------
      procedure SubSendFARM
	 (variable i : in inputs_t;
	  variable ri: in reglist_clk125_t;
	  variable ro: in reglist_clk125_t;
	  variable o : inout outputs_t;
	  variable r : inout reglist_clk125_t;
	  variable n : inout netlist_t
	  ) is
      begin
	 n.FIFOPACKETS.inputs.aclr           :='0';
	 n.FIFOPACKETS.inputs.rdclk          :=n.clk125;      
	 n.FIFOPACKETS.inputs.rdreq          :='0';
	 
	 -- src/dest loopback
	 n.MAC(3).outputs.rsrcaddr(FF_PORT)  :=SLV(7,8);
	 n.MAC(3).inputs.wdestaddr(FF_PORT)  := x"14";  --loop procedure is on
							--na62l0tp2 PC. the
							--program to run the
							--loop process is: read_primitives.
	 n.MAC(3).inputs.wdestport(FF_PORT)  := SLV(1,4);
	 n.MAC(3).outputs.rsrcport(FF_PORT)  := SLV(1,4);
	 n.MAC(3).inputs.wtxclr(FF_PORT)     := '0';
	 n.MAC(3).inputs.wena(FF_PORT)       := '1';
	 n.MAC(3).inputs.wclk(FF_PORT)       := n.clk125;
	 n.MAC(3).inputs.wrst(FF_PORT)       := n.rst.clk125; 
	 n.MAC(3).inputs.wdata(FF_PORT)      :=(others =>'0');
	 n.MAC(3).inputs.wreq(FF_PORT)       := '0';
	 n.MAC(3).inputs.wtxreq(FF_PORT)     := '0';

             
         --------------------------------------------------------------   
	 r.MEPSourceID       :=x"40"; --by definition from dataformats
	 r.MEPSourceSubID    :=x"03"; --ethernet which sends data
	 ---------------------------------------------------------------      
	 r.MEPLenEOB    :=SLV(8+464+384,16); --#of prim + header    	
			 
	 case ro.FSMSend is
	    when idle =>
	       
	       if (ro.MEPEventWritten(7 downto 0) = ro.MEPEventNumber(7 downto 0)) then
		  r.MEPEventRead :=  ro.MEPEventNumber(7 downto 0);-- quanti ne devo leggere.
		  r.MEPLen       :=SLV(UINT(ro.MEPEventWritten)*96+8,16); --#of prim + header    	
		  r.framelen     := SLV(28+8+96*UINT(ro.MEPEventWritten),11); --#of prim + header		
		  r.FSMSend      := PacketHeader;
		  
	       elsif  ro.eob_ev125 ='1' and ro.eob_data_send ='0' then --I have
								       --to
								       --send EOB
		  
		  r.MEPEventRead :=  ro.MEPEventWritten;-- #of event to fit in
							-- the last packet.
		  r.eob_data_send:='1';
		  r.FSMSend   := PacketHeaderEOB;
		  r.MEPLen    :=SLV(UINT(ro.MEPEventWritten)*96+8,16); --#of prim + header    	
		  r.framelen  := SLV(28+8+96*UINT(ro.MEPEventWritten),11); --#of prim+header+IP header		
	       else
		  r.FSMSend := Idle;
	       end if;


	    when PacketHeader => --HEADER OF PACKET
	       
	       -- 1) -----HEADER-------------------------------------------------
	       if n.FIFOPACKETS.outputs.rdempty ='0' then
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)   := ro.MEPSourceSubID              ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 55  downto  48)  := ro.MEPEventRead                ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)   := ro.MEPLen(15 downto 8)         ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)   := ro.MEPLen(7 downto 0)          ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)   := ro.MEPsourceID                 ;   
		     n.MAC(3).inputs.wdata(FF_PORT)( 23  downto  16)  := ro.MEPeventNum(23 downto 16)   ; 
		     n.MAC(3).inputs.wdata(FF_PORT)( 15  downto  8)   := ro.MEPeventNum(15 downto 8)    ; 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7  downto  0)    := ro.MEPeventNum(7 downto 0)     ; 
		     n.MAC(3).inputs.wreq(FF_PORT)                    := '1'                            ;
		     n.FIFOPACKETS.inputs.rdreq :='1';
		     r.FSMSend :=EventHeader;
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);   
		     r.FSMSend := PacketHeader;
		  else
		     r.ETHLINKERROR :=ro.ETHLINKERROR OR SLV(32,32); 
		     r.FSMSend :=  Idle;
		  end if;	--end header
	       else
		  r.FSMSend :=PacketHeader;
		  
	       end if;
	       
	    when PacketHeaderEOB=> --ONLY EOB
	       if ro.MEPEventRead /="00000000" then	
		  if n.FIFOPACKETS.outputs.rdempty ='0' then  
		     if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
			n.FIFOPACKETS.inputs.rdreq :='1';  
			n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)   := ro.MEPSourceSubID              ;
			n.MAC(3).inputs.wdata(FF_PORT)( 55  downto  48)  := SLV(UINT(ro.MEPEventRead),8)   ; 
			n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)   := ro.MEPLen(15 downto 8)         ;
			n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)   := ro.MEPLen(7 downto 0)          ;
			n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)   := ro.MEPsourceID                 ;   
			n.MAC(3).inputs.wdata(FF_PORT)( 23  downto  16)  := ro.MEPeventNum(23 downto 16)   ; 
			n.MAC(3).inputs.wdata(FF_PORT)( 15  downto  8)   := ro.MEPeventNum(15 downto 8)    ; 
			n.MAC(3).inputs.wdata(FF_PORT)( 7  downto  0)    := ro.MEPeventNum(7 downto 0)     ;   
			n.MAC(3).inputs.wreq(FF_PORT)                    := '1'                            ;
			r.FSMSend :=EventHeader;
		     elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
			r.FSMSend := PacketHeaderEOB;
			r.ETHLINKERROR :=SLV(16,32);
		     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		     end if;	--end header eob		
		     
		     
		  else --fifo non pronta
		     r.FSMSend := PacketHeaderEOB;
		  end if;

	       else -- non ho da leggere
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)   := ro.MEPSourceSubID              ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 55  downto  48)  := SLV(1,8)                       ; --1 per l'eob
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)   := ro.MEPLenEOB(15 downto 8)      ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)   := ro.MEPLenEOB(7 downto 0)       ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)   := ro.MEPsourceID                 ;   
		     n.MAC(3).inputs.wdata(FF_PORT)( 23  downto  16)  := ro.MEPeventNum(23 downto 16)   ; 
		     n.MAC(3).inputs.wdata(FF_PORT)( 15  downto  8)   := ro.MEPeventNum(15 downto 8)    ; 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7  downto  0)    := ro.MEPeventNum(7 downto 0)     ;   
		     n.MAC(3).inputs.wreq(FF_PORT)                    := '1'                            ;
		     r.FSMSend :=EventHeader;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := PacketHeaderEOB;
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32); 
		  else null;
		       r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(32,32); 
		  end if;	--end header eob

	       end if;

--------MEP HEADER EOB-------------------------------------------------   	 
	       

	       
	    when EventHeader =>
	       
	       -------------------Event header-------------------------------------------------------------------------
	       
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := ro.eob_data125(191 downto 184);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := ro.eob_data125(183 downto 176);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := ro.eob_data125(175 downto 168);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := ro.eob_data125(167 downto 160);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := "10000000";--EVENT FLAG
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := SLV(3,8);  --Length of event (400)
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)    := SLV(80,8);--Length of event
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.MEPeventNum :=SLV(UINT(ro.MEPeventNum)+1,24);
		     r.FSMSend := Data_0;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := EventHeader;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;		
		  
	       else
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q( 63 downto  56);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 55 downto  48);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 47 downto  40);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 39 downto  32);
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 31 downto  24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := ro.MEPeventNum(7 downto 0);
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 15 downto  8) ;--LengthOfEvent
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)    := n.FIFOPACKETS.outputs.q( 7 downto  0)  ;--LengthOfEvent	
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.MEPeventNum :=SLV(UINT(ro.MEPeventNum)+1,24);
		     r.FSMSend := Data_0;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := EventHeader;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);

		  end if;		  


	       end if;
	       
	    ---------------------Event data_0-------------------------------------------------------------------------- 	
	    when Data_0 =>
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then    
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := (others =>'0');
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.control_detector(7 downto 0);                                                      
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.reference_detector(7 downto 0);   
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.finetime_bits(7 downto 0);   	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.fixed_Latency125(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.fixed_Latency125(7 downto 0);    	                                                       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.eob_data125(17 downto 10);--Data type  
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := (others =>'0');
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';		
		     r.FSMSend := Data_1;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_0;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;		
		  
		  
	       else
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then    
		     n.MAC(3).inputs.wdata(FF_PORT)(63  downto  56)   := n.FIFOPACKETS.outputs.q(127  downto  120);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)   := n.FIFOPACKETS.outputs.q( 119 downto  112);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)   := n.FIFOPACKETS.outputs.q( 111 downto  104);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)   := n.FIFOPACKETS.outputs.q( 103 downto  96) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)   := n.FIFOPACKETS.outputs.q( 95 downto  88)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)   := n.FIFOPACKETS.outputs.q( 87 downto  80)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto   8)   := n.FIFOPACKETS.outputs.q( 79 downto   72) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)     := n.FIFOPACKETS.outputs.q( 71 downto  64)  ;

		     n.MAC(3).inputs.wreq(FF_PORT) := '1';		
		     r.FSMSend := Data_1;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_0;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);

		  end if;		
		  
	       end if;
	       
	    ---------------------Event data_1-------------------------------------------------------------------------- 	
	    when Data_1 =>
	       
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then	
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.ntriggers_predownscaling_control(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.ntriggers_predownscaling_control(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.ntriggers_predownscaling_control(15 downto 8);	       
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.ntriggers_predownscaling_control(7 downto 0);	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.control_trigger_downscaling(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.control_trigger_downscaling(7 downto 0);	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := (others=>'0');  --reserved
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := (others=>'0');  --reserved

		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_2;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_1;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;		

	       else
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then
		     n.MAC(3).inputs.wdata(FF_PORT)(63  downto  56) := n.FIFOPACKETS.outputs.q(191  downto  184) ; --primitiveID G 	
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48) := n.FIFOPACKETS.outputs.q( 183 downto  176) ; --primitiveID G     	
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40) := n.FIFOPACKETS.outputs.q( 175 downto  168) ; --primitiveID F
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32) := n.FIFOPACKETS.outputs.q( 167 downto  160) ; --primitiveID F     	
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24) := n.FIFOPACKETS.outputs.q( 159 downto  152) ; --primitiveID E     
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16) := n.FIFOPACKETS.outputs.q( 151 downto  144) ; --primitiveID E
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto   8) := n.FIFOPACKETS.outputs.q( 143 downto   136); --primitiveID D     		
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)   := n.FIFOPACKETS.outputs.q( 135 downto  128) ; --primitiveID D 
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_2;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_1;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;		
	       end if;	
	       
	    ---------------------Event data_2-------------------------------------------------------------------------- 	
	    when Data_2 => 
	       
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB

		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.eob_data125(33 downto 26)   ; --EVENT             
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.eob_data125(25 downto 18)   ; --TW        
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := SLV(ro.old_tw,8)               ;             
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := SLV(ro.eob_data125(151 downto 146),8);--TW HW 	                                              
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) :=ro.old_timestamp(31 downto 24)  ;                    
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) :=ro.old_timestamp(23 downto 16)  ;                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) :=ro.old_timestamp(15 downto 8)   ;             
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  :=ro.old_timestamp(7 downto 0)    ;              
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_3;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_2;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
		  
	       else --DATIs
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q( 255 downto  248); --EV TW
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 247 downto  240); --EV TW 
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 239 downto  232);-- OLDTW       
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 231 downto  224);-- TW
		     --old timestamp:
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 223 downto  216);       
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 215 downto  208); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 207 downto  200); 
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q(199  downto  192);
		     ----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     
		     r.FSMSend := Data_3; --DATA END
		  ------------------------------------------ 
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_2;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32); 
		 else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
		  
	       end if;
	       
	    ----------------------------------------------------------------------------------------------- 	
	    when Data_3 =>
	       
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(1)(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(1)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(1)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(1)(7 downto 0);    
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(0)(31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(0)(23 downto 16);       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(0)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(0)(7 downto 0);    
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_4;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_3;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                  else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;   
		  
	       else --DATA 
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := (others =>'0'); --reserved per le flag ulteriori                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := (others =>'0'); --reserved per le flag ulteriori  
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := (others =>'0'); --reserved per le flag ulteriori             
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := (others =>'0'); --reserved per le flag ulteriori       	                                                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q(687 downto 680);--DPrim NewCHOD 
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q(679 downto 672);--DPrim MUV3
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q(671 downto 664);--DPrim RICH
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q(663 downto 656);--DPrim CHOD
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_4;			
		     
		     ------------------------------------------ 
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_3;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32); 
		 else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; --mac
		  
	       end if;--dati
	       
	    -----------------Data 4 SPEDISCO I DATI E VADO AVANTI SE EOB ---------------------------------------------------------------------------------------
	    when Data_4 =>
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(3)  (31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(3)  (23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(3)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(3)  (7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(2)  (31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(2)  (23 downto 16);       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(2)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(2)  (7 downto 0);    
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_5;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_4;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
		  
		  
	       else --DATA 4
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := (others =>'0'); --reserved                  
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 311 downto  304); --FT G 0   
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 303 downto  296); --FT F 0              
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 295 downto  288); --FT E 0        	                                                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 287 downto  280); --FT D 0   
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 279 downto  272); --FT C 0
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 271 downto  264); --FT B 0
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q(263  downto  256); --FT A 0
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_5;
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_4;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32); 
		  
		    else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; --mac
	       end if;
	       
	    -----------------------------------Data 5----------------------------------------------------------------------
	    when Data_5 =>
	       if ro.eob_data_send = '1'  and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(5)  (31 downto 24); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(5)  (23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(5)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(5)  (7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(4)  (31 downto 24);          
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(4)  (23 downto 16);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(4)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(4)  (7 downto 0);      
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_6;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_5;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
		  
	       else --DATA 5
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q( 479 downto  472); --primitive C   1
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 471 downto  464); --primitive C   1              
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q(463 downto  456);  --primitive B   1                      
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q(455  downto  448); ---primitive B  1   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 447 downto  440); -- primitive A  1
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 439 downto  432); --ptimitive A   1
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := (others =>'0') ; --reserved
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    :=	(others => '0'); --reserved  
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_6;--RITENTA
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_5;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
		     r.ETHLINKERROR :=SLV(32,32);
		  end if; --mac
	       end if;
	       
	       ----------------------------Data 6---------------------------------------------------------------------------
	       
	    when Data_6 =>
	       if ro.eob_data_send = '1'  and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_CHOKE(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_CHOKE(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_CHOKE(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_CHOKE(7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(6)(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(6)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(6)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(6)(7 downto 0);   
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_7;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_6;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
		  
	       else 
		  
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q( 543 downto  536); --primitive  G  1                  
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 535 downto  528); -- primitive G  1
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q(527 downto  520);  -- primitive F  1             
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q(519  downto  512); -- primitive F  1        	                                                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 511 downto  504); -- primitive E  1   
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 503 downto  496); -- primitive E  1 
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 495 downto  488); -- primitive D  1 
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q( 487 downto  480); -- primitive D  1 

		     

----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_7;	 
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_6;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32); 
		  else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; --mac
	       end if;
	       
	    ----------------------------Data 7---------------------------------------------------------------------------
	    when Data_7 =>
	       if ro.eob_data_send = '1'  and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.periodicrandomtriggercounter(31 downto 24);          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.periodicrandomtriggercounter(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.periodicrandomtriggercounter(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.periodicrandomtriggercounter(7 downto 0)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_error(31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_error(23 downto 16);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_error(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_error(7 downto 0);  
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_8;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_7;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := (others =>'0');			                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 367 downto  360); --FT G 1   
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 359 downto  352); --FT F 1              
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 351 downto  344); --FT E 1        	                                    
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 343 downto  336); --FT D 1
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q(335 downto   328); --FT C 1
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q(327  downto  320); --FT B 1
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q( 319 downto  312); --FT A 1

		   
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_8;  
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_7;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       end if;
	       
-----------------------------Data 8-----------------------------------------------------------------------------
	    when Data_8 => 
	       if ro.eob_data_send = '1'  and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.ntriggers_postdownscaling_control(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.ntriggers_postdownscaling_control(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.ntriggers_postdownscaling_control(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.ntriggers_postdownscaling_control(7 downto 0);
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.calibration_trigger(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.calibration_trigger(23 downto 16);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.calibration_trigger(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.calibration_trigger(7 downto 0)  ;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_9;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_8;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q(591 downto  584);  -- primitive C   2                  
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q(583  downto  576); -- primitive C   2   
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 575 downto  568); -- primitive B   2              
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 567 downto  560); --primitive  B   2        	                            
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 559 downto  552); --primitive  A   2
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 551 downto  544); --primitive  A   2
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := (others=>'0');--reserved
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := (others=>'0');--reserved
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_9;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_8;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if;
	       end if;
	       ----------------------------------Data 9----------------------------------------------------------------------

	       -----------ONLY EOB!!!!!!!!!!!!!!!!!!!!!! => MASK CONFIGURATION
	    when Data_9 =>
	       if ro.eob_data_send = '1'  and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.downscaling(ro.maskindex)(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.downscaling(ro.maskindex)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.downscaling(ro.maskindex)(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.downscaling(ro.maskindex)(7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := (others=>'0');                         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := (others=>'0');                        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := (others=>'0');           
		     if(ro.maskindex=0) then    
			n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"00";
		     elsif (ro.maskindex=1) then
			n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"01";
		     elsif (ro.maskindex=2) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"02";
		     elsif (ro.maskindex=3) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"03";
		     elsif(ro.maskindex=4) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"04";
		     elsif(ro.maskindex=5) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"05";
		     elsif(ro.maskindex=6) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"06";
		     elsif(ro.maskindex=7) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"07";
                     elsif(ro.maskindex=8) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"08";
                     elsif(ro.maskindex=9) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"09";
                     elsif(ro.maskindex=10) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0a";
                     elsif(ro.maskindex=11) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0b";
                     elsif(ro.maskindex=12) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0c";
                     elsif(ro.maskindex=13) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0d";
                     elsif(ro.maskindex=14) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0e";
                     elsif(ro.maskindex=15) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0f";
                       
		     end if;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_10;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_9;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(16,32);
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);

		  end if; 
	       else 
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := n.FIFOPACKETS.outputs.q(655 downto  648);  -- primitive  G   2                  
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q(647  downto  640); -- primitive  G   2   
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 639 downto  632); -- primitive  F   2               
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 631 downto  624); -- primitive  F   2        	                                                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q( 623 downto  616); -- primitive  E   2
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q( 615 downto  608); -- primitive  E   2
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 607 downto  600); -- primitive  D   2
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q( 599 downto  592); -- primitive  D   2
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_10;  
		  end if; 
	       end if;
	       
	       -----------------------Data 10----------------------------------------------------------------------------------
	       
	       
	    when Data_10 =>
	       if ro.eob_data_send = '1' and ro.MEPEventRead ="00000000" then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56)  := ro.ntriggers_predownscaling(ro.maskindex)(31 downto 24)  ;       
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48)  := ro.ntriggers_predownscaling(ro.maskindex)(23 downto 16)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40)  := ro.ntriggers_predownscaling(ro.maskindex)(15 downto 8)   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32)  := ro.ntriggers_predownscaling(ro.maskindex)(7 downto 0)    ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24)  := ro.ntriggers_postdownscaling(ro.maskindex)(31 downto 24);      
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16)  := ro.ntriggers_postdownscaling(ro.maskindex)(23 downto 16);     
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)  := ro.ntriggers_postdownscaling(ro.maskindex)(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)   := ro.ntriggers_postdownscaling(ro.maskindex)(7 downto 0)  ;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_11;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_10;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := (others=>'0');               
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := n.FIFOPACKETS.outputs.q( 423 downto  416); --FT G 2 
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := n.FIFOPACKETS.outputs.q( 415 downto  408); --FT F 2            
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := n.FIFOPACKETS.outputs.q( 407 downto  400); --FT E 2      	                                                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := n.FIFOPACKETS.outputs.q(399 downto  392);  --FT D 2 
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := n.FIFOPACKETS.outputs.q(391  downto  384); --FT C 2
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := n.FIFOPACKETS.outputs.q( 383 downto  376); --FT B 2
		     n.MAC(3).inputs.wdata(FF_PORT)(7  downto  0)    := n.FIFOPACKETS.outputs.q( 375 downto  368); --FT A 2
		     

----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.MEPEventRead := SLV(UINT(ro.MEPEventRead)-1,8); -- ho letto un evento
		     

		     if ro.MEPEventRead ="00000001" then 
		        
			if ro.eob_data_send ='0' then
			   
			   if n.MAC(3).outputs.wempty(FF_PORT) ='0' then --SPEDISCO
			      n.MAC(3).inputs.wframelen(FF_PORT) := ro.framelen;
			      n.MAC(3).inputs.wtxreq(FF_PORT) := '1';
			      r.MEPNum :=SLV(UINT(ro.MEPnum)+1,32);	
			   end if;--fine spedisco		
			   
			   r.FSMSend := idle; --DATA END, no eob

			elsif ro.eob_data_send ='1' then
			   r.FSMSend := PacketHeaderEOB; --DATA END but eob to append
			   r.MEPLen    :=SLV(8+464+384,16); --#of prim + header    	
			   r.framelen  := SLV(28+8+464+384,11); --#of prim+header+IP header
                           r.MEPEventRead := SLV(0,8);      
                           
			   if n.MAC(3).outputs.wempty(FF_PORT) ='0' then
			      --SEND LAST PACKET WITH ONLY DATA (NO EOB). SEND EOB AS STAND ALONE PACKET
			      n.MAC(3).inputs.wframelen(FF_PORT) := ro.framelen;
			      n.MAC(3).inputs.wtxreq(FF_PORT) := '1';
			      r.MEPNum :=SLV(UINT(ro.MEPnum)+1,32);	
			   end if;--fine spedisco		
		
			end if;--fine eob
			
		     else --ho ancora eventi da leggere
			n.FIFOPACKETS.inputs.rdreq :='1';	
			r.FSMSend := EventHeader; --DATA END but eob to append
		     end if; --ho scritto l'ultimo dato 
		     
		  end if; 

	       end if;
	       
	       

	       
---------------------------Data 11------------------------------------------------------------------------------
	       
	    when Data_11=> --det a e b
	       if ro.eob_data_send = '1' then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindex)(95 downto 88)   ;--DetectorB          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindex)(87 downto 80)   ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindex)(95 downto 88)       ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindex)(87 downto 80)       ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindex)(111 downto 104) ;--DetectorA         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindex)(103 downto 96)  ;--DetectorA        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindex)(111 downto 104)     ;--DetectorA
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindex)(103 downto 96)      ;--DetectorA
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_12;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_11;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  r.FSMSend := PacketHeader;--ERROR
	       end if;
	       
---------------------------Data 12------------------------------------------------------------------------------
	       
	    when Data_12 =>
	       if ro.eob_data_send = '1' then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindex)(63 downto 56)    ;--DetectorD          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindex)(55 downto 48)    ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindex)(63 downto 56)        ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindex)(55 downto 48)        ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindex)(79 downto 72)    ;--DetectorC         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindex)(71 downto 64)    ;--DetectorC        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindex)(79 downto 72)        ;--DetectorC
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindex)(71 downto 64)        ;--DetectorC
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_13;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_12;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  r.FSMSend := PacketHeader;--ERROR
	       end if;
	       
	       
	       ---------------------------Data 13------------------------------------------------------------------------------
	       
	    when Data_13 =>
	       if ro.eob_data_send = '1' then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindex)(31 downto 24)   ;--DetectorF          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindex)(23 downto 16)   ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindex)(31 downto 24)       ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindex)(23 downto 16)       ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindex)(47 downto 40)   ;--DetectorE         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindex)(39 downto 32)   ;--DetectorE        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindex)(47 downto 40)       ;--DetectorE
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindex)(39 downto 32)       ;--DetectorE
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_14;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_13;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  r.FSMSend := PacketHeader;--ERROR
	       end if;
	       
	       ---------------------------Data 14------------------------------------------------------------------------------

	    when Data_14 =>
	       if ro.eob_data_send = '1' then --EOB
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := (others =>'0')                   ;          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindex)(15 downto 8);--DetectorG         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindex)(7 downto 0) ;--DetectorG        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindex)(15 downto 8)    ;--DetectorG
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindex)(7 downto 0)     ;--DetectorG
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Data_15;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Data_14;--RITENTA
                     else null;
			  r.ETHLINKERROR :=SLV(32,32);
		  end if; 
	       else 
		  r.FSMSend := PacketHeader;--ERROR
	       end if;
	       
	       


	    when Data_15 => 
	       if ro.maskindex = (nmask - 1) then
		  r.FSMSend                          := IdleDebug;	 
		  r.MEPHeader125                     := '1';	   
		  n.MAC(3).inputs.wframelen(FF_PORT) :=  SLV(28+8+464+384,11);
		  n.MAC(3).inputs.wtxreq(FF_PORT)    := '1';
		  r.MEPNum                           :=SLV(UINT(ro.MEPnum)+1,32);
	  	  r.maskindex                        := 0;
	       else
		  r.FSMSend := Data_9; -- next mask
		  r.maskindex := ro.maskindex + 1; 
	       end if;


	    when IdleDebug =>

	  
	       r.FSMSend   := Debug0;

	 
	    when Debug0 => -- First 8 bytes of Debug
	 --MEP Header
	 --Source ID;
	 --Source SubID;
	 
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 

		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)   := X"ff";--fake
										--SubSourceID to be
										--recognised as debug packet
		     
			n.MAC(3).inputs.wdata(FF_PORT)( 55  downto  48)  := SLV(1,8); --#events in packet
			n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)   := ro.MEPLen(15 downto 8)         ;
			n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)   := ro.MEPLen(7 downto 0)          ;
			n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)   := ro.MEPsourceID                 ;   
			n.MAC(3).inputs.wdata(FF_PORT)( 23  downto  16)  := ro.MEPeventNum(23 downto 16)   ; 
			n.MAC(3).inputs.wdata(FF_PORT)( 15  downto  8)   := ro.MEPeventNum(15 downto 8)    ; 
			n.MAC(3).inputs.wdata(FF_PORT)( 7  downto  0)    := ro.MEPeventNum(7 downto 0)     ;   
			n.MAC(3).inputs.wreq(FF_PORT)                    := '1'                            ;
		     
		     r.FSMSend :=Debug1;
		     
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);   
		     r.FSMSend := Debug0;
		  end if;	--end header

	       

	       
	    when Debug1 => 
	       --EOB Timestamp
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto  56)  := ro.eob_data125(191 downto 184);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto  48)  := ro.eob_data125(183 downto 176);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto  40)  := ro.eob_data125(175 downto 168);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto  32)  := ro.eob_data125(167 downto 160);   --timestamp;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto  24)  := ro.randomtriggercounter(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto  16)  := ro.randomtriggercounter(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)   := ro.randomtriggercounter(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)    := ro.randomtriggercounter(7 downto 0);
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		    
		     r.FSMSend := Debug2;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug1;
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 
		  end if;		
		  
	       
	 when Debug2 =>
	 --Fixed Latency;
	 --Control Detector;
	 --Reference Detector;
	 --Finetime Bits;
	 --Fixed Latency;
	    	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then    
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := (others =>'0');
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.control_detector(7 downto 0);                                                      
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.reference_detector(7 downto 0);   
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.finetime_bits(7 downto 0);   	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.fixed_Latency125(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.fixed_Latency125(7 downto 0);    	                                                       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := (others =>'0');
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.temperature;
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';		
		     r.FSMSend := Debug3;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug2;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if;		
		  
		  	
	    when Debug3 =>
	       --
	    	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then	
                     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.ntriggers_predownscaling_control(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.ntriggers_predownscaling_control(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.ntriggers_predownscaling_control(15 downto 8);	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.ntriggers_predownscaling_control(7 downto 0);	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.control_trigger_downscaling(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.control_trigger_downscaling(7 downto 0);	                                               
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.active_triggers(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.active_triggers(7 downto 0);
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug4;
		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);	
		     r.FSMSend := Debug3;--RITENTA
		  end if;		

	      	
	    when Debug4 => 

		  --Event Trigger Word
		  --Old Trigger Word
		  --Trigger Word
		  --Old Timestamp
		  
	      	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.eob_data125(33 downto 26)   ; --EVENT             
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.eob_data125(25 downto 18)   ; --TW        
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := SLV(ro.old_tw,8)               ;             
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := X"FF";--FAKE TW HW 	                                              
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) :=ro.old_timestamp(31 downto 24)  ;                    
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) :=ro.old_timestamp(23 downto 16)  ;                   
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) :=ro.old_timestamp(15 downto 8)   ;             
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  :=ro.old_timestamp(7 downto 0)    ;              
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug5;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug4;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 
		  end if; 
		  
		  when Debug5 =>
		  
	       --#primitives detector 0
	       --#primitives detector 1
	      
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(1)(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(1)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(1)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(1)(7 downto 0);    
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(0)(31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(0)(23 downto 16);       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(0)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(0)(7 downto 0);    
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug6;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug5;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 

		  end if;   
		  
	     
	       
	   
	    when Debug6 =>
		  --#primitives detector 3
		  --#primitives detector 2
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(3)  (31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(3)  (23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(3)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(3)  (7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(2)  (31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(2)  (23 downto 16);       
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(2)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(2)  (7 downto 0);    
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug7;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug6;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
		  
	    -----------------------------------Data 5----------------------------------------------------------------------
	 when Debug7=>
	  --#primitives detector 4
	  --#primitives detector 5
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_primitives(5)  (31 downto 24); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_primitives(5)  (23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_primitives(5)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_primitives(5)  (7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(4)  (31 downto 24);          
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(4)  (23 downto 16);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(4)  (15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(4)  (7 downto 0);      
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug8;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug7;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       
	    when Debug8 =>
	     	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.number_of_CHOKE(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.number_of_CHOKE(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.number_of_CHOKE(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.number_of_CHOKE(7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_primitives(6)(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_primitives(6)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_primitives(6)(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_primitives(6)(7 downto 0);   
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug9;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug8;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
		   
	    ----------------------------Data 7---------------------------------------------------------------------------
	    when Debug9 =>
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.periodicrandomtriggercounter(31 downto 24);          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.periodicrandomtriggercounter(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.periodicrandomtriggercounter(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.periodicrandomtriggercounter(7 downto 0)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.number_of_error(31 downto 24);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.number_of_error(23 downto 16);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.number_of_error(15 downto 8); 
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.number_of_error(7 downto 0);  
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug10;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug9;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 
		  end if; 
	       
	    when Debug10 => 
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.ntriggers_postdownscaling_control(31 downto 24);
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.ntriggers_postdownscaling_control(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.ntriggers_postdownscaling_control(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.ntriggers_postdownscaling_control(7 downto 0);
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.calibration_trigger(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.calibration_trigger(23 downto 16);        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.calibration_trigger(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.calibration_trigger(7 downto 0)  ;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug11;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug10;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 
		  end if; 
	       
	    when Debug11 =>
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.downscaling(ro.maskindexdebug)(31 downto 24);         
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.downscaling(ro.maskindexdebug)(23 downto 16);
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.downscaling(ro.maskindexdebug)(15 downto 8);
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.downscaling(ro.maskindexdebug)(7 downto 0);  
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := (others=>'0');                         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := (others=>'0');                        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := (others=>'0');           
		     if(ro.maskindexdebug=0) then    
			n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"00";
		     elsif (ro.maskindexdebug=1) then
			n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"01";
		     elsif (ro.maskindexdebug=2) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"02";
		     elsif (ro.maskindexdebug=3) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"03";
		     elsif(ro.maskindexdebug=4) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"04";
		     elsif(ro.maskindexdebug=5) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"05";
		     elsif(ro.maskindexdebug=6) then
		       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"06";
		     elsif(ro.maskindexdebug=7) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"07";
                     elsif(ro.maskindexdebug=8) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"08";
                     elsif(ro.maskindexdebug=9) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"09";
                     elsif(ro.maskindexdebug=10) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0a";
                     elsif(ro.maskindexdebug=11) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0b";
                     elsif(ro.maskindexdebug=12) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0c";
                     elsif(ro.maskindexdebug=13) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0d";
                     elsif(ro.maskindexdebug=14) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0e";
                     elsif(ro.maskindexdebug=15) then
                       n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := X"0f";
		     end if;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug12;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug11;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32); 

		  end if; 
	       
	       
	    when Debug12 =>
	       	  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56)  := ro.ntriggers_predownscaling(ro.maskindexdebug)(31 downto 24)  ;       
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48)  := ro.ntriggers_predownscaling(ro.maskindexdebug)(23 downto 16)  ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40)  := ro.ntriggers_predownscaling(ro.maskindexdebug)(15 downto 8)   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32)  := ro.ntriggers_predownscaling(ro.maskindexdebug)(7 downto 0)    ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24)  := ro.ntriggers_postdownscaling(ro.maskindexdebug)(31 downto 24);      
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16)  := ro.ntriggers_postdownscaling(ro.maskindexdebug)(23 downto 16);     
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8)  := ro.ntriggers_postdownscaling(ro.maskindexdebug)(15 downto 8) ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)   := ro.ntriggers_postdownscaling(ro.maskindexdebug)(7 downto 0)  ;
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug13;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug12;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       

	       
---------------------------Data 11------------------------------------------------------------------------------
	       
	    when Debug13=> --det a e b
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindexdebug)(95 downto 88)   ;--DetectorB          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindexdebug)(87 downto 80)   ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindexdebug)(95 downto 88)       ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindexdebug)(87 downto 80)       ;--DetectorB
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindexdebug)(111 downto 104) ;--DetectorA         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindexdebug)(103 downto 96)  ;--DetectorA        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindexdebug)(111 downto 104)     ;--DetectorA
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindexdebug)(103 downto 96)      ;--DetectorA
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug14;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug13;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       
	       
	    when Debug14 =>
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindexdebug)(63 downto 56)    ;--DetectorD          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindexdebug)(55 downto 48)    ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindexdebug)(63 downto 56)        ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindexdebug)(55 downto 48)        ;--DetectorD
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindexdebug)(79 downto 72)    ;--DetectorC         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindexdebug)(71 downto 64)    ;--DetectorC        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindexdebug)(79 downto 72)        ;--DetectorC
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindexdebug)(71 downto 64)        ;--DetectorC
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug15;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug14;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       
	    when Debug15 =>
	       
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := ro.dontcare(ro.maskindexdebug)(31 downto 24)   ;--DetectorF          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := ro.dontcare(ro.maskindexdebug)(23 downto 16)   ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := ro.mask(ro.maskindexdebug)(31 downto 24)       ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := ro.mask(ro.maskindexdebug)(23 downto 16)       ;--DetectorF
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindexdebug)(47 downto 40)   ;--DetectorE         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindexdebug)(39 downto 32)   ;--DetectorE        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindexdebug)(47 downto 40)       ;--DetectorE
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindexdebug)(39 downto 32)       ;--DetectorE
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug16;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug15;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       

	    when Debug16 =>
		  if n.MAC(3).outputs.wready(FF_PORT)='1' and n.MAC(3).outputs.wfull(FF_PORT) ='0' then 			
		     n.MAC(3).inputs.wdata(FF_PORT)( 63 downto 56) := (others =>'0')                   ;          
		     n.MAC(3).inputs.wdata(FF_PORT)( 55 downto 48) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 47 downto 40) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 39 downto 32) := (others =>'0')                   ;
		     n.MAC(3).inputs.wdata(FF_PORT)( 31 downto 24) := ro.dontcare(ro.maskindexdebug)(15 downto 8);--DetectorG         
		     n.MAC(3).inputs.wdata(FF_PORT)( 23 downto 16) := ro.dontcare(ro.maskindexdebug)(7 downto 0) ;--DetectorG        
		     n.MAC(3).inputs.wdata(FF_PORT)( 15 downto  8) := ro.mask(ro.maskindexdebug)(15 downto 8)    ;--DetectorG
		     n.MAC(3).inputs.wdata(FF_PORT)( 7 downto  0)  := ro.mask(ro.maskindexdebug)(7 downto 0)     ;--DetectorG
----------------------------------------------------------------------------------------------------------------
		     n.MAC(3).inputs.wreq(FF_PORT) := '1';
		     r.FSMSend := Debug17;	 

		  elsif n.MAC(3).outputs.wready(FF_PORT)='0'  then
		     r.FSMSend := Debug16;--RITENTA
		     r.ETHLINKERROR := ro.ETHLINKERROR OR SLV(64,32);
		  end if; 
	       
	       


	    when Debug17 =>
	       if ro.maskindexdebug = (nmask - 1) then
		  r.FSMSend                             :=Idle;	 
		  n.MAC(3).inputs.wframelen(FF_PORT)    := SLV(28+8+464+384,11); --#of prim + header
		  n.MAC(3).inputs.wtxreq(FF_PORT)       :='1';
		  r.maskindexdebug                      := 0; 	
	       else
		  r.FSMSend := Debug11; -- next mask
		  r.maskindexdebug := ro.maskindexdebug + 1; 
	       end if;

	 end case;	 
      end procedure;  





      
      
      procedure Clock20MHz
	 (
	    variable i : in inputs_t;
	    variable ri: in reglist_clk40_t;
	    variable ro: in reglist_Clk40_t;
	    variable o : inout outputs_t;
	    variable r : inout reglist_Clk40_t;
	    variable n : inout netlist_t
	    ) is
      begin

	 if ro.activate_clock20MHz = '1' then
	    if  n.clk40='1' then
	       if ro.clockDiv =1 then
		  r.clockDiv:=0;
		  r.div2:=not(n.clk40);
	       else
		  r.clockDiv:=ro.clockDiv+1;
		  r.div2 := n.clk40;
	       end if;
	    end if;
	    o.LTU3 := ro.div2;
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
		  --Reset FSMs:
		  r.FSMResetCounters             := S1;
		  r.FSMSend                      := Idle;--SPEDISCE E CREA UN PACCHETTO NUOVO
		  r.FSMSendDebug                 := Idle;--SPEDISCE E CREA UN PACCHETTO NUOVO
		  r.FSMDelay                     := (others=>skipdata);
		  r.FSMReceive64bit(0)           := S0;
		  r.FSMReceive32bit(0)           := S0;
		  r.enet_FSMReceive64bit(0)      := S0;
		  r.enet_FSMReceive32bit(0)      := S0;
		  r.FSMReceive64bit(1)           := S0;
		  r.FSMReceive32bit(1)           := S0;
		  r.enet_FSMReceive64bit(1)      := S0;
		  r.enet_FSMReceive32bit(1)      := S0;
             	  r.FSMReceive64bit(2)           := S0;
		  r.FSMReceive32bit(2)           := S0;
		  r.enet_FSMReceive64bit(2)      := S0;
		  r.enet_FSMReceive32bit(2)      := S0;
		  r.enet_FSMReceive64bit(3)      := S0;
		  r.enet_FSMReceive32bit(3)      := S0;

		  r.enet_headerreceived(0)       :='0';
		  r.enet_headerreceived(1)       :='0';
		  r.enet_headerreceived(2)       :='0';
		  r.enet_headerreceived(3)       :='0';
		  r.headerreceived(0)            :='0';
		  r.headerreceived(1)            :='0';
		  r.headerreceived(2)            :='0';

		  r.enet_headermode(0)          :='1';
		  r.enet_headermode(1)          :='1';
		  r.enet_headermode(2)          :='1';
		  r.enet_headermode(3)          :='1';
		  r.headermode(0)               :='1';
		  r.headermode(1)               :='1';
		  r.headermode(2)               :='1';
        r.errorchecktimestamp         := (others =>'0');  
		  r.old_number_of_primitives            := (others=>"00000000000000000000000000000000");
		  r.number_of_primitives            := (others=>"00000000000000000000000000000000");
		  r.ETHLINKERROR                    := SLV(0,32);
		  r.calibration_trigger             := SLV(0,32);
		  r.number_of_CHOKE                 := (others=>'0');
		  r.number_of_ERROR                 := (others=>'0');
		  r.old_timestamp                   := (others=>'0');
		  r.old_tw                          := (others=>'0');
		  r.MEPeventNum                     := (others=>'0');
		  r.MEPNum                          := (others=>'0');
		  r.periodicrandomtriggercounter    := (others=>'0');
                  r.randomtriggercounter            := (others=>'0');
		  r.MTPNUMREF                       := (others=>"00000000");  
		
		  r.fifODelay                    := (others=>"00000000000000000000000000000000");
		  r.sent                         := '1';
		  r.MEPeventWritten              := (others =>'0');
		  r.MEPeventRead                 := (others =>'0');
		  r.eob_data_send                := '0';	
		  r.start_latency                := (others=>'0');
		  r.readdetector                 := (others=>'0');
		  r.addressfarm                  := (others=>'0');
		  r.maskindex                    := 0; 
		  r.maskindexdebug               := 0; 
		  
		  n.ERRORFIFOOFF.inputs.aclr     := '1';
		  n.CHOKEFIFOOFF.inputs.aclr     := '1';
		  n.ERRORFIFOON.inputs.aclr      := '1';
		  n.CHOKEFIFOON.inputs.aclr      := '1';
		  n.FIFOPACKETS.inputs.aclr      := '1';
		  
		  r.timerdebug                   := 0;
		  
	       else
--EOB--
		  r.FSMResetCounters :=S0;
	       end if;

	    when s1=>
	       
	       if ro.BURST125 ='0' then --EOB
		  if  n.CHOKEFIFOON.outputs.rdempty ='0' and  i.readchokefifoon = '1' then
		      o.outchokefifoon  := n.CHOKEFIFOON.outputs.q;
		      n.CHOKEFIFOON.inputs.rdreq :='1'; 
	          else
	             o.outchokefifoon  := (others=>'0');
	          end if;

		   if  n.CHOKEFIFOOFF.outputs.rdempty ='0' and  i.readchokefifooff = '1' then
		      o.outchokefifooff  := n.CHOKEFIFOOFF.outputs.q;
		      n.CHOKEFIFOOFF.inputs.rdreq :='1'; 
	          else
	             o.outchokefifooff := (others=>'0');
	          end if;

		   if  n.ERRORFIFOOFF.outputs.rdempty ='0' and  i.readerrorfifooff = '1' then
		      o.outerrorfifooff  := n.ERRORFIFOOFF.outputs.q;
		      n.ERRORFIFOOFF.inputs.rdreq :='1'; 
	          else
	             o.outerrorfifooff := (others=>'0');
	          end if;

		  if  n.ERRORFIFOON.outputs.rdempty ='0' and  i.readerrorfifoon = '1' then
		      o.outerrorfifoon  := n.ERRORFIFOON.outputs.q;
		      n.ERRORFIFOON.inputs.rdreq :='1'; 
	          else
	             o.outerrorfifoon := (others=>'0');
	          end if;

		  
		  if ro.timer = 20000 then
		     n.FIFOPACKETS.inputs.aclr :='1';
                     for index in 0 to ethlink_NODES -2 loop
			n.FIFODelay(index).inputs.aclr :='1';
		     end loop;

		     r.sob_data_send             :='0';	
		     r.timer := 0;	
		     r.FSMResetCounters :=S0;

		  else
		     r.timer := ro.timer+1;
		     r.FSMResetCounters :=S1;
		  end if;
		  
	       else
		  r.FSMResetCounters :=S1;
	       end if;
	 end case;
      end procedure;





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
      n.SyncRST.outputs := allcmps.SyncRST.outputs;


      FOR index IN 0 TO SGMII_NODES - 1 LOOP
	 n.MAC(index).outputs     := allcmps.MAC(index).outputs;
      END LOOP;

      FOR index IN 0 TO RGMII_NODES - 1 LOOP
	 n.enet_MAC(index).outputs     := allcmps.enet_MAC(index).outputs;
      END LOOP;
 
      --
      -- all procedures call (edit)
      --	
      SubMain(i, ri, ro, o, r, n);
      SubReset(i, ri, ro, o, r, n);
      
      -- clock domain: 125 MHz OR 40 MHz
      SubReceive32bit(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReceiveRGMII32bit(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReceive64bit(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReceiveRGMII64bit(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubReadFIFODelay(i, ri.clk125, ro.clk125, o, r.clk125, n);
      SubSendBuffer(i,ri.clk125, ro.clk125, o, r.clk125, n);
      
      SubSendDETECTORS(i,ri.clk40, ro.clk40, o, r.clk40, n);
      SubGeneratePackets(i,ri.clk125, ro.clk125, o, r.clk125, n);
      SubSendFARM(i,ri.clk125, ro.clk125, o, r.clk125, n);
      Clock20MHz(i, ri.clk40, ro.clk40, o, r.clk40, n);
      ResetCounters(i,ri.clk125, ro.clk125, o, r.clk125, n);


      -- allouts/regs/nets updates
      
      allouts <= o;
      allregs.din <= r;
      allnets <= n;

   end process;

--**************************************************************
--**************************************************************
   outputs <= allouts;

end rtl;
