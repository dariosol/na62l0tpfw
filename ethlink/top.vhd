library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;
use work.GLOBALS.all;

--Top entity of the project. It is connected to 4 SGMII onboard ethernet links,
-- 4 RGMII HSMC additional ethernet links, an external board to communicate
-- with the TTC, an external NIM adaptor to receive LKr calibration signals, a
-- usb interface created with the "tmu" project, temperature sensor.


entity top is
   port
      (

         --------------------------------------------------------------
	 -- ethlink interface (begin)
	 --------------------------------------------------------------
	 --External Clock and Reset:
         OSC_50_B2    : in std_logic;
	 CPU_RESET_n  : in std_logic;

	 --Switch to set mac address ----------------
	 SW           : in std_logic_vector(7 downto 0);    

	 -- SGMII(0 to 3): Onboard ethernet links ---
	 ETH_RST_n    : out std_logic;
	 ETH_RX_p     : in std_logic_vector(0 to 3);
	 ETH_TX_p     : out std_logic_vector(0 to 3);


	 -- RGMII(0 to 1) : HSMC Port A -------------
	 -- RGMII(2 to 3) : HSMC Port B -------------
	 ENET_RST_n   : out std_logic_vector(0 to 3);
	 ENET_TX_EN   : out std_logic_vector(0 to 3);
	 ENET_TX_ER   : out std_logic_vector(0 to 3);
	 ENET_GTX_CLK : out std_logic_vector(0 to 3);
	 ENET_TX_D    : out vector8bit_t(0 to 3); 
	 ENET_RX_DV   : in std_logic_vector(0 to 3);
	 ENET_RX_ER   : in std_logic_vector(0 to 3);
	 ENET_RX_CLK  : in std_logic_vector(0 to 3);
	 ENET_RX_D    : in vector8bit_t(0 to 3); 


	 --NIM INTERFACE--------------
	 LKrNIMCalib   : in std_logic;
	 DetectorNim0  : in std_logic;
	 DetectorNim1  : in std_logic;
	 DetectorNim2  : in std_logic;
	 DetectorNim3  : in std_logic;
	 DetectorNim4  : in std_logic;

	 ---TTC signals from LTU------
	 SMA_CLKIN_p  : in std_logic;

         ECRST        : in std_logic;
         BCRST        : in std_logic;
	 CHOKE0       : in std_logic;
	 CHOKE1       : in std_logic;
	 CHOKE2       : in std_logic;
	 CHOKE3       : in std_logic;
	 CHOKE4       : in std_logic;
	 CHOKE5       : in std_logic;
	 CHOKE6       : in std_logic;
	 CHOKE7       : in std_logic;
	 CHOKE8       : in std_logic;
	 CHOKE9       : in std_logic;
	 CHOKE10      : in std_logic;
	 CHOKE11      : in std_logic;
	 CHOKE12      : in std_logic;
	 CHOKE13      : in std_logic;
	 ERROR0       : in std_logic;
	 ERROR1       : in std_logic;
	 ERROR2       : in std_logic;
	 ERROR3       : in std_logic;
	 ERROR4       : in std_logic;
	 ERROR5       : in std_logic;
	 ERROR6       : in std_logic;
	 ERROR7       : in std_logic;
	 ERROR8       : in std_logic;
	 ERROR9       : in std_logic;
	 ERROR10      : in std_logic;
	 ERROR11      : in std_logic;
	 ERROR12      : in std_logic;
	 ERROR13      : in std_logic;

	 QPLL_ERROR   : in std_logic;
	 QPLL_LOCKED  : in std_logic;
	 TTC_BCNT     : in std_logic_vector(11 downto 0);
	 TTC_BCNTSTR  : in std_logic;
	 TTC_EVCNTHSTR: in std_logic;
	 TTC_EVCNTLSTR: in std_logic;
	 TTC_L1ACCEPT : in std_logic;
	 TTC_READY    : in std_logic;

	 QPLL_RESET   : out std_logic;
	 TTCrxReset   : out std_logic;
	 LTU0         : out std_logic;
	 LTU1 	      : out std_logic;
	 LTU2 	      : out std_logic;
	 LTU3 	      : out std_logic;
	 LTU4 	      : out std_logic;
	 LTU5 	      : out std_logic;
	 LTU_TRIGGER  : out std_logic;
         TTC_SCL      : out std_logic;
	 TTC_SDA      : out std_logic;

	 --LED------------------------
	 Led1 	       : out std_logic;
	 led2          : out std_logic;
	 Led3          : out std_logic;
	 --USB------------------------
	 OTG_DC_DREQ  : in std_logic;
	 OTG_DC_IRQ   : in std_logic;
	 OTG_HC_DREQ  : in std_logic;
	 OTG_HC_IRQ   : in std_logic;
	 OTG_D        : inout std_logic_vector(31 downto 0);
	 OTG_A        : out std_logic_vector(17 downto 1);
	 OTG_CS_n     : out std_logic;
	 OTG_DC_DACK  : out std_logic;
	 OTG_HC_DACK  : out std_logic;
	 OTG_OE_n     : out std_logic;
	 OTG_RESET_n  : out std_logic;
	 OTG_WE_n     : out std_logic
	 );
end top;

--**************************************************************
--
-- Component Architecture
--
--**************************************************************

-- Local libraries (constant)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.component_ethlink.all;
use work.component_trigger.all;
use work.globals.all;

architecture rtl of top is

--clocks
--PLL 125 MHz signals:
   signal s_clk125                         : std_logic;
   signal s_locked  		           : std_logic;

--PLL 40 MHz signals:
   signal s_clk40                          : std_logic;
   signal s_locked40                       : std_logic;
-------------------------------------

--reset
   signal s_rst125                         : std_LOGIC;
   signal s_rst40                          : std_LOGIC;
   signal s_software_CPU_RESET_n           : std_LOGIC; 
-------------------------------------

--startRUN, internal timestamp clock signals
   signal s_BURST                          : std_logic;
   signal s_startRUN                       : std_logic;
   signal s_internal_timestamp             : std_logic_vector(29 downto 0);
   signal s_internal_timestamp125          : std_logic_vector(29 downto 0);
------------------------------------------------------------------------

--USB Signals
   signal s_status                         : std_logic_vector (31 downto 0);
   signal s_status125                      : std_logic_vector (31 downto 0);
   signal s_data_in                 	   : std_logic_vector (31 downto 0);
   signal s_number_of_triggers       	   : std_logic_vector(31 downto 0) ;
   
-----------------------------------------------------------------------
--counters of the number of triggers after LUT, before any downscaling
   signal s_ntriggers_predownscaling		     : vector32bit_t(0 to nmask-1);
   signal s_ntriggers_predownscaling_control         : std_logic_vector(31 downto 0);
--after downscaling
   signal s_ntriggers_postdownscaling                : vector32bit_t(0 to nmask-1);
   signal s_ntriggers_postdownscaling_control        : std_logic_vector(31 downto 0);     
