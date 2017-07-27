library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.globals.all;
use work.userlib.all;

entity generator is
    
port (
      clk                   : in std_logic;
      activaterandomtrigger : in std_logic;
      randomtime            : in std_logic_vector(31 downto 0);
      randomstarttime       : in std_logic_vector(31 downto 0);
      randomendtime         : in std_logic_vector(31 downto 0);
      internal_timestamp    : in std_logic_vector(31 downto 0);
      random_triggerword_in : in std_logic_vector(5 downto 0);		
      random_signal         : out std_logic;
      random_triggerword_out: out std_logic_vector(5 downto 0)
    );
end generator;

architecture Behavioral of generator is
  signal s_enable                : std_logic;
  signal s_counter               : std_logic_vector(31 downto 0);
  signal s_randomtime            : std_logic_vector(31 downto 0);
  signal s_randomstarttime       : std_logic_vector(31 downto 0);
  signal s_randomendtime         : std_logic_vector(31 downto 0);
  signal s_activaterandomtrigger : std_logic;  
  signal s_triggerword           : std_logic_vector(5 downto 0);
  signal s_random_signal         : std_logic;
  signal s_random : std_logic_vector(11 downto 0);
  
 component random_gaussian is
 Port ( clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        random : out  STD_LOGIC_VECTOR (11 downto 0)
         );
end component;
 
 
begin
  
  random_gaussian_inst : random_gaussian port map (
  clk => clk,
  reset => '0',
  random => s_random
  );
  
  
  s_randomendtime         <= randomendtime;
  s_randomstarttime       <= randomstarttime;
  s_randomtime            <= randomtime;
  s_activaterandomtrigger <= activaterandomtrigger;
  s_triggerword           <= random_triggerword_in;
  
P1: PROCESS(clk)
begin
 if(clk='1' and clk'event)  then
     if s_activaterandomtrigger ='1' and UINT(internal_timestamp) > UINT(s_randomstarttime) and UINT(internal_timestamp) < UINT(s_randomendtime) then 
     	    if s_counter = SLV(UINT(s_randomtime)-1,32) then
	        s_counter <=(others=>'0');
	        s_enable <='1';
	     else
	        s_counter <= SLV(UINT(s_counter)+1,32);
	        s_enable <='0';
	     end if;
       else
       s_counter <=(others=>'0');
       s_enable <='0';
     end if;
 end if;
end process;
  

P2: PROCESS(clk)
begin
  if(clk='1' and clk'event)  then
    if(s_enable ='1') then
       if(s_random(0)='1') then
          s_random_signal <='1';
       else 
          s_random_signal <='0';
        end if;
    else
     s_random_signal <='0';
    end if;
  end if;
end process;
random_signal <= s_random_signal;
random_triggerword_out <= s_triggerword;
end behavioral;
