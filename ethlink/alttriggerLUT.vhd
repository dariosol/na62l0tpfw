library ieee;
use ieee.std_logic_1164.all;
use work.userlib.all;
use work.globals.all;
use ieee.numeric_std.all;

entity altTriggerLUT is
   port ( 
      
      --INPUTS
      clk                      : in std_logic;
      reset                    : in std_logic;
      --write enable
      wena                     : in std_logic;
      --mask
      mask                     : in mem;
      dontcare                 : in mem;
      control_detector_mask    : in std_logic_vector(111 downto 0);
      control_detector_dontcare: in std_logic_vector(111 downto 0);
      bit_finetime             : in std_logic_vector(2 downto 0);
      --enable
      enable_control_detector  : in std_logic;
      enable_mask              : in std_logic_vector(nmask-1 downto 0);
      --input detectors:
      detector                 : in vector16bit_t(0 to ethlink_NODES-2);
      primitiveID0                : in vector16bit_t(0 to ethlink_NODES-2);
      primitiveID1                : in vector16bit_t(0 to ethlink_NODES-2);
      primitiveID2                : in vector16bit_t(0 to ethlink_NODES-2);
      --time in
      timestamp_in             : in std_logic_vector(31 downto 0);
      finetime_ref_in          : in std_logic_vector(7 downto 0);         
      finetime_in0             : in vector8bit_t(0 to ethlink_NODES-2);
      finetime_in1             : in vector8bit_t(0 to ethlink_NODES-2);
      finetime_in2             : in vector8bit_t(0 to ethlink_NODES-2);
      control_detector         : in std_logic_vector(1 downto 0);
      --OUTPUTS
      --ready
      rdready                  : out std_logic;
      --time out
      timestamp_out            : out std_logic_vector(31 downto 0);
      finetime_out0            : out vector8bit_t(0 to ethlink_NODES-2);
      finetime_out1            : out vector8bit_t(0 to ethlink_NODES-2);
      finetime_out2            : out vector8bit_t(0 to ethlink_NODES-2);
      finetime_ref_out         : out std_logic_vector(7 downto 0);
      address_ref              : out std_logic_vector(32 downto 0);
      --triggerword
      triggerword              : out std_logic_vector(7 downto 0);
      --primitive ID
      primitiveID_t_out0       : out vector16bit_t(0 to ethlink_NODES-2);
      primitiveID_t_out1       : out vector16bit_t(0 to ethlink_NODES-2);
      primitiveID_t_out2       : out vector16bit_t(0 to ethlink_NODES-2);

      --which trigger has been satisfied
      n_of_trigger             : out std_logic_vector(nmask-1 downto 0);
      control_detector_out     : out std_logic_vector(1 downto 0)
      
      );
end altTriggerLUT;



architecture behavioral of altTriggerLUT is
   
   signal s_control_detector     : std_logic_vector(1 downto 0); -- from fifo
   signal s_control_detector_out : std_logic_vector(1 downto 0); --after mask selection
   signal s_timestamp            : std_logic_vector(31 downto 0);
   signal s_n_of_trigger         : std_logic_vector(nmask-1 downto 0);
   signal s_finetime_ref         : std_logic_vector(7 downto 0);
   
   signal s_finetime_out0        : vector8bit_t(0 to ethlink_NODES-2);
   signal s_finetime_out1        : vector8bit_t(0 to ethlink_NODES-2);
   signal s_finetime_out2        : vector8bit_t(0 to ethlink_NODES-2);
   signal s_primitiveID0         : vector16bit_t(0 to ethlink_NODES-2);
   signal s_primitiveID1         : vector16bit_t(0 to ethlink_NODES-2);
   signal s_primitiveID2         : vector16bit_t(0 to ethlink_NODES-2);
   
   
   signal s_decoding         : std_logic_vector(nmask-1 downto 0);
   
   signal current_state      : vector112bit_t(nmask-1 downto 0);
   signal current_state0     : vector112bit_t(nmask-1 downto 0);
   signal current_state1     : vector112bit_t(nmask-1 downto 0);
   signal current_state2     : vector112bit_t(nmask-1 downto 0);

   signal current_state_control      : std_logic_vector(111 downto 0);
   signal current_state0_control     : std_logic_vector(111 downto 0);
   signal current_state1_control     : std_logic_vector(111 downto 0);
   signal current_state2_control     : std_logic_vector(111 downto 0);

   
   signal s_control_primitiveID0: std_logic_vector(1 downto 0);
   signal s_control_primitiveID1: std_logic_vector(1 downto 0);
   signal s_control_primitiveID2: std_logic_vector(1 downto 0);
   
   signal s_timestamp0       : std_logic_vector(31 downto 0);
   signal s_timestamp1       : std_logic_vector(31 downto 0);
   signal s_timestamp2       : std_logic_vector(31 downto 0);
   
   signal s_finetime0        : vector8bit_t(0 to ethlink_NODES-2);
   signal s_finetime1        : vector8bit_t(0 to ethlink_NODES-2);
   signal s_finetime2        : vector8bit_t(0 to ethlink_NODES-2);
   
   signal s_finetime_ref0    : std_logic_vector(7 downto 0);
   signal s_finetime_ref1    : std_logic_vector(7 downto 0);
   signal s_finetime_ref2    : std_logic_vector(7 downto 0);

   signal s_primitiveID_t0   : vector16bit_t(0 to ethlink_NODES-2);
   signal s_primitiveID_t1   : vector16bit_t(0 to ethlink_NODES-2);
   signal s_primitiveID_t2   : vector16bit_t(0 to ethlink_NODES-2);
   
   signal s_wait0            : std_logic;
   signal s_wait1            : std_logic;
   signal s_wait2            : std_logic;
   signal s_outputenable     : std_logic;
   signal s_denom            : std_logic_vector(1 downto 0);

   signal s_address_ref      : std_logic_vector(32 downto 0); --reference
							      --detector ram address
   
   type FSM_t is (S0,S1,S2);
   signal FSM         : FSM_t;
   