------------------------------------------------------------------------
--counter data sent to LTU (outoutput to the detectors
   signal s_CounterLTU			   : std_logic_vector(31 downto 0);
------------------------------------------------------------------------
--Random trigger counter
   signal s_periodicrandomtriggercounter   : std_logic_vector(31 downto 0);
   signal s_randomtriggercounter           : std_logic_vector(31 downto 0);
------------------------------------------------------------------------
   signal s_MEPNum			   : std_logic_vector (31 downto 0);
-----------counters of primitives---------------------------------------
   signal s_number_of_primitives     	   : vector32bit_t(0 to ethlink_NODES-2);
------------------------------------------------------------------------
--monitoring signals
   signal s_TRIGGERERROR	           : std_logic_vector (31 downto 0);                   
   signal s_ETHLINKERROR                   : std_logic_vector (31 downto 0);
------------------------------------------------------------------------
--CHOKE/ERROR signals
   signal s_enaCHOKE_and_ERROR   	   : std_logic;
   signal s_CHOKE_OFF                      : std_LOGIC;			
   signal s_CHOKE_ON                       : std_LOGIC;			
   signal s_ERROR_OFF                      : std_LOGIC;
   signal s_ERROR_ON                       : std_LOGIC;
   signal s_CHOKE_signal                   : std_logic_vector(13 downto 0); --which detector is in ch/er
   signal s_ERROR_signal                   : std_logic_vector(13 downto 0); 
   signal s_n_of_choke                     : std_logic_vector(31 downto 0);
   signal s_n_of_error                     : std_logic_vector(31 downto 0);
   signal s_CounterCHOKE	           : std_logic_vector(31 downto 0);
   signal s_CounterERROR		   : std_logic_vector(31 downto 0);

------------------------------------------------------------------------
-- timestamp out to trigger into ethlink module (in order to send the information @ right time)
   signal s_timestamp_out      		    : std_logic_vector(31 downto 0);
   signal s_timestamp_calib_out             : vector32bit_t(0 to ethlink_NODES - 2);     
   signal s_timestamp_random_out      	    : std_logic_vector(31 downto 0);
-- finetime out to trigger into ethlink module (in order to send the information @ right time)
   signal s_finetime_ref_out      	    : std_logic_vector(7 downto 0);
   signal s_finetime_out0      		    : vector8bit_t(0 to ethlink_NODES - 2);-- SLOT N
   signal s_finetime_out1      		    : vector8bit_t(0 to ethlink_NODES - 2);-- SLOT N-1
   signal s_finetime_out2      		    : vector8bit_t(0 to ethlink_NODES - 2); -- SLOT N+1
   signal s_finetime_calib_out              : vector8bit_t(0 to ethlink_NODES - 2);
---------------------------------------------------------------------------------
--ethlink says to trigger that it has received someting 
   signal s_packet_received                 : std_logic;
   signal s_received_signal 		    : std_logic_vector(0 to ethlink_NODES-2);
   signal s_calib_signal                    : std_logic_vector(6 downto 0);
   signal s_trigger_signal     		    : std_logic;
   signal s_synch_signal                    : std_logic;
   signal s_control_signal                  : std_logic;
------------------------------------------------------------------------------
--primitive data output of ethlink into trigger
   signal s_primitiveID 	 	 : vector16bit_t(0 to ethlink_NODES - 2);
   signal s_reserved    		 : vector8bit_t(0 to ethlink_NODES - 2);
   signal s_finetime    		 : vector8bit_t(0 to ethlink_NODES - 2);
   signal s_timestamp   		 : vector32bit_t(0 to ethlink_NODES - 2);
   signal s_MTPNUMREF                    : vector8bit_t(0 to ethlink_NODES - 2);

------------------------------------------------------------------------
--Parameter set via USB
   signal s_MEPEventNumber                 : std_logic_vector (31 downto 0);
   signal s_primitiveDT                    : std_logic_vector(31 downto 0);
   signal s_bit_finetime                   : std_logic_vector(31 downto 0);
   signal s_offset                         : vector32bit_t(0 to 6); -- number of packet to skip
   signal s_deltapacket                    : std_logic_vector(31 downto 0);
   signal s_dataformat                     : std_logic_vector(31 downto 0); --0: 64 bit primitives;
						                            --1: 32 bit primitives
---------------------------------------------------------------------------------
   signal s_Fixed_Latency                  : std_logic_vector(31 downto 0);
   signal s_Fixed_Latency_o                : std_logic_vector(31 downto 0);
------------------------------------------------------------------------------
--Activate Signals
   signal s_activetriggers                 : std_logic_vector(31 downto 0);
   signal s_activateperiodictrigger0       : std_logic;
   signal s_activateperiodictrigger1       : std_logic;
   signal s_activatecontroltrigger         : std_logic;
   signal s_activaterandomtrigger          : std_logic;
   signal s_activateNIMCalib               : std_logic;
   signal s_activateprimitives             : std_logic;
   signal s_activatecalibtrigger           : std_logic;
   signal s_activatesynchtrigger           : std_logic;
   signal s_activateclock20MHz		   : std_logic;
   signal s_activateCHOKE                  : std_logic;
   signal s_activateERROR                  : std_logic;
   signal s_activateSOBEOB                 : std_logic;
------------------------------------------------------------------------------
-- signals of the mask in the LUT (inside trigger module) 
   signal s_enable_mask                    : std_logic_vector(nmask-1 downto 0);
   signal s_mask                           : mem;
   signal s_dontcare                       : mem;
   signal s_control_mask                   : std_logic_vector(111 downto 0);
   signal s_control_dontcare               : std_logic_vector(111 downto 0);
------------------------------------------------------------------------
--triggerword signals out from trigger into ethlink for sending info
   signal s_triggerword        		 : std_logic_vector(5 downto 0);
   signal s_NIMCalib_Triggerword       	 : std_logic_vector(31 downto 0); --via NIM
   signal s_calib_triggerword            : std_logic_vector(31 downto 0); --via primitive
   signal s_triggerflag                  : std_logic_vector(15 downto 0);
------------------------------------------------------------------------
--downscaling signal (one for each trigger type)
   signal s_control_trigger_downscaling  : std_logic_vector(31 downto 0);     
   signal s_downscaling                  : vector32bit_t(0 to nmask-1);
   signal s_downscaling_reset            : std_logic_vector(31 downto 0);
------------------------------------------------------------------------
--Reference detector signal
   signal s_reference_detector             : std_logic_vector(31 downto 0);
   signal s_control_detector               : std_logic_vector(31 downto 0);
------------------------------------------------------------------------
--periodic triggerword set via usb
   signal s_periodic_triggerword0          : std_logic_vector(31 downto 0);
   signal s_periodic_triggerword0_out      : std_logic_vector(31 downto 0);
   signal s_periodictime0                  : std_logic_vector(31 downto 0);
   signal s_periodic_End_Time0             : std_logic_vector(31 downto 0);
   signal s_periodic_Start_Time0           : std_logic_vector(31 downto 0);
   signal s_periodictime1                  : std_logic_vector(31 downto 0);
   signal s_periodic_End_Time1             : std_logic_vector(31 downto 0);
   signal s_periodic_Start_Time1           : std_logic_vector(31 downto 0);
   signal s_periodic_triggerword1          : std_logic_vector(31 downto 0);
   signal s_periodic_triggerword1_out      : std_logic_vector(31 downto 0);
   signal s_periodic_signal0               : std_logic;
   signal s_periodic_signal1               : std_logic;

------------------------------------------------------------------------
--Random triggerword set via usb
   signal s_Random_triggerword             : std_logic_vector(31 downto 0);
   signal s_Random_triggerword_out         : std_logic_vector(31 downto 0);
   signal s_Random_Period                  : std_logic_vector(31 downto 0);
   signal s_Random_Start_Time              : std_logic_vector(31 downto 0);
   signal s_Random_End_TIme                : std_logic_vector(31 downto 0);
   signal s_randomtime                     : std_logic_vector(31 downto 0);
   signal s_random_signal                  : std_logic;
------------------------------------------------------------------------
--Trigger primitive ID in slot 0,1,2
   signal s_primitive_t0                   : vector16bit_t(0 to ethlink_NODES -2);
   signal s_primitive_t1                   : vector16bit_t(0 to ethlink_NODES -2);
   signal s_primitive_t2                   : vector16bit_t(0 to ethlink_NODES -2);

------------------------------------
--Calibration Primitive
   signal s_primitive_c                    : vector16bit_t(0 to ethlink_NODES -2);
------------------------------------------------------------------------
-- calibration via NIM interface
   signal s_calibration_NIM                : std_logic;
   signal s_Calib_Latency                  : std_logic_vector(31 downto 0);
   signal s_calib_direction                : std_logic_vector(31 downto 0);

--Detector with the largest initial latency - system waits it before
--starting to count packets. The other detectors are recorded in a FIFO
--Buffer
   signal s_maximum_delay_detector         : std_logic_vector(31 downto 0);

-----------FIFOS CHOKE ERROR--------------------------------------------
   signal s_readCHOKEFIFOON                : std_logic;
   signal s_readCHOKEFIFOOFF               : std_logic;
   signal s_readERRORFIFOON                : std_logic;
   signal s_readERRORFIFOOFF               : std_logic;
   signal s_CHOKEFIFOON                    : std_logic_vector(31 downto 0);
   signal s_CHOKEFIFOOFF                   : std_logic_vector(31 downto 0);
   signal s_ERRORFIFOON                    : std_logic_vector(31 downto 0);
   signal s_ERRORFIFOOFF                   : std_logic_vector(31 downto 0);
   signal s_CHOKEMASK                      : std_logic_vector(13 downto 0);
   signal s_ERRORMASK                      : std_logic_vector(13 downto 0);
   signal s_FAKECHOKE                      : std_logic_vector(13 downto 0);
   signal s_FAKEERROR                      : std_logic_vector(13 downto 0);
   
--Vector with time cuts respect to the reference detector
   signal s_timecut                        : vector16bit_t(0 to ethlink_NODES -2); 

--Dead time before sending primitive trigger to compensate the spike from SPS 
   signal s_delaydeliveryprimitive         : std_logic_vector(31 downto 0);
   signal s_delaydeliveryoutput            : std_logic_vector(31 downto 0);
  

--Software reset signals:
   signal s_reset_counter : natural;
   type FSMreset_t is (S0,S1,S2);	
   signal FSMreset : FSMreset_t;
   --Temperature
   signal s_tsdcalo : std_logic_vector(7 downto 0);     
   signal s_tsdcaldone : std_logic;
   signal s_ce_temp    : std_logic;
   signal s_clr_temp   : std_logic;
   signal s_temp_counter : integer;


--Component declarations:
   --Handle the temperature measurement:
   --Also when the cooling in the electronic barack is off, the FPGA never goes
   --over 38 degrees
   component TemperatureSensor is
      port (
	 clk        : in  std_logic;                           
	 ce         : in std_logic;
	 clr        : in std_logic;
	 tsdcalo    : out std_logic_vector(7 downto 0);        
	 tsdcaldone : out std_logic                         
	 );
   end component;
  
-----------
   --PLL clock @ 125 MHz:
   component altpll_refclk2
      port(
	 areset		: IN STD_LOGIC  := '0';
	 inclk0		: IN STD_LOGIC;
	 c0	        : OUT STD_LOGIC ;
	 locked		: OUT STD_LOGIC 
	 );
   end component;

----------
   --PLL clock @ 40 MHz (from external source:)
   component altpll40MHz
      port(
	 areset	   : IN STD_LOGIC  := '0';
	 inclk0	   : IN STD_LOGIC;
	 c0	   : OUT STD_LOGIC ;
	 locked	   : OUT STD_LOGIC 
	 );
   end component;
----------
--Handle sob/eob choke on/choke off triggers:
   component altTTC
      port (
	 clk40          : in std_logic;
	reset           : in std_logic;	
	startRUN        : in std_logic;
	activateCHOKE   : in std_logic;
	activateERROR   : in std_logic;
	BCRST           : in std_logic;
	ECRST           : in std_logic;
	BURST           : out std_logic;
	CHOKE           : in std_logic_vector(13 downto 0);
	ERROR           : in std_logic_vector(13 downto 0);
	CHOKEMASK       : in std_logic_vector(13 downto 0);
	ERRORMASK       : in std_logic_vector(13 downto 0);
	led1            : out std_logic;
	led3            : out std_logic;
	CHOKE_signal    : out std_logic_vector(13 downto 0);
	ERROR_signal    : out std_logic_vector(13 downto 0);
	CHOKE_ON        : out std_logic;
	ERROR_ON	: out std_logic;
	CHOKE_OFF       : out std_logic;
	ERROR_OFF       : out std_logic
	);end component;


   --Handle Timestamp @40 MHz and 125 MHz with crossing domain using a dual
   --port fifo:
   component altcountertimestamp IS
      port (
	 clock40   : in STD_LOGIC;
	 clock125  : in STD_LOGIC;
	 BURST       : in STD_LOGIC;
	 internal_timestamp : out STD_LOGIC_VECTOR(29 downto 0);
	 internal_timestamp125 : out STD_LOGIC_VECTOR(29 downto 0)
	 ); end component;

   --It was used in 2014 to produce triggers from NIM output of detectors.
   --Actually the input pin are in TTL logic.
   --Since 2016 it is only used for the LKr calibration.
   component NIMInterface is
      port(
         reset                      : in std_LOGIC;
         CalibNimIn                 : in std_logic;  --40 MHz
         clkB                       : in std_logic;  --125 MHz
         CalibNimOut                : out std_logic;  --125 MHz
         -------------------------
         activateCalib              : in std_logic;
         BURST                      : in STD_LOGIC
	 );
   end component;

   
   --Multiplexer for the micro-usb connection:
   component usb_portmux
      port (
   ---USER SIGNALS--
         status             : in std_logic_vector (31 downto 0);
         status125          : in std_logic_vector (31 downto 0);
         number_of_triggers : out std_logic_vector(31 downto 0);
         data_in            : out std_logic_vector(31 downto 0);
         ---------------------
         reset_n            : in std_logic;
         clk                : in std_logic;
         OSC1_50            : in std_logic;
         OTG_A              : out std_logic_vector(17 downto 1);
         OTG_CS_n           : out std_logic;
         OTG_D              : inout std_logic_vector(31 downto 0);
         OTG_DC_DACK        : out std_logic;
         OTG_DC_DREQ        : in std_logic;
         OTG_DC_IRQ         : in std_logic;
         OTG_HC_DACK        : out std_logic;
         OTG_HC_DREQ        : in std_logic;
         OTG_HC_IRQ         : in std_logic;
         OTG_OE_n           : out std_logic;
         OTG_RESET_n        : out std_logic;
         OTG_WE_n           : out std_logic

	 );end component;


--State machine to set/read parameters from the USB:
   component USBinterface
      port (
         reset                        : in std_logic;
	 clk125                       : in std_logic; --debug 125 Mhz
	 BURST                        : in std_logic;
	 data_in                      : in  std_logic_vector(31 downto 0);--FROM USB
	 number_of_triggers           : in  std_logic_vector(31 downto 0);
         status                       : out std_logic_vector(31 downto 0);
	 status125                    : out std_logic_vector(31 downto 0);
	 startRUN                     : out std_logic; --faccio partire lo start of burst
	 
	 --Trigger Types-------------------------------------------------------------------
	 
	 activateclock20MHz           : out std_logic;
	 activateCHOKE                : out std_logic;
	 activateERROR                : out std_logic;
	 activateperiodictrigger0     : out std_logic;
	 activateperiodictrigger1     : out std_logic;
         activatecontroltrigger       : out std_logic;
	 activatecalibtrigger         : out std_logic;
	 activatesynchtrigger         : out std_logic;
	 activateprimitives           : out std_logic;
	 activaterandomtrigger        : out std_logic;
         activateSOBEOBtrigger        : out std_logic;
         activateNIMCalibration       : out std_logic;
	 activetriggers               : out std_logic_vector(31 downto 0);
	 --Debug---------------------------------------------------------------------------
	 ntriggers_predownscaling 	    : in vector32bit_t(0 to nmask-1);
	 ntriggers_postdownscaling_control  : in std_logic_vector(31 downto 0);
	 MEPNum                       : in std_logic_vector(31 downto 0);
	 number_of_primitives         : in vector32bit_t(0 to ethlink_NODES-2);
	 
	 periodicrandomtriggercounter : in std_logic_vector(31 downto 0);
	 randomtriggercounter         : in std_logic_vector(31 downto 0);
	 CounterLTU                   : in std_logic_vector(31 downto 0);
	 TRIGGERERROR                    : in std_logic_vector(31 downto 0);
	 ETHLINKERROR                 : in std_logic_vector(31 downto 0);
	 n_of_choke                   : in std_logic_vector(31 downto 0);
         n_of_error                   : in std_logic_vector(31 downto 0);
	 n_of_random                  : in std_logic_vector(31 downto 0); 
	 n_of_Calibration             : in std_logic_vector(31 downto 0);
	 n_of_NIM_Calibration         : in std_logic_vector(31 downto 0);

	 Fixed_Latency_i              : in std_logic_vector(31 downto 0);
	 delaydeliveryoutput          : in std_logic_vector(31 downto 0);
	 
	 CHOKEFIFOON                  : in std_logic_vector(31 downto 0);
	 CHOKEFIFOOFF                 : in std_logic_vector(31 downto 0);
	 ERRORFIFOON                  : in std_logic_vector(31 downto 0);
	 ERRORFIFOOFF                 : in std_logic_vector(31 downto 0);
	 readCHOKEFIFOON              : out std_LOGIC;
	 readCHOKEFIFOOFF             : out std_LOGIC;
	 readERRORFIFOON              : out std_LOGIC;
	 readERRORFIFOOFF             : out std_LOGIC;
	 
	 --Parameters---------------------------------------------------------
	 Out_mask                     : out mem;
	 Out_dontcare                 : out mem;
	 Downscaling                  : out vector32bit_t(0 to nmask-1);
	 
	 MEPEventNumber               : out std_logic_vector(31 downto 0);
	 FIxed_LAtency                : out std_logic_vector(31 downto 0);
	 Calib_Triggerword            : out std_logic_vector(31 downto 0);
	 NIMCalib_Latency             : out std_logic_vector(31 downto 0);
	 NIMCalib_direction           : out std_logic_vector(31 downto 0);
	 NIMCalib_Triggerword         : out std_logic_vector(31 downto 0);
	 Periodic_Period0             : out std_logic_vector(31 downto 0);
         Periodic_Triggerword0        : out std_logic_vector(31 downto 0);
         Periodic_StartTime0          : out std_logic_vector(31 downto 0);
         Periodic_EndTime0            : out std_logic_vector(31 downto 0);
         Periodic_Period1             : out std_logic_vector(31 downto 0);
         Periodic_Triggerword1        : out std_logic_vector(31 downto 0);
         Periodic_StartTime1          : out std_logic_vector(31 downto 0);
         Periodic_EndTime1            : out std_logic_vector(31 downto 0);
         
	 Random_Triggerword           : out std_logic_vector(31 downto 0);
         Random_Period                : out std_logic_vector(31 downto 0);
         Random_StartTime             : out std_logic_vector(31 downto 0);
         Random_EndTime               : out std_logic_vector(31 downto 0);
	 Offset                       : out vector32bit_t(0 to 6)        ;
         Maximum_Delay_Detector       : out std_logic_vector(31 downto 0);
         PrimitiveDT                  : out std_logic_vector(31 downto 0);
         Reference_detector           : out std_logic_vector(31 downto 0);
         Control_detector             : out std_logic_vector(31 downto 0);
	 Control_trigger_downscaling  : out std_logic_vector(31 downto 0);
         Out_enable_mask              : out std_logic_vector(nmask-1 downto 0);
         Bit_finetime                 : out std_logic_vector(31 downto 0);
	 Deltapacket                  : out std_logic_vector(31 downto 0);
	 
	 Out_control_mask             : out std_logic_vector(111 downto 0);
	 Out_control_dontcare         : out std_logic_vector(111 downto 0);
	 CHOKEMASK                    : out std_logic_vector(13 downto 0);
	 ERRORMASK                    : out std_logic_vector(13 downto 0);
	 Timecut                      : out vector16bit_t(0 to ethlink_NODES-2);
	 Downscaling_reset            : out std_logic_vector(31 downto 0);
	 Delaydeliveryprimitive       : out std_logic_vector(31 downto 0);
	 Dataformat                   : out std_logic_vector(31 downto 0);
	 FAKECHOKE                    : out std_logic_vector(13 downto 0);
	 FAKEERROR                    : out std_logic_vector(13 downto 0)
	 );
   end component;

--Periodic trigger generator (two different pulsers can be activated)
   component pulser 
      port (
	 BURST125                   : in std_logic;
	 clk125                     : in std_logic; --40 MHZ FROM LTU
	 activateperiodictrigger0   : in std_logic;
	 periodicstarttime0         : in std_logic_vector(31 downto 0);
	 periodicendtime0           : in std_logic_vector(31 downto 0);
	 periodictime0              : in std_logic_vector(31 downto 0);
         periodic_triggerword0_in   : in std_logic_vector(5 downto 0);
         periodic_triggerword1_in   : in std_logic_vector(5 downto 0);
         
	 activateperiodictrigger1   : in std_logic;
	 periodicstarttime1         : in std_logic_vector(31 downto 0);
	 periodicendtime1           : in std_logic_vector(31 downto 0);
	 periodictime1              : in std_logic_vector(31 downto 0);
         
	 internal_timestamp         : in std_logic_vector(31 downto 0);
	 periodic_signal0           : out std_logic;
	 periodic_signal1           : out std_logic;
         periodic_triggerword0_out  : out std_logic_vector(5 downto 0);
         periodic_triggerword1_out  : out std_logic_vector(5 downto 0)
	 );

   end component;

--Pseudorandom trigger generator
   component generator 
     port (
       clk                      : in std_logic; --40 MHZ FROM LTU
       activaterandomtrigger    : in std_logic;
       randomstarttime          : in std_logic_vector(31 downto 0);
       randomendtime            : in std_logic_vector(31 downto 0);
       randomtime               : in std_logic_vector(31 downto 0);
       random_triggerword_in    : in std_logic_vector(5 downto 0);
       internal_timestamp       : in std_logic_vector(31 downto 0);
       random_signal            : out std_logic;
       random_triggerword_out   : out std_logic_vector(5 downto 0)
       );

end component;



begin
 
   TTCrxReset <= (s_software_CPU_RESET_n); --Autoreset at the poweron of the
                                           --board. inverse logic. It allow to
                                           --have always the same latecy at the
                                           --start of the data taking
   TTC_SCL    <= '1';
   TTC_SDA    <= '1';
   QPLL_RESET <= '1'; --Inverse logic??

-- component port map

   TemperatureSensor_inst : TemperatureSensor port map (
    clk => s_clk40,
    ce  => s_ce_temp,
    clr => s_clr_temp,
    tsdcalo => s_tsdcalo,
    tsdcaldone => s_tsdcaldone
    );


   pulser_inst : pulser port map(
      clk125                            => s_clk125,
      BURST125                          => s_BURST,
      activateperiodictrigger0          => s_activateperiodictrigger0,
      periodicstarttime0                => s_periodic_start_time0,
      periodicendtime0                  => s_periodic_end_time0,
      periodictime0                     => s_periodictime0,
      periodic_triggerword0_in          => s_periodic_triggerword0(5 downto 0),

      activateperiodictrigger1          => s_activateperiodictrigger1,
      periodicstarttime1                => s_periodic_start_time1,
      periodicendtime1                  => s_periodic_end_time1,
      periodictime1                     => s_periodictime1,
      periodic_triggerword1_in          => s_periodic_triggerword1(5 downto 0),

      internal_timestamp(31 downto 30)  => (others=>'0'),
      internal_timestamp(29 downto 0)   => s_internal_timestamp125,
      periodic_signal0                  => s_periodic_signal0,
      periodic_signal1                  => s_periodic_signal1,
      periodic_triggerword0_out         => s_periodic_triggerword0_out(5 downto 0),
      periodic_triggerword1_out         => s_periodic_triggerword1_out(5 downto 0)
      );

   random_inst : generator port map(
     clk                              => s_clk125,
     activaterandomtrigger            => s_activaterandomtrigger,
     randomstarttime                  => s_random_start_time,
     randomendtime                    => s_random_end_time,
     randomtime                       => s_randomtime,
     random_triggerword_in            => s_random_triggerword(5 downto 0),
     internal_timestamp(31 downto 30) => (others=>'0'),
     internal_timestamp(29 downto 0)  => s_internal_timestamp125,
     random_signal                    => s_random_signal,
     random_triggerword_out           => s_random_triggerword_out(5 downto 0)
   );

--Internal PLL
   PLL125_inst : altpll_refclk2 port map(
      inclk0   => OSC_50_B2, --from DE4
      areset   => '0',
      Locked   => s_locked,
      c0       => s_clk125
   );
   

   PLL40_inst : altpll40MHz port map(
      inclk0   => SMA_CLKIN_p, --from TTCrx
      areset   => '0',
      Locked   => s_locked40,
      c0       => s_clk40
      );


   ethlink_inst : ethlink port map(
	 
      inputs.rxp      => ETH_RX_p(0 to SGMII_NODES - 1), 
      
      inputs.enet_rx_clk   => ENET_RX_CLK(0 to RGMII_NODES - 1),
      inputs.enet_rx_dv    => ENET_RX_DV(0 to RGMII_NODES - 1),
      inputs.enet_rx_er    => ENET_RX_ER(0 to RGMII_NODES - 1),
      inputs.enet_rx_d     => ENET_RX_D(0 to RGMII_NODES - 1),
      
      outputs.resetn       => ETH_RST_n,
      outputs.txp          => ETH_TX_p(0 to SGMII_NODES - 1),
      
      outputs.enet_resetn  => ENET_RST_n(0 to RGMII_NODES - 1),
      outputs.enet_gtx_clk => ENET_GTX_CLK(0 to RGMII_NODES - 1),
      outputs.enet_tx_en   => ENET_TX_EN(0 to RGMII_NODES - 1),
      outputs.enet_tx_er   => ENET_TX_ER(0 to RGMII_NODES - 1),
      outputs.enet_tx_d    => ENET_TX_D(0 to RGMII_NODES - 1),
      
      --------------------------------------------------------------
      inputs.clkin_50                          => OSC_50_B2,
      inputs.clkin_40                          => s_clk40,
      inputs.clkin_125                         => s_clk125,
      inputs.cpu_resetn                        => s_software_CPU_RESET_n,
      inputs.USER_DIPSW                        => SW,--
      inputs.BURST                             => s_BURST,
      inputs.MEPEventNumber                    => s_MEPEventNumber , 
      inputs.Fixed_Latency                     => s_Fixed_Latency,	
      inputs.activate_clock20MHz               => s_activateclock20MHz,
      					       
      inputs.primitiveID_t0                    => s_primitive_t0,--trigger
      inputs.primitiveID_t1                    => s_primitive_t1,--trigger
      inputs.primitiveID_t2                    => s_primitive_t2,--trigger
      					       
      inputs.primitiveID_c                     => s_primitive_c,--calibration
      					       
      inputs.ntriggers_predownscaling          => s_ntriggers_predownscaling,
      inputs.ntriggers_postdownscaling         => s_ntriggers_postdownscaling,
      inputs.downscaling                       => s_downscaling       ,
      inputs.control_trigger_downscaling       => s_control_trigger_downscaling,
      					       
      inputs.mask                              => s_mask,
      inputs.dontcare                          => s_dontcare,
      inputs.triggerflag                       => s_triggerflag,
      					       
      inputs.finetime_bits                     => s_bit_finetime      ,
      inputs.reference_detector                => s_reference_detector,
      inputs.control_detector                  => s_control_detector,	
      inputs.periodic_triggerword0             => s_periodic_triggerword0_out(5 downto 0),
      inputs.periodic_triggerword1             => s_periodic_triggerword1_out(5 downto 0),
      inputs.random_triggerword                => s_random_triggerword_out(5 downto 0),	
      inputs.calibration_NIM                   => s_calibration_NIM,
      inputs.finetime_calib                    => s_finetime_calib_out  ,
      inputs.timestamp_calib                   => s_timestamp_calib_out ,
      inputs.triggerword_calib                 => s_NIMCalib_Triggerword(5 downto 0),
      inputs.calib_signal                      => s_calib_signal,
      inputs.finetime_physics0                 => s_finetime_out0,
      inputs.finetime_physics1                 => s_finetime_out1,
      inputs.finetime_physics2                 => s_finetime_out2,
      					       
      inputs.finetime_physics_ref              => s_finetime_ref_out,
      inputs.timestamp_physics                 => s_timestamp_out,
      					       
      inputs.internal_timestamp                => SLV(s_internal_timestamp,32),
      inputs.internal_timestamp125             => SLV(s_internal_timestamp125,32),
      inputs.triggerword                       => s_triggerword,
      inputs.random_signal                     => s_random_signal,
      inputs.periodic_signal0                  => s_periodic_signal0,
      inputs.periodic_signal1                  => s_periodic_signal1,
      inputs.synch_signal                      => s_synch_signal   ,
      inputs.trigger_signal                    => s_trigger_signal ,
      inputs.ERROR_signal                      => s_ERROR_signal   ,
      inputs.CHOKE_signal                      => s_CHOKE_signal   ,
      				               
      inputs.CHOKE_OFF                         => s_CHOKE_OFF,
      inputs.CHOKE_ON                          => s_CHOKE_ON,
      inputs.ERROR_OFF                         => s_ERROR_OFF,
      inputs.ERROR_ON                          => S_ERROR_ON,
      				               
      inputs.active_triggers                   => s_activetriggers,
      inputs.activate_synch                    =>  s_activatesynchtrigger,
      inputs.activate_SOBEOBtrigger            => s_activateSOBEOB,
      					       
      inputs.enable_mask                       => s_enable_mask,
      inputs.activate_controltrigger           => s_activatecontroltrigger,
      					       
      inputs.readCHOKEFIFOON                   => s_readCHOKEFIFOON,
      inputs.readCHOKEFIFOOFF                  => s_readCHOKEFIFOOFF,
      inputs.readERRORFIFOON                   => s_readERRORFIFOON,
      inputs.readERRORFIFOOFF                  => s_readERRORFIFOOFF,
      				               
      outputs.outchokefifoon                   => s_CHOKEFIFOON,
      outputs.outchokefifooff                  => s_CHOKEFIFOOFF,
      outputs.outERRORfifoon                   => s_ERRORFIFOON,
      outputs.outERRORfifooff                  => s_ERRORFIFOOFF,
      					       
      outputs.LTU0 		               => LTU0,
      outputs.LTU1 		               => LTU1,
      outputs.LTU2 		               => LTU2,
      outputs.LTU3 		               => LTU3,
      outputs.LTU4 		               => LTU4,
      outputs.LTU5                             => LTU5,
      outputs.LTU_TRIGGER                      => LTU_TRIGGER,
      outputs.Fixed_Latency_o                  => s_Fixed_Latency_o,
      outputs.number_of_primitives             => s_number_of_primitives,
      					       
      outputs.MEPNum                           => s_MEPNum,
      outputs.MTPNUMREF                        => s_MTPNUMREF,
      outputs.packet_received                  => s_packet_received,
      					       
      outputs.ETHLINKERROR                     => s_ETHLINKERROR,
      outputs.CounterLTU                       => s_CounterLTU,
      outputs.CounterCHOKE                     => s_CounterCHOKE,
      outputs.CounterERROR                     => s_CounterERROR,
      outputs.received_signal                  => s_received_signal,
      outputs.primitiveID 	               => s_primitiveID, 
      outputs.reserved    	               => s_reserved,
      outputs.finetime    	               => s_finetime,  
      outputs.timestamp                        => s_timestamp,
      outputs.rst125                           => s_rst125,
      outputs.rst40                            => s_rst40,
      					       
      outputs.periodicrandomtriggercounter     => s_periodicrandomtriggercounter,
      outputs.randomtriggercounter             => s_randomtriggercounter,
      -----------			       
      inputs.activate_primitives               => s_activateprimitives,
      inputs.delay_set                         => s_offset,
      inputs.maximum_delay_detector            => s_maximum_delay_detector,
      inputs.Calib_Latency                     => s_Calib_Latency,
      inputs.calib_direction                   => s_calib_direction(0),
      inputs.primitiveDT                       => s_primitiveDT,
      inputs.ntriggers_postdownscaling_control => s_ntriggers_postdownscaling_control,
      inputs.ntriggers_predownscaling_control  => s_ntriggers_predownscaling_control,
      inputs.control_signal                    => s_control_signal,
      inputs.dataformat                        => s_dataformat(6 downto 0), --one for each detector
      inputs.temperature                       => s_tsdcalo
      );

   
   trigger_inst : trigger port map(
	 
      inputs.clkin_125          => s_clk125,
      inputs.clkin_40           => s_clk40,
      
      inputs.rst125             => s_rst125,
      inputs.rst40              => s_rst40,
      
      inputs.RUN                => s_startRUN,
      inputs.BURST              => s_BURST,
      
      inputs.received_signal                    => s_received_signal,
      inputs.primitiveID 	                => s_primitiveID,
      inputs.reserved    	                => s_reserved,
      inputs.finetime    	                => s_finetime,
      inputs.timestamp   	                => s_timestamp,
      
      inputs.internal_timestamp125(29 downto 0) => s_internal_timestamp125,
      inputs.internal_timestamp125(31 downto 30)=>"00",
      inputs.internal_timestamp(29 downto 0)    => s_internal_timestamp,
      inputs.internal_timestamp(31 downto 30)   =>"00",
      
      inputs.mask                               => s_mask,
      inputs.dontcare                           => s_dontcare,
      					        
      inputs.control_mask                       => s_control_mask,
      inputs.control_dontcare                   => s_control_dontcare,
      inputs.activatecalibtrigger               => s_activatecalibtrigger,
      inputs.activatesynchtrigger               => s_activatesynchtrigger,
      inputs.downscaling_set                    => s_downscaling,
      inputs.downscaling_reset                  => s_downscaling_reset,
      inputs.activatecontroltrigger             => s_activatecontroltrigger,
      inputs.enable_mask                        => s_enable_mask,
      					        
      inputs.calib_triggerword                  => s_calib_triggerword(7 downto 0), --Calib triggerword
      inputs.bit_finetime                       => s_bit_finetime, -- #bit finetime 
      inputs.deltapacket                        => s_deltapacket, 
      inputs.reference_detector                 => s_reference_detector,
      					        
      inputs.control_detector                   => s_control_detector,
      inputs.control_downscaling_set            => s_control_trigger_downscaling,
      					        
      inputs.packet_received                    => s_packet_received ,
      inputs.MTPNUMREF                          => s_MTPNUMREF,
      inputs.timecut                            => s_timecut,
      inputs.delaydeliveryprimitive             => s_delaydeliveryprimitive,
      outputs.timestamp_out                     => s_timestamp_out ,
      outputs.finetime_ref_out                  => s_finetime_ref_out,
      outputs.finetime0_out                     => s_finetime_out0,	
      outputs.finetime1_out                     => s_finetime_out1,	
      outputs.finetime2_out                     => s_finetime_out2,	
      					        
      outputs.triggerword                       => s_triggerword    ,
      outputs.trigger_signal                    => s_trigger_signal ,
      outputs.synch_signal                      => s_synch_signal,	
      outputs.calib_signal                      => s_calib_signal,
      outputs.triggerword_calib                 => s_calib_triggerword(5 downto 0),
      outputs.finetime_calib_out                => s_finetime_calib_out ,
      outputs.timestamp_calib_out               => s_timestamp_calib_out,
      					        
      outputs.primitiveID0_t                    => s_primitive_t0,
      outputs.primitiveID1_t                    => s_primitive_t1,
      outputs.primitiveID2_t                    => s_primitive_t2,
      
      outputs.primitiveID_c                     => s_primitive_c    ,
      
      outputs.ntriggers_predownscaling          => s_ntriggers_predownscaling,
      outputs.ntriggers_predownscaling_control  => s_ntriggers_predownscaling_control,
      outputs.ntriggers_postdownscaling         => s_ntriggers_postdownscaling(0 to nmask-1),
      outputs.ntriggers_postdownscaling_control => s_ntriggers_postdownscaling_control,
      outputs.TRIGGERERROR                      => s_TRIGGERERROR,
      outputs.control_signal                    => s_control_signal,
      outputs.triggerflag                       => s_triggerflag,
      outputs.delaydeliveryoutput               => s_delaydeliveryoutput
      );



   CDC_inst2 : NIMInterface port map (
      reset          	=> '0',
      CalibNimIn        => DetectorNim0, --Modificato l'imput
					     --LKrNimCalib, poiche' non
					     --funzionava (sempre alto).
      activateCalib     => s_activateNIMCalib,
      BURST             => s_BURST,         
      clkB           	=> s_clk125,
      CalibNimOut       => s_calibration_NIM
      
      );

   ALTTTC_inst : altTTC port map(
      clk40      	  => s_clk40, --to sample SOB/EOB TTCrx
      reset 		  => s_software_CPU_RESET_n,
      ECRST 		  => ECRST,
      BCRST 		  => BCRST,
      startRUN            => s_startRUN,
      BURST   		  => s_B

      Led1                => Led1,
      Led3                => Led3,
      CHOKE(0)            => CHOKE0  or s_FAKECHOKE(0) ,
      CHOKE(1)            => CHOKE1   or s_FAKECHOKE(1) ,
      CHOKE(2)            => CHOKE2   or s_FAKECHOKE(2) ,
      CHOKE(3)            => CHOKE3   or s_FAKECHOKE(3) ,
      CHOKE(4)            => CHOKE4   or s_FAKECHOKE(4) ,
      CHOKE(5)            => CHOKE5   or s_FAKECHOKE(5) ,
      CHOKE(6)            => CHOKE6   or s_FAKECHOKE(6) ,
      CHOKE(7)            => CHOKE7   or s_FAKECHOKE(7) ,
      CHOKE(8)            => CHOKE8   or s_FAKECHOKE(8) ,
      CHOKE(9)            => CHOKE9   or s_FAKECHOKE(9) ,
      CHOKE(10)           => CHOKE10  or s_FAKECHOKE(10),
      CHOKE(11)           => CHOKE11  or s_FAKECHOKE(11),
      CHOKE(12)           => CHOKE12  or s_FAKECHOKE(12),
      CHOKE(13)           => CHOKE13  or s_FAKECHOKE(13),
      
      ERROR(0)            => ERROR0  or s_FAKEERROR(0) ,
      ERROR(1)            => ERROR1  or s_FAKEERROR(1) ,
      ERROR(2)            => ERROR2  or s_FAKEERROR(2) ,
      ERROR(3)            => ERROR3  or s_FAKEERROR(3) ,
      ERROR(4)            => ERROR4  or s_FAKEERROR(4) ,
      ERROR(5)            => ERROR5  or s_FAKEERROR(5) ,
      ERROR(6)            => ERROR6  or s_FAKEERROR(6) ,
      ERROR(7)            => ERROR7  or s_FAKEERROR(7) ,
      ERROR(8)            => ERROR8  or s_FAKEERROR(8) ,
      ERROR(9)            => ERROR9  or s_FAKEERROR(9) ,
      ERROR(10)           => ERROR10 or s_FAKEERROR(10),
      ERROR(11)           => ERROR11 or s_FAKEERROR(11),
      ERROR(12)           => ERROR12 or s_FAKEERROR(12),
      ERROR(13)           => ERROR13 or s_FAKEERROR(13),

      activateCHOKE       => s_activateCHOKE,
      activateERROR       => s_activateERROR,
      CHOKE_signal        => s_CHOKE_signal ,
      ERROR_signal        => s_ERROR_signal ,
      CHOKE_ON            => s_CHOKE_ON     , 
      CHOKE_OFF           => s_CHOKE_OFF    ,
      ERROR_ON            => s_ERROR_ON     , 
      ERROR_OFF           => s_ERROR_OFF    ,
      CHOKEMASK           => s_CHOKEMASK    ,
      ERRORMASK           => s_ERRORMASK
      
      );

   CTSTMP: altcountertimestamp port map (
      clock40               => s_clk40,
      clock125              =>s_clk125,
      BURST                 => s_BURST,
      internal_timestamp    => s_internal_timestamp,
      internal_timestamp125 => s_internal_timestamp125  
      );
 
 
   usb_portmux_inst : usb_portmux port map(
      reset_n 			=> CPU_RESET_n,
      clk     			=> OSC_50_B2,
      OSC1_50                   => OSC_50_B2,
      number_of_triggers 	=> s_number_of_triggers,
      status 			=> s_status,
      status125 		=> s_status125,
      data_in 			=> s_data_in,
      OTG_D			=> OTG_D,
      OTG_A			=> OTG_A,
      OTG_CS_n			=> OTG_CS_n,
      OTG_WE_n			=> OTG_WE_n,
      OTG_OE_n			=> OTG_OE_n,
      OTG_HC_IRQ		=> OTG_HC_IRQ,
      OTG_DC_IRQ		=> OTG_DC_IRQ,
      OTG_RESET_n		=> OTG_RESET_n,
      OTG_HC_DREQ		=> OTG_HC_DREQ,
      OTG_HC_DACK		=> OTG_HC_DACK,
      OTG_DC_DREQ		=> OTG_DC_DREQ,
      OTG_DC_DACK		=> OTG_DC_DACK
      ); 



   usbinterface_inst : USBinterface port map(

      reset                              => NOT(CPU_RESET_n), 
      clk125                             => s_clk125,
      BURST                              => s_BURST,
      data_in                            => s_data_in,
      status                             => s_status,
      status125                          => s_status125,
      number_of_triggers                 => s_number_of_triggers	,
      startRUN                           => s_startRUN,
      activetriggers                     => s_activetriggers,
      activateperiodictrigger0           => s_activateperiodictrigger0,
      activateperiodictrigger1           => s_activateperiodictrigger1,
      activatecontroltrigger             => s_activatecontroltrigger,
      activatecalibtrigger               => s_activatecalibtrigger,
      activatesynchtrigger               => s_activatesynchtrigger,
      activateprimitives                 => s_activateprimitives,
      activateCHOKE                      => s_activateCHOKE,
      activateERROR                      => s_activateERROR ,
      activateSOBEOBtrigger              => s_activateSOBEOB,
      activateRandomtrigger              => s_activateRandomtrigger,
      activateClock20MHz                 => s_activateClock20MHz,
      activateNIMCalibration             => s_activateNIMCalib,
     
      ntriggers_predownscaling           => s_ntriggers_predownscaling,
      number_of_primitives               => s_number_of_primitives ,
      n_of_random                        => (others =>'0'), 
      n_of_Calibration                   => (others =>'0'),
      n_of_NIM_Calibration               => (others =>'0'),
      
      MEPEventNumber                     => s_MEPEventNumber,
      Fixed_Latency                      => s_Fixed_Latency,
      Calib_Triggerword                  => s_Calib_Triggerword,
      NIMcalib_direction                 => s_calib_direction,
      NIMCalib_Latency                   => s_Calib_Latency,
      NIMCalib_Triggerword               => s_NIMCalib_Triggerword,
      Periodic_Period0                   => s_periodictime0,
      periodic_triggerword0              => s_periodic_triggerword0,
      periodic_StartTime0                => s_periodic_Start_Time0,
      periodic_EndTime0                  => s_periodic_End_Time0,

      Periodic_Period1                   => s_periodictime1,
      periodic_triggerword1              => s_periodic_triggerword1,
      periodic_StartTime1                => s_periodic_Start_Time1,
      periodic_EndTime1                  => s_periodic_End_Time1,
				         
      Random_triggerword                 => s_random_triggerword,
      Random_Period                      => s_randomtime,
      Random_StartTime                   => s_Random_Start_Time,
      Random_EndTime                     => s_Random_End_Time,

      Offset                             => s_offset,
      maximum_delay_detector             => s_maximum_delay_detector,
      primitiveDT                        => s_primitiveDT,
      reference_detector                 => s_reference_detector,
      control_detector                   => s_control_detector,
      control_trigger_downscaling        => s_control_trigger_downscaling,
      out_enable_mask                    => s_enable_mask,
      bit_finetime                       => s_bit_finetime,
      downscaling                        => s_downscaling,
      Downscaling_reset                  => s_downscaling_reset,
      deltapacket                        => s_deltapacket,
      out_mask                           => s_mask,
      out_dontcare                       => s_dontcare,

      MEPNum                             => s_MEPNum,
      CounterLTU                         => s_CounterLTU,
      TRIGGERERROR                       => s_TRIGGERERROR,  
      ETHLINKERROR                       => s_ETHLINKERROR,
      Fixed_Latency_i                    => s_Fixed_Latency_o,
      
      n_of_choke                         => s_CounterCHOKE,
      n_of_error	                 => s_CounterERROR,
      
      periodicrandomtriggercounter       => s_periodicrandomtriggercounter,
      randomtriggercounter               => s_randomtriggercounter,
      ntriggers_postdownscaling_control  => s_ntriggers_postdownscaling_control,
      out_control_dontcare               => s_control_dontcare,
      out_control_mask                   => s_control_mask,       
      delaydeliveryoutput                => s_delaydeliveryoutput, --to read register on the monitor   
      readCHOKEFIFOON                    => s_readCHOKEFIFOON,
      readCHOKEFIFOOFF                   => s_readCHOKEFIFOOFF,
      readERRORFIFOON                    => s_readERRORFIFOON,
      readERRORFIFOOFF                   => s_readERRORFIFOOFF,
      CHOKEFIFOON                        => s_CHOKEFIFOON,
      CHOKEFIFOOFF                       => s_CHOKEFIFOOFF,
      ERRORFIFOON                        => s_ERRORFIFOON,
      ERRORFIFOOFF                       => s_ERRORFIFOOFF,
      CHOKEMASK                          => s_CHOKEMASK,
      ERRORMASK                          => s_ERRORMASK,
      timecut                            => s_timecut,
      delaydeliveryprimitive             => s_delaydeliveryprimitive, --to set register
      dataformat                         => s_dataformat,
      FAKEERROR                          => s_FAKEERROR,
      FAKECHOKE                          => s_FAKECHOKE
      );


   process(s_locked,s_locked40,TTC_READY,QPLL_LOCKED,QPLL_ERROR)
   begin
      if s_locked='1' and s_locked40 ='1' and TTC_READY ='1' and QPLL_LOCKED ='1' and QPLL_ERROR ='0' then
	 led2<='0';
      else
	 led2<='1';
      end if;
   end process;
         
   process(s_clk125)
   begin
      if(s_clk125='1' and s_clk125'event)  then
         case FSMreset is
	    when S0=>
	       s_software_CPU_RESET_n <= '1';
	       s_reset_counter<=0;
	       FSMReset<=S1;
	     
	    when S1=>
	       if s_reset_counter <200000 then
                  FSMReset<=S1;
                  s_reset_counter<=s_reset_counter+1;
                  s_software_CPU_RESET_n <= '1';
               else
		  FSMReset<=S2;
		  s_software_CPU_RESET_n <= '0';
	      end if;
	    when S2=>
	       if s_reset_counter < 125000000 then --1 sec of asynch reset
		  s_software_CPU_RESET_n <= '0';
		  s_reset_counter <= s_reset_counter+1;
	       else
		  s_software_CPU_RESET_n <= '1';
	       end if;  
         end case;
      end if;
   end process;

   TEMP_P: process(s_clk40,s_software_CPU_RESET_n)
   begin
      if s_software_CPU_RESET_n = '0' then
         s_temp_counter<=0;
         s_clr_temp<='1';
         s_ce_temp<='0';
      elsif(s_clk40='1' and s_clk40'event) then
         if(s_BURST ='1') then
            if(s_temp_counter<100000000) then --after 2.5 seconds during the burst
                                          --I measure the temperature
               s_temp_counter<=s_temp_counter+1;
               s_clr_temp<='1';
               s_ce_temp<='0';
             else
               s_clr_temp<='0';
               s_ce_temp<='1';
             end if;
         else
               s_temp_counter<=0;
               s_clr_temp<=s_clr_temp;
               s_ce_temp<=s_ce_temp;
         end if;
      end if;
   end process;
end rtl;
