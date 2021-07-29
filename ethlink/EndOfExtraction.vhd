library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;
use work.userlib.all;

--End of extraction signal:
--Needed to terminate primitive triggers before
--LKr calibrations
entity EndOfExtraction is
   port(
      reset               : in std_logic;
      EE                  : in std_logic;  -- 40 MHz
      clkB                : in std_logic;  -- 125 MHz
      EEout               : out std_logic; -- 125 MHz
      -------
      BURST               : in STD_LOGIC
      
      );
end entity;

architecture rtl of EndOfExtraction is

 
   type FSMnim is (S0,S1); 
   signal  state : FSMnim;
   signal s_EEout :   std_logic;
   
begin
   
  
   
  --End Of extraction
   process(clkB,reset,EE,BURST)
   begin
      if(reset='1')then
	 state <= S0;
	 s_EEout <='0';
      elsif(clkb='1' and clkb'event)  then
	 case state is
	    when S0 =>
	       if BURST = '1' then
		  if EE = '1' then
		     s_EEout <= '1';
		     state <=S1;
		  else
		     s_EEout <='0';
		     state <=S0;
		  end if;
	       else 
		  state <=S0;
	       end if;
               
           when S1 =>
              if BURST = '0' then
                s_EEout <='0';     
                state <=S0;
	       else
		s_EEout <='1';     
		state <=S1;
	       end if;
	 end case;
      end if;
   end process;
   EEout            <= s_EEout;  
end RTL;