begin

   process(clk,reset) 
   begin

----RESET STATUS-----------------------

      if reset ='1' then 
	 s_wait0                 <= '0';
	 s_wait1                 <= '0';
	 s_wait2                 <= '0';
	 s_control_primitiveID0  <= "00";
	 s_control_primitiveID1	 <= "00";
	 s_control_primitiveID2  <= "00";
	 
	 current_state_control  <= (others=>'0');
	 current_state0_control <= (others=>'0');
	 current_state1_control <= (others=>'0');
	 current_state2_control <= (others=>'0');	
	 
	 s_outputenable       <= '0';
	 s_finetime_ref0      <= (others=>'0');
	 s_finetime_ref1      <= (others=>'0');
	 s_finetime_ref2      <= (others=>'0');
	 s_timestamp0         <= (others=>'0');
	 s_timestamp1         <= (others=>'0');
	 s_timestamp2         <= (others=>'0');
	 s_address_ref        <= (others=>'0');
	 
	 for index in 0 to nmask-1 loop
	    current_state(index)    <= (others=>'0');
	    current_state0(index)   <= (others=>'0');
	    current_state1(index)   <= (others=>'0');
	    current_state2(index)   <= (others=>'0');	
	 end loop;
	 
	 for index in 0 to ethlink_NODES-2 loop 
	    s_primitiveID_t0(index) <= (others=>'0');
	    s_primitiveID_t1(index) <= (others=>'0');
	    s_primitiveID_t2(index) <= (others=>'0');
	    s_finetime0(index)      <= (others=>'0');
	    s_finetime1(index)      <= (others=>'0');
	    s_finetime2(index)      <= (others=>'0');
	    
	 end loop;
	 
	 
	 
      elsif rising_edge(clk) then 
	 
---------WRITING CONDITIONS	
	 if wena ='1' then
	    -----inputs:------------------------------------------
	    for index in 0 to nmask-1 loop
	       current_state0(index) <= Detector(0) & Detector(1) & Detector(2) & Detector(3) & Detector(4) & Detector(5) & Detector(6);
	    end loop;
	    
	    current_state0_control <= Detector(0) & Detector(1) & Detector(2) & Detector(3) & Detector(4) & Detector(5) & Detector(6);
	    s_control_primitiveID0 <= control_detector;
	    s_timestamp0           <= timestamp_in;
	    
	    s_finetime0            <= finetime_in0;
	    s_primitiveID0         <= primitiveID0;
	    s_finetime1            <= finetime_in1;
	    s_primitiveID1         <= primitiveID1;
	    s_finetime2            <= finetime_in2;
	    s_primitiveID2         <= primitiveID2;
	    
	    s_finetime_ref0        <= finetime_ref_in;
	    s_primitiveID_t0       <= primitiveID0;
	    s_primitiveID_t1       <= primitiveID1;
	    s_primitiveID_t2       <= primitiveID2;
	    s_wait0                <= '1';
	    

	    if(UINT(bit_finetime)=0) then
	       s_address_ref<= '0' & timestamp_in(31 downto 0);
 	    elsif(UINT(bit_finetime)=1) then
	       s_address_ref<= timestamp_in(31 downto 0) & finetime_ref_in(7);
	    elsif(UINT(bit_finetime)=2) then
	       s_address_ref<= timestamp_in(30 downto 0) & finetime_ref_in(7 downto 6);
           elsif(UINT(bit_finetime)=3) then
  	       s_address_ref<= timestamp_in(29 downto 0) & finetime_ref_in(7 downto 5);
	    end if;

	    
	    --------Shift ad ogni wrena-------------------------
	    
	    -----Shift 1---------------------------------
	    
	    for index in 0 to nmask-1 loop
	       current_state1(index) <= current_state0(index);
	    end loop;
	    
	    current_state1_control <= current_state0_control;
	    s_finetime1        <= finetime_in1      ;
	    s_timestamp1       <= timestamp_in      ;
	    s_finetime_ref1    <= finetime_ref_in   ;
	    s_Wait1            <= s_wait0           ;
	    s_control_primitiveID1 <= s_control_primitiveID0 ;

	    -----Shift 2---------------------------------
	    
	    for index in 0 to nmask-1 loop
	       current_state2(index) <= current_state1(index);
	    end loop;

	    current_state2_control <= current_state1_control;
	    s_wait2            <= s_wait1              ;
	    s_timestamp2       <= timestamp_in         ;
	    s_finetime_ref2    <= finetime_ref_in      ;
	    s_finetime2        <= finetime_in2         ;
	    s_control_primitiveID2 <= s_control_primitiveID1 ;

	    
	 else
	    
	    if s_outputenable ='1' then
	       s_outputenable <='0';
	    end if;

	    ---After 2 shifts, I send everything out and reset the registers.
	    if s_wait2 = '1' then 
	       s_wait0            <= '0';
	       s_wait1            <= '0';
	       s_wait2            <= '0';
	       s_outputenable     <= '1';
	       s_timestamp        <= s_timestamp2;
	       s_finetime_ref     <= s_finetime_ref2;
	       s_control_detector <= s_control_primitiveID2;
	       
	       s_finetime_out0    <= s_finetime0;
	       s_finetime_out1    <= s_finetime1;
	       s_finetime_out2    <= s_finetime2;
	       
	       

	       for index in 0 to ethlink_NODES-2 loop --FOR SU TUTTI I DETECTOR
		  
		  s_finetime0(index)      <=(others =>'0');
		  s_finetime1(index)      <=(others =>'0');
		  s_finetime2(index)      <=(others =>'0');
		  
	       end loop;
	       
	       for index in 0 to nmask-1 loop -- for su tutte le maschere
		  current_state0(index)   <=(others=>'0');
		  current_state1(index)   <=(others=>'0');
		  current_state2(index)   <=(others=>'0');
		  current_state(index)    <= current_state0(index) OR current_state1(index) OR current_state2(index);
	       end loop;
	       
	       current_state_control    <= current_state0_control OR current_state1_control OR current_state2_control;

	    else
	       s_outputenable<='0';
	       for index in 0 to nmask-1 loop
		  current_state(index) <= (others=>'0');
	       end loop;
	       
	       current_state_control <= (others=>'0');

	    end if; --wait=1
	    
	 end if; --end write enable
      end if; --reset
   end process;
   
   
   

