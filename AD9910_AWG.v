`timescale 1ns / 1ps
//`include "PISO.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: Gatech
// Engineer: G Shu
// 
// Create Date:    10:35:01 08/29/2015 
// Design Name: 
// Module Name:    AD9910_AWG 
// Project Name: 
// Target Devices: AD9910
// Tool versions: 
// Description: Parallel AWG
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module AD9910_AWG
#(parameter P_ADDR = 4'b0)
(
	input wire [3:0] iAddr,
	input wire iReset,
	input wire iClk,
	input wire iTrig,
	input wire [15:0] iStartAddr,
	input wire [31:0] iMemData,
	
	output wire wReady_o,
	inout  wire [15:0] wMemAddr_io,       //to memory controller

	//Parallel ports
	inout wire [17:0] wPData_io,
	output wire wTxEnable_o,
	//serial ports
	output wire wCS_o,
	output wire	wIOUpdate_o,
	
	inout wire ioSDO,
   inout wire ioSCLK,
   
	output wire [2:0] oProfile
);

//3 steps:
//1. serial 		setup
//2. parallel 		AWG
//3. serial clean up

//States constants
localparam S_IDLE 	= 4'h0;
localparam S_MDELAY  = 4'h1;
localparam S_HEAD0   = 4'h2;
localparam S_HEAD1   = 4'h3;
localparam S_HEAD2   = 4'h4;
localparam S_SERIAL  = 4'h5;
localparam S_PARA		= 4'h6;
localparam S_DELAY	= 4'h7;
localparam S_FINAL   = 4'h8;

localparam FTW_ADDR = 8'h7;
localparam SRL_ADDR = 8'h1;

localparam MAX_SWIDTH = 32;

//state registors
reg [3:0] rState = S_IDLE;
reg [3:0] rNextState = S_IDLE;

//serial ports
reg [5:0] 	rSIdx = MAX_SWIDTH;
reg [39:0] 	rSData = 40'b0;
reg rCS = 1'b1;
reg rIOUpdate = 1'b0;
assign wCS_o = rCS;
assign wIOUpdate_o = rIOUpdate;


//parallel ports
reg [15:0] rStartAddr = 16'b0;
reg [31:0] rStep = 32'b0, rStepIdx = 32'b0;

//repeat
reg [27:0] rRepeat = 28'b0;
reg [27:0] rRepeatIdx = 28'b0;

reg [30:0] rDelay = 31'b0;

reg rTxEnable = 1'b0;
reg [15:0]	rMemAddr = 16'b0;

//semi constant
//wire [15:0] wDataEndAddr, wDataStartAddr;
//assign wDataStartAddr 	= rStartAddr + 3;
//assign wDataEndAddr 		= rStartAddr + 2 + rStep;
reg [15:0]	rDataStartAddr = 16'b0, rDataEndAddr = 16'b0;

assign wMemAddr_io 		= iAddr == P_ADDR ? rMemAddr : 16'hzzzz;
wire wSDO;

