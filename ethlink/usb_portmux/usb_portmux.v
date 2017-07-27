// Talk to an input port on the user circuit that is WIDTH bits wide

module sys_to_fpga #
(
	parameter	WIDTH = 32
)
(
	input			clk,
	input			shift_load_en,
	input			shift_en,
	input			sel,
	input	[31:0]	mux_data,
	output	[WIDTH-1:0]	user_data
);

localparam WIDTH_PAD32 = (WIDTH + 31) & (~31);
localparam WIDTH_PAD8 = (WIDTH + 7) & (~7);

localparam SHIFTREG_WIDTH = WIDTH_PAD32;
localparam SHIFT_AMOUNT = (WIDTH > 16) ? 32 : WIDTH_PAD8;

	reg [SHIFTREG_WIDTH-1:0] shiftreg;

generate
if (SHIFT_AMOUNT < SHIFTREG_WIDTH) begin : shifter

	// This version handles port widths that are not 32 bits wide.
	// One or more 32 bit words is taken from the FIFO that comes
	// from the NIOS CPU (which got it from the USB cable) and put into
	// the most significant bits of the shift register.  The shift
	// register will shift by SHIFT_AMOUNT to move the data towards
	// the least significant bits, where it will be fed to the user circuit.

	// Port widths of 16 bits or less are rounded up to the next byte.
	// Wider port widths are rounded up to the next 32 bit word.

	always @ (posedge clk) begin
		if (sel) begin

			// Note that the shift must come before the load, so that the load
			// takes precedence.  This matters when the port is <= 16 bits wide
			// as the shift data will be useless if we are trying to load new data.

			if (shift_en)
				shiftreg[SHIFTREG_WIDTH-1-SHIFT_AMOUNT : 0] <= shiftreg[SHIFTREG_WIDTH-1 : SHIFT_AMOUNT];

			if (shift_load_en)
				shiftreg[SHIFTREG_WIDTH-1 : SHIFTREG_WIDTH-32] <= mux_data;
		end
	end
end
else begin : noshifting

	// This version handles ports that are 32 bits wide.
	// A 32 bit word is taken from the FIFO from the CPU,
	// and stored in the shift register.  Shifting isn't necessary,
	// as the shift register is then fed directly to the 32 bit
	// wide FIFO.

	always @ (posedge clk) begin
		if (sel) begin
			if (shift_load_en)
				shiftreg[SHIFTREG_WIDTH-1 : SHIFTREG_WIDTH-32] <= mux_data;
		end
	end
end
endgenerate

	// The least significant bits of the shift register go to the circuit
	
	assign user_data = shiftreg[WIDTH-1 : 0];

endmodule



// Talk to an output port on the user circuit that is WIDTH bits wide

module fpga_to_sys #
(
	parameter	WIDTH = 32
)
(
	input			clk,
	input			shift_en,
	input			shift_load_en,
	input			sel,	
	output	[31:0]	mux_data,
	input	[WIDTH-1:0]	user_data
);

localparam WIDTH_PAD32 = (WIDTH + 31) & (~31);
localparam WIDTH_PAD8 = (WIDTH + 7) & (~7);
localparam WIDTH_PAD = (WIDTH > 16) ? WIDTH_PAD32 : WIDTH_PAD8;

localparam SHIFTREG_WIDTH = WIDTH_PAD32;
localparam SHIFT_AMOUNT = (WIDTH > 16) ? 32 : WIDTH_PAD8;

	reg [SHIFTREG_WIDTH-1:0] shiftreg;
	
generate
if (SHIFT_AMOUNT < SHIFTREG_WIDTH) begin : shifter

	// This version handles port widths that are not 32 bits wide.
	// One or more values are taken from the user circuit and put into
	// the most significant bits of the shift register.  The shift
	// register will shift by SHIFT_AMOUNT to move the data towards
	// the least significant bits, where it will be fed to the FIFO
	// that goes to the NIOS CPU (and hence to the USB cable)

	// Port widths of 16 bits or less are rounded up to the next byte.
	// Wider port widths are rounded up to the next 32 bit word.

	always @ (posedge clk) begin
		if (sel) begin

			// Note that the shift must come before the load, so that the load
			// takes precedence.

			if (shift_en)
				shiftreg[SHIFTREG_WIDTH-1-SHIFT_AMOUNT : 0] <= shiftreg[SHIFTREG_WIDTH-1 : SHIFT_AMOUNT];

			if (shift_load_en)
				shiftreg[SHIFTREG_WIDTH-1 : SHIFTREG_WIDTH-WIDTH_PAD] <= user_data;
		end
	end
