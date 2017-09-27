`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Gatech
// Engineer: G. Shu 
// 
// Create Date:    13:11:46 01/15/2015 
// Design Name: 
// Module Name:    TAC 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// Count pulses and measure the distribution with respect to some sync signal. The top
// level structure is as follows:
// - photon pulses move through a series of 64 latches clocked at hclk_in
// - on sync signal, the data on the latches is saved
//	- there are 64 counters which increment whenever there is a photon in corresponding latch
// - the data is shifted out of the counters when logger starts
// - logger sends the data out to a pipe, to be picked up by the PC
// - Single edge design
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


module TAC(
//signals
input wire clk_in,	//usb clock
input wire hclk_in,  //high speed clock
input wire pmt_in,
input wire sync_in,
//triggers
input wire pmtrst_in,
input wire addrrst_in,
//commands
input wire cmd_trig_in,
input wire [15:0] cmd_in,
input wire [15:0] data_in,
//outputs
output wire [15:0] wOutData0_out,
output wire [15:0] wOutData1_out,
//pipe
input wire  wPipeRead_in,
output wire [15:0] wPipeData_out
);
	 
localparam nMaxDim = 128;	//the max buffer to store the TAC histogram

//Data registers
reg [15:0] 	rOutData0 = 16'b0, rOutData1 = 16'b0;
reg [15:0] 	rPipeOutData = 16'b0;
reg [6:0] 	rPipeReadIdx = 7'b1111111;
//output data
assign wOutData0_out = rOutData0;
assign wOutData1_out = rOutData1; 
assign wPipeData_out = rPipeOutData;

//time stamps
reg   [15:0] rTimeStamp = 16'b0;		// time stamp records clock sticks
reg	[31:0] rPhotonNum = 32'b0, rCurPhotonNum = 32'b0;	// track how many photons arrived since PMT reset
reg   [15:0] rPMTTS = 16'b0;								// PMT time stamps
reg	[31:0] rLPMTTS = 16'b0;
reg   [31:0] rSyncTS = 32'b0;
reg	[15:0] rLSyncTS = 16'b0;   						// latest sync time stamps
reg   [31:0] rSyncNum = 32'b0;
reg   [6:0]  rTimeDiff = 7'b0;
wire   [15:0] wTimeDiff;	
reg   [15:0] rHistogram[nMaxDim - 1 : 0];
reg   [11:0]  rPMTBuff = 12'b0;

//PC interface
localparam CMD_READ 		= 4'h0;
localparam CMD_R_TS 		= 4'h1;
localparam CMD_R_TPMT 	= 4'h2;
localparam CMD_R_TLPMT  = 4'h3;
localparam CMD_R_TSYNC 	= 4'h4;
localparam CMD_R_TLSYNC = 4'h5;
localparam CMD_R_TDIFF  = 4'h6;
localparam CMD_R_PADDR	= 4'h7;
localparam CMD_R_HIST   = 4'h8;
localparam CMD_R_LOCK   = 4'h9;
localparam CMD_R_PCNT   = 4'ha;
localparam CMD_R_SCNT   = 4'hb;
localparam CMD_WRITE 	= 4'h1;
localparam CMD_W_PADDR  = 4'h1;
localparam CMD_PMT_RST   = 4'h2;
localparam CMD_ADDR_RST  = 4'h3;

always @ (posedge clk_in)
begin
	if (cmd_trig_in)
		begin
			case (cmd_in[15:12])
				CMD_READ:
					begin
						case (cmd_in[3:0])
							CMD_R_TS:		{rOutData1, rOutData0} <= {16'b0, rTimeStamp};
							CMD_R_TPMT: 	{rOutData1, rOutData0} <= {16'b0, rPMTTS};
							CMD_R_TLPMT:	{rOutData1, rOutData0} <= rLPMTTS;
							CMD_R_TSYNC: 	{rOutData1, rOutData0} <= rSyncTS;
							CMD_R_TLSYNC: 	{rOutData1, rOutData0} <= {16'b0, rLSyncTS};
							CMD_R_TDIFF:	rOutData0 <= {8'b0, rTimeDiff};
							CMD_R_PADDR:  	rOutData0 <= {8'h0, rPipeReadIdx};
							CMD_R_HIST:   	rOutData0 <= rHistogram[data_in[6:0]];
							CMD_R_LOCK:		rOutData0 <= {15'b0, 15'b1};
							CMD_R_PCNT:		{rOutData1, rOutData0} <= rPhotonNum; 
							CMD_R_SCNT:		{rOutData1, rOutData0} <= rSyncNum;
							default:		{rOutData1, rOutData0} <= 0;
						endcase
					end
				CMD_WRITE:
					begin
						case (cmd_in[3:0])
							//CMD_W_PADDR:	rPipeReadIdx <= WireInData0[6:0];
							default:;
						endcase
					end
			endcase
		end
		
end

//high speed time stamp
always @ (posedge hclk_in) 
begin
	rTimeStamp <= rTimeStamp + 16'b1;
end

//a sync event
always @ (posedge sync_in)
begin
	rSyncTS <= {rSyncTS[15:0], rTimeStamp};
	rSyncNum <= rSyncNum + 1;
end

//a photon arriving event
always @ (posedge pmt_in)
begin
   rPhotonNum <= pmtrst_in ? 0 : rPhotonNum + 1;
	rLPMTTS <= {rLPMTTS[15:0], rPMTTS};
	rPMTTS <= rTimeStamp;			//record current PMT time stamp
	rLSyncTS <= rSyncTS[15:0];		//record the last sync time stamp
end

//recording
integer i;
assign wTimeDiff = (rPMTTS > rLSyncTS) ? (rPMTTS - rLSyncTS) : (rLSyncTS - rPMTTS);

always @ (posedge clk_in)	//use usb clock to do complicated logic
begin
	if (pmtrst_in)
		begin
			//initial buffer
			rCurPhotonNum <= rPhotonNum;
			rTimeDiff <= nMaxDim - 1;
			for (i = 0; i < nMaxDim; i = i + 1)
				begin
					rHistogram[i] <= 16'b0;
				end
		end
	else
		if (rPhotonNum != rCurPhotonNum)	// a valid new photon event
			begin
				rCurPhotonNum <= rPhotonNum;
				rTimeDiff <= wTimeDiff[6:0];
				rHistogram[rTimeDiff] <= rHistogram[rTimeDiff] + 1;
			end
		else
			begin
				rCurPhotonNum <= rCurPhotonNum;
				rTimeDiff <= rTimeDiff;
				rHistogram[rTimeDiff] <= rHistogram[rTimeDiff];
			end
end

always @ (negedge clk_in)
begin
	if (addrrst_in)
		begin
			rPipeReadIdx <= 7'b1111111;
			rPipeOutData <= 16'b0;
		end		
	else
		begin
			rPipeReadIdx <= wPipeRead_in ? rPipeReadIdx + 7'b1 : rPipeReadIdx;
			rPipeOutData <= rHistogram[rPipeReadIdx];
		end
end

endmodule
