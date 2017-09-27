`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:05:34 02/19/2015 
// Design Name: 
// Module Name:    YAG_CTRL 
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
module YAG_CTRL(
    input wire clk_i,
    input wire trig_i,
    input wire [31:0] delay_i, //default to be 3600 cycles, corresponding to 150 us
    output wire f_o,
    output wire q_o
    );
	 
localparam S_IDLE 	= 2'h0;
localparam S_DELAY1 	= 2'h1;
localparam S_DELAY2 	= 2'h2;
	 
reg [31:0] rDelay = 0;
reg rFlash = 0;
reg rQSwitch = 0;
reg [1:0] rState = S_IDLE;

assign f_o = rFlash;
assign q_o = rQSwitch;

always @ (posedge clk_i)
begin
		case (rState)
			S_IDLE:
				if (trig_i)
					begin
						rDelay <= delay_i;
						rFlash <= 1'b1;
						rState <= S_DELAY1;
					end									
			S_DELAY1:
				begin
					rFlash <= 0;
					if (rDelay)
						rDelay <= rDelay - 1;
					else
						begin
							rDelay <= 31'd6000; //second delay
							rState <= S_DELAY2;
							rQSwitch <= 1'b1;
						end
				end
			S_DELAY2:
				begin
					rQSwitch <= 1'b0;
					if (rDelay)
						rDelay <= rDelay - 1;
					else
						rState <= S_IDLE;
				end
		endcase
end

endmodule
