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
module ADF4360(
	 input wire reset_i,
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
reg [1:0] rClkDiv;
reg [3:0] rDelayTrig, rDelayReset;
wire wSClk, wDelayTrig, wDelayReset;

assign wSClk = rClkDiv[1];
assign clk_o = rCS | ~wSClk;
assign wDelayTrig = |rDelayTrig;
assign wDelayReset = |rDelayReset;

always @ (posedge clk_i)
begin
	rDelayReset <= {rDelayReset[2:0], reset_i};
	rDelayTrig  <= {rDelayTrig[2:0], trig_i};
	if (reset_i)
		rClkDiv <= 2'b0;
	else
		rClkDiv <= rClkDiv + 2'b1;
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

reg [4:0] rIdx;
reg [1:0] rState, rRegIdx;
reg [23:0] rR, rC, rN;
wire [23:0] wCurPReg;
reg rLE, rReady, rCS;

reg [15:0] rDelayCnt;

assign le_o = rLE;
assign wCurPReg = rRegIdx == R_R ? rR : ( rRegIdx == R_C ? rC : rN);
assign ready_o = rReady;

always @ (posedge wSClk)
begin
if (wDelayReset)
	begin
		rState <= S_IDLE;
		rRegIdx <= R_R;
		rIdx <= N_WIDTH;
		rLE <= 0;
		rReady <= 1;
		rDelayCnt <= P_MINIDELAY;
		rCS <= 1;
	end
else
	begin
		case (rState)
			S_IDLE:
				begin
				   if (wDelayTrig)
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
					
//					if (rRegIdx != R_N) //next latch
//						begin
//							rRegIdx <= rRegIdx + 1;
//							rIdx <= N_WIDTH - 1;
//							rState <= S_WRITE;							
//						end
//					else
//						begin
//							rState <= S_IDLE;
//							rReady <= 1;
//						end
//				end
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


///////////////////////////////////////////////////
//New PLL controller with one more control wire (CE)
///////////////////////////////////////////////////
module 
ADF4360M2
(
    input wire clk_i,
    input wire trig_i,
    output wire ready_o,
    input wire [23:0] cmd_i,
 
	 output wire sdata_o,
	 output wire clk_o,
	 output wire le_o,
	 output wire ce_o
);
localparam C_CTRL = 2'b0;
localparam C_NCNT = 2'b10;
localparam C_RCNT = 2'b1;
localparam C_CE   = 2'b11;

localparam S_IDLE = 1'h0;
localparam S_WRITE= 1'h1;

reg [1:0] rEdge = 2'b0;
wire wEdge;
assign wEdge = (~rEdge[1]) && rEdge[0];

reg rState  = S_IDLE;
reg rCE     = 1'b0;
assign ce_o = rCE;

reg [23:0] rSPI     = 24'b0;
reg 	   rSPITrig = 0;
wire	   wSPIReady;
reg 		rReady = 1'b1;
assign 	ready_o = rReady;

always @ (posedge clk_i)
begin
	rEdge <= {rEdge[0], trig_i};
	case (rState)
	S_IDLE:
		if (wEdge)
			begin
				case (cmd_i[23:22])
				    2'b11: //enable chip
				        begin
				            rCE <= cmd_i[0];  
				        end
				    default:
				        begin
				            rSPI <= {cmd_i[21:0], cmd_i[23:22]};
				            rSPITrig <= 1;
				            rState <= S_WRITE;
				            rReady <= 1'b0;
				        end				    
				endcase
			end
   S_WRITE:
        begin
            rSPITrig <= 0;
            rState <= wSPIReady ? S_IDLE : S_WRITE;
            rReady <= wSPIReady;
        end
   endcase
end

SingleSPIG 
#(.MAXWIDTH(24),
.UPDATEDELAY(1))
sspi
(
	.iClk(clk_i),
	.iClk180(~clk_i),
	.iTrig(rSPITrig),
	.iAutoUpdate(1'b1),
	.iUpdate(1'b0),
	.iDataWidth(8'd24),
	.iData(rSPI),
	.oData(sdata_o),
	.oCS(le_o),
	.oClk(clk_o),
	.oReady(wSPIReady)
);

endmodule