-- PHYSICS OUTPUT	
   
   trigger_process : process (clk,reset)
   begin
      
      if reset =  '1' then
	 FSM<= S0;
	 
      elsif rising_edge(clk) then 

	 case FSM is
	    when S0 =>
	       if(s_outputenable = '1') then
		  
		  if ((current_state_control or control_detector_dontcare) = control_detector_mask) and enable_control_detector = '1' and s_control_detector(1)='1' then					
		     s_decoding(1)     <= '1';
		     s_control_detector_out(1) <='1';
		  end if;
		  
		  for index in 0 to nmask-1 loop
		     if ((current_state(index) or dontcare(index)) = mask(index)) and (enable_mask(index) = '1')  and s_control_detector(0)= '1' then
			s_decoding(index)         <= '1';
			s_n_of_trigger(index)     <= '1';  
			s_control_detector_out(0) <='1';
		     else
			s_n_of_trigger(index) <= '0'; 	
		     end if;	 
		  end loop; 	 
		  
		  FSM<=S1;		

	       else
		  FSM <= S0;
	       end if;

	    when S1 =>
	       for index in 0 to nmask-1 loop
		  s_n_of_trigger(index) <= '0';
		  s_decoding(index)     <= '0' ;
		  s_control_detector_out <="00";

	       end loop;
	       FSM <= S2;
	    when S2 => 
	       for index in 0 to nmask-1 loop
		  s_n_of_trigger(index) <= '0';
		  s_decoding(index)     <= '0' ;
		  s_control_detector_out <="00";
	       end loop;
	       FSM<=S0;
	 end case;
      end if;
   end process;



   
   process(clk,reset) 
   begin	 

      if reset ='1' then
	 triggerword <= (others=>'0');
	 rdready <='0';
	 timestamp_out   <=(others=>'0');
	 
      elsif rising_edge(clk) then
	 if s_decoding = SLV(0,16) then
	    triggerword          <= (others=>'0');
	    rdready              <='0';
	    timestamp_out        <=(others=>'0');
	    control_detector_out <=(others=>'0');
	 else
	    --	I need here something to encode triggerword in some format to
	    --	be defined.
	    triggerword           <= "00000001"; -- All the triggers form
						 -- physics have triggerword 1
	    rdready               <= '1';
	    timestamp_out         <= s_timestamp;
	    address_ref           <= s_address_ref;
	    finetime_out0         <= s_finetime_out0;
	    finetime_out1         <= s_finetime_out1;
	    finetime_out2         <= s_finetime_out2;
	    finetime_ref_out      <= s_finetime_ref;
	    primitiveID_t_out0    <= s_primitiveID_t0;
	    primitiveID_t_out1    <= s_primitiveID_t1;
	    primitiveID_t_out2    <= s_primitiveID_t2;
	    control_detector_out  <= s_control_detector_out;
	    n_of_trigger          <= s_n_of_trigger ; 
	 end if;
      end if;
   end process;


end architecture behavioral;



