library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;
use work.userlib.all;

---Syncronizer for clock 40 MHz
--From 40 MHz to 125 MHz

entity NIMInterface is
   port(
      reset               : in std_logic;
      CalibNimIn          : in std_logic;  -- 40 MHz
      clkB                : in std_logic;  -- 125 MHz
      CAlibnimOut         : out std_logic; -- 125 MHz
      -------
      activateCalib       : in std_logic;
      BURST               : in STD_LOGIC
      
      );
end entity;

architecture rtl of NIMInterface is

   signal tstmpcounter : integer;
 
   type FSMnim is (S0,S1); 
   signal  state : FSMnim;
   signal s_calibNimOut :   std_logic;
   
begin
   
  
   
  --Calibration for the LKr 
   process(clkB,reset)
   begin
      if(reset='1')then
	 tstmpcounter <=0;
	 state <= S0;
	 s_CalibnimOut <='0';
      elsif(clkb='1' and clkb'event)  then
	 case state is
	    when S0 =>
	       if activateCalib ='1' and BURST = '1' then
		  if CalibNimIn = '1' then
		     s_CalibNimOut<='1';
		     state <=S1;
		  else
		     s_CalibnimOut <='0';
		     state <=S0;
		  end if;
	       else 
		  state <=S0;
	       end if;	 
	    when S1 =>
	       s_CalibNimOut<='0';
	       if tstmpcounter = 15 then --1.9 us
		  tstmpcounter <= 0;
		  state <=S0;
	       else
		  tstmpcounter <= tstmpcounter +1;
		  state <=S1;
	       end if;
	 end case;
      end if;
   end process;
   CalibnimOut            <= s_calibNimOut;  
end RTL;
