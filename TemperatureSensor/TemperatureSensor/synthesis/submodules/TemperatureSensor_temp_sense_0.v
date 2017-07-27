//alttemp_sense CBX_AUTO_BLACKBOX="ALL" CBX_SINGLE_OUTPUT_FILE="ON" CLK_FREQUENCY="40.0" CLOCK_DIVIDER_ENABLE="on" CLOCK_DIVIDER_VALUE=80 DEVICE_FAMILY="Stratix IV" NUMBER_OF_SAMPLES=128 POI_CAL_TEMPERATURE=85 SIM_TSDCALO=0 USE_WYS="on" USER_OFFSET_ENABLE="off" ce clk clr tsdcaldone tsdcalo ALTERA_INTERNAL_OPTIONS=SUPPRESS_DA_RULE_INTERNAL=C106
//VERSION_BEGIN 14.1 cbx_alttemp_sense 2014:12:03:18:16:05:SJ cbx_cycloneii 2014:12:03:18:16:05:SJ cbx_lpm_add_sub 2014:12:03:18:16:05:SJ cbx_lpm_compare 2014:12:03:18:16:05:SJ cbx_lpm_counter 2014:12:03:18:16:05:SJ cbx_lpm_decode 2014:12:03:18:16:05:SJ cbx_mgl 2014:12:03:20:51:57:SJ cbx_nightfury 2014:12:03:18:16:04:SJ cbx_stratix 2014:12:03:18:16:05:SJ cbx_stratixii 2014:12:03:18:16:05:SJ cbx_stratixiii 2014:12:03:18:16:05:SJ cbx_stratixv 2014:12:03:18:16:05:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 1991-2014 Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus II License Agreement,
//  the Altera MegaCore Function License Agreement, or other 
//  applicable license agreement, including, without limitation, 
//  that your use is for the sole purpose of programming logic 
//  devices manufactured by Altera and sold by Altera or its 
//  authorized distributors.  Please refer to the applicable 
//  agreement for further details.



//synthesis_resources = stratixiv_tsdblock 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"SUPPRESS_DA_RULE_INTERNAL=C106"} *)
module  TemperatureSensor_temp_sense_0
	( 
	ce,
	clk,
	clr,
	tsdcaldone,
	tsdcalo) /* synthesis synthesis_clearbox=1 */;
	input   ce;
	input   clk;
	input   clr;
	output   tsdcaldone;
	output   [7:0]  tsdcalo;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1   ce;
	tri0   clr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire  wire_sd1_tsdcaldone;
	wire  [7:0]   wire_sd1_tsdcalo;

	stratixiv_tsdblock   sd1
	( 
	.ce(ce),
	.clk(clk),
	.clr(clr),
	.offsetout(),
	.tsdcaldone(wire_sd1_tsdcaldone),
	.tsdcalo(wire_sd1_tsdcalo),
	.tsdcompout()
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.compouttest(1'b0),
	.fdbkctrlfromcore(1'b0),
	.offset({6{1'b0}}),
	.testin({8{1'b0}})
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	);
	defparam
		sd1.clock_divider_enable = "on",
		sd1.clock_divider_value = 80,
		sd1.sim_tsdcalo = 0,
		sd1.lpm_type = "stratixiv_tsdblock";
	assign
		tsdcaldone = wire_sd1_tsdcaldone,
		tsdcalo = wire_sd1_tsdcalo;
endmodule //TemperatureSensor_temp_sense_0
//VALID FILE
