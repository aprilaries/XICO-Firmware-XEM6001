`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:53:59 02/11/2015 
// Design Name: 
// Module Name:    MEdgeDetector 
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
module MEdgeDetector(
    input wire iClk,
    input wire iSource,
    output wire oEdge,
    input wire iReset
    );

reg [1:0] rBuf;

always @ (posedge iClk)	rBuf <= iReset ? 2'b0 : {rBuf[0], iSource};
assign oEdge = ~rBuf[1] && rBuf[0];

endmodule