end
else begin : noshifting

	// This version handles ports that are 32 bits wide.
	// A 32 bit word is taken from circuit port
	// and stored in the shift register.  Shifting isn't necessary,
	// as the shift register is then fed directly to the 32 bit
	// wide FIFO.

	always @ (posedge clk) begin
		if (sel) begin
			if (shift_load_en)
				shiftreg[SHIFTREG_WIDTH-1 : SHIFTREG_WIDTH-WIDTH_PAD] <= user_data;
		end
	end
end
endgenerate

	// The least significant 32 bits of the shift register go to the FIFO
	// that leads to the NIOS CPU (and hence to the USB cable).
	
	assign mux_data = shiftreg[31:0];

endmodule






module usb_portmux
(
	input 							OSC1_50,
	input							clk,
	input 							reset_n,
	
	// DE3 USB interface
	inout     	[31:0]	  	OTG_D,
	output    	[17:1]	  	OTG_A,
	output		    		OTG_CS_n,
	output		    		OTG_WE_n,
	output		    		OTG_OE_n,
	input		     		OTG_HC_IRQ,
	input		     		OTG_DC_IRQ,
	output		    		OTG_RESET_n,
	input		     		OTG_HC_DREQ,
	output		    		OTG_HC_DACK,
	input		     		OTG_DC_DREQ,
	output		    		OTG_DC_DACK,

	// User signals
	output	[31:0]	number_of_triggers,
	input	[31:0]	status,
	input	[31:0]	status125,
	output	[31:0]	data_in
);

// Number of ports
localparam NUM_PORTS = 4;


// SOPC system
wire s_reset_n;
wire [3:0]	s_address;
wire s_we;
wire s_re;
wire [31:0]	s_writedata;
reg	[31:0]	s_readdata;

usb_control usb_ctrl (
	.reset_n		   (reset_n),		   //   reset.reset_n
	.clk		       (OSC1_50),		       //     clk.clk
	.A_from_the_ISP1761	(OTG_A),
	.CS_N_from_the_ISP1761     (OTG_CS_n),
	.DC_DACK_from_the_ISP1761  (OTG_DC_DACK),
	.DC_DREQ_to_the_ISP1761    (OTG_DC_DREQ),
	.DC_IRQ_to_the_ISP1761     (OTG_DC_IRQ),
	.D_to_and_from_the_ISP1761 (OTG_D),
	.HC_DACK_from_the_ISP1761  (OTG_HC_DACK),
	.HC_DREQ_to_the_ISP1761    (OTG_HC_DREQ),
	.HC_IRQ_to_the_ISP1761     (OTG_HC_IRQ),
	.RD_N_from_the_ISP1761     (OTG_OE_n),
	.RESET_N_from_the_ISP1761  (OTG_RESET_n),
	.WR_N_from_the_ISP1761     (OTG_WE_n),
	.m_we_from_the_ports				(s_we),		// portmux.we
	.m_re_from_the_ports				(s_re),		//	.re
	.m_writedata_from_the_ports	(s_writedata),	 //	.writedata
	.m_readdata_to_the_ports		(s_readdata),	  //	.readdata
	.m_reset_n_from_the_ports		(s_reset_n),	   //	.reset_n
	.m_address_from_the_ports		(s_address)	    //	.address
);




// Port mux
reg [6:0] cur_port;
wire [NUM_PORTS-1:0] sel;

reg shift_load_en, shift_en, f2s_want, s2f_ready;
reg [31:0] s2f_data;

wire [NUM_PORTS-1:0] s2f_wants;
wire s2f_want;

wire [NUM_PORTS-1:0] f2s_readies;
wire f2s_ready;

wire [32*NUM_PORTS-1:0] f2s_datas;
wire [31:0] f2s_data;

wire [5:0] num_bytes_per_transfer;

generate
if (NUM_PORTS > 1) begin : muxes
	lpm_mux #
	(
		.lpm_width(1),
		.lpm_size(NUM_PORTS),
		.lpm_widths(7)
	) s2f_want_mux
	(
		.data(s2f_wants),
		.sel(cur_port),
		.result(s2f_want)
	);	

	lpm_mux #
	(
		.lpm_width(1),
		.lpm_size(NUM_PORTS),
		.lpm_widths(7)
	) f2s_ready_mux
	(
		.data(f2s_readies),
		.sel(cur_port),
		.result(f2s_ready)
	);
	
	lpm_mux #
	(
		.lpm_width(32),
		.lpm_size(NUM_PORTS),
		.lpm_widths(7)
	) f2s_data_mux
	(
		.data(f2s_datas),
		.sel(cur_port),
		.result(f2s_data)
	);

	lpm_decode #
	(
		.lpm_width(7),
		.lpm_decodes(NUM_PORTS)
	) sel_decoder
	(
		.data(cur_port),
		.eq(sel)
	);

	lpm_mux #
	(
		.lpm_width(6),
		.lpm_size(NUM_PORTS),
		.lpm_widths(7)
	) cycles_selector
	(
		.data({6'd4,6'd4,6'd4,6'd4}),
		.sel(cur_port),
		.result(num_bytes_per_transfer)
	);
