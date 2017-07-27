library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use IEEE.NUMERIC_BIT.all;
use work.globals.all;
use work.userlib.all;

entity USBinterface is
   port (
      reset                        : in std_logic;
      clk125                       : in std_logic; --debug 125 Mhz
      BURST                        : in std_logic;
      data_in                      : in  std_logic_vector(31 downto 0);--FROM USB
      number_of_triggers           : in  std_logic_vector(31 downto 0);
      status                       : out std_logic_vector(31 downto 0);
      status125                    : out std_logic_vector(31 downto 0);
      startRUN                     : out std_logic; --faccio partire lo start of RUN
      
      --Trigger Types-------------------------------------------------------------------
      
      activateclock20MHz           : out std_logic;
      activateCHOKE                : out std_logic;
      activateERROR                : out std_logic;
      activateperiodictrigger0     : out std_logic;
      activateperiodictrigger1     : out std_logic;
      activatecalibtrigger         : out std_logic;
      activatesynchtrigger         : out std_logic;
      activateprimitives           : out std_logic;
      activaterandomtrigger        : out std_logic;
      activateSOBEOBtrigger        : out std_logic;
      activateNIMCalibration       : out std_logic;
      activatecontroltrigger       : out std_logic;
      --Debug---------------------------------------------------------------------------
      
      ntriggers_predownscaling 		   : in vector32bit_t(0 to nmask-1);
      MEPNum                       : in std_logic_vector(31 downto 0);
      number_of_primitives         : vector32bit_t(0 to ethlink_NODES-2);
      
      ntriggers_postdownscaling_control: in std_logic_vector(31 downto 0);
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
      
      --FIFO SIGNALS-------------------------------------------------------
      readCHOKEFIFOON              : out std_logic                   ;
      readERRORFIFOON              : out std_logic                   ;
      CHOKEFIFOON                  : in std_logic_vector(31 downto 0);
      ERRORFIFOON                  : in std_logic_vector(31 downto 0);
      
      readCHOKEFIFOOFF             : out std_logic                   ;
      readERRORFIFOOFF             : out std_logic                   ;
      CHOKEFIFOOFF                 : in std_logic_vector(31 downto 0);
      ERRORFIFOOFF                 : in std_logic_vector(31 downto 0);
      delaydeliveryoutput          : in std_logic_vector(31 downto 0);
      --Parameters---------------------------------------------------------
      Out_mask                     : out mem;
      Out_dontcare                 : out mem;
      Out_control_mask             : out std_logic_vector(111 downto 0);
      Out_control_dontcare         : out std_logic_vector(111 downto 0);
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
      
      Random_Period                : out std_logic_vector(31 downto 0);
      Random_Triggerword           : out std_logic_vector(31 downto 0);  
      Random_Detector	           : out std_logic_vector(31 downto 0);
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
      CHOKEMASK                    : out std_logic_vector(13 downto 0);
      ERRORMASK                    : out std_logic_vector(13 downto 0);
      Timecut                      : out vector16bit_t(0 to ethlink_NODES-2);
      Downscaling_reset            : out std_logic_vector(31 downto 0);
      Delaydeliveryprimitive       : out std_logic_vector(31 downto 0);
      Dataformat                   : out std_logic_vector(31 downto 0);
      FAKECHOKE                    : out std_logic_vector(13 downto 0);
      FAKEERROR                    : out std_logic_vector(13 downto 0);
      activetriggers               : out std_logic_vector(31 downto 0)
      );

   
end USBinterface;

architecture rtl of USBinterface is

   type FSMUSB is (Idle,Init,start,Reset_RunControl,SendClock20MHz,SetAddressPar,SetParameter,ReadParameter);
   type FSMUSB125 is (Idle,EOB,SetAddressPar,ReadParameter,READCHOKEOFF,READCHOKEON,READERROROFF,READERRORON);

   signal USBstate        : FSMUSB;
   signal DEBUGstate      : FSMUSB125;

-- matrix for parameters:
   type vector32bit_t is array(NATURAL RANGE <>) of std_logic_vector(31 downto 0)  ;
   signal s_parameters                 : vector32bit_t(0 to 255)                   ;
   signal s_address                    : std_logic_vector(31 downto 0)             ;
   signal parametersdebug              : vector32bit_t(0 to 127)                   ;
   signal s_addressdebug               : std_logic_vector(31 downto 0)             ;

   signal s_activetriggers             : std_logic_vector(31 downto 0);
   signal s_activateperiodictrigger0   : std_logic;
   signal s_activateperiodictrigger1   : std_logic;
   signal s_activatesynchtrigger       : std_logic;
   signal s_activate_primitives        : std_logic;
   signal s_activatecalibtrigger       : std_logic;
   signal s_activateSOBEOB             : std_logic;
   signal s_activateClock20MHz         : std_logic;
   signal s_activateCHOKE              : std_logic;
   signal s_activateERROR              : std_logic;
   signal s_activateNIMCalib           : std_logic;
   signal s_activateRandomtrigger      : std_logic;
   signal s_activatecontroltrigger     : std_logic;
 
	
--FAKE----------------------------------------------
	signal s_FAKECHOKE                  : std_logic_vector(13 downto 0);
	signal s_FAKEERROR                  : std_logic_vector(13 downto 0);
	
   signal debug_signal                 : std_logic;
   signal counter_USB_latency          : integer;

