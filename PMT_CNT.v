`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: Gatech
// Engineer: G. Shu
// 
// Create Date:    22:34:31 09/21/2015 
// Design Name:    PMT counter and conditioner 
// Module Name:    PMT_CNT 
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
module PMT_CNT(
	 input 	wire wPmt_i,
    input 	wire wHClk_i,
    input 	wire wLClk_i,
    input 	wire [31:0] wExpTime_i,
    output 	wire  wPmt_o,				//conditioned PMT signal
    output 	wire [31:0] wPmtCnt_o,  
	 output  wire [31:0] wPmtACnt_o
    );

reg [1:0] 	rEdge = 2'b0;
wire      	wEdge;
reg [31:0] 	rACnt = 32'b0, rACnt1 = 32'b0, rPmtCnt = 32'b0;
assign 		wPmtCnt_o = rPmtCnt;
reg [31:0] 	rDelayCnt;
reg [31:0] 	rLastCnt;
reg rPmt = 1'b0;
assign wPmt_o = rPmt;

assign wEdge = ~rEdge[1] && rEdge[0];
assign wPmtACnt_o = rACnt1;

always @ (posedge wHClk_i) 
begin
	rEdge <= {rEdge[0], wPmt_i};
	rDelayCnt <= rDelayCnt == wExpTime_i ? 32'b0 : rDelayCnt + 32'b1;
	rACnt 	 <= rDelayCnt == wExpTime_i ? 32'b0 : rACnt + {31'b0, wEdge};
	rPmtCnt <= rDelayCnt == (wExpTime_i - 1) ? rACnt : rPmtCnt;
	rACnt1    <= rACnt1 + {31'b0, wEdge};
end

always @ (posedge wLClk_i)
begin
	rPmt 	<= rLastCnt != rACnt1;
	rLastCnt <= rACnt1;
end

endmodule
