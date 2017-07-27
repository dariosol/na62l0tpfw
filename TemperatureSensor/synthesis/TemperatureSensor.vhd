-- TemperatureSensor.vhd

-- Generated using ACDS version 14.1 186 at 2017.01.25.14:54:48

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TemperatureSensor is
	port (
		clk        : in  std_logic                    := '0'; --        clk.clk
		tsdcaldone : out std_logic;                           -- tsdcaldone.tsdcaldone
		tsdcalo    : out std_logic_vector(7 downto 0)         --    tsdcalo.tsdcalo
	);
end entity TemperatureSensor;

architecture rtl of TemperatureSensor is
	component TemperatureSensor_temp_sense_0 is
		port (
			clk        : in  std_logic                    := 'X'; -- clk
			tsdcalo    : out std_logic_vector(7 downto 0);        -- tsdcalo
			tsdcaldone : out std_logic                            -- tsdcaldone
		);
	end component TemperatureSensor_temp_sense_0;

begin

	temp_sense_0 : component TemperatureSensor_temp_sense_0
		port map (
			clk        => clk,        --        clk.clk
			tsdcalo    => tsdcalo,    --    tsdcalo.tsdcalo
			tsdcaldone => tsdcaldone  -- tsdcaldone.tsdcaldone
		);

end architecture rtl; -- of TemperatureSensor
