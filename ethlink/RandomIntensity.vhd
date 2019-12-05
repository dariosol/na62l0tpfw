library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_BIT.all;
use work.userlib.all;
use work.GLOBALS.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity RandomIntensityTrigger is
  port (
    BURST125            : in std_logic;
    reset               : in std_logic;
    clk125              : in std_logic;
    received_signal     : in std_logic;
    received_packet     : in std_logic;
    activaterandomintensitytrigger : in std_logic;
    
    time_stamp          : in std_logic_vector(29 downto 0);
    internal_time_stamp : in std_logic_vector(29 downto 0);
    nprimitiveforrandom : in std_logic_vector(31 downto 0);    
    trigger             : out std_logic;
    posttrigger         : out std_logic;
    errorfifo           : out std_logic_vector(4 downto 0)
    );

end RandomIntensityTrigger;

Architecture rtl of RandomIntensityTrigger is
  signal timerit : std_logic_vector(29 downto 0);
  signal s_time_stamp_data : std_logic_vector(29 downto 0);
  signal s_rdreq : std_logic;
  signal s_wrreq : std_logic;
  signal s_rdempty : std_logic;
  signal s_rdfull  : std_logic;
  signal s_rdusedw : std_logic_vector(4 downto 0);
  signal s_wrempty : std_logic;
  signal s_wrfull  : std_logic;
  signal s_wrusedw : std_logic_vector(4 downto 0);
  signal s_aclr    : std_logic;

  signal s_trigger : std_logic;
  signal s_posttrigger : std_logic;
  signal s_time_stamp : std_logic_vector(29 downto 0);
  signal s_internal_time : std_logic_vector(29 downto 0);
  signal s_dato     : std_logic_vector(31 downto 0);
  signal s_received_signal : std_logic;
  signal s_received_packet : std_logic;

  signal s_check  : std_logic;
  signal s_activaterandomintensitytrigger : std_logic;
  signal s_BURST125 : std_logic;
  signal s_errorfifo : std_logic_vector(4 downto 0);
  
  component altFIFOtstmp IS 
    port
      (
        aclr		: IN STD_LOGIC  := '0';
        data		: IN STD_LOGIC_VECTOR (29 DOWNTO 0);
        rdclk		: IN STD_LOGIC ;
        rdreq		: IN STD_LOGIC ;
        wrclk		: IN STD_LOGIC ;
        wrreq		: IN STD_LOGIC ;
        
        q		      : OUT STD_LOGIC_VECTOR (29 DOWNTO 0);
        rdempty		: OUT STD_LOGIC ;
        rdfull		: OUT STD_LOGIC ;
        rdusedw		: OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
        wrempty		: OUT STD_LOGIC ;
        wrfull		: OUT STD_LOGIC ;
        wrusedw		: OUT STD_LOGIC_VECTOR (4 DOWNTO 0)
        );	  
  end component;
  
begin
  s_time_stamp      <=  time_stamp;
  s_internal_time   <=  internal_time_stamp;
  s_received_signal <=  received_signal;
  s_received_packet <=  received_packet;
  s_activaterandomintensitytrigger <= activaterandomintensitytrigger;
  s_BURST125        <= BURST125;
  
  FIFOTstsmp_inst : altFIFOtstmp port map (
    aclr	       => s_aclr           , 
    data	       => s_time_stamp_data,  
    rdclk	       => clk125           ,
    rdreq	       => s_rdreq          ,   -- questo è 1 quando voglio togliere un dato
    wrclk	       => clk125           ,
    wrreq	       => s_wrreq          ,   -- quando vuole scrivere questo è 1, ma solo per un colpo di clock

    q		       => timerit          ,   -- questa è l'uscita
    rdempty            => s_rdempty        ,
    rdfull             => s_rdfull         ,
    rdusedw            => s_rdusedw        ,
    wrempty            => s_wrempty        ,   -- se questo è 0 non è vuota allora leggo
    wrfull             => s_wrfull         ,
    wrusedw            => s_wrusedw
    );

  
  EventCounter : process(reset, clk125)
    variable dato  : integer range 0 to 10000000;
    variable check : integer range 0 to 1;
    
  begin
    --Parte iniziale, se non c'è il BURST non accade nulla
    if (reset = '1') then
      s_time_stamp_data <= (OTHERS => '0');
      s_wrreq           <= '0';
      s_trigger         <= '0';
      s_aclr            <= '1'; 
      s_rdreq           <= '0';
      --s_dato            <=  (others => '0') ;
      dato := 0;
      s_errorfifo <= (others => '0');
      
    elsif rising_edge(clk125)  then

      if(s_BURST125='0') then --when burst is 0 I reset counters
        s_aclr            <= '0';
        s_time_stamp_data <= (OTHERS => '0');
        s_wrreq           <= '0';
        s_trigger         <= '0';
        s_aclr            <= '1'; 
        s_rdreq           <= '0';
        --s_dato            <=  (others => '0') ;
        dato := 0;
        s_errorfifo <= (others => '0');
      elsif (s_BURST125 = '1' and s_activaterandomintensitytrigger = '1' ) then-- I am in burst:
        s_aclr            <= '0';
        s_errorfifo <= (others => '0');
      --Sezione comparatore e lettore
        if (SLV(UINT(timerit) + 2772,30) = s_internal_time ) and (UINT(s_internal_time) > 2773 ) and (check = 0) then-- 2772 = 69.3 us
          s_posttrigger  <= '1';
          s_rdreq        <= '1';
          check          :=  1 ;
        else
          s_posttrigger  <= '0';
          s_rdreq        <= '0';
          check          :=  0 ;
        end if;  -- end comparison
        
     
        if (s_received_signal = '1') then  --start counting
         -- s_dato <= SLV(UINT(s_dato) + 1 , 32);
          dato := dato + 1;
        end if;

      --s_time_stamp_data <= s_time_stamp;
      
        --if (UINT(s_dato) = 10) then
        
        --TO BE PASSED THROUGH USB
      if (dato = UINT(nprimitiveforrandom)) and (s_wrfull='0') then
          s_trigger      <= '1';
          s_wrreq        <= '1';
          s_time_stamp_data <= s_time_stamp;
          dato := 0;
          s_errorfifo <= (others => '0');
      elsif (s_wrfull='1') then
        s_errorfifo <= "10000";
          
        else
          s_trigger     <= '0';
          s_wrreq       <= '0';      
          s_time_stamp_data <= (OTHERS => '0');
        end if;
      --fine contatore e scrittore
      
      end if; -- end burst
      end if; --end reset/clock
  end process;
  trigger     <= s_trigger;
  posttrigger <= s_posttrigger;
  errorfifo   <= s_errorfifo;
end rtl; 
