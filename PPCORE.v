`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:41:51 11/03/2015 
// Design Name: 
// Module Name:    PPCORE 
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
//////////////////////////////////////////////////////////////////////////////////
module PPCORE(
	 input wire wReset_i,
    input wire wClk_i,
	 input wire wHClk_i,
	 input wire [15:0] wStartAddr_i,
    input wire wStartTrig_i,
    input wire wStopTrig_i,
	 output wire wBusy_o,
	 //Debug
	 input wire wDebug_i,
    input wire wStepTrig_i,
	 output wire [1:0]  wState_o,
	 output wire [31:0] wCmd_o,
	 output wire [31:0] wData_o,
	 output wire [31:0] wW_o,
	 output wire [15:0] wI_o,
	 output wire [15:0] wCmdPnt,
	 //memory	 
    input wire [31:0] wMem_i,
	 output wire [31:0] wMem_o,
	 output wire wMemWE_o,
    output wire [15:0] wMemAddr_o,
    //
	 input wire wLineTrig_i,
    input wire wHWReady_i,	 
	 //DDS
	 output reg rDDSTrig_o,
	 output reg [3:0]  rDDSBrdIdx_o,
	 output reg [36:0] rAD9959Cmd_o,
	 output reg [3:0]  rAD9959PIdx_o,
	 output reg [33:0] rAD9910Cmd_o,	
	 //AWG
	 output reg [15:0] rAWG9959StartAddr_o,
	 output reg [15:0] rAWG9910StartAddr_o,
	 //Digital clicks
	 output reg             rDCTrig_o,
	 output reg	[15:0]		rDCStep_o,
	 output reg  [15:0]		rDCDelay_o,
	 output reg  				rDCHlvl_o,
	 //Pulse picker
	 output reg [7:0]			rPulseDelay_o,
	 output reg [7:0]			rPulseWidth_o,
	 output reg 				rPTrig_o,
	 output reg					rPInit_o,
	 //PMT
	 input wire wPMT_i,
	 input wire [31:0] wPMTA_i,
	 //DIO
	 output reg [7:0] rDO_o
    );

///////////////////////////////////////////////////
// pulse sequencer instruction definitions
// The D subfix means the operand is a direct number
///////////////////////////////////////////////////
	localparam			PP_NOP		= 8'h00;	// no operation	
	//basic operation
	localparam			PP_LDWR		= 8'h01;	// W <= Var
	//localparam			PP_LDWRD		= 8'h02;	// W <= Const
	localparam			PP_LDWI		= 8'h03;	// W <= *I
	localparam			PP_STWR		= 8'h04;	// Var <= W
	localparam			PP_STWI		= 8'h05;	// *I <= W
	localparam			PP_LDINDF	= 8'h06;	// INDF <= Var
	localparam			PP_STINDF   = 8'h07; // Var <= INDF
	localparam			PP_CLRW		= 8'h08; // W = 0
	localparam			PP_CMP		= 8'h09;	// W <= W - Var
	localparam			PP_CMPI		= 8'h0a; // I <= I - Var
	//localparam		PP_CMPD		= 8'h0a; // W <= W - Const
	localparam			PP_JMP		= 8'h10;	// Jump
	localparam			PP_JMPZ		= 8'h11;	// Jump if W = 0
	localparam			PP_JMPNZ		= 8'h12;	// Jump if W != 0
	localparam			PP_JMPG		= 8'h13;	//	Jump if W > 0
	localparam			PP_JMPL		= 8'h14; //	Jump if W < 0
	localparam			PP_JMPGE    = 8'h15;	//	Jump if W >= 0
	localparam        PP_JMPLE  	= 8'h16; //	Jump if W <= 0
	//Arithmetic
	localparam			PP_ANDW		= 8'h17;	// W = W & Var
	localparam			PP_ADDW		= 8'h19;	// W = W + Var
	localparam			PP_ADDI		= 8'h21;   // I = I + Var
	localparam			PP_INC		= 8'h23;	// W = W + 1
	localparam        PP_INCI     = 8'h24;   // I = I + 1
	localparam			PP_DEC		= 8'h25;	// W = W - 1
	localparam        PP_DECI     = 8'h26;   // I = I - 1
	localparam			PP_MUL		= 8'h27; //W <= W * Var
	localparam        PP_SUB      = 8'h29; //W <= W - Var
	localparam			PP_SUBI		= 8'h31;   //I <= I - Var;
	localparam			PP_SHL		= 8'h33;	//W <= W << Var;
	localparam			PP_SHR		= 8'h35;	 //W <= W >> Var;
	//DDS related
	localparam			PP_DDSFRQ	= 8'h37; // set dds frequency
	localparam			PP_DDSAMP	= 8'h38;	// set dds amplitude
	localparam			PP_DDSPHS	= 8'h39;	// set dds phase
	localparam			PP_DDSCHN	= 8'h40;	// set dds channel	
	//AWG command
	localparam        PP_AWG		= 8'h41; //start AWG
	//Delay	
	localparam			PP_DELAY		= 8'h42;	//Delay Var cycles
	localparam        PP_WAITL    = 8'h44; //wait for line trigger
	//Counter	
	localparam			PP_COUNT		= 8'h45;	// Delay n cycles, adding photon counts to W
	localparam			PP_CNT2W    = 8'h47;	//W <= pmta_i - r_PMTRef, r_PMTLast <= pmta_i;
	localparam			PP_CNTD2W   = 8'h48;	//W <= pmta_i - r_PMTLast, r_PMTLast <= pmta_i;
	localparam        PP_ZCNT		= 8'h49;	//r_PMTRef <= pmta_i 
	//Time Ref
	localparam        PP_ZTS		= 8'h50; //r_TimeRef <= r_TimeStick
	localparam			PP_TS2W		= 8'h51; //W <= r_TimeStick - r_TimeRef
	//Digial Click command
	localparam			PP_SHUTTER  = 8'h52; // set shutter state	
	localparam			PP_DCLK		= 8'h53;	//rDCDelay_o <= Var
	localparam        PP_DSTEPH   = 8'h54; //rDCStep_o <= Var, rDCTrig_o <= 1;
	localparam			PP_DSTEPL   = 8'h55; //rDCStep_o <= Var, rDCTrig_o <= 1; but no real pulse out;
	//Pulse picker command
	localparam			PP_PPW		= 8'h56; // set pulse picker width
	localparam			PP_PPD		= 8'h57; // set pulse delay
	localparam			PP_PPT		= 8'h58; // send out trigger
	localparam			PP_PPR		= 8'h5A; // reset the pulse picker
	//DDS profile commands
	localparam 			PP_DDSMTYP  = 8'h60; // set modulation type
	localparam			PP_DDSPRF   = 8'h61; // write profile registers
   localparam 			PP_DDSMSTR 	= 8'h62;	// start modulation
	localparam			PP_DDSMSTP	= 8'h63; // stop modulation
	localparam			PP_DDSPSWT	= 8'h64; // switch the profile pin
	//end	
	localparam			PP_STOP		= 8'hFF;		 
	 
	 //processor states
	 localparam S_IDLE = 2'h0;
	 localparam S_EXE1 = 2'h1;		//Command ready, operand address ready, direct operand ready; query memory for operand
	 localparam S_EXE2 = 2'h2;		//operand ready, query memory for next command
	 localparam S_WAIT = 2'h3;
	 //localparam S_HWAIT = 3'h4;	//wait for one clock cycle only for hardware trigger
	 
	 reg [1:0] rCmpFlag = 2'b11;
	 localparam CF_EQ = 2'h0;
	 localparam CF_G  = 2'h1;
	 localparam CF_L  = 2'h2;	 
	 
	 //DDS commands
	 //The cards must follow following order
	//AD9959, AD9958, AD9910 ....
	localparam C_AD9959_0 			= 4'h0;
	localparam C_AD9959_1 			= 4'h1;
	localparam C_AD9910_0 			= 4'h2;
	localparam C_AD9910_1 			= 4'h3;
	localparam C_AWG					= 4'h8;
	localparam C_AWG9959_0 			= C_AD9959_0 + C_AWG;
	localparam C_AWG9959_1 			= C_AD9959_1 + C_AWG;
	localparam C_AWG9910_0 			= C_AD9910_0 + C_AWG;
	localparam C_AWG9910_1 			= C_AD9910_1 + C_AWG;
	 //9959/58
	 localparam	C_DDS_INIT 	= 5'h0;
	 localparam C_DDS_CH 	= 5'h1;
	 localparam C_DDS_FRQ 	= 5'h2;
	 localparam C_DDS_PH 	= 5'h3;
	 localparam C_DDS_AMP 	= 5'h4;
	 //extra
	 //1. select modulation mode
	 localparam C_DDS_MTYP  = 5'h6;
	 localparam C_DDS_MSTR  = 5'h7;
	 localparam C_DDS_MSTP  = 5'h8;
	
	 //9910
	 localparam C_DDSS_INIT	= 2'h3;
	 localparam C_DDSS_FRQ 	= 2'h2;
	 localparam C_DDSS_PHS 	= 2'h1;
	 localparam C_DDSS_AMP 	= 2'h0;
	 
	 reg rCntFlg;
	 reg [31:0] rLastCnt;
	 reg [31:0] rCurTS, rLastTS;

	 reg [1:0]	rState = S_IDLE;
	 wire[1:0]  wNextState;
	 reg [31:0] rW;
	 reg [15:0] rI;
	 reg [7:0]  rCmd;
	 wire[7:0]	wCmd;
	 reg [15:0] rCmdPnt, rCmdPntCache;
	 wire[15:0] wDataPnt;
	 reg [31:0] rLastOperand;
	 wire[31:0] wMemOperand;
	 reg [23:0] rDirOperand;
	 wire[31:0] wOperand;
	 reg [31:0] rDelayCnt;
	 
	 	 
	 wire wWait;
	 wire wHWTrig;
		
	 assign wBusy_o 		= rState != S_IDLE;
	 assign wWait 			= rDelayCnt != 0;
	 assign wCmd			= wMem_i[31:24];
	 
	 assign wMemWE_o 		= (rState == S_EXE1) && (wCmd == PP_STWR || wCmd == PP_STWI);
	 assign wMem_o 		= wCmd == PP_STINDF ? rI : rW;
	 assign wMemAddr_o 	= (rState == S_EXE1) ? wDataPnt : rCmdPnt;
	 
	 assign wDataPnt 		= (wCmd == PP_LDWI || wCmd == PP_STWI) ? rI : wMem_i[15:0];
	 assign wMemOperand		= (rState == S_EXE2) ? wMem_i : 32'b0;
	 //select between direct operand and normal operand (address)
	 assign wOperand		= rDirOperand[23] == 1'b1 ? {9'b0, rDirOperand[22:0]} : wMemOperand;
	 
	 assign wHWTrig		= rDDSTrig_o || rDCTrig_o || rPTrig_o;
	 
	 assign wCmd_o			= {rCmd, rDirOperand};
	 assign wData_o		= rLastOperand;
	 assign wState_o     = rState;
	 assign wW_o			= rW;
	 assign wI_o			= rI;
	 assign wCmdPnt		= rCmdPntCache;
	 
	 function [1:0] NEXT_STATE(input reset, input [1:0] CurState, input [7:0] Cmd, input StartTrig, input StopTrig, input LineTrig, input Debug, input Step, input HWTrig, input HWReady);
	 
	 if (StopTrig || reset)
		NEXT_STATE = S_IDLE;
	 else
		case (CurState)
			S_IDLE: NEXT_STATE = StartTrig ? S_WAIT : S_IDLE;
			
			S_EXE1: NEXT_STATE = S_EXE2;
			
			S_EXE2:  
				begin
					if (Cmd == PP_STOP)
						NEXT_STATE = S_IDLE;
					else
						if (Debug || Cmd == PP_DELAY || (~HWReady) || Cmd == PP_WAITL || Cmd == PP_COUNT || 
						Cmd == PP_DDSFRQ || Cmd == PP_DDSAMP || Cmd == PP_DDSPHS || Cmd == PP_DDSCHN || 
						Cmd == PP_DDSMTYP || Cmd == PP_DDSPRF || Cmd == PP_DDSMSTR || Cmd == PP_DDSMSTP ||
						Cmd == PP_AWG || 
						Cmd == PP_DSTEPH || Cmd == PP_DSTEPL ||
						Cmd == PP_PPT)
							NEXT_STATE = S_WAIT;
						else 						
							NEXT_STATE = S_EXE1;						
				end
			
			S_WAIT: 
				begin
					if (Debug)
						NEXT_STATE = Step ? S_EXE1 : S_WAIT;
					else
						if (Cmd == PP_WAITL)
							NEXT_STATE = LineTrig ? S_EXE1 : S_WAIT;
						else
							NEXT_STATE = (wWait || ~HWReady || HWTrig) ? S_WAIT : S_EXE1;
				end
			default: NEXT_STATE = S_IDLE;
		endcase;
	 endfunction;

	 assign wNextState = NEXT_STATE( wReset_i, rState, rCmd, wStartTrig_i, wStopTrig_i, wLineTrig_i, wDebug_i, wStepTrig_i, wHWTrig, wHWReady_i);
	 
	 
	 always @ (posedge wHClk_i) rCurTS <= rCurTS + 1;
	 
	 always @ (posedge wClk_i)
		begin
			if (wReset_i)
				begin				
					//DDS
					rDDSTrig_o 		<= 1'b0;
					rDDSBrdIdx_o 	<= 4'h0;
					rAD9959Cmd_o 	<= 0;
					rAD9959PIdx_o 	<= 0;
					rAD9910Cmd_o 	<= 0;	 
					//AWG
					rAWG9959StartAddr_o <= 0;
					rAWG9910StartAddr_o <= 0;
					//Digital clicks
					rDCTrig_o <= 0;
					rDCStep_o <= 0;
					rDCDelay_o <= 2;
					rDCHlvl_o <= 1;
					rDO_o <= 8'b0;
	 
					rW 		<= 0;
					rI 		<= 0;
					rDelayCnt <= 0;
					rCmd		<= 0;
					//Compare
					rCmpFlag <= 2'b11;
					
					rCmdPnt  		<= 16'hFFFF;
					rCmdPntCache 	<= 16'hFFFF;
					
					rCntFlg <= 0;
					rLastCnt <= 0;
					
					//rCurTS <= 0;
					rLastTS <= 0;
					
					rPulseDelay_o <= 8'b0;
					rPulseWidth_o <= 8'b1;
					rPTrig_o <= 1'b0;
					rPInit_o <= 1'b0;
					//
					rState <= S_IDLE;
				end
			else
				begin
					//rCurTS  <= rCurTS + 1;					
				   rState  <= wNextState;
					
					case (rState)
						S_IDLE:
							begin // zero all registors, which is not necessary
								rCmdPnt 		<= wStartAddr_i;
								rDelayCnt 	<= 0;
								
								rW				<= 0;
								rI				<= 0;
								rCntFlg  	<= 0;
								
								rDDSTrig_o <= 0;
								rDCTrig_o  <= 0;
								rPInit_o  <= 0;
							end
						
						S_EXE1:
							begin
								//trigger resets
								rDDSTrig_o <= 0;
								rDCTrig_o  <= 0;
								rPTrig_o <= 0;
								rPInit_o  <= 0;
								rCntFlg  <= 0;
								/////////////////////////////
								rCmd 			<= wMem_i[31:24];					//Store current command
								rDirOperand 	<= wMem_i[23:0]; 					//Store direct operand, it starts with a 1 at MSB		
								rCmdPnt  	<= ( wCmd == PP_JMP 			 ||	 
								(wCmd == PP_JMPZ  && rCmpFlag == CF_EQ) ||
								(wCmd == PP_JMPNZ && rCmpFlag != CF_EQ) ||
								(wCmd == PP_JMPG  && rCmpFlag == CF_G)  ||
								(wCmd == PP_JMPL  && rCmpFlag == CF_L)  ||
								(wCmd == PP_JMPGE && rCmpFlag != CF_L)  ||
								(wCmd == PP_JMPLE && rCmpFlag != CF_G)
								) ? wMem_i[15:0] : rCmdPnt + 16'h1;		//Move to next command								
							end								
						
						S_EXE2:
							begin
								rLastOperand <= wMemOperand;								
								case (rCmd)
									//Logic
									PP_STOP: ;
									PP_NOP:  ;
									PP_LDWR: 	rW <= wOperand;
									PP_LDINDF: 	rI <= wOperand[15:0];
									PP_LDWI:  	rW <= wOperand;
									PP_CLRW:  	rW <= 0;
									PP_CMP:   	rCmpFlag <= rW > wOperand ? CF_G : (rW < wOperand ? CF_L : CF_EQ);
									PP_CMPI:	rCmpFlag <= rI > wOperand[15:0] ? CF_G : (rI < wOperand[15:0] ? CF_L : CF_EQ);
									//Arithmetic
									PP_ANDW:  rW <= rW && wOperand;
									PP_ADDW:  rW <= rW + wOperand;
									PP_ADDI:  rI <= rI + wOperand[15:0];
									
									PP_INC:   rW <= wOperand == 0 ? (rW + 32'b1) : (wOperand + 32'b1); 			
									PP_INCI:  rI <= wOperand == 0 ? (rI + 16'b1) : wOperand[15:0] + 16'b1; 	
									PP_DEC:	  rW <= wOperand == 0 ? (rW - 32'b1) : wOperand - 32'b1;
									PP_DECI:  rI <= wOperand == 0 ? (rI - 16'b1)	: wOperand[15:0] - 16'b1;
									
									PP_MUL:   rW <= rW * wOperand;
									PP_SUB:   rW <= rW - wOperand;
									PP_SUBI:  rI <= rI - wOperand[15:0];
									PP_SHL:   rW <= rW << wOperand;
									PP_SHR:   rW <= rW >> wOperand;									
									//DDS
									PP_DDSCHN:
										begin
											rDDSBrdIdx_o <= rDirOperand[7:4];
											rAD9959Cmd_o <= {C_DDS_CH, 28'b0, rDirOperand[3:0]};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSFRQ:
										begin										
											rAD9959Cmd_o <= {C_DDS_FRQ, wMemOperand};
											rAD9910Cmd_o <= {C_DDSS_FRQ, wMemOperand};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSAMP:
										begin
											rAD9959Cmd_o <= {C_DDS_AMP, 22'b0, wMemOperand[9:0]};
											rAD9910Cmd_o <= {C_DDSS_FRQ, 18'b0, wMemOperand[13:0]};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSPHS:
										begin
											rAD9959Cmd_o <= {C_DDS_PH, 18'b0, wMemOperand[13:0]};
											rAD9910Cmd_o <= {C_DDSS_PHS, 16'b0, wMemOperand[15:0]};
											rDDSTrig_o 	 <= 1;
										end
									
									//profile pins
								   PP_DDSMTYP: //Configure modulation channel and type
										begin										
											rAD9959Cmd_o <= {C_DDS_MTYP, 30'b0, rDirOperand[1:0]};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSMSTR: //Start the modulation
										begin
											rAD9959Cmd_o <= {C_DDS_MSTR, 32'b0};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSPRF: //Write to the profile registor
										begin
											rAD9959Cmd_o  <= {rDirOperand[20:16], wOperand[31:0]};
											rDDSTrig_o 	  <= 1;
										end
									PP_DDSMSTP:
										begin
											rAD9959Cmd_o <= {C_DDS_MSTP, 32'b0};
											rDDSTrig_o 	 <= 1;
										end
									PP_DDSPSWT:	//swtich the profile
										rAD9959PIdx_o <= wOperand[3:0];
									//AWG
									PP_AWG:
										begin
											rDDSBrdIdx_o 				<= rDirOperand[19:16] + C_AWG;
											rDDSTrig_o 					<= 1'b1;
											rAWG9959StartAddr_o 		<= wMemOperand[15:0];
											rAWG9910StartAddr_o     <= wMemOperand[15:0];
										end
									//Counter
									PP_COUNT:
										begin
											rDelayCnt <= wOperand;
											rW <= 0;
											rCntFlg <= 1;
										end
									PP_ZCNT: rLastCnt <= wPMTA_i;
									PP_CNT2W: rW <= wPMTA_i;
									PP_CNTD2W: rW <= wPMTA_i - rLastCnt;
									//digital click
									PP_DCLK: rDCDelay_o <= wOperand[15:0];
									PP_DSTEPH:
										begin
											rDCStep_o <= wOperand[15:0];
											rDCTrig_o <= 1'b1;
											rDCHlvl_o <= 1'b1;
										end
									PP_DSTEPL:
										begin
											rDCStep_o <= wOperand[15:0];
											rDCTrig_o <= 1'b1;
											rDCHlvl_o <= 1'b0;
										end
									//time stamp
									PP_ZTS:	rLastTS <= rCurTS;
									PP_TS2W: rW <= rCurTS - rLastTS;
									//DIO
									PP_SHUTTER: rDO_o <= wOperand[7:0];
									//DELAY
									PP_DELAY: rDelayCnt <= wOperand > 4 ? (wOperand - 4) : 0;
									//Pulse picker
									PP_PPW:	rPulseWidth_o <= wOperand[7:0];
									PP_PPD:  rPulseDelay_o <= wOperand[7:0];
									PP_PPT:  rPTrig_o		  <= 1;						
									PP_PPR:  rPInit_o	     <= 1;
									default:	;
								endcase
							end
						
						S_WAIT: 	
							begin
								rDDSTrig_o <= 0;
								rDCTrig_o  <= 0;
								rPTrig_o   <= 0;
								rPInit_o  <= 0;
								
								rDelayCnt <= wWait ? rDelayCnt - 1 : 0;
								
								rW <= rCntFlg ? rW + {31'b0, wPMT_i} : rW;
								rCmdPntCache <= wNextState != S_WAIT ? rCmdPnt : rCmdPntCache;
							end
						default:;
					endcase
				end				
		end
endmodule
