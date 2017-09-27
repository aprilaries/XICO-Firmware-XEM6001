`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:22:26 08/09/2016
// Design Name:   AD9959P_R
// Module Name:   C:/Users/Admin/Xilinx Projects/XICO-XEM6001/AD9959_Tester.v
// Project Name:  XICO
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: AD9959P_R
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module AD9959_Tester;
	//const
	localparam HCLK = 10;
	localparam CLK = 20;
	localparam CMD_INIT	= 5'h0;
	localparam CMD_CH 	= 5'h1;
	localparam CMD_FRQ 	= 5'h2;
	localparam CMD_PHS 	= 5'h3;
	localparam CMD_AMP 	= 5'h4;
	localparam CMD_MPD  	= 5'h5;

	// Inputs
	reg [3:0] profile_i;
	reg [3:0] sel_i;
	reg [4:0] cmd_i;
	reg [31:0] data_i;
	reg cmdtrig_i;
	reg clk_i;
	reg reset_i;

	// Outputs
	wire [7:0] spi_io, spi1_io;
	wire [3:0] profile_o, profile1_o;
	wire ready_o, ready1_o;
	wire [31:0] wRead_o, wRead1_o;

	// Instantiate the Unit Under Test (UUT)
	AD9959P_R uut (
		.spi_io(spi_io), 
		.profile_o(profile_o), 
		.ready_o(ready_o), 
		.profile_i(profile_i), 
		.sel_i(sel_i), 
		.cmd_i(cmd_i), 
		.data_i(data_i), 
		.cmdtrig_i(cmdtrig_i), 
		.clk_i(clk_i), 
		.reset_i(reset_i), 
		.wRead_o(wRead_o)
	);
	
	AD9959P uut1 (
		.spi_io(spi1_io), 
		.profile_o(profile1_o), 
		.ready_o(ready1_o), 
		.profile_i(profile_i), 
		.sel_i(sel_i), 
		.cmd_i(cmd_i), 
		.data_i(data_i), 
		.cmdtrig_i(cmdtrig_i), 
		.clk_i(clk_i), 
		.reset_i(reset_i), 
		.wRead_o(wRead1_o)
	);

	initial begin
		// Initialize Inputs
		profile_i = 0;
		sel_i = 0;
		cmd_i = 0;
		data_i = 0;
		cmdtrig_i = 0;
		clk_i = 0;
		reset_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset_i = 1;
		#CLK;
		reset_i = 0;
		#(10*CLK);
		
		cmd_i = CMD_INIT;
		data_i = 0;
		cmdtrig_i = 1;
		#CLK;
		cmdtrig_i = 0;
		#CLK;
		wait (ready_o == 1'b1);
		#CLK;
		
		cmd_i = CMD_FRQ;
		data_i = 12345678;
		cmdtrig_i = 1;
		#CLK;
		cmdtrig_i = 0;
		sel_i = 1;
		#CLK;

	end
	
	always #HCLK clk_i = ~clk_i;
      
endmodule