end
else begin: nomuxes
	assign s2f_want = s2f_wants[0];
	assign f2s_ready = f2s_readies[0];
	assign f2s_data = f2s_datas;
	assign sel[0] = 1'b1;
	assign num_bytes_per_transfer = {6'd4,6'd4,6'd4,6'd4};
end
endgenerate


// FIFOs and connections

localparam [15:0] S2F_FIFO_NUMWORDS = 16'd128;
localparam [14:0] F2S_FIFO_NUMWORDS = 15'd128;

reg [31:0]	s2f_fifo_data;
wire [31:0] s2f_fifo_q;
reg s2f_fifo_rdreq;
reg s2f_fifo_wrreq;
wire s2f_fifo_empty;
wire [7:0] s2f_fifo_usedw;
dcfifo #
(
	.lpm_width(32),
	.lpm_numwords(S2F_FIFO_NUMWORDS),
	.lpm_widthu(7),
	.lpm_showahead("ON"),
	.add_usedw_msb_bit("ON")
) s2f_fifo
(
	.rdclk(clk),
	.wrclk(OSC1_50),
	.data(s2f_fifo_data),
	.wrreq(s2f_fifo_wrreq),
	.rdreq(s2f_fifo_rdreq),
	.aclr(!s_reset_n),
	.q(s2f_fifo_q),
	.rdempty(s2f_fifo_empty),
	.wrusedw(s2f_fifo_usedw[6:0]),
	.wrfull(s2f_fifo_usedw[7])
);

reg [31:0]	f2s_fifo_data;
wire [31:0] f2s_fifo_q;
reg f2s_fifo_rdreq;
reg f2s_fifo_wrreq;
wire f2s_fifo_full;
wire [7:0] f2s_fifo_usedw;
wire f2s_fifo_empty;
dcfifo #
(
	.lpm_width(32),
	.lpm_numwords(F2S_FIFO_NUMWORDS),
	.lpm_showahead("ON"),
	.add_usedw_msb_bit("ON"),
	.lpm_widthu(7)
) f2s_fifo
(
	.rdclk(OSC1_50),
	.wrclk(clk),
	.data(f2s_fifo_data),
	.wrreq(f2s_fifo_wrreq),
	.rdreq(f2s_fifo_rdreq),
	.aclr(!s_reset_n),
	.q(f2s_fifo_q),
	.wrfull(f2s_fifo_full),
	.rdusedw(f2s_fifo_usedw[6:0]),
	.rdfull(f2s_fifo_usedw[7]),
	.rdempty(f2s_fifo_empty)
);

// Avalon slave logic

localparam [3:0] A_S2F_FIFO_DATA = 4'h0, A_S2F_FIFO_STATUS = 4'h4, A_F2S_FIFO_DATA = 4'h8, A_F2S_FIFO_STATUS = 4'hC;

always @* begin
	s_readdata = 32'bx;
	s2f_fifo_data = 32'bx;
	s2f_fifo_wrreq = 1'b0;
	f2s_fifo_rdreq = 1'b0;
	
	case (s_address)	
		A_S2F_FIFO_DATA: begin
			s2f_fifo_data = s_writedata;
			s2f_fifo_wrreq = s_we;
		end
		
		A_S2F_FIFO_STATUS: begin
			s_readdata = 32'b0;
			s_readdata[15:0] = s2f_fifo_usedw;
			s_readdata[31:16] = S2F_FIFO_NUMWORDS;
		end
		
		A_F2S_FIFO_DATA: begin
			s_readdata = f2s_fifo_q;
			f2s_fifo_rdreq = s_re;
		end
		
		A_F2S_FIFO_STATUS: begin
			s_readdata = 32'b0;
			s_readdata[15:0] = f2s_fifo_usedw;
			s_readdata[30:16] = F2S_FIFO_NUMWORDS;
			s_readdata[31] = f2s_fifo_empty;
		end
		
		default: begin
		end
	endcase
end


// Transfer/handshake state machine

