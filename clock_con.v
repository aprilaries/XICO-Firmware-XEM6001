`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:24:06 09/26/2012 
// Design Name: 
// Module Name:    clock_con 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////
module clock_con(
	input wire clk,
	input wire rset,
	output wire sdo,
	output wire sclk,
	output wire csb,
	output wire [25:0] test
	);
	
	//wires and assignments ****************************************************
	//data wires
	parameter [23:0] C_latch = 24'h8FF980;
	parameter [23:0] N_latch = 24'h409C22;//24'h409C22;
	parameter [23:0] R_latch = 24'h3000C9;
	reg [23:0] write_latch;
	
	//wires for state machine
	reg [2:0] state;
	reg [7:0] counts;
	wire countRset = counts == 8'h18;
	wire load = ~|counts;
	
	//wires for reset stretching - the state machine only triggers
	// on the clock when the counter gets reset.  This is not a clock
	// that can be sent to the okTriggers, so the clock that drives
	// the counter must be the one sent into the okTrigger module.
	// Now the reset pulses don't line up with counter resets, so this
	// stretcher elongates the reset pulses so that they can be detected
	// by the state machine.
	reg [7:0] stretching_counts;
	wire done_stretching = stretching_counts == 8'h18;
	reg stateReset;
	reg writing;
	wire send;
	
	//wires for shift register
	wire [23:0] shifter_output;
	
	wire [23:0] shifter_input = (load) ? write_latch[23:0] : {shifter_output[22:0], 1'b0};
	
	//final output assignments
	assign sclk = ~clk;
	assign sdo = shifter_output[23];
	assign csb = (load & send) | ~send;
	
	//DO NOT REMOVE THIS LINE!!!!!!!!!!!!!
	//  if you do, ISE will retardedly "optimize" both state and write_latch
	//  out of this module because it hates you with a passion more heated
	//  than the surface of the sun
	assign test = {write_latch, state};
	
	//counter ******************************************************************
	always @(posedge clk) begin
		case(countRset)
			1'b0: counts[7:0] <= counts[7:0] + 1;
			1'b1: counts[7:0] <= 8'b0;
			default: counts[7:0] <= 8'b0; 
		endcase
	end
	
	//countRset pulse stretcher ************************************************
	reg stretching;
	always @(posedge clk) begin
		case(stretching)
			1'b0: begin
					stretching <= rset;
					stateReset <= 1'b0;
				end
			1'b1: begin
					stretching_counts <= (done_stretching) ? 8'b0 : stretching_counts + 1;
					stretching <= ~done_stretching;
					stateReset <= 1'b1;
				end
		endcase
	end
	
	//setup state machine ******************************************************
	parameter send_R = 3'b000;
	parameter send_N = 3'b001;
	parameter waiting = 3'b010;
	parameter send_C = 3'b011;
	parameter done = 3'b100;
	
	//BUFGCE sff(.I(clk), .CE(countRset), .O(loading_clock));
	//assign loading_clock = (countRset) ? clk : 1'b0;
	
	always @(posedge clk) begin
		if(countRset) begin
			case(state[2:0])
				send_R: begin	//prepare to load R_Latch
					write_latch[23:0] <= R_latch[23:0];
					state[2:0] <= send_C;
					writing <= 1'b1;
					end
				send_C: begin	//prepare to load C_Latch 
					write_latch[23:0] <= C_latch[23:0];
					state[2:0] <= send_N;
					writing <= 1'b1;
					end
				send_N: begin	//prepare to load N_Latch
					write_latch[23:0] <= N_latch[23:0];
					state[2:0] <= waiting;
					writing <= 1'b1;
					end
				waiting: begin
					write_latch[23:0] <= 24'h000000;
					writing <= 1'b0;
					case(stateReset)
						1'b0: begin
								state[2:0] <= waiting;
							end
						1'b1: begin
								state[2:0] <= send_R;
							end
					endcase
					end
				default: begin	//a bad thing has happened in the universe, so just
					//write the R latch, and try to restart the state machine
					write_latch[23:0] <= R_latch[23:0];
					state[2:0] <= send_R;
					writing <= 1'b0;
					end
			endcase
		end
	end
	
	//create a 1 clock cycle phase delay to line up with le correctly
	FDCE sf(.Q(send), .C(clk), .CE(1'b1), .CLR(1'b0), .D(writing));
	
	//shift register ***********************************************************
	genvar i;
	generate
		for(i = 0; i < 24; i = i + 1) begin: shift_register
			FDCE ff(.Q(shifter_output[i]), .C(clk), .CE(1'b1), .CLR(1'b0), .D(shifter_input[i]));
		end
	endgenerate
	
endmodule
