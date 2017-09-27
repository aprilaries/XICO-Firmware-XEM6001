`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:13:38 01/19/2015 
// Design Name: 
// Module Name:    TAC_EDetect 
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
module TAC_EDetect(
    input wire sig_in,
    input wire clk_in,
    input wire rst_in,
    output wire edge_out
    );

reg [1:0] _rEBuf;

always @ (posedge clk_in)	_rEBuf[1:0] <= rst_in == 0 ? {_rEBuf[0], sig_in} : 2'b0;
assign edge_out = _rEBuf[0] && ~_rEBuf[1];

endmodule
