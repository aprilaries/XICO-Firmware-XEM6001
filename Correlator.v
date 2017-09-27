`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:56:29 04/15/2013 
// Design Name: 
// Module Name:    Correlator 
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
//////////////////////////////////////////////////////////////////////////////////

module MCorrelator(
	 input wire  i_Stop,
    input wire  i_Start,				
    input wire  i_PmtSource,
    input wire  i_clk,
	 input wire  [31:0] i_Tao1,
	 input wire  [31:0] i_Tao2,
    output reg  [31:0] r_TimeSpan,
	 output reg	 r_Bright,
	 output reg  [1:0] r_Arrival,
    output reg  r_Done
    );
	
   localparam DELAY = 8;	//delay for 10 clock cycles after finish before r_Done set
		
	reg r_Start;
	reg [31:0] r_Tao1, r_Tao2;
	//reg [31:0] r_ExpireTime;
	always @ (posedge i_clk)
	begin
		r_Start <= i_Start;
	end
	
	//TimeStamp
	reg [63:0] r_TimeStamp, r_LastTimeStamp;
	always @ (posedge i_clk)
		r_TimeStamp <= r_TimeStamp + 64'b1;
	
	//PMT edge counter
	reg [1:0]  r_PmtEdge;
	reg [63:0] r_PhotonTimeStamp, r_LastPhotonTimeStamp, r_TimeSpan64;
	always @(posedge i_clk) r_PmtEdge <= {r_PmtEdge[0], i_PmtSource};
	always @(posedge i_clk)
	if (~r_PmtEdge[1] && r_PmtEdge[0])
		r_PhotonTimeStamp <= r_TimeStamp;		
	
	//state machine
	reg [7:0]  r_State;
	localparam S_IDLE  			= 8'b1;
	localparam S_READY 			= 8'b10;
	localparam S_COUNT_START	= 8'b100;
	localparam S_COUNT_WAIT		= 8'b1000;
	localparam S_COUNT_WAIT1	= 8'b10000;
	localparam S_COUNT_WAIT2	= 8'b100000;
	localparam S_DONE  			= 8'b1000000;
	
	always @(posedge i_clk)
	begin
		case (r_State)
		S_IDLE:			
			begin
			r_Done <= 1'b0;
			r_TimeSpan <= 0;
			if (r_Start)
				begin					
					r_Tao1[31:0] <= i_Tao1;
					r_Tao2[31:0] <= i_Tao1 + i_Tao2;					
					r_Bright <= 1'b0;
					r_State <= S_READY;			
				end
			end
		S_READY:	r_State <= S_COUNT_START;		
		S_COUNT_START:
			begin
				r_LastPhotonTimeStamp <= r_PhotonTimeStamp;
				r_LastTimeStamp <= r_TimeStamp;
				r_State <= S_COUNT_WAIT;
				r_Arrival <= 2'b0;
			end
		S_COUNT_WAIT:
			begin
				r_TimeSpan64 <= r_TimeStamp - r_LastTimeStamp;
				if (i_Stop)
					r_State <= S_DONE;
				else if (r_TimeSpan64 >= r_Tao1)	r_State <= S_COUNT_WAIT1;
				else if (r_LastPhotonTimeStamp == r_PhotonTimeStamp) // wait for the first photon	
					r_State <= S_COUNT_WAIT;
				else     //a new event
					begin
						r_TimeSpan64 <= r_PhotonTimeStamp - r_LastPhotonTimeStamp;
						r_Arrival <= 2'b1;
						r_Bright <= 1'b1;
						r_State <= S_DONE;
					end
			end	
		S_COUNT_WAIT1:
			begin
			   r_TimeSpan64 <= r_TimeStamp - r_LastTimeStamp;
				if (i_Stop)
					r_State <= S_DONE;
				else if (r_TimeSpan64 >= r_Tao2)	//dark state with no photon
				begin
					r_Bright <= 1'b0;	//dark event
					r_Arrival <= 2'b0;
					r_State <= S_DONE;
				end
				else if (r_LastPhotonTimeStamp == r_PhotonTimeStamp) // wait for the late first photon	
					r_State <= S_COUNT_WAIT1;
				else     //a new event
					begin
						r_TimeSpan64 <= r_PhotonTimeStamp - r_LastPhotonTimeStamp;
						r_LastPhotonTimeStamp <= r_PhotonTimeStamp;
						r_State <= S_COUNT_WAIT2;
					end				
			end
		S_COUNT_WAIT2:
			begin
			   r_TimeSpan64 <= r_TimeStamp - r_LastTimeStamp;
				if (i_Stop)
					r_State <= S_DONE;
				else if (r_TimeSpan64 >= r_Tao2)	//dark state with 1 photon
				begin
					r_Bright <= 1'b0;	//dark event
					r_Arrival <= 2'b10;
					r_State <= S_DONE;
				end
				else if (r_LastPhotonTimeStamp == r_PhotonTimeStamp) // wait for the late second photon	
					r_State <= S_COUNT_WAIT2;
				else
					begin
						r_TimeSpan64 <= r_PhotonTimeStamp - r_LastPhotonTimeStamp;
						r_Arrival <= 2'b11;
						r_Bright <= 1'b1;
						r_State <= S_DONE;
					end				
			end
		S_DONE:
			begin
				r_Done <= 1'b1;
				r_State <= S_IDLE;
			end
		default:;		
		endcase
	end	

endmodule
