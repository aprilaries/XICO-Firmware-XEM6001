`timescale 1ns / 1ps
`include "clock_con.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:15:11 09/28/2012 
// Design Name: 
// Module Name:    clock_top 
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
module clock_top(
	input wire ti_clk,
	input wire rset,
	output wire sdo,
	output wire sclk,
	output wire le,
	output wire rsetClk
   );
	
	//clocking wires
	wire clk, clk_fb, clk_fb_2;
	
	//spi core clocking
	BUFG this_buff_should_not_be_necessary_but_it_is(.I(clk_fb), .O(clk_fb_2));
	DCM #(.CLKDV_DIVIDE(16.0)) clk_divider (.CLKIN(ti_clk), .CLK0(clk_fb), 
								.CLKDV(clk), .CLKFB(clk_fb_2), .RST(1'b0));
	
	assign rsetClk = ~clk;
	
	//spi clock controller core
	clock_con cc(.clk(clk), .rset(rset), .sdo(sdo), .sclk(sclk), .csb(le), .test(led));
	//assign sdo = rsetClk;
	//assign sclk = rset;
	//assign le = 1'b1;
	
endmodule
