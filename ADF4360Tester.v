`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:25:30 08/11/2016
// Design Name:   ADF4360
// Module Name:   C:/Users/Admin/Xilinx Projects/XICO-XEM6001/ADF4360Tester.v
// Project Name:  XICO
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ADF4360
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ADF4360Tester;
	localparam HCLK = 5;
	localparam CLK = 10;

	// Inputs
	reg clk_i;
	reg trig_i;
	reg [23:0] R_i;
	reg [23:0] C_i;
	reg [23:0] N_i;

	// Outputs
	wire ready_o;
	wire sdata_o;
	wire clk_o;
	wire le_o;

	// Instantiate the Unit Under Test (UUT)
	ADF4360 uut (
		.clk_i(clk_i), 
		.trig_i(trig_i), 
		.ready_o(ready_o), 
		.R_i(R_i), 
		.C_i(C_i), 
		.N_i(N_i), 
		.sdata_o(sdata_o), 
		.clk_o(clk_o), 
		.le_o(le_o)
	);

	initial begin
		// Initialize Inputs
		clk_i = 0;
		trig_i = 0;
		R_i = 24'h123456;
		C_i = 24'h234567;
		N_i = 24'h345678;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		trig_i = 1;
		#CLK;
		trig_i = 0;

	end
	
	always # HCLK clk_i = ~clk_i;
      
endmodule

