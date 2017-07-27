	component TemperatureSensor is
		port (
			ce         : in  std_logic                    := 'X'; -- ce
			clk        : in  std_logic                    := 'X'; -- clk
			clr        : in  std_logic                    := 'X'; -- reset
			tsdcaldone : out std_logic;                           -- tsdcaldone
			tsdcalo    : out std_logic_vector(7 downto 0)         -- tsdcalo
		);
	end component TemperatureSensor;

	u0 : component TemperatureSensor
		port map (
			ce         => CONNECTED_TO_ce,         --         ce.ce
			clk        => CONNECTED_TO_clk,        --        clk.clk
			clr        => CONNECTED_TO_clr,        --        clr.reset
			tsdcaldone => CONNECTED_TO_tsdcaldone, -- tsdcaldone.tsdcaldone
			tsdcalo    => CONNECTED_TO_tsdcalo     --    tsdcalo.tsdcalo
		);

