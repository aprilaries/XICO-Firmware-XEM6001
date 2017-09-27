`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:37:43 01/25/2014 
// Design Name: 
// Module Name:    MUX 
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

module MUX_MSB
(
output wire[3:0]    sdata_o,
input  wire[63:0]   pdata_i,
input  wire[4:0]    idx_i,
input  wire         mode_i
);
assign sdata_o[3] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[67 - 4 * idx_i]: 1'b0 ;
assign sdata_o[2] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[66 - 4 * idx_i]: 1'b0 ;
assign sdata_o[1] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[65 - 4 * idx_i]: 1'b0 ;
assign sdata_o[0] = (idx_i > 0 && idx_i < 17) ? (mode_i ? pdata_i[64 - 4 * idx_i] : pdata_i[64 - idx_i]): 1'b0;
endmodule

module MUX_MSB_HS
(
output wire[3:0]    sdata_o,
input  wire[63:0]   pdata_i,
input  wire[4:0]    idx_i,
input  wire         mode_i
);
wire [16:0] wSData0, wSData1, wSData2, wSData3;

assign wSData0[0] = 0;
assign wSData0[16:1] = {pdata_i[0], pdata_i[4], pdata_i[8], pdata_i[12], pdata_i[16], pdata_i[20], pdata_i[24], pdata_i[28], pdata_i[32], pdata_i[36], pdata_i[40], pdata_i[44], pdata_i[48], pdata_i[52], pdata_i[56], pdata_i[60]};

assign wSData1[0] = 0;
assign wSData1[16:1] = {pdata_i[1], pdata_i[5], pdata_i[9], pdata_i[13], pdata_i[17], pdata_i[21], pdata_i[25], pdata_i[29], pdata_i[33], pdata_i[37], pdata_i[41], pdata_i[45], pdata_i[49], pdata_i[53], pdata_i[57], pdata_i[61]};

assign wSData2[0] = 0;
assign wSData2[16:1] = {pdata_i[2], pdata_i[6], pdata_i[10], pdata_i[14], pdata_i[18], pdata_i[22], pdata_i[26], pdata_i[30], pdata_i[34], pdata_i[38], pdata_i[42], pdata_i[46], pdata_i[50], pdata_i[54], pdata_i[58], pdata_i[62]};

assign wSData3[0] = 0;
assign wSData3[16:1] = {pdata_i[3], pdata_i[7], pdata_i[11], pdata_i[15], pdata_i[19], pdata_i[23], pdata_i[27], pdata_i[31], pdata_i[35], pdata_i[39], pdata_i[43], pdata_i[47], pdata_i[51], pdata_i[55], pdata_i[59], pdata_i[63]};

assign sdata_o[0] = mode_i ? wSData0[idx_i] : pdata_i[64 - idx_i];
assign sdata_o[1] = mode_i ? wSData1[idx_i] : 0;
assign sdata_o[2] = mode_i ? wSData2[idx_i] : 0;
assign sdata_o[3] = mode_i ? wSData3[idx_i] : 0;

endmodule


//////////////////////////////////////////////////////////////////////////////////

module MUX_MSB_S 
#(
parameter DATA_WIDTH = 24,
parameter IDX_WIDTH = 5
)
(
output wire sdata_o,
input  wire [DATA_WIDTH - 1 : 0] pdata_i,
input  wire [IDX_WIDTH - 1 : 0]  idx_i
);
assign sdata_o = ( idx_i > 0 && idx_i < (DATA_WIDTH + 1)) ? pdata_i[DATA_WIDTH - idx_i] : 0; 
endmodule

module MUX_MSB_SS
#(
parameter DATA_WIDTH = 24,
parameter IDX_WIDTH = 5
)
(
output wire sdata_o,
input  wire [DATA_WIDTH - 1 : 0] pdata_i,
input  wire [IDX_WIDTH - 1 : 0] idx_i
);
assign sdata_o = (idx_i < DATA_WIDTH) ? pdata_i[idx_i] : 0;
endmodule

//////////////////////////////////////////////////////////////////////////////////

module MUX_LSB
(
output wire[3:0] sdata_o,
input  wire[63:0] pdata_i,
input  wire[4:0] idx_i,
input  wire mode_i
);
assign sdata_o[3] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[4 * idx_i - 1]: 0 ;
assign sdata_o[2] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[4 * idx_i - 2]: 0 ;
assign sdata_o[1] = (idx_i > 0 && idx_i < 17 && mode_i) ? pdata_i[4 * idx_i - 3]: 0 ;
assign sdata_o[0] = (idx_i > 0 && idx_i < 17) ? (mode_i ? pdata_i[4 * idx_i - 4] : pdata_i[idx_i - 1]): 0;
endmodule

///////////////////////////////////////////////////////////////////////////////////
module MUX_MSB_WR
(
inout wire[3:0] sdata_io,
input wire[7:0] pdata_i,
output reg[31:0] pdata_o,
input wire[4:0] idx_i,
input wire clk_i,
input wire reset_i);

assign sdata_io[3:0] = (idx_i == 1) ? pdata_i[7:4] : ((idx_i == 2) ? pdata_i[3:0] : 4'bZZZZ);

always @ (posedge clk_i)
begin
	if (reset_i)
	pdata_o[31:0] <= 32'h0;
	else
	if (idx_i > 2)
	begin
		pdata_o[43 - 4*idx_i] <= sdata_io[3];
		pdata_o[42 - 4*idx_i] <= sdata_io[2];
		pdata_o[41 - 4*idx_i] <= sdata_io[1];
		pdata_o[40 - 4*idx_i] <= sdata_io[0];
	end
end

endmodule