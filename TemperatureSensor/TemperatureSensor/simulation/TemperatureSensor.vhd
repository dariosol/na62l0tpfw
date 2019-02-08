-- TemperatureSensor.vhd

-- Generated using ACDS version 16.1 196

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TemperatureSensor is
	port (
		ce         : in  std_logic                    := '0'; --         ce.ce
		clk        : in  std_logic                    := '0'; --        clk.clk
		clr        : in  std_logic                    := '0'; --        clr.reset
		tsdcaldone : out std_logic;                           -- tsdcaldone.tsdcaldone
		tsdcalo    : out std_logic_vector(7 downto 0)         --    tsdcalo.tsdcalo
	);
end entity TemperatureSensor;

architecture rtl of TemperatureSensor is
	component altera_temp_sense is
		port (
			clk        : in  std_logic                    := 'X'; -- clk
			tsdcalo    : out std_logic_vector(7 downto 0);        -- tsdcalo
			tsdcaldone : out std_logic;                           -- tsdcaldone
			ce         : in  std_logic                    := 'X'; -- ce
			clr        : in  std_logic                    := 'X'  -- reset
		);
	end component altera_temp_sense;

begin

	temp_sense_0 : component altera_temp_sense
		port map (
			clk        => clk,        --        clk.clk
			tsdcalo    => tsdcalo,    --    tsdcalo.tsdcalo
			tsdcaldone => tsdcaldone, -- tsdcaldone.tsdcaldone
			ce         => ce,         --         ce.ce
			clr        => clr         --        clr.reset
		);

end architecture rtl; -- of TemperatureSensor
