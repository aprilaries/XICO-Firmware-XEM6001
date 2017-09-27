`timescale 1ns / 1ps
`include "PPCORE.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:52:46 08/10/2016 
// Design Name: 
// Module Name:    PPCoreTiming 
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
module PPCoreTiming(
input wire wReset_i,
input wire wClk_i,
input wire wHClk_i,
output wire [7:0] wDO_o
    );

PPCORE ppc(
	 .wReset_i(wReset_i),
    .wClk_i(wClk_i),
	 .wHClk_i(wHClk_i),
	 .wStartAddr_i(0),
    .wStartTrig_i(0),
    .wStopTrig_i(0),
	 //Debug
	 .wDebug_i(0),
    .wStepTrig_i(0),
//	 output wire [1:0]  wState_o,
//	 output wire [31:0] wCmd_o,
//	 output wire [31:0] wData_o,
//	 output wire [31:0] wW_o,
//	 output wire [15:0] wI_o,
//	 output wire [15:0] wCmdPnt,
	 //memory	 
    .wMem_i(0),
//	 output wire [31:0] wMem_o,
//	 output wire wMemWE_o,
//    output wire [15:0] wMemAddr_o,
    //
	 .wLineTrig_i(0),
    .wHWReady_i(0),	 
	 //DDS
//	 output reg rDDSTrig_o,
//	 output reg [3:0]  rDDSBrdIdx_o,
//	 output reg [36:0] rAD9959Cmd_o,
//	 output reg [3:0]  rAD9959PIdx_o,
//	 output reg [33:0] rAD9910Cmd_o,	
	 //AWG
//	 output reg [15:0] rAWG9959StartAddr_o,
//	 output reg [15:0] rAWG9910StartAddr_o,
	 //Digital clicks
//	 output reg             rDCTrig_o,
//	 output reg	[15:0]		rDCStep_o,
//	 output reg  [15:0]		rDCDelay_o,
//	 output reg  				rDCHlvl_o,
//	 //Pulse picker
//	 output reg [7:0]			rPulseDelay_o,
//	 output reg [7:0]			rPulseWidth_o,
//	 output reg 				rPTrig_o,
//	 output reg					rPInit_o,
	 //PMT
	 .wPMT_i(0),
	 .wPMTA_i(0),
	 //DIO
	 .rDO_o(wDO_o)
    );


endmodule
