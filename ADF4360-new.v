`timescale 1ns / 1ps
`include "PISO.v"

//////////////////////////////////////////////////////////////////////////////////
// Company: Gatech	
// Engineer: G. Shu
// 
// Create Date:    16:51:29 08/23/2015 
// Design Name: 
// Module Name:    ADF4360 
// Project Name: 
// Target Devices: ADF4360, Opal Kelly 
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
module ADF4360
#(parameter CDIVW = 5)
(
    input wire clk_i,
    input wire trig_i,
    output wire ready_o,
    input wire [23:0] R_i,
    input wire [23:0] C_i,
    input wire [23:0] N_i,
	 output wire sdata_o,
	 output wire clk_o,
	 output wire le_o
    );
//internal clock management
//divide the external clock by 4
//turn fast trigger into slow trigger
reg [CDIVW-1 : 0] rClkDiv = 0;
reg rDelayTrig = 0;
wire wSClk;

assign wSClk = rClkDiv[CDIVW-1];
assign clk_o = rCS | ~wSClk;

always @ (posedge clk_i)
begin
	rClkDiv 		<= rClkDiv + 1;
	if (rReady)
		rDelayTrig <= trig_i ? 1 : rDelayTrig;
	else
		rDelayTrig <= 0;
end

//Main logic
localparam R_R = 1;
localparam R_C = 2;
localparam R_N = 3;
localparam N_WIDTH = 24;

localparam S_IDLE = 0;
localparam S_WRITE = 1;
localparam S_LATCH = 2;
localparam S_WAIT  = 3;

localparam P_MINIDELAY = 5;//16'h3100;

reg [4:0] rIdx = N_WIDTH;
reg [1:0] rState = S_IDLE, rRegIdx = R_R;
reg [23:0] rR = 0, rC = 0, rN = 0;
wire [23:0] wCurPReg;
reg rLE = 0, rReady = 1, rCS = 1;

reg [15:0] rDelayCnt = P_MINIDELAY;

assign le_o = rLE;
assign wCurPReg = rRegIdx == R_R ? rR : ( rRegIdx == R_C ? rC : rN);
assign ready_o = rReady;

always @ (posedge wSClk)
begin
	begin
		case (rState)
			S_IDLE:
				begin
				   if (rDelayTrig)
						begin
							//take the input
							rR <= R_i;
							rC <= C_i;
							rN <= N_i;
							rRegIdx 	<= R_R;
							rState 	<= S_WRITE;
							rLE 		<= 0;
							rReady   <= 0;
							rIdx <= rIdx - 5'b1;
							rDelayCnt <= P_MINIDELAY;
							rCS <= 0;
						end
					else
						rIdx <= N_WIDTH;
						rLE  <= 0;
				end
			S_WRITE:
				begin
						if (rIdx != 0)
							rIdx <= rIdx - 5'b1;
						else
							begin
								rState <= S_LATCH;
								rCS <= 1;
								rLE <= 1;
								rIdx <= N_WIDTH;
							end
				end
			S_LATCH:
				begin				
					rLE <= 0;	
					case (rRegIdx)
						R_R:
							begin
								rRegIdx <= rRegIdx + 2'b1;
								rIdx <= N_WIDTH - 5'b1;
								rState <= S_WRITE;
								rCS <= 0;
							end
						R_C:
							if (rDelayCnt != 0)
								rDelayCnt <= rDelayCnt - 16'b1;
							else
								begin
									rRegIdx <= rRegIdx + 2'b1;
									rIdx <= N_WIDTH - 5'b1;
									rState <= S_WRITE;
									rCS <= 0;
								end
						R_N:
							begin
								rIdx <= N_WIDTH;
								rState <= S_IDLE;
								rReady <= 1'b1;
								rCS <= 1'b1;
							end
					endcase
				end
		endcase
	end
end

MUX_MSB_SS msb_s 
(
.sdata_o(sdata_o),
.pdata_i(wCurPReg),
.idx_i(rIdx)
);

endmodule
