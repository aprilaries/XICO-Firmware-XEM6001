`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:17:51 02/12/2014 
// Design Name: 
// Module Name:    CLK_TICK 
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

module CLK_TICK(
input wire clk_i,
input wire [15:0] step_i,
input wire [15:0] delay_i,
input wire trig_i,
input wire h_i,

output wire wtick_o,
output wire wready_o
);

localparam S_IDLE   = 2'd0;
localparam S_UP 	= 2'd1;
localparam S_DOWN   = 2'd2;
localparam S_WAIT   = 2'd3;

reg [15:0] clk_cnt = 0, step_cnt = 0;
reg [15:0] cur_clk = 0;
reg [1:0]  state = S_IDLE;
reg h_level = 1;
reg rTick = 0;
assign wtick_o = rTick;
reg rReady = 1;
assign wready_o = rReady;

always @ (posedge clk_i)
		begin
			case (state)
				S_IDLE:
					begin
						if (trig_i && step_i && delay_i > 1)
							begin
								clk_cnt  <= delay_i;
								step_cnt <= step_i;
								cur_clk  <= delay_i;
								state <= S_UP;	
								rReady <= 0;
								h_level <= h_i;
							end
						else
							begin
								state <= S_IDLE;
								rReady <= 1;
							end
					end
				S_UP:
					begin
						rTick <= h_level;
						state <= S_DOWN;
						step_cnt <= step_cnt - 1;
						cur_clk  <= cur_clk - 2;
					end
				S_DOWN:
					begin
						rTick <= 1'b0;
						if (!step_cnt) //done
							state <= S_IDLE;
						else if (cur_clk)
							state <= S_WAIT;
						else
							begin
								state <= S_UP;
								cur_clk <= clk_cnt;
							end
					end
				S_WAIT:
					begin
						cur_clk <= cur_clk - 1;
						if (!cur_clk)
							begin
								cur_clk <= clk_cnt;
								state <= S_UP;
							end
					end
			endcase
		end

endmodule

module DIGI_CLICK(
input wire clk_i,
input wire [15:0] step_i,
input wire [15:0] delay_i,
input wire trig_i,
input wire h_i,

output wire wTick_o,
output wire wReady_o
);

localparam S_IDLE   = 2'd0;
localparam S_UP 	= 2'd1;
localparam S_DOWN   = 2'd2;
localparam S_WAIT   = 2'd3;

reg rTick = 0;
reg rReady = 1;
assign wTick_o = rTick;
assign wReady_o = rReady;

reg [15:0] clk_cnt = 0, step_cnt = 0;
reg [15:0] half_cnt = 0;
reg [15:0] cur_clk;
reg [1:0]  state = S_IDLE;
reg h_lvl = 1;

always @ (posedge clk_i)
		begin
			case (state)
				S_IDLE:
					begin
						if (trig_i && step_i && delay_i > 1)
							begin
								clk_cnt  <= delay_i;
								step_cnt <= step_i;
								half_cnt <= {1'b0, delay_i[15:1]};
								cur_clk  <= delay_i;
								state <= S_UP;	
								rReady <= 0;
								h_lvl <= h_i;
							end
						else
							begin
								state <= S_IDLE;
								rReady <= 1;
							end
					end
				S_UP:
					begin
						rTick <= h_lvl;
						state <= S_WAIT;
						step_cnt <= step_cnt - 1;
						cur_clk  <= cur_clk - 2;
					end
				S_WAIT:
					begin
						if (cur_clk <= half_cnt)
							rTick <= 1'b0;
						if (cur_clk)
							cur_clk <= cur_clk - 1;
						else
							begin
								cur_clk <= clk_cnt;
								if (!step_cnt)
									state <= S_IDLE;
								else
									state <= S_UP;
							end
					end
			endcase
		end

endmodule