localparam DIR_F2S = 1'b0, DIR_S2F = 1'b1;

// Number of bytes remaining in entire transaction
reg [31:0] xfer_count;
reg xfer_count_dec;
reg xfer_count_load;

// Number of data bytes in the port shift register
reg signed [6:0] s2f_num_bytes_in_shift_register;
reg s2f_sr_bytes_inc;
reg s2f_sr_bytes_zero;
reg s2f_sr_bytes_dec;

// Number of data bytes in the port shift register
reg signed [6:0] f2s_num_bytes_in_shift_register;
reg f2s_sr_bytes_inc;
reg f2s_sr_bytes_zero;
reg f2s_sr_bytes_dec;

// Port info
reg xfer_dir;
reg xfer_portdir_load;

reg [2:0] state, nextstate;
localparam [2:0] S_IDLE = 3'd0, S_F2S = 3'd1, S_S2F = 3'd2, S_GETSIZE = 3'd3, S_F2S_PUTSIZE = 3'd4;

always @ (posedge clk or negedge s_reset_n)
begin
	if (!s_reset_n) begin
		state <= S_IDLE;
		xfer_count <= 'd0;
		s2f_num_bytes_in_shift_register <= 0;
		f2s_num_bytes_in_shift_register <= 0;
	end
	else begin
		state <= nextstate;
		
		if (xfer_count_load) xfer_count <= s2f_fifo_q;
		else if (xfer_count_dec) xfer_count <= xfer_count - num_bytes_per_transfer;

		if (s2f_sr_bytes_zero)
			s2f_num_bytes_in_shift_register <= 0;
		else if (s2f_sr_bytes_inc)
			s2f_num_bytes_in_shift_register <= s2f_num_bytes_in_shift_register + 6'd4;
		else if (s2f_sr_bytes_dec)
			s2f_num_bytes_in_shift_register <= s2f_num_bytes_in_shift_register - num_bytes_per_transfer;

		if (f2s_sr_bytes_zero)
			f2s_num_bytes_in_shift_register <= 0;
		else if (f2s_sr_bytes_inc)
			f2s_num_bytes_in_shift_register <= f2s_num_bytes_in_shift_register + num_bytes_per_transfer;
		else if (f2s_sr_bytes_dec)
			f2s_num_bytes_in_shift_register <= f2s_num_bytes_in_shift_register - 6'd4;
		
		if (xfer_portdir_load) begin
			cur_port <= s2f_fifo_q[6:0];
			xfer_dir <= s2f_fifo_q[7];
		end
	end
end

