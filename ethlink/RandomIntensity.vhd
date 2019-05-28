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
    clk125              : in std_logic;
    received_signal     : in std_logic;
    received_packet     : in std_logic;
    time_stamp          : in std_logic_vector(29 downto 0);
    internal_time_stamp : in std_logic_vector(29 downto 0);
    
    trigger             : out std_logic;
    posttrigger         : out std_logic
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
  s_time_stamp     <=  time_stamp;
  s_internal_time  <=  internal_time_stamp;

  FIFOTstsmp_inst : altFIFOtstmp port map (
    aclr	       => s_aclr           , 
    data	       => s_time_stamp_data,  
    rdclk	       => clk125           ,
    rdreq	       => s_rdreq          ,   -- questo è 1 quando voglio togliere un dato
    wrclk	       => clk125           ,
    wrreq	       => s_wrreq          ,   -- quando vuole scrivere questo è 1, ma solo per un colpo di clock

    q		         => timerit          ,   -- questa è l'uscita
    rdempty      => s_rdempty        ,
    rdfull       => s_rdfull         ,
    rdusedw      => s_rdusedw        ,
    wrempty      => s_wrempty        ,   -- se questo è 0 non è vuota allora leggo
    wrfull       => s_wrfull         ,
    wrusedw      => s_wrusedw
    );

  
  EventCounter : process(clk125, BURST125)
    variable dato : integer range 0 to 10000000;
    
  begin
    --Parte iniziale, se non c'è il BURST non accade nulla
    if (BURST125 = '0') then
      s_time_stamp_data <= (OTHERS => '0');
      s_wrreq           <= '0';
      s_trigger         <= '0';
      s_aclr            <= '1'; 
      s_rdreq           <= '0';
      dato              :=  0 ;

    elsif (clk125'EVENT) then
      s_aclr            <= '0';

      --Sezione comparatore e lettore
      if (SLV(UINT(timerit) + 109,30) = internal_time_stamp ) and (UINT(internal_time_stamp) > 10 ) then
        s_posttrigger <= '1';
        s_rdreq        <= '1';
      else
        s_posttrigger <= '0';
        s_rdreq        <= '0';
      end if;
      --fine sezione comparatore e lettore

      if (clk125 = '1') then
        
        --inizio contatore e scrittore
        if (received_signal = '1') then
          dato := dato +1;
        end if;
        if (dato = 10) then
          s_trigger     <= '1';
          s_wrreq       <= '1';
          dato          :=  0 ;
          s_time_stamp_data <= s_time_stamp;
          --s_time_stamp_data <= s_internal_time;   
        else
          s_trigger     <= '0';
          s_wrreq       <= '0';      
          s_time_stamp_data <= (OTHERS => '0');
        end if;
      --fine contatore e scrittore
      end if;

    else 
      s_trigger         <= '0';
      s_time_stamp_data <= (OTHERS => '0');
      
    end if;  
  end process;
  trigger <= s_trigger;
  posttrigger <= s_posttrigger;
end rtl; 