--LUT----------------------------------------
   signal mask                         : mem;
   signal dontcare                     : mem;
   signal control_mask                 : std_logic_vector(31 downto 0);
   signal control_dontcare             : std_logic_vector(31 downto 0);
	

begin


   parametersdebug(0) <= Number_of_Primitives(0)     ; --Primitive Received
   parametersdebug(1) <= Number_of_Primitives(1)     ;
   parametersdebug(2) <= Number_of_Primitives(2)     ;
   parametersdebug(3) <= Number_of_Primitives(3)     ;
   parametersdebug(4) <= Number_of_Primitives(4)     ;
   parametersdebug(5) <= Number_of_Primitives(5)     ;
   parametersdebug(6) <= Number_of_Primitives(6)     ;
   parametersdebug(7) <= MEPNum                      ; --number of meps sent
   parametersdebug(8) <= periodicrandomtriggercounter; --number of MEP generated
   parametersdebug(9) <= CounterLTU                  ; --number of trigger sent to LTU
   parametersdebug(10)<= TRIGGERERROR                ; -- error in trigger module
   parametersdebug(11)<= ETHLINKERROR                ; -- error in ethernet module
   parametersdebug(12)<= n_of_choke                  ;  --number of choke  
   parametersdebug(13)<= n_of_error                  ;  --number of error  
   parametersdebug(14)<= n_of_random                 ; --number of random  
   parametersdebug(15)<= n_of_Calibration            ; --number of Calibration  
   parametersdebug(16)<= n_of_NIM_Calibration        ; --number of Calibration NIM
   parametersdebug(17)<= Fixed_Latency_i             ; --number of Calibration NIM
   parametersdebug(18) <= ntriggers_predownscaling(0); --Triggers before donwscaling mask 0
   parametersdebug(19) <= ntriggers_predownscaling(1); --Triggers before donwscaling mask 1
   parametersdebug(20) <= ntriggers_predownscaling(2); --Triggers before donwscaling mask 2
   parametersdebug(21) <= ntriggers_predownscaling(3); --Triggers before donwscaling mask 3
   parametersdebug(22) <= ntriggers_predownscaling(4); --Triggers before donwscaling mask 4
   parametersdebug(23) <= ntriggers_predownscaling(5); --Triggers before donwscaling mask 5
   parametersdebug(24) <= ntriggers_predownscaling(6); --Triggers before donwscaling mask 6
   parametersdebug(25) <= ntriggers_predownscaling(7); --Triggers before donwscaling mask 7
   parametersdebug(26) <= ntriggers_postdownscaling_control  ; 
   parametersdebug(27) <= randomtriggercounter       ;
   parametersdebug(28) <= delaydeliveryoutput        ; -- time to wait before delivering trigger with primitives

   parametersdebug(29) <= ntriggers_predownscaling(8); --Triggers before donwscaling mask 8
   parametersdebug(30) <= ntriggers_predownscaling(9); --Triggers before donwscaling mask 9
   parametersdebug(31) <= ntriggers_predownscaling(10); --Triggers before donwscaling mask 10
   parametersdebug(32) <= ntriggers_predownscaling(11); --Triggers before donwscaling mask 11
   parametersdebug(33) <= ntriggers_predownscaling(12); --Triggers before donwscaling mask 12
   parametersdebug(34) <= ntriggers_predownscaling(13); --Triggers before donwscaling mask 13
   parametersdebug(35) <= ntriggers_predownscaling(14); --Triggers before donwscaling mask 14
   parametersdebug(36) <= ntriggers_predownscaling(15); --Triggers before donwscaling mask 15

   parametersdebug(37)(0)  <= s_activate_primitives    ; 
   parametersdebug(37)(1)  <= s_activatecontroltrigger ;
   parametersdebug(37)(2)  <= s_activateperiodictrigger0; 	
   parametersdebug(37)(3)  <= s_activateperiodictrigger1; 	
   parametersdebug(37)(4)  <= s_activateRandomtrigger; 	
   parametersdebug(37)(5)  <= s_activateNIMCalib; 	
   parametersdebug(37)(6)  <= s_activatecalibtrigger; 	
   parametersdebug(37)(7)  <= s_activateSOBEOB; 	
   parametersdebug(37)(8)  <= s_activateCHOKE; 	
   parametersdebug(37)(9)  <= s_activateERROR; 	
   parametersdebug(37)(10) <= s_activateClock20MHz; 	 
   parametersdebug(37)(11) <= s_activatesynchtrigger; 	 	

   
   
   parametersdebug(38 to 127) <= (others =>"00000000000000000000000000000000"); --reserved

   P1: PROCESS(Reset,clk125,data_in)
   begin
      if(reset='1') then
	 
   	 USBstate                <= Idle            ;
	 status                     <=SLV(999999,32);
	 startRUN                   <='0'           ;
	 s_activateclock20MHz       <='0'           ;
      elsif(clk125='1' and clk125'event) then
	 
	 startRUN                   <='0'           ;         -- Default states
	 s_activateclock20MHz       <='0'           ;
	 case USBstate is
	    
	    when idle =>
	       
	       status                   <=SLV(0,32)       ; --Dico alla interfaccia che sono in idle
	       ----CLEAR COUNTERS------------------------------
	       s_activateperiodictrigger0<='0'; --0)
	       s_activateperiodictrigger1<='0'; --1)
	       s_activate_primitives     <='0'; --2)
	       s_activatesynchtrigger    <='0'; --3)
	       s_activatecalibtrigger    <='0'; --4)
	       s_activateCHOKE           <='0'; --5)
	       s_activateERROR           <='0'; --6)
	       s_activaterandomtrigger   <='0'; --7)
	       s_activateClock20MHz      <='0'; --8)
	       s_activateSOBEOB          <='0'; --9)
	       s_activateNIMCalib        <='0'; --A)
	       s_activatecontroltrigger  <='0'; --B)
	       s_parameters              <=(others=>X"00000000");
	       s_address                 <=(others=>'0')        ;  
	       s_FAKECHOKE               <=(others=>'0');
	       s_FAKEERROR               <=(others=>'0');
			 
	       
	       if data_in = par_init then  -- Se arriva il comando di inizializzazione, vado in init
		  USBstate            <= Init         ;
	       else
		  USBstate            <= Idle         ;
	       end if;
	       
	       
	    when Init=>
	       
	       ----scrivere i vari parametri
	       
	       status                   <=SLV(1,32)       ; -- Mi dice che sono in init

	       --Trigger types
	       s_activateperiodictrigger0<='0'; --0)
	       s_activateperiodictrigger1<='0'; --1)
	       s_activate_primitives     <='0'; --2)
	       s_activatesynchtrigger    <='0'; --3)
	       s_activatecalibtrigger    <='0'; --4)
	       s_activateCHOKE           <='0'; --5)
	       s_activateERROR           <='0'; --6)
	       s_activaterandomtrigger   <='0'; --7)
	       s_activateClock20MHz      <='0'; --8)
	       s_activateSOBEOB          <='0'; --9)
	       s_activateNIMCalib        <='0'; --A)
	       s_activatecontroltrigger  <='0'; --B)
	       
	       if data_in= par_reset then                  -- Reset_RunControl;
		  USBstate <=Reset_RunControl;
		  
	       elsif data_in = par_start then              --  Start Data taking;
		  USBstate   <=Start;
		  
	       elsif data_in = par_setaddresspar then      --  Set Parameter address;
		  USBstate <= setaddresspar;	 	  
		  
	       elsif data_in = par_readparameter then      --  Read Parameter;
		  USBstate <= readparameter;	 	
		  
	       elsif data_in = par_setparameter then       -- Write Parameter in the selected address;
		  USBstate <= SetParameter;	 	  	 
		  
	       elsif data_in = par_activateClock20MHz then --Activate Synch clock to LTU
		  USBstate   <= SendClock20MHz;

	      	  
		  
	       else 
		  USBstate <=Init;
	       end if;

	   	  
	    when SendClock20MHz =>
	       if data_in = par_init then 
		  USBstate <= Init;
	       else
		  status <=SLV(100,32); 
		  s_activateClock20MHz     <='1';
		  USBstate <=SendClock20MHz;
	       end if;
	       

	    when readParameter =>
	       if data_in = par_init then 
		  USBstate <= Init;
	       else
		  status <= s_parameters(UINT(s_address)); 
	       end if;	

	       
	       
	    when setaddressPar=>
	       if data_in = par_init then 
		  USBstate <= Init;
	       else
		  status <=SLV(300,32); 
		  s_address <=data_in;
		  USBstate <=setAddressPar;
	       end if;
	       

	    when setParameter=>
	       if data_in = par_init then 
		  USBstate <= Init;
	       else
		  status <=SLV(301,32); 
		  s_parameters(UINT(s_address))(31 downto 0)  <=data_in(31 downto 0);
		  USBstate <=setParameter;
	       end if;
	       
	       
	    when start => 
	       
	       if data_in = par_stop     then----STOP
		  USBstate <= Init;
		  
	       elsif data_in = par_reset then--Reset
		  USBstate<=Reset_RunControl;
		  
	       else
		  startRUN <='1';
		  status   <= SLV(2,32);
		  USBstate <= start;
		  
		  ----Activate Debug------------------
		  if data_in =par_debugOn     then
		     debug_signal <='1';
		  elsif data_in =par_debugOff then
		     debug_signal <='0';
		  else
		     debug_signal <=debug_signal;
		  end if;
		  ---------------------------------------
		  if data_in = par_activateFAKEchoke then
		     s_FAKECHOKE <="00000000000001";
		  end if;

		  if data_in = par_activateFAKEerror then
		     s_FAKEERROR <="00000000000001";
		  end if;
		  
		  if data_in = par_deactivateFAKEchoke then
		     s_FAKECHOKE <="00000000000000";
		  end if;

		  if data_in = par_deactivateFAKEerror then
		     s_FAKEERROR <="00000000000000";
		  end if;
		 
		  
		  if data_in = par_activateperiodictrigger0      then
		     s_activateperiodictrigger0 <='1';  
		  elsif data_in = par_deactivateperiodictrigger0 then
		     s_activateperiodictrigger0 <='0';
		  else
		     s_activateperiodictrigger0 <=s_activateperiodictrigger0;
		  end if;--periodictrigger0

		  if data_in = par_activateperiodictrigger1      then
		     s_activateperiodictrigger1 <='1';  
		  elsif data_in = par_deactivateperiodictrigger1 then
		     s_activateperiodictrigger1 <='0';
		  else
		     s_activateperiodictrigger1 <=s_activateperiodictrigger1;
		  end if;--periodictrigger1
		  
		  
		  if data_in = par_activatecontroltrigger      then
		     s_activatecontroltrigger <='1';  
		  elsif data_in = par_deactivatecontroltrigger then
		     s_activatecontroltrigger <='0';
		  else
		     s_activatecontroltrigger <=s_activatecontroltrigger;
		  end if;--controltrigger
		  
		  
		  if data_in = par_activatecalibtrigger      then
		     s_activatecalibtrigger <='1';	
		  elsif data_in = par_deactivatecalibtrigger then
		     s_activatecalibtrigger <='0';
		  else
		     s_activatecalibtrigger <=s_activatecalibtrigger;
		  end if;--calib trigger
		  
		  if data_in = par_activate_primitives      then
		     s_activate_primitives <='1';
		  elsif data_in = par_deactivate_primitives then
		     s_activate_primitives <='0';
		  else
		     s_activate_primitives <=s_activate_primitives;
		  end if;--primitives trigger
		  
		  if data_in = par_activatesynchtrigger      then
		     s_activatesynchtrigger <='1';
		  elsif data_in = par_deactivatesynchtrigger then
		     s_activatesynchtrigger <='0';
		  else
		     s_activatesynchtrigger <=s_activatesynchtrigger;
		  end if; --synch trigger
		  
		  if data_in = par_activateCHOKE         then
		     s_activateCHOKE <='1'; 
		  elsif data_in = par_deactivateCHOKE    then
		     s_activateCHOKE <='0';
		  else
		     s_activateCHOKE <=s_activateCHOKE;
		  end if; --CHOKE trigger
		  
		  if data_in = par_activateERROR         then
		     s_activateERROR <='1';
		  elsif data_in = par_deactivateERROR    then
		     s_activateERROR <='0';
		  else
		     s_activateERROR <=s_activateERROR;
		  end if; --ERROR trigger
		  
		  if data_in = par_activateSOBEOB        then
		     s_activateSOBEOB <='1';
		  elsif data_in = par_deactivateSOBEOB	then
		     s_activateSOBEOB <='0';
		  else
		     s_activateSOBEOB <=s_activateSOBEOB;
		  end if; --SOBEOB trigger
		  
		  
		  if data_in = par_activateNIMCalib        then
		     s_activateNIMCalib <='1';
		  elsif data_in = par_deactivateNIMCalib	then
		     s_activateNIMCalib <='0';
		  else
		     s_activateNIMCalib <=s_activateNIMCalib;
		  end if; --NIM Calibration trigger		
		  
		  
		  if data_in = par_activaterandomtrigger        then
		     s_activaterandomtrigger <='1';
		  elsif data_in = par_deactivaterandomtrigger then
		     s_activaterandomtrigger <='0';
		  else
		     s_activaterandomtrigger <=s_activaterandomtrigger;
		  end if; --Random trigger		
		  
		  
		  
		  
		  
	       end if; --SOB
	       
	    when Reset_RunControl =>
	       USBstate <= Idle;
	       startRUN <='0';
	 end case;

      end if;
   end PROCESS;
   