always @* begin
	nextstate = state;
	
	s2f_ready = 1'b0;
	f2s_want = 1'b0;
	shift_en = 1'b0;
	shift_load_en = 1'b0;
	s2f_data = 32'bx;
	
	s2f_fifo_rdreq = 1'b0;
	f2s_fifo_wrreq = 1'b0;
	f2s_fifo_data = 32'bx;
	
	xfer_count_load = 1'b0;
	xfer_count_dec = 1'b0;
	xfer_portdir_load = 1'b0;

	s2f_sr_bytes_zero = 1'b0;
	s2f_sr_bytes_inc = 1'b0;
	s2f_sr_bytes_dec = 1'b0;

	f2s_sr_bytes_zero = 1'b0;
	f2s_sr_bytes_inc = 1'b0;
	f2s_sr_bytes_dec = 1'b0;

	case (state)
	S_IDLE: begin
		if (!s2f_fifo_empty) begin
			xfer_portdir_load = 1'b1;
			s2f_fifo_rdreq = 1'b1;
			nextstate = S_GETSIZE;
		end
	end
	
	S_GETSIZE: begin
		s2f_sr_bytes_zero = 1'b1;
		f2s_sr_bytes_zero = 1'b1;
		if (!s2f_fifo_empty) begin
			xfer_count_load = 1'b1;
			s2f_fifo_rdreq = 1'b1;
			
			if (xfer_dir == DIR_F2S) begin
				nextstate = S_F2S_PUTSIZE;
			end
			else begin
				nextstate = S_S2F;
			end
		end
	end	
	
	S_S2F: begin

		// Transfer data from the USB cable to a port on the user
		// circuit.

		s2f_data = s2f_fifo_q;
		
		if (xfer_count[31] || xfer_count == 32'd0) begin

			// We've transfered all of the data to the user
			// circuit.

			nextstate = S_IDLE;
		end
		else begin
			if (s2f_num_bytes_in_shift_register >= num_bytes_per_transfer) begin

				// There is enough data in the shift register
				// to feed to the port on the user circuit.
				// Ask the user circuit to take it.

				s2f_ready = 1'b1;
				if (s2f_want) begin

					// Decrement the transfer count.
					// Decrease the shift register
					// data count, and shift the
					// remaining data over.

					xfer_count_dec = 1'b1;
					s2f_sr_bytes_dec = 1'b1;
					shift_en = 1'b1;
				end
			end

			else if (!s2f_fifo_empty) begin

				// We need more data.  Get some from
				// the FIFO.  Shift the existing data
				// in the shift register over to make room.
				// Increase the shift register data count.

				s2f_fifo_rdreq = 1'b1;
				s2f_sr_bytes_inc = 1'b1;
				shift_load_en = 1'b1;
				shift_en = 1'b1;
			end
		end
	end			
	
	S_F2S_PUTSIZE: begin
		if (!f2s_fifo_full) begin
			f2s_fifo_data = xfer_count;
			f2s_fifo_wrreq = 1'b1;
			nextstate = S_F2S;
		end
	end
	
	S_F2S: begin

		// Transfer data from the FPGA towards the USB cable

		f2s_fifo_data = f2s_data;
		
		if ((xfer_count <= 0) && (f2s_num_bytes_in_shift_register <= 0)) begin

			// We got all the data from the user circuit, and there is
			// nothing left in the shift register, so we're done.

			nextstate = S_IDLE;
		end
		else begin
			if ((xfer_count > 0) && (f2s_num_bytes_in_shift_register < 4)) begin

				// There is more data to get from the user circuit,
				// and we haven't filled the shift register, so ask the
				// circuit for more.

				f2s_want = 1'b1;
				if (f2s_ready) begin

					// Shift the existing shift register
					// data over to make room.  Copy the
					// new data to the shift register.
					// Increase the shift register data
					// count, and decrement the number of
					// data items to transfer.

					xfer_count_dec = 1'b1;
					shift_load_en = 1'b1;
					shift_en = 1'b1;
					f2s_sr_bytes_inc = 1'b1;
				end
			end

			else if ((xfer_count == 0) && (f2s_num_bytes_in_shift_register < 4)) begin

				// We got all of the data from the user circuit,
				// but the shift register isn't full.  Shift it
				// over until it is.  This only happens for
				// port widths <= 16 bits.

				shift_en = 1'b1;
				f2s_sr_bytes_inc = 1'b1;
			end

			else if (!f2s_fifo_full) begin

				// Transfer the shift register contents to the
				// FIFO that leads to the CPU (and hence to
				// the USB cable).  Shift the shift register
				// to get the next word ready to go, in the
				// case of ports with widths > 32 bits.

				shift_en = 1'b1;
				f2s_fifo_wrreq = 1'b1;
				f2s_sr_bytes_dec = 1'b1;
			end
		end
	end
	
	default: begin
	end

	endcase
end


// Autogenerated connections to user signals

wire [31:0] number_of_triggers_oreg_d;
sys_to_fpga # (.WIDTH(32)) number_of_triggers_inst (.clk(clk), .shift_load_en(shift_load_en), .shift_en(shift_en), .sel(sel[0]), .mux_data(s2f_data), .user_data(number_of_triggers_oreg_d));
lpm_ff # (.LPM_WIDTH(32)) number_of_triggers_oreg (.clock(clk), .data(number_of_triggers_oreg_d), .enable(s2f_ready & sel[0]), .q(number_of_triggers));
fpga_to_sys # (.WIDTH(32)) status_inst (.clk(clk), .shift_en(shift_en), .sel(sel[1]), .shift_load_en(shift_load_en), .mux_data(f2s_datas[63:32]), .user_data(status));
fpga_to_sys # (.WIDTH(32)) status125_inst (.clk(clk), .shift_en(shift_en), .sel(sel[2]), .shift_load_en(shift_load_en), .mux_data(f2s_datas[95:64]), .user_data(status125));
wire [31:0] data_in_oreg_d;
sys_to_fpga # (.WIDTH(32)) data_in_inst (.clk(clk), .shift_load_en(shift_load_en), .shift_en(shift_en), .sel(sel[3]), .mux_data(s2f_data), .user_data(data_in_oreg_d));
lpm_ff # (.LPM_WIDTH(32)) data_in_oreg (.clock(clk), .data(data_in_oreg_d), .enable(s2f_ready & sel[3]), .q(data_in));


assign s2f_wants[0] = 1'b1;
assign f2s_readies[1] = 1'b1;
assign f2s_readies[2] = 1'b1;
assign s2f_wants[3] = 1'b1;



endmodule



	

	


