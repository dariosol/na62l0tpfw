
module TemperatureSensor (
	ce,
	clk,
	clr,
	tsdcaldone,
	tsdcalo);	

	input		ce;
	input		clk;
	input		clr;
	output		tsdcaldone;
	output	[7:0]	tsdcalo;
endmodule