------------------------------------------------------------
   P2: PROCESS(clk125,Reset)

   begin
      if(reset='1')then
	 DEBUGstate <= Idle;
	 status125 <=SLV(0,32);
      elsif(clk125='1' and clk125'event)  then
	 case  DEBUGstate is
	    when Idle =>
	       if  BURST ='0' then --arriva l'EOB
		  DEBUGstate  <=EOB;
	       else --sono in Run
		  status125 <= SLV(0,32);
		  DEBUGstate  <=Idle;
	       end if;
	       
	    when EOB =>
	       status125  <=SLV(1,32);
	       if number_of_triggers = par_SetAddressDebug then            --  Set Parameter address;
		  DEBUGstate <= setaddresspar;	 	  
		  
	       elsif number_of_triggers = par_ReadParameterDebug then      --  Read Parameter;
		  DEBUGstate <= readparameter;
		  
	       elsif number_of_triggers = par_readchokeon then            --  Set Parameter address;
		  readCHOKEFIFOON <= '1';	 
		  DEBUGstate <= READCHOKEON;
		  
	       elsif number_of_triggers = par_readchokeoff then            --  Set Parameter address;
		  readCHOKEFIFOOFF <= '1';	 
		  DEBUGstate <= READCHOKEOFF;
		  
	       elsif number_of_triggers = par_readerroron then            --  Set Parameter address;
		  readERRORFIFOON <= '1';	 
		  DEBUGstate <= READERRORON;
		  
	       elsif number_of_triggers = par_readerroroff then            --  Set Parameter address;
		  readERRORFIFOOFF <= '1';	 
		  DEBUGstate <= READERROROFF;
	       else
		  DEBUGstate <= IDLE;
	       end if;
	       
	       if BURST ='1' then
		  DEBUGstate  <=Idle;
	       end if;
	       
	       

	    when READCHOKEON =>
	       if  BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <= CHOKEFIFOON; 
		  end if;	
	       else
		  DEBUGstate  <=Idle;
	       end if;
	       
	       
	    when READCHOKEOFF =>
	       if BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <= CHOKEFIFOOFF; 
		  end if;	
	       else
		  DEBUGstate  <=Idle;
	       end if;
	       
	       
	    when READERROROFF =>
	       if BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <= ERRORFIFOOFF; 
		  end if;	
	       else
		  DEBUGstate  <=Idle;
	       end if;
	       
	       
	    when READERRORON =>
	       if BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <= ERRORFIFOON; 
		  end if;	
	       else
		  DEBUGstate  <=Idle;
	       end if;
	       
	       
	       
	       
	    when readParameter =>
	       if BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <= parametersdebug(UINT(s_addressdebug)); 
		  end if;	
	       else
		  DEBUGstate  <=Idle;
	       end if;
	       
	       
	       
	       
	    when setaddressPar=>
	       if BURST ='0' then
		  if number_of_triggers = par_initdebug then 
		     DEBUGstate <= EOB;
		  else
		     status125 <=SLV(300,32); 
		     s_addressdebug <=number_of_triggers;
		     DEBUGstate <=setAddressPar;
		  end if;
	       else 
		  DEBUGstate <= Idle;
	       end if;
	       
	 end case;
      end if;
   end process;
   
   
--------TRIGGERTYPES----------------------------

   activetriggers             <= parametersdebug(37)        ;
   activateperiodictrigger0   <= s_activateperiodictrigger0 ;
   activateperiodictrigger1   <= s_activateperiodictrigger1 ;
   activatecalibtrigger       <= s_activatecalibtrigger     ;
   activatesynchtrigger       <= s_activatesynchtrigger     ;
   activateprimitives         <= s_activate_primitives      ;
   activateCHOKE              <= s_activateCHOKE            ;
   activateERROR              <= s_activateERROR            ;	
   activateSOBEOBtrigger      <= s_activateSOBEOB           ;
   activateRandomtrigger      <= s_activateRandomtrigger    ;
   activateClock20MHz         <= s_activateClock20MHz       ;
   activateNIMCalibration     <= s_activateNIMCalib         ;
   activatecontroltrigger     <= s_activatecontroltrigger   ;
   FAKECHOKE                  <= s_FAKECHOKE(13 downto 0)   ;
   FAKEERROR                  <= s_FAKEERROR(13 downto 0)  ;
--------OUTPUTS--------------------------------
   MEPEventNumber             <= s_parameters(0) ;
   FIxed_LAtency              <= s_parameters(1) ;
   NIMCalib_Latency           <= s_parameters(2) ;
   NIMCalib_direction         <= s_parameters(3) ;
   NIMCalib_Triggerword       <= s_parameters(4) ;
   Periodic_Period0           <= s_parameters(5) ;
   Periodic_Triggerword0      <= s_parameters(6) ;	
   Periodic_StartTime0        <= s_parameters(7) ;
   Periodic_EndTime0          <= s_parameters(8) ;
   Random_Triggerword         <= s_parameters(9) ;
   Random_Period              <= s_parameters(10);
   Delaydeliveryprimitive     <= s_parameters(11);
   Random_StartTime           <= s_parameters(12);
   Random_EndTime             <= s_parameters(13);
   Offset(0)                  <= s_parameters(14);
   Offset(1)                  <= s_parameters(15);
   Offset(2)                  <= s_parameters(16);
   Offset(3)                  <= s_parameters(17);
   Offset(4)                  <= s_parameters(18);
   Offset(5)                  <= s_parameters(19);
   Offset(6)                  <= s_parameters(20);
   Maximum_Delay_Detector     <= s_parameters(21);
   PrimitiveDT                <= s_parameters(22);
   Reference_detector         <= s_parameters(23);
   Control_detector           <= s_parameters(24);
   Out_enable_mask            <= s_parameters(25)(nmask-1 downto 0);
   Bit_finetime               <= s_parameters(26);
   Downscaling(0)             <= s_parameters(27);
   Downscaling(1)             <= s_parameters(28);
   Downscaling(2)             <= s_parameters(29);
   Downscaling(3)             <= s_parameters(30);
   Downscaling(4)             <= s_parameters(31);
   Downscaling(5)             <= s_parameters(32);
   Downscaling(6)             <= s_parameters(33);
   Downscaling(7)             <= s_parameters(34);
   Downscaling(8)             <= s_parameters(35);
   Downscaling(9)             <= s_parameters(36);
   Downscaling(10)            <= s_parameters(37);
   Downscaling(11)            <= s_parameters(38);
   Downscaling(12)            <= s_parameters(39);
   Downscaling(13)            <= s_parameters(40);
   Downscaling(14)            <= s_parameters(41);
   Downscaling(15)            <= s_parameters(42);
   Calib_Triggerword            <= s_parameters(99);
   Deltapacket                  <= s_parameters(100);
   Control_trigger_downscaling <= s_parameters(101);
   --.....PARAMETER 102 MISSING....
   CHOKEMASK                    <= s_parameters(104)(13 downto 0);
   ERRORMASK                    <= s_parameters(104)(27 downto 14);
   
  
   
   Timecut(0)                   <= s_parameters(105)(15 downto 0);
   Timecut(1)                   <= s_parameters(106)(15 downto 0);
   Timecut(2)                   <= s_parameters(107)(15 downto 0);
   Timecut(3)                   <= s_parameters(108)(15 downto 0);
   Timecut(4)                   <= s_parameters(109)(15 downto 0);
   Timecut(5)                   <= s_parameters(110)(15 downto 0);
   Timecut(6)                   <= s_parameters(111)(15 downto 0);
   
   Periodic_Period1             <= s_parameters(112)  ;
   Periodic_Triggerword1        <= s_parameters(113)  ;	
   Periodic_StartTime1          <= s_parameters(114)  ;
   Periodic_EndTime1            <= s_parameters(115)  ;
   Downscaling_reset            <= s_parameters(122)  ;
   DataFormat                   <= s_parameters(123)  ;

   
   Out_control_mask             <= s_parameters(103)(15 downto 0) & --A
				   s_parameters(116)(15 downto 0) & --B
				   s_parameters(117)(15 downto 0) & --C
				   s_parameters(118)(15 downto 0) & --D
				   s_parameters(119)(15 downto 0) & --E
				   s_parameters(120)(15 downto 0) & --F
				   s_parameters(121)(15 downto 0);  --G
   
   Out_control_dontcare         <= s_parameters(103)(31 downto 16) &
				   s_parameters(116)(31 downto 16) &
				   s_parameters(117)(31 downto 16) &
				   s_parameters(118)(31 downto 16) &
				   s_parameters(119)(31 downto 16) &
				   s_parameters(120)(31 downto 16) &
				   s_parameters(121)(31 downto 16) ;
   ---MASK 0---------------------------------------------------------------
   Out_mask(0)                <= s_parameters(43)(15  downto 0) & --detector A 
				 s_parameters(44)(15  downto 0) & --detector B 
				 s_parameters(45)(15  downto 0) & --detector C 
				 s_parameters(46)(15  downto 0) & --detector D 
				 s_parameters(47)(15  downto 0) & --detector E
				 s_parameters(48)(15  downto 0) & --detector F
				 s_parameters(49)(15  downto 0) ; --detector G

   
   Out_dontcare(0)            <= s_parameters(43)(31  downto 16) & --detector A 
				 s_parameters(44)(31  downto 16) & --detector B 
				 s_parameters(45)(31  downto 16) & --detector C 
				 s_parameters(46)(31  downto 16) & --detector D 
				 s_parameters(47)(31  downto 16) & --detector E
				 s_parameters(48)(31  downto 16) & --detector F
				 s_parameters(49)(31  downto 16) ; --detector G 				  
   
   ---MASK 1---------------------------------------------------------------
   
   Out_mask(1)               <= s_parameters(50)(15  downto 0) & --detector A 
				s_parameters(51)(15  downto 0) & --detector B 
				s_parameters(52)(15  downto 0) & --detector C 
				s_parameters(53)(15  downto 0) & --detector D 
				s_parameters(54)(15  downto 0) & --detector E
				s_parameters(55)(15  downto 0) & --detector F
				s_parameters(56)(15  downto 0) ; --detector G

   
   Out_dontcare(1)           <= s_parameters(50)(31  downto 16) & --detector A 
				s_parameters(51)(31  downto 16) & --detector B 
				s_parameters(52)(31  downto 16) & --detector C 
				s_parameters(53)(31  downto 16) & --detector D 
				s_parameters(54)(31  downto 16) & --detector E
				s_parameters(55)(31  downto 16) & --detector F
				s_parameters(56)(31  downto 16) ; --detector G 				  
   
   
   ---MASK 2---------------------------------------------------------------
   
   Out_mask(2)               <= s_parameters(57)(15  downto 0) & --detector A 
				s_parameters(58)(15  downto 0) & --detector B 
				s_parameters(59)(15  downto 0) & --detector C 
				s_parameters(60)(15  downto 0) & --detector D 
				s_parameters(61)(15  downto 0) & --detector E
				s_parameters(62)(15  downto 0) & --detector F
				s_parameters(63)(15  downto 0) ; --detector G

   
   Out_dontcare(2)           <= s_parameters(57)(31  downto 16) & --detector A 
				s_parameters(58)(31  downto 16) & --detector B 
				s_parameters(59)(31  downto 16) & --detector C 
				s_parameters(60)(31  downto 16) & --detector D 
				s_parameters(61)(31  downto 16) & --detector E
				s_parameters(62)(31  downto 16) & --detector F
				s_parameters(63)(31  downto 16) ; --detector G 		
   
   
   
   ---MASK 3---------------------------------------------------------------
   
   Out_mask(3)               <= s_parameters(64)(15  downto 0) & --detector A 
				s_parameters(65)(15  downto 0) & --detector B 
				s_parameters(66)(15  downto 0) & --detector C 
				s_parameters(67)(15  downto 0) & --detector D 
				s_parameters(68)(15  downto 0) & --detector E
				s_parameters(69)(15  downto 0) & --detector F
				s_parameters(70)(15  downto 0) ; --detector G

   
   Out_dontcare(3)           <= s_parameters(64)(31  downto 16) & --detector A 
				s_parameters(65)(31  downto 16) & --detector B 
				s_parameters(66)(31  downto 16) & --detector C 
				s_parameters(67)(31  downto 16) & --detector D 
				s_parameters(68)(31  downto 16) & --detector E
				s_parameters(69)(31  downto 16) & --detector F
				s_parameters(70)(31  downto 16) ; --detector G 		
   
   
   ---MASK 4---------------------------------------------------------------
   
   Out_mask(4)               <= s_parameters(71)(15  downto 0) & --detector A 
				s_parameters(72)(15  downto 0) & --detector B 
				s_parameters(73)(15  downto 0) & --detector C 
				s_parameters(74)(15  downto 0) & --detector D 
				s_parameters(75)(15  downto 0) & --detector E
				s_parameters(76)(15  downto 0) & --detector F
				s_parameters(77)(15  downto 0) ; --detector G

   
   Out_dontcare(4)           <= s_parameters(71)(31  downto 16) & --detector A 
				s_parameters(72)(31  downto 16) & --detector B 
				s_parameters(73)(31  downto 16) & --detector C 
				s_parameters(74)(31  downto 16) & --detector D 
				s_parameters(75)(31  downto 16) & --detector E
				s_parameters(76)(31  downto 16) & --detector F
				s_parameters(77)(31  downto 16) ; --detector G 		
   
   
   
   
   ---MASK 5---------------------------------------------------------------
   
   Out_mask(5)               <= s_parameters(78)(15  downto 0) & --detector A 
				s_parameters(79)(15  downto 0) & --detector B 
				s_parameters(80)(15  downto 0) & --detector C 
				s_parameters(81)(15  downto 0) & --detector D 
				s_parameters(82)(15  downto 0) & --detector E
				s_parameters(83)(15  downto 0) & --detector F
				s_parameters(84)(15  downto 0) ; --detector G

   
   Out_dontcare(5)           <= s_parameters(78)(31  downto 16) & --detector A 
				s_parameters(79)(31  downto 16) & --detector B 
				s_parameters(80)(31  downto 16) & --detector C 
				s_parameters(81)(31  downto 16) & --detector D 
				s_parameters(82)(31  downto 16) & --detector E
				s_parameters(83)(31  downto 16) & --detector F
				s_parameters(84)(31  downto 16) ; --detector G 		
   
   
   ---MASK 6---------------------------------------------------------------
   
   Out_mask(6)               <= s_parameters(85)(15  downto 0) & --detector A 
				s_parameters(86)(15  downto 0) & --detector B 
				s_parameters(87)(15  downto 0) & --detector C 
				s_parameters(88)(15  downto 0) & --detector D 
				s_parameters(89)(15  downto 0) & --detector E
				s_parameters(90)(15  downto 0) & --detector F
				s_parameters(91)(15  downto 0) ; --detector G

   
   Out_dontcare(6)           <= s_parameters(85)(31  downto 16) & --detector A 
				s_parameters(86)(31  downto 16) & --detector B 
				s_parameters(87)(31  downto 16) & --detector C 
				s_parameters(88)(31  downto 16) & --detector D 
				s_parameters(89)(31  downto 16) & --detector E
				s_parameters(90)(31  downto 16) & --detector F
				s_parameters(91)(31  downto 16) ; --detector G 
   
   
   
   ---MASK 7---------------------------------------------------------------
   
   Out_mask(7)               <= s_parameters(92)(15  downto 0) & --detector A 
				s_parameters(93)(15  downto 0) & --detector B 
				s_parameters(94)(15  downto 0) & --detector C 
				s_parameters(95)(15  downto 0) & --detector D 
				s_parameters(96)(15  downto 0) & --detector E
				s_parameters(97)(15  downto 0) & --detector F
				s_parameters(98)(15  downto 0) ; --detector G

   
   Out_dontcare(7)           <= s_parameters(92)(31  downto 16) & --detector A 
				s_parameters(93)(31  downto 16) & --detector B 
				s_parameters(94)(31  downto 16) & --detector C 
				s_parameters(95)(31  downto 16) & --detector D 
				s_parameters(96)(31  downto 16) & --detector E
				s_parameters(97)(31  downto 16) & --detector F
				s_parameters(98)(31  downto 16) ; --detector G
                                                                  --


   
   ---MASK 8---------------------------------------------------------------
   
   Out_mask(8)               <= s_parameters(124)(15  downto 0) & --detector A 
				s_parameters(125)(15  downto 0) & --detector B 
				s_parameters(126)(15  downto 0) & --detector C 
				s_parameters(127)(15  downto 0) & --detector D 
				s_parameters(128)(15  downto 0) & --detector E
				s_parameters(129)(15  downto 0) & --detector F
				s_parameters(130)(15  downto 0) ; --detector G

   
   Out_dontcare(8)           <= s_parameters(124)(31  downto 16) & --detector A 
				s_parameters(125)(31  downto 16) & --detector B 
				s_parameters(126)(31  downto 16) & --detector C 
				s_parameters(127)(31  downto 16) & --detector D 
				s_parameters(128)(31  downto 16) & --detector E
				s_parameters(129)(31  downto 16) & --detector F
				s_parameters(130)(31  downto 16) ; --detector G
                                                                   --

    ---MASK 9---------------------------------------------------------------
   
   Out_mask(9)               <= s_parameters(131)(15  downto 0) & --detector A 
				s_parameters(132)(15  downto 0) & --detector B 
				s_parameters(133)(15  downto 0) & --detector C 
				s_parameters(134)(15  downto 0) & --detector D 
				s_parameters(135)(15  downto 0) & --detector E
				s_parameters(136)(15  downto 0) & --detector F
				s_parameters(137)(15  downto 0) ; --detector G

   
   Out_dontcare(9)           <= s_parameters(131)(31  downto 16) & --detector A 
				s_parameters(132)(31  downto 16) & --detector B 
				s_parameters(133)(31  downto 16) & --detector C 
				s_parameters(134)(31  downto 16) & --detector D 
				s_parameters(135)(31  downto 16) & --detector E
				s_parameters(136)(31  downto 16) & --detector F
				s_parameters(137)(31  downto 16) ; --detector G
                                                                   --

     ---MASK 10---------------------------------------------------------------
   
   Out_mask(10)              <= s_parameters(138)(15  downto 0) & --detector A 
				s_parameters(139)(15  downto 0) & --detector B 
				s_parameters(140)(15  downto 0) & --detector C 
				s_parameters(141)(15  downto 0) & --detector D 
				s_parameters(142)(15  downto 0) & --detector E
				s_parameters(143)(15  downto 0) & --detector F
				s_parameters(144)(15  downto 0) ; --detector G

   
   Out_dontcare(10)          <= s_parameters(138)(31  downto 16) & --detector A 
				s_parameters(139)(31  downto 16) & --detector B 
				s_parameters(140)(31  downto 16) & --detector C 
				s_parameters(141)(31  downto 16) & --detector D 
				s_parameters(142)(31  downto 16) & --detector E
				s_parameters(143)(31  downto 16) & --detector F
				s_parameters(144)(31  downto 16) ; --detector G 


      ---MASK 11---------------------------------------------------------------
   
   Out_mask(11)              <= s_parameters(145)(15  downto 0) & --detector A 
				s_parameters(146)(15  downto 0) & --detector B 
				s_parameters(147)(15  downto 0) & --detector C 
				s_parameters(148)(15  downto 0) & --detector D 
				s_parameters(149)(15  downto 0) & --detector E
				s_parameters(150)(15  downto 0) & --detector F
				s_parameters(151)(15  downto 0) ; --detector G

   
   Out_dontcare(11)          <= s_parameters(145)(31  downto 16) & --detector A 
				s_parameters(146)(31  downto 16) & --detector B 
				s_parameters(147)(31  downto 16) & --detector C 
				s_parameters(148)(31  downto 16) & --detector D 
				s_parameters(149)(31  downto 16) & --detector E
				s_parameters(150)(31  downto 16) & --detector F
				s_parameters(151)(31  downto 16) ; --detector G




       ---MASK 12---------------------------------------------------------------
   
   Out_mask(12)              <= s_parameters(152)(15  downto 0) & --detector A 
				s_parameters(153)(15  downto 0) & --detector B 
				s_parameters(154)(15  downto 0) & --detector C 
				s_parameters(155)(15  downto 0) & --detector D 
				s_parameters(156)(15  downto 0) & --detector E
				s_parameters(157)(15  downto 0) & --detector F
				s_parameters(158)(15  downto 0) ; --detector G

   
   Out_dontcare(12)          <= s_parameters(152)(31  downto 16) & --detector A 
				s_parameters(153)(31  downto 16) & --detector B 
				s_parameters(154)(31  downto 16) & --detector C 
				s_parameters(155)(31  downto 16) & --detector D 
				s_parameters(156)(31  downto 16) & --detector E
				s_parameters(157)(31  downto 16) & --detector F
				s_parameters(158)(31  downto 16) ; --detector G 




     ---MASK 13---------------------------------------------------------------
   
   Out_mask(13)              <= s_parameters(159)(15  downto 0) & --detector A 
				s_parameters(160)(15  downto 0) & --detector B 
				s_parameters(161)(15  downto 0) & --detector C 
				s_parameters(162)(15  downto 0) & --detector D 
				s_parameters(163)(15  downto 0) & --detector E
				s_parameters(164)(15  downto 0) & --detector F
				s_parameters(165)(15  downto 0) ; --detector G

   
   Out_dontcare(13)          <= s_parameters(159)(31  downto 16) & --detector A 
				s_parameters(160)(31  downto 16) & --detector B 
				s_parameters(161)(31  downto 16) & --detector C 
				s_parameters(162)(31  downto 16) & --detector D 
				s_parameters(163)(31  downto 16) & --detector E
				s_parameters(164)(31  downto 16) & --detector F
				s_parameters(165)(31  downto 16) ; --detector G 



   
     ---MASK 14---------------------------------------------------------------
   
   Out_mask(14)              <= s_parameters(166)(15  downto 0) & --detector A 
				s_parameters(167)(15  downto 0) & --detector B 
				s_parameters(168)(15  downto 0) & --detector C 
				s_parameters(169)(15  downto 0) & --detector D 
				s_parameters(170)(15  downto 0) & --detector E
				s_parameters(171)(15  downto 0) & --detector F
				s_parameters(172)(15  downto 0) ; --detector G

   
   Out_dontcare(14)          <= s_parameters(166)(31  downto 16) & --detector A 
				s_parameters(167)(31  downto 16) & --detector B 
				s_parameters(168)(31  downto 16) & --detector C 
				s_parameters(169)(31  downto 16) & --detector D 
				s_parameters(170)(31  downto 16) & --detector E
				s_parameters(171)(31  downto 16) & --detector F
				s_parameters(172)(31  downto 16) ; --detector G
                                                                   --
  ---MASK 15---------------------------------------------------------------
   
   Out_mask(15)              <= s_parameters(173)(15  downto 0) & --detector A 
				s_parameters(174)(15  downto 0) & --detector B 
				s_parameters(175)(15  downto 0) & --detector C 
				s_parameters(176)(15  downto 0) & --detector D 
				s_parameters(177)(15  downto 0) & --detector E
				s_parameters(178)(15  downto 0) & --detector F
				s_parameters(179)(15  downto 0) ; --detector G

   
   Out_dontcare(15)          <= s_parameters(173)(31  downto 16) & --detector A 
				s_parameters(174)(31  downto 16) & --detector B 
				s_parameters(175)(31  downto 16) & --detector C 
				s_parameters(176)(31  downto 16) & --detector D 
				s_parameters(177)(31  downto 16) & --detector E
				s_parameters(178)(31  downto 16) & --detector F
				s_parameters(179)(31  downto 16) ; --detector G


   
end rtl;