assign wReady_o 			= iAddr == P_ADDR ? (rState == S_IDLE ? 1'b1 : 0) : 1'b1;

//serial clock
assign ioSCLK 			= iAddr == P_ADDR ? ~iClk : 1'bz;
assign ioSDO 			= iAddr == P_ADDR ? wSDO : 1'bz;
assign oProfile 		= 3'b0;

assign wPData_io 		= iAddr == P_ADDR  ? iMemData[17:0] : 18'bzzzzzzzzzzzzzzzzzz;
assign wTxEnable_o 	= iAddr == P_ADDR  ? rTxEnable & (iMemData[31] & ~iMemData[30]) : 1'bz;

always @ (posedge iClk)
begin
	case (rState)
		S_IDLE:
			begin
				if (iTrig && iAddr == P_ADDR)
					begin
						rStartAddr 	<= iStartAddr; 
						rMemAddr 	<= iStartAddr;  //set h1
						rState 		<= S_MDELAY;
					end
			end
		S_MDELAY:
			begin
				rState 	<= S_HEAD0;
				rMemAddr <= rMemAddr + 16'b1;    //to read h1, set h2 address
				rDataStartAddr <= rStartAddr + 16'h3;
			end
		S_HEAD0: //Set waveform step number from h1
			begin
				rStep 	<= iMemData;
				rStepIdx <= 0;
				rState 	<= S_HEAD1;
				rMemAddr <= rMemAddr + 16'b1;    //to read h2, set h3 address
			end
		S_HEAD1: //Set frequency tuning word from h2
			begin
				rSData 	<= {FTW_ADDR, iMemData}; 
				rSIdx 	<= MAX_SWIDTH - 1;
				rCS 		<= 0;
				rState 	<= S_SERIAL;
				rNextState <= S_HEAD2;
				rDataEndAddr <= rStartAddr + rStep;
			end
		S_HEAD2: //Set Parallel mode and the frequency offset from h3
			begin
				rIOUpdate <= 0;
				rSData 		<= {SRL_ADDR, 8'h0, 20'h40083, iMemData[31:28]};
				
				rRepeat 		<= iMemData[27:0];
				rRepeatIdx 	<= 1;
				
				rSIdx 		<= MAX_SWIDTH - 1;
				rCS	 		<= 0;
				
				rState 		<= S_SERIAL;
				rNextState 	<= S_PARA;
				rMemAddr 	<= rMemAddr + 1;		
				rDataEndAddr <= rDataEndAddr + 14'h2;
			end
		S_PARA: //start parallel modulation mode
			begin
				rIOUpdate <= 0;												
				casez (iMemData[31:30])
					2'b0z: //delay
						begin
							rStepIdx <= rStepIdx + 1;	//a delay must be in the middle of a waveform								
							if (iMemData[30:0] > 1)
								begin
									rDelay 	<= iMemData[30:0] - 1;
									rState 	<= S_DELAY;
									rTxEnable<= 0;
								end
							else
								rMemAddr <= (rMemAddr == rDataEndAddr) ? rDataStartAddr : rMemAddr + 1;
						end
						
					2'b10: //modulation
						begin
							if (rStepIdx == rStep) //End of one round
								begin
										rRepeatIdx <= rRepeatIdx + 1;
										if (rRepeatIdx == rRepeat)  //The repeats finish, go to the final serial command
											begin
												rTxEnable 	<= 0;
												rState 		<= S_SERIAL;
												rNextState 	<= S_IDLE;
												rSData 		<= {SRL_ADDR, 8'h0, 24'h400820};
												rSIdx 		<= MAX_SWIDTH - 1;
												rCS			<= 0;
											end
										else
											begin
												rTxEnable 	<= 1;
												rStepIdx 	<= 1;
												rMemAddr 	<= (rMemAddr == rDataEndAddr) ? rDataStartAddr : rMemAddr + 1;
											end
								end
							else  //in the middle of a waveform repeat  
								begin
									rTxEnable 	<= 1;
									rMemAddr 	<= (rMemAddr == rDataEndAddr) ? rDataStartAddr : rMemAddr + 1;
									rStepIdx 	<= rStepIdx + 1;
								end
						end
				endcase
			end
		S_SERIAL:
			begin
				if (rSIdx == 0)
					begin
						rSIdx 	<= MAX_SWIDTH;
						rState 	<= rNextState;
						rCS	 	<= 1'b1;
						rIOUpdate <= 1'b1;
					end
				else
					rSIdx <= rSIdx - 1;
			end
		S_DELAY:
			begin
				rDelay <= rDelay - 1;
				if (rDelay == 1)
					begin
						rState 		<= S_PARA;
						rTxEnable 	<= 1;
						rMemAddr 	<= (rMemAddr == rDataEndAddr) ? rDataStartAddr : rMemAddr + 1;
					end
			end
	endcase
end

MUX_MSB_SS 
#(
.DATA_WIDTH(40),
.IDX_WIDTH(6)
)
msb_9910
(
.sdata_o(wSDO),
.pdata_i(rSData),
.idx_i(rSIdx)
);

endmodule