LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE work.globals.all;
USE work.userlib.all;



entity shift_register_gonnella is
  port(
    reset   : in std_logic;
    clk     : in std_logic;
    delay   : in std_logic_vector(31 downto 0);
    shiftin : in std_logic_vector(4 downto 0);
    shiftout: out std_logic_vector(4 downto 0)
);
end entity;



architecture behavior of shift_register_gonnella is
  type taps_t is array(NATURAL RANGE <>) of std_logic_vector(4 downto 0);
 signal taps  : taps_t(0 to 450);
begin
  process(reset,clk)
    begin
      if reset ='1' then
        taps <=(others =>"00000");
      elsif rising_edge(clk) then
           taps(0) <= shiftin;
        for index in 0 to 449 loop
          taps(index+1) <=taps(index);
        end loop;
    end if;
  end process;
  
  
  shiftout <= taps(UINT(delay));

  
  
end behavior;
      
      
      
      
