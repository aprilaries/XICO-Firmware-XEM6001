`timescale 1ns / 1ps
//all tested
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:19:50 01/08/2014 
// Design Name: 
// Module Name:    pipectrl 
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
// take in 16bit pipe data and turn into 32bit data and write to a RAM
// 1. set start address
// 2. trig the restart
// 3. start the pipe
//////////////////////////////////////////////////////////////////////////////////
module pipe_in(
input wire wea_i,
input wire [15:0] data16_i,
input wire clk_i,
input wire [15:0] saddr_i,
input wire restart_i,

output reg [31:0] data32_o,
output reg [15:0] addr_o,
output reg wea_o
);

localparam S_L16 = 1'b0;
localparam S_H16 = 1'b1;

reg state;
reg [15:0] datal_r;
reg [15:0] addr_r;

always @ (posedge clk_i)
begin
	if (restart_i)
		begin
			state <= S_L16;
			data32_o <= 0;
			wea_o <= 0;
			addr_o <= 0;
			addr_r <= saddr_i;
		end
	else if (wea_i)
			begin
				case (state)
					S_L16:
						begin
							datal_r <= data16_i;
							state <= S_H16;
							wea_o <= 0;
						end
					S_H16:
						begin
							data32_o <= {data16_i, datal_r};
							addr_o <= addr_r;
							addr_r <= addr_r + 16'b1;
							state <= S_L16;
							wea_o <= 1;
						end
				endcase
			end	
	 else
		 wea_o <= 0;
		
end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:19:50 01/08/2014 
// Design Name: 
// Module Name:    pipectrl 
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
// take in 16bit pipe data and turn into 32bit data and write to a RAM
// 1. set start address saddr_i
// 2. restart_i
// 3. start the pipe
//////////////////////////////////////////////////////////////////////////////////
module pipe_out
(
output reg [15:0] addr_o,
output reg [15:0] data16_o,

input wire [31:0] data32_i,
input wire [15:0] saddr_i,
input wire rea_i,
input wire restart_i,
input wire clk_i
);

localparam S_L16 = 0;
localparam S_H16 = 1;

reg state;
reg delay_read;
reg [15:0] datah;

always @ (negedge clk_i)
begin
	if (restart_i)
		begin
			//delay_read <= 0;
			addr_o <= saddr_i;
			data16_o <= 16'h0;
			state <= S_L16;
		end
	else 
		begin	
			delay_read <= rea_i;
			if (delay_read)
			begin
				case (state)
				S_L16:
					begin
						data16_o <= data32_i[15:0];
						datah <= data32_i[31:16];
						state <= S_H16;
						addr_o <= addr_o + 16'b1;
					end
				S_H16:
					begin
						data16_o <= datah;
						state <= S_L16;							
					end
				endcase
			end
		end
end
endmodule