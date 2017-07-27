// usb_portmux_iface.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module portmux_export 
	(
		input  wire        s_we,        //             slave.write
		input  wire        s_re,        //                  .read
		input  wire [31:0] s_writedata, //                  .writedata
		output wire [31:0] s_readdata,  //                  .readdata
		input  wire [3:0]  s_address,   //                  .address
		input  wire        s_clk,       //       clock_reset.clk
		input  wire        s_reset_n,    // clock_reset_reset.reset_n
		
		output wire			 m_we,
		output wire			 m_re,
		output wire [31:0] m_writedata,
		input  wire [31:0] m_readdata,
		output wire        m_reset_n,
        output wire [3:0]  m_address
	);

	assign m_we = s_we;
	assign m_re = s_re;
	assign m_writedata = s_writedata;
	assign s_readdata = m_readdata;
	assign m_reset_n = s_reset_n;
    assign m_address = s_address;

endmodule
