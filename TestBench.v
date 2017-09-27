`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:51:57 03/29/2013
// Design Name:   ppseq
// Module Name:   C:/Users/Rick/XPro/Blue_DDS_Rick/TestBench.v
// Project Name:  DDS
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ppseq
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module TestBench;

	// Inputs
	reg [31:0] pp_din_i;
	reg clk_i;
	reg reset_i;
	reg start_i;
	reg stop_i;
	reg pmt_i;
	reg ddsready_i;
	reg linetrig_i;

	// Outputs
	wire [11:0] pp_addr_o;
	wire pp_we_o;
	wire [31:0] pp_dout_o;
	wire pp_active_o;
	wire [31:0] ddsdata_o;
	wire [3:0] ddscmd_o;
	wire ddscmd_trig_o;
	wire [3:0] shutter_o;
	wire [11:0] PC_o;
	wire [7:0] cmd_o;
	wire [23:0] data_o;
	wire [31:0] W_o;

	// Instantiate the Unit Under Test (UUT)
	ppseq uut (
		.pp_addr_o(pp_addr_o), 
		.pp_we_o(pp_we_o), 
		.pp_dout_o(pp_dout_o), 
		.pp_active_o(pp_active_o), 
		.ddsdata_o(ddsdata_o), 
		.ddscmd_o(ddscmd_o), 
		.ddscmd_trig_o(ddscmd_trig_o), 
		.shutter_o(shutter_o), 
		.PC_o(PC_o), 
		.cmd_o(cmd_o), 
		.data_o(data_o), 
		.pp_din_i(pp_din_i), 
		.W_o(W_o), 
		.clk_i(clk_i), 
		.reset_i(reset_i), 
		.start_i(start_i), 
		.stop_i(stop_i), 
		.pmt_i(pmt_i), 
		.ddsready_i(ddsready_i), 
		.linetrig_i(linetrig_i)
	);

	initial begin
		// Initialize Inputs
		pp_din_i = 0;
		clk_i = 0;
		reset_i = 0;
		start_i = 0;
		stop_i = 0;
		pmt_i = 0;
		ddsready_i = 0;
		linetrig_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

