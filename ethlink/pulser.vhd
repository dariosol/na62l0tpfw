library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use IEEE.NUMERIC_BIT.all;
use work.globals.all;
use work.userlib.all;

entity pulser is
   port (
      BURST125                     : in std_logic;
      clk125                       : in std_logic; --40 MHZ FROM LTU
      activateperiodictrigger0     : in std_logic;
      periodicstarttime0           : in std_logic_vector(31 downto 0);
      periodicendtime0             : in std_logic_vector(31 downto 0);
      periodictime0                : in std_logic_vector(31 downto 0);
      periodic_triggerword0_in     : in std_logic_vector(5 downto 0);
      periodic_triggerword1_in     : in std_logic_vector(5 downto 0);
      activateperiodictrigger1     : in std_logic;
      periodicstarttime1           : in std_logic_vector(31 downto 0);
      periodicendtime1             : in std_logic_vector(31 downto 0);
      periodictime1                : in std_logic_vector(31 downto 0);
      internal_timestamp           : in std_logic_vector(31 downto 0);
      
      periodic_signal0             : out std_logic;
      periodic_signal1             : out std_logic;
      periodic_triggerword0_out    : out std_logic_vector(5 downto 0);
      periodic_triggerword1_out    : out std_logic_vector(5 downto 0)
      
      );
end entity;	


architecture rtl of pulser is

   signal s_periodicstarttime0         : std_logic_vector(31 downto 0);
   signal s_periodicendtime0           : std_logic_vector(31 downto 0);
   signal s_periodictime0              : std_logic_vector(31 downto 0);
   signal s_activateperiodictrigger0   : std_logic;
   signal s_BURST125                   : std_logic_vector(31 downto 0);
   signal s_periodiccounter0           : std_logic_vector(31 downto 0);
   signal s_triggerword0               : std_logic_vector(5 downto 0);
   signal s_periodic_signal0           : std_logic;

   signal s_triggerword1               : std_logic_vector(5 downto 0);
   signal s_periodicstarttime1         : std_logic_vector(31 downto 0);
   signal s_periodicendtime1           : std_logic_vector(31 downto 0);
   signal s_periodictime1              : std_logic_vector(31 downto 0);
   signal s_activateperiodictrigger1   : std_logic;
   signal s_periodiccounter1           : std_logic_vector(31 downto 0);
   signal s_periodic_signal1           : std_logic;



begin

   s_BURST125                 <= s_BURST125;

   s_periodicendtime0         <= periodicendtime0;
   s_periodicstarttime0       <= periodicstarttime0;
   s_periodictime0            <= periodictime0;
   s_activateperiodictrigger0 <= activateperiodictrigger0;

   s_periodicendtime1         <= periodicendtime1;
   s_periodicstarttime1       <= periodicstarttime1;
   s_periodictime1            <= periodictime1;
   s_activateperiodictrigger1 <= activateperiodictrigger1;



   P1: PROCESS(s_BURST125,clk125,s_activateperiodictrigger0)
   begin
      if(clk125='1' and clk125'event)  then
	 if BURST125 ='1' then --FROM USB
	    if s_activateperiodictrigger0 ='1' and UINT(internal_timestamp) > UINT(s_periodicstarttime0) and UINT(internal_timestamp) < UINT(s_periodicendtime0) then 
	       if s_periodiccounter0 = SLV(UINT(s_periodictime0)-1,32) then
		  s_periodiccounter0 <=(others=>'0');
	          s_periodic_signal0 <='1';
		  s_triggerword0     <= periodic_triggerword0_in;

	       else
		  s_periodiccounter0 <= SLV(UINT(s_periodiccounter0)+1,32);
		  s_triggerword0     <= (others=>'0');				 
		  s_periodic_signal0 <='0';
	       end if;
	    else
	       s_periodiccounter0 <=(others=>'0');
	       s_periodic_signal0 <='0';
	    end if;
	    
	 else
	    s_periodiccounter0 <= SLV(UINT(s_periodiccounter0)+1,32);
	    s_periodic_signal0 <='0';
	    s_triggerword0     <= (others=>'0');				 
	 end if;
      end if;
   end process;



   P2: PROCESS(s_BURST125,clk125,s_activateperiodictrigger1)
   begin
      if(clk125='1' and clk125'event)  then
	 if BURST125 ='1' then --FROM USB
	    if s_activateperiodictrigger1 ='1' and UINT(internal_timestamp) > UINT(s_periodicstarttime1) and UINT(internal_timestamp) < UINT(s_periodicendtime1) then 
	       if s_periodiccounter1 = SLV(UINT(s_periodictime1)-1,32) then
		  s_periodiccounter1 <=(others=>'0');
	          s_periodic_signal1 <='1';
		  s_triggerword1 <= periodic_triggerword1_in;
	       else
		  s_periodiccounter1 <= SLV(UINT(s_periodiccounter1)+1,32);
		  s_periodic_signal1 <='0';
		  s_triggerword1 <=(others=>'0');
	       end if;
	    else
	       s_periodiccounter1 <=(others=>'0');
	       s_periodic_signal1 <='0';
	       s_triggerword1 <=(others=>'0');
	    end if;
	    
	 else
	    s_periodiccounter1 <= SLV(UINT(s_periodiccounter1)+1,32);
	    s_periodic_signal1 <='0';
	 end if;
      end if;
   end process;



   periodic_signal0 <= s_periodic_signal0;
   periodic_signal1 <= s_periodic_signal1;
   periodic_triggerword0_out <= s_triggerword0;
   periodic_triggerword1_out <= s_triggerword1;

end rtl;
