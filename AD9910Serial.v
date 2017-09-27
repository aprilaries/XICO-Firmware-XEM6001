`timescale 1ns / 1ps
//`include "PISO.v"

//////////////////////////////////////////////////////////////////////////////////
// Company: Gatech	
// Engineer: G Shu
// 
// Create Date:    21:50:37 08/27/2015 
// Design Name:    
// Module Name:    AD9910Serial 
// Project Name: 
// Target Devices: AD9910
// Tool versions: 
// Description: serial driver
//
// Dependencies: 
// PISO.v
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// 2 steps in the AD9910 serial mode
// 1. enable amplitude tuning
// 2. standard operations
//////////////////////////////////////////////////////////////////////////////////
module AD9910Serial
#(
    parameter P_ADDR = 0,
    parameter P_DEFP = 0
)
(
	input wire 		[3:0]   iAddr,
    input wire 	[33:0]  iCmd,
    input wire 	        iTrig,
	 input wire					iReset,
    output wire         	wReady_o,
	//high impedance when not active
    inout  wire         	ioSDO,
    inout  wire         	ioSCLK,
    output wire          wCS_o,
	 //
    output wire         wIOUpdate_o,
    output wire [2:0]   oProfile,
	output wire	        wReset_o,
    input  wire         iClk,
	 input wire				iClk180
);
	 
localparam CMD_AMP  = 0;
localparam CMD_PHS  = 1;
localparam CMD_FRQ  = 2;
localparam CMD_INIT = 3;


localparam  S_IDLE  = 0;
localparam  S_EXE   = 1;
reg         rState  = S_IDLE;

localparam C_PIDXW  = 72;
localparam C_CIDXW  = 40;
localparam C_PADDR  = 5'hE;
localparam C_CADDR  = 5'h1;
localparam C_ENABLEAMP = 32'h1400820; //for CFR2

/*/////////////////////////
Two rSData formats:
1. a control command format of 40 bits
[39:32]: address
[31:0] : content
2. a profile register format of 72 bits
[71:64]: address
[63:0]:  content
/////////////////////////*/
reg [71:0] rSData   = 72'b0;
reg [6:0]  rIdx     = C_PIDXW;

reg [31:0] rFrq     = 32'b0;
reg [13:0] rAmp     = 14'b0;
reg [15:0] rPhs     = 16'b0;
reg rIOUpdate       = 1'b0;
assign wIOUpdate_o  = rIOUpdate;
wire 	   wSDO;

//A constant profile for now
reg [2:0] rProfile  = 3'b0;

wire wSelect;

assign wSelect = iAddr == P_ADDR;

assign wReset_o = wSelect ? iReset 			: 1'b0;
assign ioSCLK  =  wSelect ? ~iClk 			: 1'bz;
assign ioSDO	 = wSelect ? wSDO | wCS_o 	: 1'bz;
assign wReady_o = wSelect ? (rState == S_IDLE ? 1'b1 : 1'b0) : 1'b1;
assign wCS_o    = wSelect ? (rState == S_IDLE ? 1'b1 : 1'b0) : 1'b1;

assign oProfile = P_DEFP;

always @ (posedge iClk)
if (iAddr == P_ADDR)
begin
	case (rState)
		S_IDLE:
			begin
	   		  rIOUpdate <= 0;
			  if (iTrig)
				begin
					case (iCmd[33:32])
						CMD_FRQ:
							begin
				    			rFrq <= iCmd[31:0];
								rSData <= {3'h0, C_PADDR, 2'b0, rAmp, rPhs, iCmd[31:0]};
								rIdx <= C_PIDXW - 1;
							end
						CMD_PHS:
							begin
								rPhs <= iCmd[15:0];
								rSData <= {3'h0, C_PADDR, 2'b0, rAmp, iCmd[15:0], rFrq};
								rIdx <= C_PIDXW - 1;
							end
						CMD_AMP:
							begin
								rAmp <= iCmd[13:0];
								rSData <= {3'h0, C_PADDR, 2'b0, iCmd[13:0], rPhs, rFrq};
								rIdx <= C_PIDXW - 1;
							end
						CMD_INIT:
							begin
								rSData <= {32'h0, 3'h0, C_CADDR, C_ENABLEAMP};
								rIdx <= C_CIDXW - 1;
							end
					endcase
						rState <= S_EXE;
				 end
			end
			S_EXE:
				begin
					if (rIdx != 0)
						rIdx <= rIdx - 1;
					else
						begin
							rIdx <= C_PIDXW;
							rState <= S_IDLE;
							rIOUpdate <= 1;
						end
					end
			endcase
end

MUX_MSB_SS 
#(
.DATA_WIDTH(72),
.IDX_WIDTH(7)
)
msb_9910
(
.sdata_o(wSDO),
.pdata_i(rSData),
.idx_i(rIdx)
);

endmodule