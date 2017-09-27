`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:15:32 1/6/2014 
// Design Name:    AD9958/9959 Driver
// Module Name:    AD9958/9959 Dr 
// Project Name: 
// Target Devices: XEM3010
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 
// Additional Comments: 
// command word format:
// INIT	= 4'h0;
// CH 	= 4'h1;
// FRQ 	= 4'h2;
// PHS 	= 4'h3;
// AMP 	= 4'h4;
// Data always use the LSB first
//////////////////////////////////////////////////////////////////////////////////

/*module AD9959Dr
#(
parameter BRDIDX 		= 4'b0, 
parameter SYNC_DELAY = 4'h2			// sync_delay time must be longer than 2X4 the master clock cycles (~20 ns) 
)
( 
output wire [7:0] 	spi_o,       	//{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0}
output reg 				ready_o,

output wire [3:0]    profile_o,
input wire [3:0]     profile_i,

input wire [3:0]  	sel_i,         //{card selection}
input wire [3:0]  	cmd_i,
input wire [31:0] 	data_i,		 	//{31-data}
input wire 				cmdtrig_i,
input wire 				clk_i,
input wire				clk180_i,
input wire 				reset_i
);

localparam SPI_SGL = 1'b0;
localparam SPI_MUL = 1'b1;

localparam CMD_INIT	= 4'h0;
localparam CMD_CH 	= 4'h1;
localparam CMD_FRQ 	= 4'h2;
localparam CMD_PHS 	= 4'h3;
localparam CMD_AMP 	= 4'h4;
localparam CMD_MPD  	= 4'h5;

localparam S_START 		= 5'h0;
localparam S_SYNC_DELAY = 5'h31;

reg [4:0] 	state;
reg [4:0] 	MaxState;
reg [3:0] 	synccnt;

reg IO;
reg CSB;
reg spiMode; //1 for quad, 0 for single
reg [63:0] spidata;
reg init;

wire wSelect;
assign wSelect = sel_i == BRDIDX;
assign spi_o[4] = wSelect ? reset_i : 1'b0;
assign spi_o[5] = wSelect ? (CSB || ~clk_i) : 1'b1;
assign spi_o[6] = wSelect ? CSB : 1'b1;
assign spi_o[7] = wSelect ? IO : 1'b0;

assign profile_o = 4'b0;

always @ (posedge clk_i)
 begin
 if (wSelect)
		if (reset_i)
			begin
			   init <= 1'b0;
				state <= S_START;		
				CSB <= 1'b1;
				IO  <= 1'b0;
				spidata <= 64'b0;
				ready_o <= 1'b1;
				synccnt <= 4'b0;	
				spiMode <= SPI_SGL;
			end
		else
			begin
			   case (state)
				S_START: //initialization
				begin
				   if (cmdtrig_i)
						begin
							state 		<= 5'h1;
							CSB 			<= 1'b0;
							ready_o 		<= 1'b0;
							
							case (cmd_i)
								CMD_INIT: //initial command, single SPI
									begin
										spiMode <= SPI_SGL;
										spidata[63:48] <= {8'b0, 8'b1100_0110};//spidata[63: 32] <= 32'b0; 			// address
										MaxState <= 5'd16;
									end
								CMD_CH: //channel
									begin
										spiMode <= SPI_MUL;
										spidata[63:56] <= 8'b0;
										//choose all channels or choose a single channel
										spidata[55:48] <= data_i[3:0] > 3 ? {4'b1111, 4'b110} : {(4'h1 << data_i[1:0]), 4'b110};
										spidata[47: 0] <= 48'h0;
										MaxState <= 5'd4;
									end
								CMD_FRQ: //frequency
									begin
										spiMode <= SPI_MUL;
										spidata[63:24] <= {8'h4, data_i[31:0]};
										spidata[23:0]  <= 24'h0;
										MaxState <= 5'd10;
									end
								CMD_AMP: // amp
									begin
										spiMode <= SPI_MUL;
										spidata[63:32] <= {8'h6, 8'h0, 6'b100, data_i[9:0]};
										spidata[31:0]  <= 32'h0;
										MaxState <= 5'd8;
									end							
								CMD_MPD: //match pipleline delay
									begin
										spiMode <= SPI_MUL;
										spidata[63:0] <= {8'h3, 24'h320, 32'h0};
										MaxState <= 5'd8;								
									end
								default:	//phase
									begin
										spiMode <= SPI_MUL;
										spidata[63:40] <= {8'h5, 2'b0, data_i[13:0]};
										spidata[39:0] <= 40'h0;
										MaxState <= 5'd6;
									end								
								endcase
							end
						else
							begin
								CSB 			<= 1'b1;
								ready_o 		<= 1'b1;
							end
				end
 
			 MaxState:
				begin
					CSB	<= 1'b1;
					IO 	<= 1'b1;
					synccnt <= 1;
					state <= S_SYNC_DELAY;
				end
				
			S_SYNC_DELAY:
					begin
						if (synccnt == SYNC_DELAY)
							begin
								IO <= 1'b0;
								ready_o <= 1'b1;
								state <=  1'b0;
							end
						else
							synccnt <= synccnt + 4'b1;			
					end
				
			 default:
				begin
					IO <= 1'b0;
					CSB <= 1'b0;
					state <= state + 5'b1;
				end
			endcase
		end
 end

MUX_MSB mux_msb_int1(.sdata_o(spi_o[3:0]), .pdata_i(spidata), .idx_i(state), .mode_i(spiMode));

endmodule*/


module AD9959Dr_N
#(
parameter BRDIDX 		= 4'b0, 
parameter SYNC_DELAY = 4'h2			// sync_delay time must be longer than 2X4 the master clock cycles (~20 ns) 
)
( 
output wire [7:0] 	spi_o,       	//{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0}
output wire [3:0]    profile_o,
output wire				ready_o,

input wire [3:0]     profile_i,
input wire [3:0]  	sel_i,         //{card selection}
input wire [3:0]  	cmd_i,			//extended command set
input wire [31:0] 	data_i,		 	//{31-data}
input wire 				cmdtrig_i,
input wire 				clk_i,
input wire 				reset_i
);

localparam SPI_SGL = 1'b0;
localparam SPI_MUL = 1'b1;

//Commands
//basic
localparam CMD_INIT	= 4'h0;
localparam CMD_CH 	= 4'h1;
localparam CMD_FRQ 	= 4'h2;
localparam CMD_PHS 	= 4'h3;
localparam CMD_AMP 	= 4'h4;
localparam CMD_MPD  	= 4'h5;
//extra
//select modulation level and channel, use current channel as channel parameter, take the parameter as modulation type
localparam CMD_MTYP  = 4'h6;
//2. select modulation type, take type as parameter
localparam CMD_STRM  = 4'h7;
//3. write to the profile registers, take profile value as parameter
localparam CMD_PRF 	= 4'h8;
localparam CMD_STPM = 4'h9; 


localparam S_START 		= 2'h0;
localparam S_SERIAL		= 2'h1;
localparam S_SYNC_DELAY = 2'h2;

reg [1:0] 	rState;
reg [1:0]   rCurCh;
reg [4:0]   rCurIdx;
reg [4:0] 	rMaxState;
reg [3:0] 	rSyncCnt;


reg rIO;
reg rCSB;
reg rSPIMode; //1 for quad, 0 for single
reg [63:0] rSPIData;
wire wBusy;
wire wSelect;

//Modulation related
reg [1:0] rMMode;
reg       rMStatus;

//reg init;

assign wSelect = sel_i == BRDIDX;
assign spi_o[4] = wSelect ? reset_i : 1'b0;
assign spi_o[5] = wSelect ? (rCSB || ~clk_i) : 1'b1;
assign spi_o[6] = wSelect ? rCSB : 1'b1;
assign spi_o[7] = wSelect ? rIO : 1'b0;
assign ready_o  = wSelect ? (rState == S_START): 1'b1; 
assign profile_o = (wSelect & rMStatus) ? profile_i : 4'b0;

always @ (posedge clk_i)
 begin
 if (wSelect)
		if (reset_i)
			begin
			   //init <= 1'b0;
				rState <= S_START;		
				rCSB <= 1'b1;
				rIO  <= 1'b0;
				rSPIData <= 64'b0;
				rSyncCnt <= 4'b0;	
				rSPIMode <= SPI_SGL;
				rCurIdx <= 0;
				rCurCh  <= 0;
			end
		else
			begin
			   case (rState)
				S_START: //initialization
				begin
				   if (cmdtrig_i)
						begin
							rState 		<= S_SERIAL;
							rCSB 		<= 1'b0;
							rCurIdx     <= 1;
							
							case (cmd_i)
								CMD_INIT: //initial command, single SPI
									begin
										rSPIMode 			<= SPI_SGL;
										rSPIData[63:48] 	<= {8'b0, 8'b1111_0110};//rSPIData[63: 32] <= 32'b0; 			// address
										rMaxState 			<= 5'd16;
									end
								CMD_CH: //channel
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:56] 	<= 8'b0;
										//choose all channels or choose a single channel
										rSPIData[55:48] 	<= data_i[3:0] > 3 ? {4'b1111, 4'b110} : {4'b1 << data_i[1:0], 4'b110};
										rSPIData[47: 0] 	<= 48'h0;
										rCurCh            <= data_i[1:0];
										rMaxState 			<= 5'd4;
									end
								CMD_FRQ: //frequency
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:24] 	<= {8'h4, data_i[31:0]};
										rSPIData[23:0]  	<= 24'h0;
										rMaxState 			<= 5'd10;
									end
								CMD_AMP: // amp
									begin
										rSPIMode <= SPI_MUL;
										rSPIData[63:32] 	<= {8'h6, 8'h0, 6'b100, data_i[9:0]};
										rSPIData[31:0]  	<= 32'h0;
										rMaxState 			<= 5'd8;
									end	
								CMD_PHS:	//phase
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:40] 	<= {8'h5, 2'b0, data_i[13:0]};
										rSPIData[39:0] 	<= 40'h0;
										rMaxState 			<= 5'd6;
									end									
								CMD_MPD: //match pipleline delay
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:0] 	<= {8'h3, 24'h320, 32'h0};
										rMaxState 			<= 5'd8;								
									end								
								//Modulation related
								CMD_MCFG: //set modulation parameter, use the current channel and 16 level modulation
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:32] 	<= {8'h1, 8'h0, 2'h0, rCurCh[1:0], 2'b0, 2'b11, 8'h0};
										rSPIData[31:0] 	<= 32'h0;
										rMaxState 			<= 5'd8;
									end
								CMD_MTYP: //set modulation type, turn off modulation by set 00
									begin
										rSPIMode 			<= SPI_MUL;
										rSPIData[63:32] 	<= {8'h3, data_i[1:0], 22'h320};
										rSPIData[31:0] 	    <= 32'h0;
										rMaxState 			<= 5'd8;
										rMMode              <= data_i[1:0];
									end	
								//write to the profile registers
								CMD_PRF:
									begin
									   rSPIMode 			<= SPI_MUL;
										rSPIData[23:0] 	<= 24'h0;										
										
										case (rMMode)
											2'h2: // frequency
												begin
													rSPIData[63:56] 	<= profile_i == 0 ? {3'b0, 5'h4} : {1'b0, profile_i + 5'h9};
													rSPIData[55:24] 	<= data_i[31:0];													
													rMaxState 			<= 5'd10;
												end
											2'h3: // phase
												begin
													rSPIData[63:56]  	<= profile_i == 0 ? {3'b0, 5'h5} : {1'b0, profile_i + 5'h9};
													rSPIData[55:42]  	<= data_i[13:0];
													rMaxState			<= profile_i == 0 ? 5'd6 : 5'd10;
												end
											default: // amplitude
												begin
													rSPIData[63:56]  	<= profile_i == 0 ? {3'b0, 5'h6} : {1'b0, profile_i + 5'h9};
													rSPIData[55:46]  	<= data_i[9:0];
													rMaxState			<= profile_i == 0 ? 5'd8 : 5'd10;
												end
										endcase
									end
								endcase
							end
						else
							begin
								rCSB 			<= 1'b1;
								rCurIdx		<= 0;
							end
				end 
			 S_SERIAL: 
				begin
					rCSB	<= rCurIdx == rMaxState ? 1'b1 : 1'b0;
					rIO 	<= rCurIdx == rMaxState ? 1'b1 : 1'b0;
					rSyncCnt <= rCurIdx == rMaxState ? 1'b1 : 0;
					rState <= rCurIdx == rMaxState ? S_SYNC_DELAY : S_SERIAL;
					rCurIdx <= rCurIdx == rMaxState ? rCurIdx : rCurIdx + 1;
				end
			S_SYNC_DELAY:
					begin
						if (rSyncCnt == SYNC_DELAY)
							begin
								rIO <= 1'b0;
								rState <=  S_START;
							end
						else
							rSyncCnt <= rSyncCnt + 1;			
					end
			endcase
		end
 end

MUX_MSB mux_msb_int1(.sdata_o(spi_o[3:0]), .pdata_i(rSPIData), .idx_i(rCurIdx), .mode_i(rSPIMode));

endmodule