`timescale 1ns / 1ps
`include  "correlator.v"
`include  "CLK_TICK.v"
`include  "PPCORE.v"
`default_nettype none


//////////////////////////////////////////////////////////////////////////////////
// SilverDDS firmware for XEM6 devices
// Support AD9959 and AD9910 cards
//	G. Shu, Gatech 2015.9
//////////////////////////////////////////////////////////////////////////////////
`define CC_DIO_NUM	7

module XICO(
	input  wire [7:0]  	               hi_in,
	output wire [1:0]  	               hi_out,
	inout  wire [15:0] 	               hi_inout,
   
	//input  wire 								wExClk0_i,				//for PP
	//input  wire									wExClk1_i,				//for DDS
	output wire [7:0]  	            	wLed_o,
	inout	 wire	[`CC_DIO_NUM - 1:0]		wDIO_io,
	input  wire 		                	pmt_in,
	input  wire         						ltrig_in,
	//for TAC
	input  wire									sync_in,
	
	//AD9959 X 2
	output wire [7:0] 	                wAD9959SPI0_o,	   //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0}
	output wire [3:0]							 wProfile0_o,
	output wire [7:0] 	                wAD9959SPI1_o,	   //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0}
	//AD9910 X 2
	output wire [1:0]							 wAD9910SPI_o,     	//{SCLK, SDIO};
	output wire [1:0]							 wAD9910CS_o,
	output wire [1:0]							 wAD9910IOU_o,
	output wire [1:0]							 wAD9910Reset_o,	
	output wire [3:0]							 wAD9910Profile0_o,
	output wire [3:0]							 wAD9910Profile1_o,
	
	//AWG9910
	output wire [17:0]						 wAWG9910PData_o,
	output wire [1:0]							 wAWG9910TxEnable_o,
		
	output wire			                	hi_muxsel,
	output wire			                	i2c_sda,
	output wire			                	i2c_scl,
	
	//PLL board, black dds only
	output wire									pll_sdo,
	output wire									pll_sclk,
	output wire									pll_le,
	
	//Push buttoms for debug
	input wire [3:0]							button,
	
	//test trigger
	output wire									wTestTrig0_o,
	output wire									wTestTrig1_o,
	//Pulse picker ports
	input  wire									wRegPulse_i,
	output wire									wPulseMon_o,
	input  wire									wExPTrig_i,
	output wire									wPOut_o
);

localparam C_MADDR_WIDTH = 14;

//firmware version
localparam FW_VER_DATE = 32'd20160808;
localparam FW_VER_TIME = 32'd006600;
localparam C_VAL_DDSCLK = 32'd60;
localparam C_VAL_PPCLK = 32'd60;

//PC communication
localparam C_SYS = 8'h0;
	localparam C_SYS_RESET 		= 8'h0;
	localparam C_SYS_PPCLK 		= 8'h1;
	localparam C_SYS_FWVER 		= 8'h2;
	localparam C_SYS_FWDATE 	= 8'h3;
	localparam C_SYS_MODULE 	= 8'h4;
	localparam C_SYS_FWTIME		= 8'h5;
	localparam C_SYS_D9958     = 8'h6;
	localparam C_SYS_D9959     = 8'h7;
	localparam C_SYS_D9910     = 8'h8;
	localparam C_SYS_DDSCLK    = 8'h9;
	
localparam C_PPL = 8'h1;
	localparam C_PPL_RESET 		= 8'h0;
	localparam C_PPL_ADDR  		= 8'h1;
	localparam C_PPL_WRITE 		= 8'h2;
	localparam C_PPL_READ  		= 8'h3;
	
localparam C_PPC = 8'h2;
	localparam C_PPC_STOP 		= 8'h0;
	localparam C_PPC_START 		= 8'h1;
	localparam C_PPC_STATUS 	= 8'h2;
	//PPC debug
	localparam C_PPC_DEBUG     = 8'h3;
	localparam C_PPC_STEP		= 8'h4;
	localparam C_PPC_CMD       = 8'h5;
	localparam C_PPC_DATA      = 8'h6;
	localparam C_PPC_W			= 8'h7;
	localparam C_PPC_I         = 8'h8;
	localparam C_PPC_CMDP		= 8'h9;
	//PPC memory information
	localparam C_PPC_SADDR		= 8'ha;
	localparam C_PPC_MADDR     = 8'hb;
	localparam C_PPC_MOUT		= 8'hd;
	localparam C_PPC_MIN			= 8'he;
	//Read memory
	localparam C_PPC_MRADDR		= 8'h10;
	//DDS related command
	 localparam C_PPC_DDSIDX = 8'h11;
	 localparam C_PPC_DDSCMD = 8'h12;
	 localparam C_PPC_DDSDAT = 8'h13;
	 localparam C_PPC_DDSPIDX = 8'h14;
	 localparam C_PPC_DDSSCMD = 8'h15;
	 localparam C_PPC_DDSSDAT = 8'h16;
	 
	localparam C_PPC_RESET 		= 8'hEE;
	
localparam C_DIG = 8'h3;
	localparam C_DIG_WRITE 		= 8'h1;
	localparam C_DIG_READ  		= 8'h2;
	
localparam C_DDS = 8'h4;
	localparam C_DDS_RESET 		= 8'hEE;
	localparam C_DDS_INIT 		= 8'h00;
	localparam C_DDS_CH 			= 8'h01;
	localparam C_DDS_FRQW 		= 8'h02;
	localparam C_DDS_PHW 		= 8'h03;
	localparam C_DDS_AMPW 		= 8'h04;
	localparam C_DDS_MPD 		= 8'h05;
	
	localparam C_DDS_MTYP		= 8'h06;
	localparam C_DDS_MSTR	   = 8'h07;
	localparam C_DDS_MSTP      = 8'h08;
	localparam C_DDS_SWT			= 8'h09;
	
	localparam C_DDS_FRQR 		= 8'h12;
	localparam C_DDS_PHR 		= 8'h13;
	localparam C_DDS_AMPR 		= 8'h14;
	
localparam C_CNT = 8'h5;
	localparam C_CNT_SETEXP 	= 8'h01;
	localparam C_CNT_GETCNT 	= 8'h02;
	
localparam C_TAC = 8'h6; //C_TAC command format [7:4] read or write, [3:0] item type
	localparam C_TAC_READ 		= 4'h0;
	localparam C_TAC_R_TS 		= 4'h1;
	localparam C_TAC_R_TPMT 	= 4'h2;
	localparam C_TAC_R_TLPMT 	= 4'h3;
	localparam C_TAC_R_TSYNC 	= 4'h4;
	localparam C_TAC_R_TLSYNC 	= 4'h5;
	localparam C_TAC_R_TDIFF  	= 4'h6;
	localparam C_TAC_R_PADDR	= 4'h7;
	localparam C_TAC_R_HIST   	= 4'h8;
	localparam C_TAC_R_LOCK   	= 4'h9;
	localparam C_TAC_R_PCNT   	= 4'ha;
	localparam C_TAC_R_SCNT   	= 4'hb;
	localparam C_TAC_WRITE 		= 4'h1;
	localparam C_TAC_W_PADDR  	= 4'h1;
	localparam C_TAC_PMT_RST   = 4'h2;
	localparam C_TAC_ADDR_RST  = 4'h3;
	
localparam C_YAG = 8'h7;
	localparam C_YAG_TRIG      = 8'h0;
	localparam C_YAG_DELAY     = 8'h1;
	
localparam C_PLL = 8'h8;
	localparam C_PLL_R  			= 8'h1;
	localparam C_PLL_C  			= 8'h2;
	localparam C_PLL_N  			= 8'h3;
	localparam C_PLL_T  			= 8'h4;
	localparam C_PLL_D  			= 8'h0;
	
localparam C_PULSE = 8'h9;
	localparam C_PULSE_INIT		= 8'h0;
	localparam C_PULSE_DELAY   = 8'h1;
	localparam C_PULSE_WIDTH   = 8'h2;
		
//DDS commands
//9959
localparam CMD_D9959_INIT		= 5'h0;
localparam CMD_D9959_CH 		= 5'h1;
localparam CMD_D9959_FRQ 		= 5'h2;
localparam CMD_D9959_PHS 		= 5'h3;
localparam CMD_D9959_AMP 		= 5'h4;
//9910
localparam CMD_D9910_INIT		= 2'h3;
localparam CMD_D9910_FRQ 		= 2'h2;
localparam CMD_D9910_PHS 		= 2'h1;
localparam CMD_D9910_AMP 		= 2'h0;

//DDS card index
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

//TAC command
localparam S_INIT 				= 2'h0;
localparam S_WAIT 				= 2'h1;
localparam S_TACWAIT 			= 2'h2;

//////////////////////////////////////////////////////////////////////////////////
// Opal Kelly Wires
//////////////////////////////////////////////////////////////////////////////////
wire 				sync_locked;		
wire [30:0]		ok1;
wire [16:0]		ok2;
wire [15:0]		WireInCmd, WireInParam, WireInDataL, WireInDataH;
wire [15:0]    WireOutDataL, WireOutDataH;
wire [15:0]		TrigIn40;
	
//clocks
wire				wPPClk, wUsbClk, wDDSClk;
//reset wires
wire				wPwrOnReset, wHostReset, wReset;
//PLL
reg [23:0]  	rPllR = 24'h300c9, 
					rPllC = 24'h4ff900, 
					rPllN = 24'h413822;
reg 				rPllTrig = 0;

//digital click
wire [15:0] 	wDCStep, wDCDelay;
wire 				wDCTrig, wDCOut, wDCHlvl, wDCReady;
//pp core
wire				wPPActive;
reg				rPPStartTrig 	= 0;
reg				rPPStopTrig  	= 0;
reg				rPPDebug 		= 0;
reg				rPPStepTrig		= 0;
wire [31:0]		wPPCmd;
wire [3:0]		wPPState;
wire [31:0]		wPPData;
wire [31:0]		wPPW;
wire [15:0]		wPPI;
wire [15:0]		wPPCmdP;
reg	[15:0]	rPPStartAddr 	= 0;
reg				rPPReset			= 0;
reg	[16:0]	rHostMemAddr	= 0;

wire				pp_tzero;
wire [C_MADDR_WIDTH - 1 : 0]		wPP_PC;
		
//Digital IO
reg  [7:0]		rHostShutter = 0;
wire [7:0]		wDigiIO;


//DDS
//trigger and address controls
reg  			rDDSTrig_host = 0;
wire 			wDDSTrig_pp;
wire  		wLDDSTrig_pp;
wire			wDDSTrig;
wire 	[3:0]	wDDSBrdIdx_pp;
reg	[3:0]	rDDSBrdIdx_host = 0;

//AD9958/59
reg [31:0]	rAD9959Data_host = 0;
reg [5:0]	rAD9959Cmd_host = 0;
reg			rAD9959Reset_host = 0;

wire [31:0]	wAD9959Data_pp;
wire [4:0]	wAD9959Cmd_pp;

wire [31:0]	wAD9959Data;
wire [3:0]  wDDSBrdIdx;
wire [4:0]	wAD9959Cmd;
wire [3:0]  wAD9959PIdx;

wire [1:0]	wAD9959Ready;

//AD9910
reg [33:0] 	rAD9910Cmd_host = 0;
reg			rAD9910Reset_host = 0;

wire [33:0]	wAD9910Cmd_pp;
wire [33:0]	wAD9910Cmd;

wire [1:0]	wAD9910Ready;

//awg
wire [15:0] 	wAWG9959Addr0,	wAWG9959Addr1; 
wire [7:0]  	wAD9959SPI0, wAD9959SPI1;
wire [1:0]		wAWG9959Ready;

wire [15:0]		wAWG9910Addr;
wire [7:0]		wAWG9959SPI0, wAWG9959SPI1;
wire [1:0]		wAWG9910Ready;

wire [15:0] 	wMemAddr_Host, wAWG9959StartAddr, wAWG9910StartAddr;


wire [2:0]		wHWReady; //0 for dds, 1 for dc and pulse picker, 2 for awg

//photon counter
wire			wPmt;
//pp memory
wire [15: 0]	wPPAddr; 			//address from PPCore
wire [15: 0]	host_addr_in, host_addr_out;			//pipeline address
wire [31:0]		host_din, host_dout, mem_outb, mem_inb;		
wire				pp_web, host_wea;
//Host read and write wires
reg 				rPPLReset = 0;
reg  [15:0] 	rPPLStartAddr = 0;
wire [15:0]		PipeInData, PipeOutData;
wire				PipeInWrite, PipeOutRead;
//photon correlator
wire 				w_PCStart, w_PCDone, w_PCBright;
wire [1:0]  	w_PCArrival;
wire [31:0] 	w_PCTao1, w_PCTao2;
wire [31:0] 	w_PCTimeSpan;
//PMT counter for real time monitoring
reg  [31:0] 	rExpTime = 32'd15_000_000;
wire [31:0] 	wPmtCnt;
wire [31:0]		wPmtACnt;
//PC Communication
reg  [1:0]		rPCCState = S_INIT;
reg  [31:0] 	rDataOut  = 0;
reg  [63:0]		rLastCmd = 64'h1234567812345678;
//TAC
reg 				rTacCmdTrig = 0, 
					rTacPmtRst = 0, 
					rTacAddrRst = 0;
reg  [15:0]		rTacCmd = 0, 
					rTacData = 0;
wire [15:0] 	wTacData0, wTacData1;
//YAG Laser controller
reg  [31:0] 	rYAGDelay = 32'd3600;
reg 				rYAGTrig = 0;
reg  [31:0] 	rTest = 0;
//pulse picker
reg  [7:0] 		rPulseDelayHost = 0;
wire [7:0]		wPulseDelayPP;
wire [7:0]		wPulseDelay;

reg  [7:0]  	rPulseWidthHost = 1;
wire [7:0]		wPulseWidthPP;
wire [7:0]		wPulseWidth;

wire 				wPTrigPP;
wire				wPTrig;

reg 				rPInit = 0;
wire				wPInitPP;
wire				wPInit;
wire				wPReady;

// OK required assigns
assign hi_muxsel 	= 1'b0;
assign i2c_sda 	= 1'bz;
assign i2c_scl 	= 1'bz;

// Power on reset high for 16 clock cycles
SRL16 #(.INIT(16'hFFFF)) reset_sr (.D(1'b0), .CLK(wUsbClk), .Q(wPwrOnReset),
									.A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
									
//clocks
//48 MHz USB clock speed for normal operations
//24 MHz, half USB speed for boxes with isolation chips
wire wClk300;
wire wBrdPllLocked;

assign wPPClk  = wDDSClk;
//assign wDDSClk = wUsbClk;

CLK_MNGR clk_mngr
 (.CLK_IN(wUsbClk),
  .CLK_300(wClk300),
  .CLK_060(wDDSClk),
  .RESET(wReset),
  .LOCKED(wBrdPllLocked));

assign	wHostReset 	= TrigIn40[0];
assign	wReset 		= wPwrOnReset | wHostReset;	
assign 	{WireOutDataH, WireOutDataL} = rDataOut;

/////////////////////////////////////////////////////////////////////////
// Host command loop
/////////////////////////////////////////////////////////////////////////
always @ (posedge wUsbClk)
	begin
		if (wReset)
			begin
				rPCCState <= S_INIT;
				rDataOut <= 32'b0;
				rPPStopTrig <= 0;
				rPPStartTrig <= 0;
				rPPStartAddr <= 0;
				rPPDebug <= 0;
				rPPStepTrig <= 0;
				rPPReset <= 0;
				
				rExpTime <= 32'd15_000_000;
				//AD9959
				rDDSTrig_host <= 0;
				//TAC
				rTacCmdTrig <= 0;
				rTacPmtRst <= 0;
				rTacAddrRst <= 0;
				
				rYAGDelay <= 32'd3600;
				rYAGTrig <= 0;
				rTest <= 0;
				
				//PLL default values
				rPllR <= 24'h300c9;
				rPllC <= 24'h4ff900;
				rPllN <= 24'h413822;
				rPllTrig <= 0;
				//pulse picker
				rPInit <= 0;
				rPulseWidthHost <= 1;
				
				rLastCmd <= 64'h1234567812345678;
			end
		else
			case (rPCCState)
				S_INIT:
					begin
						if (TrigIn40[1]) // command trigger
							begin
								rLastCmd <= {WireInCmd[15:0], WireInParam[15:0], WireInDataH[15:0], WireInDataL[15:0]};
								case (WireInCmd[15:8]) //command group
									C_SYS:
										begin
											case (WireInCmd[7:0])
												C_SYS_RESET: rDataOut <= 0;
												C_SYS_PPCLK: rDataOut <= C_VAL_PPCLK;
												C_SYS_D9958: rDataOut <= {8'h0, 8'h2, 16'd500};
												C_SYS_D9959: rDataOut <= {8'h2, 8'h4, 16'd500};
												C_SYS_D9910: rDataOut <= {8'h2, 8'h1, 16'd1000};
												C_SYS_DDSCLK: rDataOut <= C_VAL_DDSCLK;
												C_SYS_FWVER: rDataOut <= 32'd1006;
												C_SYS_FWDATE: rDataOut<= FW_VER_DATE; 	// date
												C_SYS_MODULE: rDataOut<= 32'b11111; 	//available module
												C_SYS_FWTIME: rDataOut <= FW_VER_TIME;
											endcase
										end
									C_PLL:
										begin
											case (WireInCmd[7:0])
												C_PLL_R:
													begin
														rDataOut <= {8'h0, rPllR};
														rPllR <= {WireInDataH[7:0], WireInDataL[15:0]};
													end
												C_PLL_C:
													begin
														rDataOut <= {8'h0, rPllC};
														rPllC <= {WireInDataH[7:0], WireInDataL[15:0]};
													end
												C_PLL_N:
													begin
														rDataOut <= {8'h0, rPllN};
														rPllN <= {WireInDataH[7:0], WireInDataL[15:0]};
													end
												C_PLL_T:
													begin
														rDataOut <= 32'b0;
														rPllTrig <= 1;
														rPCCState <= S_WAIT;
													end
												C_PLL_D:
													begin
														rPllR <= 24'h300c9;
														rPllC <= 24'h4ff900;
														rPllN <= 24'h413822;
														rDataOut <= 32'b0;
														rPllTrig <= 1;
														rPCCState <= S_WAIT;
													end													
												default: rDataOut <= 32'hFFFFFFFF;  	//wrong command
											endcase
										end
									C_PPL:
										begin
											case (WireInCmd[7:0])
												C_PPL_RESET:
													begin
														rPPLReset <= 1'b1;
														rPCCState <= S_WAIT;
														rPPLStartAddr <= 16'b0;
													end
												C_PPL_ADDR:
													begin
														rPPLReset <= 1'b1;
														rPCCState <= S_WAIT;
														rPPLStartAddr <= WireInDataL;
														rDataOut <= {16'b0, WireInDataL};
													end
												default: ;
											endcase
										end
									C_PPC:
										begin
											case(WireInCmd[7:0])
												C_PPC_STOP:
													begin
														rPPStopTrig <= 1'b1;
														rPCCState <= S_WAIT;
													end
												C_PPC_START:
													begin
														rPPStartTrig <= 1'b1;
														rPCCState <= S_WAIT;
													end
												C_PPC_STATUS:	rDataOut <= {2'b0, wPPState, wPPAddr[13:0], wPPCmd[31:24], wHWReady, wPPActive};
												C_PPC_DEBUG: 	rPPDebug <= | WireInDataL;
												C_PPC_STEP:
													begin
														rPPStepTrig <= 1;
														rPCCState <= S_WAIT;
													end
												C_PPC_CMD   :  rDataOut <= wPPCmd;
												C_PPC_DATA  :  rDataOut <= wPPData;
												C_PPC_W		:  rDataOut <= wPPW;
												C_PPC_I     :	rDataOut <= {16'b0, wPPI};	
												C_PPC_CMDP  :  rDataOut <= {16'b0, wPPCmdP};
												C_PPC_SADDR :  rPPStartAddr <= WireInDataL;
												C_PPC_MADDR :	rDataOut <= {pp_web, 15'b0, wPPAddr};
												C_PPC_MRADDR:  rHostMemAddr <= {|WireInDataH, WireInDataL};
												C_PPC_MOUT :  	rDataOut <= mem_outb;
												C_PPC_MIN:  	rDataOut <= mem_inb;
												//DDS related
												C_PPC_DDSIDX : rDataOut <= {28'b0, wDDSBrdIdx_pp};
												C_PPC_DDSCMD : rDataOut <= {27'b0, wAD9959Cmd_pp};
												C_PPC_DDSDAT : rDataOut <= wAD9959Data_pp;
												C_PPC_DDSPIDX : rDataOut <= {28'b0, wAD9959PIdx};
												C_PPC_DDSSCMD : rDataOut <= {30'b0, wAD9910Cmd_pp[33:32]};
												C_PPC_DDSSDAT : rDataOut <= wAD9910Cmd_pp[31:0];
												
												C_PPC_RESET:
													begin
														rPPReset <= 1;
														rPCCState <= S_WAIT;
													end
											endcase
										end
									C_DIG:
										begin
											case(WireInCmd[7:0])
												C_DIG_WRITE:
													rHostShutter <= WireInDataL[7:0];
												C_DIG_READ:
													rDataOut[7:0] <= rHostShutter;													
											endcase
										end
									C_DDS: //for both 9959 and 9910
										begin		
											rDataOut				<= {8'b1, wDDSBrdIdx, 4'b0, 
											4'b0, wAWG9910Ready[1], wAWG9910Ready[0], wAWG9959Ready[1], wAWG9959Ready[0],
											4'b0, wAD9910Ready[1],  wAD9910Ready[0],  wAD9959Ready[1],  wAD9959Ready[0]};
											rPCCState 			<= S_WAIT;
											//Only RESET, INIT and CH contains board and channel information
											//Board: WireInDataL[7:4]
											//Channel: WireInDataL[3:0]
											case(WireInCmd[7:0])
												C_DDS_RESET:
													begin
														rDDSBrdIdx_host 	<= WireInDataL[7:4];
														rAD9959Reset_host <= 1'b1;															
														rAD9959Data_host 	<= 32'b0;									
														rAD9910Reset_host <= 1'b1;																											
													end
												C_DDS_INIT:
													begin
														rDDSBrdIdx_host 	<= WireInDataL[7:4];
														rAD9959Cmd_host 	<= CMD_D9959_INIT;															
														rAD9910Cmd_host 	<= {CMD_D9910_INIT, 32'h0};
														rDDSTrig_host 	<= 1'b1;
													end
												C_DDS_CH:
													begin
													   rAD9959Cmd_host 	<= CMD_D9959_CH;
														rDDSBrdIdx_host 	<= WireInDataL[7:4];
														rAD9959Data_host 	<= {28'b0, WireInDataL[3:0]};
														rDDSTrig_host 	<= 1'b1;																		
													end
												C_DDS_FRQW:
													begin
														rAD9959Cmd_host 	<= CMD_D9959_FRQ;
														rAD9959Data_host 	<= {WireInDataH, WireInDataL};																
														rAD9910Cmd_host 	<= {CMD_D9910_FRQ, WireInDataH, WireInDataL};
														rDDSTrig_host 	<= 1'b1;																											
													end
												C_DDS_PHW:
													begin														
														rAD9959Cmd_host 	<= CMD_D9959_PHS;
														rAD9959Data_host 	<= {WireInDataH, WireInDataL};															
														rAD9910Cmd_host <= {CMD_D9910_PHS, 16'h0, WireInDataL};
														rDDSTrig_host 	<= 1'b1;													
													end
												C_DDS_AMPW:
													begin
														rAD9959Cmd_host 	<= CMD_D9959_AMP;
														rAD9959Data_host 	<= {WireInDataH, WireInDataL};
														rAD9910Cmd_host 	<= {CMD_D9910_AMP, 18'b0, WireInDataL[13:0]};		
														rDDSTrig_host 	<= 1'b1;														
													end
												C_DDS_MPD:
													 begin		
														rAD9959Cmd_host 	<= WireInCmd[3:0];
														rDDSTrig_host 	<= 1'b1;
													end
												C_DDS_FRQR:	;													
												C_DDS_PHR:	;													
												C_DDS_AMPR:	;													
											endcase
										end
										
									C_CNT:
										begin
											case(WireInCmd[7:0])
												//C_CNT_SETEXP:	rExpTime <= {WireInDataH, WireInDataL};
												C_CNT_GETCNT:	rDataOut <= wPmtCnt; 
											endcase
										end
									C_TAC:
										begin
											case (WireInCmd[7:4])
												C_TAC_PMT_RST:	 rTacPmtRst <= 1;		
												C_TAC_ADDR_RST: rTacAddrRst <= 1;
												C_TAC_R_LOCK:   rDataOut[0] <= wBrdPllLocked;
												default:
													begin
														rTacCmd = {WireInCmd[7:4], 8'h0, WireInCmd[3:0]};
														rTacData <= WireInDataL;
														rTacCmdTrig <= 1'b1;														
													end
											endcase
											rPCCState <= S_TACWAIT;
										end
									C_YAG:
										begin
											case (WireInCmd[7:0])
												C_YAG_TRIG:	 	rYAGTrig <= 1;
												C_YAG_DELAY:	rYAGDelay <= {WireInDataH, WireInDataL};
												default:;
											endcase
											rDataOut <= rYAGDelay;
											rPCCState <= S_WAIT;
										end
									C_PULSE:
										begin
											case (WireInCmd[7:0])
												C_PULSE_INIT:	
													begin
														rPInit 	<= 1;
														rPCCState 	<= S_WAIT;
													end
												C_PULSE_DELAY:	rPulseDelayHost <= WireInDataL[7:0];
												C_PULSE_WIDTH: rPulseWidthHost <= WireInDataL[7:0];
											endcase
											rDataOut <= {16'b0, rPulseDelayHost, rPulseWidthHost}; 
										end
									default:
										begin
											rDataOut <= 32'hFFFF;
										end
								endcase
							end
						else
							;
					end
				S_TACWAIT:
					begin
						rDataOut <= {wTacData1, wTacData0};
						rTacCmdTrig <= 1'b0;
						rTacPmtRst <= 0;
						rTacAddrRst <= 0;
						rPCCState <= S_INIT;
					end
				S_WAIT:
					begin
						rYAGTrig <= 0;
						rPllTrig <= 0;
						rPPStopTrig <= 0;
						rPPStartTrig <= 0;
						rPPStepTrig <= 0;
						
						rDDSTrig_host <= 0;
						
						rPCCState <= S_INIT;
						rPPLReset <= 0;
						rAD9959Reset_host <= 0;						
						rAD9910Reset_host <= 0;						
						rPPReset <= 0;			
							
						rPInit <= 0;
					end
				
			endcase	
	end

assign wTestTrig0_o = rYAGTrig || rPllTrig || rPPStopTrig || rPPStartTrig || rPPStepTrig || rDDSTrig_host || wDDSTrig;

/////////////////////////////////////////////////////////////////////////
//Pulse Picker
/////////////////////////////////////////////////////////////////////////
assign wPTrig = wPPActive ? wPTrigPP : wExPTrig_i;
assign wPulseDelay = wPPActive ? wPulseDelayPP : rPulseDelayHost;
assign wPulseWidth = wPPActive ? wPulseWidthPP : rPulseWidthHost; 
assign wPInit	= wPPActive ? wPInitPP : rPInit;

PULSE_PICKER pulse_picker(
    .wRegPulse_i(wRegPulse_i),  //pulses regulated by comparator
    .wDelay_i(wPulseDelay),     //delay between the output pulse and the pulse
	 .wTrig_i(wPTrig),				 	
	 .wWidth_i(wPulseWidth),	  //width of the pulse
    .wOutput_o(wPOut_o),			  //output
    .wReset_i(wReset),
	 .wInit_i(wPInit),       //extra initialization in case of losing pulses
	 .wMonitor_o(wPulseMon_o),
	 .wReady_o(wPReady)
);
/////////////////////////////////////////////////////////////////////////
// PLL control, used only by USB
/////////////////////////////////////////////////////////////////////////
ADF4360 pll
(
	.reset_i(wReset), 
	.clk_i(wUsbClk), 
	.trig_i(rPllTrig),  
	.R_i(rPllR), 
	.C_i(rPllC), 
	.N_i(rPllN), 
	.sdata_o(pll_sdo), 
	.clk_o(pll_sclk), 
	.le_o(pll_le)
);
						
/////////////////////////////////////////////////////////////////////////
// photon counter signal input conditioning
/////////////////////////////////////////////////////////////////////////
PMT_CNT u_pmt_cnt
(
.wPmt_i(pmt_in),
.wHClk_i(wClk300),
.wLClk_i(wPPClk),
.wExpTime_i(rExpTime), 
.wPmt_o(wPmt), //pp core
.wPmtCnt_o(wPmtCnt),
.wPmtACnt_o(wPmtACnt) //pp core
//.wReset_i(wReset)
);

/////////////////////////////////////////////////////////////////////////
// PP memory and pipes
// Memory is 32bits wide, 16000 deep
// Pipes connect it to the FPGA
/////////////////////////////////////////////////////////////////////////
//Pipeline memory controller
pipe_in ppl_in(.wea_i(PipeInWrite), .data16_i(PipeInData), .clk_i(wUsbClk), .saddr_i(rPPLStartAddr), .restart_i(rPPLReset), .data32_o(host_din), .addr_o(host_addr_in), .wea_o(host_wea));
pipe_out ppl_out(.addr_o(host_addr_out), .data16_o(PipeOutData), .data32_i(host_dout), .saddr_i(rPPLStartAddr), .rea_i(PipeOutRead), .restart_i(rPPLReset), .clk_i(wUsbClk));
// Memory
wire [15:0] wAWGMemAddr;
assign wAWGMemAddr = (&wAWG9910Ready) ? (wAWG9959Ready[0] ? wAWG9959Addr1 : wAWG9959Addr0) : wAWG9910Addr;
assign wMemAddr_Host = wPPActive ? wAWGMemAddr : (PipeOutRead ? host_addr_out : host_addr_in);

wire [15:0] wAddrB;
assign wAddrB = rHostMemAddr[16] ? rHostMemAddr[15:0] : wPPAddr[15:0];

ppmem_xem6 ppmem(.clka(wUsbClk), .addra(wMemAddr_Host[C_MADDR_WIDTH - 1 : 0]), .dina(host_din), .douta(host_dout), .wea(host_wea),
	.addrb(wAddrB[C_MADDR_WIDTH - 1 : 0]), .dinb(mem_inb), .doutb(mem_outb), .web(pp_web),	.clkb(wPPClk));

/////////////////////////////////////////////////////////////////////////
// Photon time stamp and correlator
/////////////////////////////////////////////////////////////////////////
//MCorrelator correlator(
// .i_Stop(rPPStopTrig),
// .i_Start(w_PCStart),				
// .i_PmtSource(pmt_in),
// .i_clk(wPPClk),
// .i_Tao1(w_PCTao1),
// .i_Tao2(w_PCTao2),
// .r_TimeSpan(w_PCTimeSpan),
// .r_Done(w_PCDone),
// .r_Bright(w_PCBright),
// .r_Arrival(w_PCArrival)
// );

/////////////////////////////////////////////////////////////////////////
// trigger simulation
/////////////////////////////////////////////////////////////////////////
//localparam sim_delay_depth = 32;
//reg   sim_ltrig_in;
//reg [sim_delay_depth - 1 : 0]   sim_div;
//
//always @ (posedge wPPClk)
//begin
//	sim_div <= sim_div + 1;
//	sim_ltrig_in <= sim_div[sim_delay_depth - 1];
//end

/////////////////////////////////////////////////////////////////////////
// Pulse Programmer 
/////////////////////////////////////////////////////////////////////////
PPCORE ppcore(
	 .wReset_i(wReset | rPPReset),
    .wClk_i(wPPClk),
	 .wHClk_i(wClk300),
	 .wStartAddr_i(rPPStartAddr),
    .wStartTrig_i(rPPStartTrig),
    .wStopTrig_i(rPPStopTrig),
	 .wBusy_o(wPPActive),
    //debug
	 .wDebug_i(rPPDebug),
    .wStepTrig_i(rPPStepTrig),
	 .wCmd_o(wPPCmd),
	 .wData_o(wPPData),
	 .wState_o(wPPState),
	 .wW_o(wPPW),
	 .wI_o(wPPI),
	 .wCmdPnt(wPPCmdP),
	 //mem	 	 
    .wMem_i(mem_outb),
	 .wMem_o(mem_inb),
	 .wMemWE_o(pp_web),
    .wMemAddr_o(wPPAddr),
    //trig
	 .wLineTrig_i(ltrig_in),
    .wHWReady_i(&wHWReady),
	 //DDS
	 .rDDSTrig_o(wDDSTrig_pp),
	 .rDDSBrdIdx_o(wDDSBrdIdx_pp),
	 .rAD9959Cmd_o({wAD9959Cmd_pp, wAD9959Data_pp}),
	 .rAD9959PIdx_o(wAD9959PIdx),
	 .rAD9910Cmd_o(wAD9910Cmd_pp),	 
	 //AWG
	 .rAWG9959StartAddr_o(wAWG9959StartAddr),
	 .rAWG9910StartAddr_o(wAWG9910StartAddr),
	 //Digital clicks
	 .rDCTrig_o(wDCTrig),
	 .rDCStep_o(wDCStep),
	 .rDCDelay_o(wDCDelay),
	 .rDCHlvl_o(wDCHlvl),
	 //PMT
	 .wPMT_i(wPmt),
	 .wPMTA_i(wPmtACnt),
	 //DIO
	 .rDO_o(wDigiIO),
	 //Pulse Picker
	 .rPulseWidth_o(wPulseWidthPP),
	 .rPulseDelay_o(wPulseDelayPP),
	 .rPTrig_o(wPTrigPP),
	 .rPInit_o(wPInitPP)
    );

////////////////////////////////////////////////////////////////////////
// Hardware Status
////////////////////////////////////////////////////////////////////////
assign wHWReady[0] = ((&wAD9959Ready) && (&wAD9910Ready)) && (~wLDDSTrig_pp);
assign wHWReady[1] = wDCReady && wPReady;
assign wHWReady[2] = ((&wAWG9959Ready) && (&wAWG9910Ready));

/////////////////////////////////////////////////////////////////////////
// Digital output
/////////////////////////////////////////////////////////////////////////
assign wDIO_io = wPPActive ? wDigiIO[`CC_DIO_NUM -1:0] : rHostShutter[`CC_DIO_NUM -1:0];
//assign wDIO_io[2]   = wDCOut;	

/////////////////////////////////////////////////////////////////////////
// DDS
/////////////////////////////////////////////////////////////////////////
//reg [1:0] rLDDSTrig;
//always @ (posedge wPPClk) rLDDSTrig <= {rLDDSTrig[0], wDDSTrig_pp};
assign wLDDSTrig_pp = wDDSTrig_pp;


//DDS board selection
assign wDDSBrdIdx = wPPActive ? wDDSBrdIdx_pp 	: rDDSBrdIdx_host;
assign wDDSTrig 	= wPPActive ? wLDDSTrig_pp 	: rDDSTrig_host;

assign wAD9959Data 	= wPPActive ? wAD9959Data_pp 	: rAD9959Data_host;
assign wAD9959Cmd 	= wPPActive ? wAD9959Cmd_pp	: rAD9959Cmd_host;
assign wAD9910Cmd 	= wPPActive ? wAD9910Cmd_pp	: rAD9910Cmd_host;


wire 	 wAWG9910CS[1:0], wAD9910CS[1:0];
wire	 wAWG9910IOU[1:0], wAD9910IOU[1:0];
//AWG swiching
assign wAD9959SPI0_o = wDDSBrdIdx < C_AWG ? wAD9959SPI0 : wAWG9959SPI0;
assign wAD9959SPI1_o = wDDSBrdIdx < C_AWG ? wAD9959SPI1 : wAWG9959SPI1;

assign {wAD9910CS_o[0], wAD9910IOU_o[0]}	= wDDSBrdIdx < C_AWG ?  {wAD9910CS[0], wAD9910IOU[0]} : {wAWG9910CS[0], wAWG9910IOU[0]};
assign {wAD9910CS_o[1], wAD9910IOU_o[1]} 	= wDDSBrdIdx < C_AWG ?  {wAD9910CS[1], wAD9910IOU[1]} : {wAWG9910CS[1], wAWG9910IOU[1]};

//DDS
AD9959P
#(.BRDIDX(C_AD9959_0)) 
DDS0 
(
.spi_io	(wAD9959SPI0), 
.ready_o	(wAD9959Ready[0]),
.profile_o(wProfile0_o),
.sel_i	(wDDSBrdIdx), 
.cmd_i	(wAD9959Cmd), 
.data_i	(wAD9959Data), 
.profile_i(wAD9959PIdx),
.cmdtrig_i(wDDSTrig), 
.clk_i	(wDDSClk),  
.reset_i	(rAD9959Reset_host || wReset)
);

AD9959P 
#(.BRDIDX(C_AD9959_1)) 
DDS1 
(
.spi_io	(wAD9959SPI1), 
.ready_o	(wAD9959Ready[1]),
.sel_i	(wDDSBrdIdx), 
.cmd_i	(wAD9959Cmd), 
.data_i	(wAD9959Data), 
.cmdtrig_i(wDDSTrig), 
.profile_i(wAD9959PIdx),
.clk_i	(wDDSClk), 
.reset_i	(rAD9959Reset_host || wReset)
);

AD9910Serial 
#(.P_ADDR(C_AD9910_0))
DDS2
(
 .iAddr(wDDSBrdIdx),
 .iCmd(wAD9910Cmd),
 
 .iTrig(wDDSTrig),	 
 .iReset(rAD9910Reset_host || wReset), 
 .wReady_o(wAD9910Ready[0]),
 .ioSDO(wAD9910SPI_o[0]),
 .ioSCLK(wAD9910SPI_o[1]),
 .wCS_o(wAD9910CS[0]),
 .wIOUpdate_o(wAD9910IOU[0]),
 .oProfile(wAD9910Profile0_o),
 .iClk(wDDSClk),
 .wReset_o(wAD9910Reset_o[0])
);

AD9910Serial 
#(.P_ADDR(C_AD9910_1))
DDS3
(
 .iAddr(wDDSBrdIdx),
 .iCmd(wAD9910Cmd),
 .iTrig(wDDSTrig),
 .iReset(rAD9910Reset_host || wReset),
 .wReady_o(wAD9910Ready[1]),
 .ioSDO(wAD9910SPI_o[0]),
 .ioSCLK(wAD9910SPI_o[1]),
 .wCS_o(wAD9910CS[1]),
 .wIOUpdate_o(wAD9910IOU[1]),
 .oProfile(wAD9910Profile1_o),
 .iClk(wDDSClk),
 .wReset_o(wAD9910Reset_o[1])
);

//AWGs
AWG_AD9959 
#(.BRD_IDX(C_AWG9959_0))
awg0
(
	.sel_i(wDDSBrdIdx_pp),
	.reset_i(wReset),		
	.clk_i(wDDSClk),		
	.start_trig_i(wDDSTrig),
	.ready_o(wAWG9959Ready[0]),		
	.addr_i(wAWG9959StartAddr),
	.wMemAddr_io(wAWG9959Addr0),        //to memory controller
	.mem_data_i(host_dout),			
	.dds_spi_o(wAWG9959SPI0)	      //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0},
);

AWG_AD9959 
#(.BRD_IDX(C_AWG9959_1))
awg1
(
	.sel_i(wDDSBrdIdx_pp),
	.reset_i(wReset),		
	.clk_i(wDDSClk),		
	.start_trig_i(wDDSTrig),
	.ready_o(wAWG9959Ready[1]),		
	.addr_i(wAWG9959StartAddr),
	.wMemAddr_io(wAWG9959Addr1),        //to memory controller
	.mem_data_i(host_dout),			
	.dds_spi_o(wAWG9959SPI1)	      //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0},
);
		
AD9910_AWG 
#(.P_ADDR(C_AWG9910_0))
awg2
(
	.iAddr(wDDSBrdIdx_pp),
	.iReset(wReset),
	.iClk(wDDSClk),
	.iTrig(wDDSTrig),
	.iStartAddr(wAWG9910StartAddr),
	.iMemData(host_dout),
	.wReady_o(wAWG9910Ready[0]),
	.wMemAddr_io(wAWG9910Addr),       //to memory controller
	//Parallel ports
	.wPData_io(wAWG9910PData_o),
	.wTxEnable_o(wAWG9910TxEnable_o[0]),
	.wIOUpdate_o(wAWG9910IOU[0]),
	//serial ports
	.wCS_o(wAWG9910CS[0]),
	.ioSDO(wAD9910SPI_o[0]),
   .ioSCLK(wAD9910SPI_o[1])
);

AD9910_AWG 
#(.P_ADDR(C_AWG9910_1))
awg3
(
	.iAddr(wDDSBrdIdx_pp),
	.iReset(wReset),
	.iClk(wDDSClk),
	.iTrig(wDDSTrig),
	.iStartAddr(wAWG9910StartAddr),
	.iMemData(host_dout),
	.wReady_o(wAWG9910Ready[1]),
	.wMemAddr_io(wAWG9910Addr),       //to memory controller
	//Parallel ports
	.wPData_io(wAWG9910PData_o),
	.wTxEnable_o(wAWG9910TxEnable_o[1]),
	.wIOUpdate_o(wAWG9910IOU[1]),
	//serial ports
	.wCS_o(wAWG9910CS[1]),
	.ioSDO(wAD9910SPI_o[0]),
   .ioSCLK(wAD9910SPI_o[1])
);
	
/////////////////////////////////////////////////////////////////////////
// Digital waveform
/////////////////////////////////////////////////////////////////////////			
CLK_TICK dc_inst(
		.clk_i(wPPClk),
		.step_i(wDCStep),
		.delay_i(wDCDelay),
		.trig_i(wDCTrig),

		.h_i(wDCHlvl),
		.wtick_o(wDCOut),
		.wready_o(wDCReady));

/////////////////////////////////////////////////////////////////////////
// TAC
/////////////////////////////////////////////////////////////////////////
wire wTacPipeRead;
wire [15:0] wTacPipeData;

TAC tac(
//signals
.clk_in(wPPClk),
.hclk_in(wClk300), //300 MHz high speed clock
.pmt_in(pmt_in),
.sync_in(sync_in),
//trigs
//.rst_in(wReset),
.pmtrst_in(rTacPmtRst),
.addrrst_in(rTacAddrRst),
//commands
.cmd_trig_in(rTacCmdTrig),
.cmd_in(rTacCmd),
.data_in(rTacData),
//outputs
.wOutData0_out(wTacData0),
.wOutData1_out(wTacData1),	
.wPipeRead_in(wTacPipeRead),
.wPipeData_out(wTacPipeData)
);

/////////////////////////////////////////////////////////////////////////
//YAG Pulse generator
/////////////////////////////////////////////////////////////////////////
YAG_CTRL mYAG_Ctrl
(.clk_i(wPPClk),
 //.rst_i(wReset),
 .trig_i(rYAGTrig),
 .delay_i(rYAGDelay) //default to be 3600 cycles, corresponding to 150 us
 //.f_o(wDIO_io[0]),
 //.q_o(wDIO_io[1])
 );

/////////////////////////////////////////////////////////////////////////
// LED
/////////////////////////////////////////////////////////////////////////
reg  [3:0] 	rRegIdx;
reg  [31:0]  rTimer;
wire [7:0]   wLed;

always @ (posedge wUsbClk)
begin
	if (wReset)
		begin
			rRegIdx 	<= 0;
			rTimer 	<= 32'd10000000;
		end
	else
		begin			
			if (rTimer == 0)
				begin
					rTimer <= 32'd10000000;
					rRegIdx <= rRegIdx == 4'd8 ? 0 : rRegIdx + 1;
				end
			else
				rTimer <= rTimer - 1;
		end
end

assign wLed[7:0] = 
( rRegIdx == 0 ? ~rLastCmd[63:56] : 
( rRegIdx == 1 ? ~rLastCmd[55:48] :
( rRegIdx == 2 ? ~rLastCmd[47:40] :
( rRegIdx == 3 ? ~rLastCmd[39:32] :
( rRegIdx == 4 ? ~rLastCmd[31:24] :
( rRegIdx == 5 ? ~rLastCmd[23:16] :
( rRegIdx == 6 ? ~rLastCmd[15:8]  : 
( rRegIdx == 7 ? ~rLastCmd[7:0]   : 8'h0
))))))));

assign wLed_o = wPPActive ? wPPCmd[31:24] : wLed[7:0];

/////////////////////////////////////////////////////////////////////////
// OK interface
/////////////////////////////////////////////////////////////////////////
okHost okHI(.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(wUsbClk), .ok1(ok1), .ok2(ok2));
//Inputs
okWireIn ep00(.ok1(ok1), .ep_addr(8'h00), .ep_dataout(WireInCmd));
okWireIn ep01(.ok1(ok1), .ep_addr(8'h01), .ep_dataout(WireInParam));
okWireIn ep02(.ok1(ok1), .ep_addr(8'h02), .ep_dataout(WireInDataL));
okWireIn ep03(.ok1(ok1), .ep_addr(8'h03), .ep_dataout(WireInDataH));
//output
wire [17*11-1:0]  ok2x;
okWireOR # (.N(11)) wireOR (ok2, ok2x);
okWireOut wire20(.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(WireOutDataL));
okWireOut wire21(.ok1(ok1), .ok2(ok2x[ 4*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(WireOutDataH));
//Triggers
//Master wReset and command trigger
okTriggerIn ep40 (.ok1(ok1),.ep_addr(8'h40), .ep_clk(wUsbClk), .ep_trigger(TrigIn40));
// Input pipe. Internal code has to read fast enough not to overflow
okPipeIn  ep80 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]),.ep_addr(8'h80), .ep_write(PipeInWrite), .ep_dataout(PipeInData));
// Output pipe. Internal code has to feed it fast enough for the fifo not to starve on readout
okPipeOut epa0 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'hA0), .ep_read(PipeOutRead), .ep_datain(PipeOutData));
// Output pipe for TAC
okPipeOut epa1 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'hA1), .ep_read(wTacPipeRead), .ep_datain(wTacPipeData));

endmodule