`timescale 1ns / 1ps
//`include "PISO.v"

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:32:16 02/15/2016 
// Design Name: 
// Module Name:    AD9959P 
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
module AD9959P
#(
parameter BRDIDX 		= 4'b0, 
parameter SYNC_DELAY = 4'h2			// sync_delay time must be longer than 2X4 the master clock cycles (~20 ns) 
)
( 
output wire [7:0] 	spi_io,       	//{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0}
output wire [3:0]    profile_o,
output wire				ready_o,

input wire [3:0]     profile_i,
input wire [3:0]  	sel_i,         //{card selection}
input wire [4:0]  	cmd_i,			//extended command set
input wire [31:0] 	data_i,		 	//{31-data}
input wire 				cmdtrig_i,
input wire 				clk_i,
input wire 				reset_i,
output wire [31:0]	wRead_o
);

localparam SPI_SGL = 1'b0;
localparam SPI_MUL = 1'b1;

//Commands
//basic
localparam CMD_INIT	= 5'h0;
localparam CMD_CH 	= 5'h1;
localparam CMD_FRQ 	= 5'h2;
localparam CMD_PHS 	= 5'h3;
localparam CMD_AMP 	= 5'h4;
localparam CMD_MPD  	= 5'h5;
//extra
//select modulation level and channel, use current channel as channel parameter, take the parameter as modulation type
localparam CMD_MTYP  = 5'h6;
//2. select modulation type, take type as parameter
localparam CMD_MSTR  = 5'h7;
localparam CMD_MSTP  = 5'h8;
//Command codes bigger than 5'h9 are treated as profile register address.
//Example to use the modulation:
//DDSMTYP AMP
//DDSPRF addr val
// ...
//DDSSTRM
//DDSSWT profile
// ...
//DDSSTPM  
localparam CMD_READ = 5'h1F;

//state machine
localparam S_START 		= 2'h0;
localparam S_SERIAL		= 2'h1;
localparam S_SYNC_DELAY = 2'h2;

reg [1:0] 	rState = S_START;
reg [1:0]   rCurCh = 2'b0;
reg [4:0]   rCurIdx = 5'b0;
reg [4:0] 	rMaxState = 5'b0;
reg [3:0] 	rSyncCnt = 4'b0;


reg rIO = 0;
reg rCSB = 1;
reg rSPIMode = SPI_SGL; //1 for quad, 0 for single
reg [63:0] rSPIData;
wire wBusy;
wire wSelect;
wire [3:0] wSDataO, wSDataI;

//Modulation related
reg [1:0] rMType;
reg rMStatus;

//reg init;

assign wSelect  = sel_i == BRDIDX;
assign spi_io[4] = wSelect ? reset_i : 1'b0;
assign spi_io[5] = ~clk_i/*(rCSB || ~clk_i)*/;
assign spi_io[6] = wSelect ? rCSB : 1'b1;
assign spi_io[7] = wSelect ? rIO : 1'b0;
assign ready_o  = wSelect ? (rState == S_START): 1'b1; 
assign profile_o[3:0] = (wSelect && rMStatus) ? {profile_i[0], profile_i[1], profile_i[2], profile_i[3]} : 4'b0;

always @ (posedge clk_i)
 begin
 if (wSelect)
		if (reset_i)
			begin
			   rState <= S_START;		
				rCSB <= 1'b1;
				rIO  <= 1'b0;
				rSPIData <= 64'b0;
				rSyncCnt <= 4'b0;	
				rSPIMode <= SPI_SGL;
				rCurIdx <= 0;
				rCurCh  <= 2'b0;
				rMType  <= 2'b0;
				rMStatus <= 0;
			end
		else
			begin
			   case (rState)
				S_START: //initialization
				begin
				   if (cmdtrig_i)
						begin
							rState 		<= S_SERIAL;
							rCSB 		   <= 1'b0;
							rCurIdx     <= 1;
							
							if (cmd_i > 5'h9 && cmd_i < 5'h19)	//Command directly writes on the profile registers
								begin
									rSPIMode 			<= SPI_MUL;		
									rMaxState			<= 5'd10;
									rSPIData[63:56] <= {3'b0, cmd_i}; // reg address
									case (rMType)
										2'b10: // frequency											
												rSPIData[55:24] 	<= data_i[31:0];
										2'b11: // phase
												rSPIData[55:24]  	<= {data_i[13:0], 18'h0};
										2'b1: // amplitude
												rSPIData[55:24]  	<= {data_i[9:0], 22'h0};
										default:
												rSPIData[55:24]    <= 32'b0;
									endcase
								end
							else
								case (cmd_i)
									CMD_INIT: //initial command, in single SPI mode
										begin
											rSPIMode 			<= SPI_SGL;
											rSPIData[63:48] 	<= {8'b0, 8'b1111_0110};
											rMaxState 			<= 5'd16;
										end
									//all the rest in multi SPI mode
									CMD_CH: //channel stored in data_i[3:0]
									
										begin
											rSPIMode 			<= SPI_MUL;
											rSPIData[63:56] 	<= 8'b0;
											rSPIData[55:48] 	<= data_i[3:0] > 4'h3 ? 8'b1111_0110 : {4'b1 << data_i[1:0], 4'b110};
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
									CMD_MTYP: //Record modulation type, set modulation channel and modulation level
										begin
											rSPIMode 			<= SPI_MUL;
											//rSPIData[63:32] 	<= {8'h1, 10'h0, 2'b0, 4'b11, 8'h0};
											rSPIData[63:32] 	<= {8'h1, 8'h0, 2'b0, rCurCh, 2'b0, 2'b11, 8'h0};
											rSPIData[31:0]		<= 32'b0;
											rMaxState 			<= 5'd8;
											rMType				<= data_i[1:0];
										end
									CMD_MSTR: //start modulation
										begin
											rSPIMode 			<= SPI_MUL;
											rSPIData[63:32] 	<= {8'h3, rMType, 6'h0, 16'h320};
											rMStatus				<= 1;
											rMaxState 			<= 5'd8;
										end	
									CMD_MSTP: //stop modulation
										begin
											rSPIMode 			<= SPI_MUL;
											rSPIData[63:32] 	<= {8'h3, 24'h320};
											rMaxState 			<= 5'd8;
											rMStatus				<= 0;
											rMType				<= 2'b0;
										end	
									CMD_READ: //read from AD9959 device, use the data_i as the register address
										begin
										   rSPIData[63:56] <= {1'b1, 2'b0, data_i[4:0]};
											case (data_i[4:0])
												0: rMaxState <= 4;
												1: rMaxState <= 8;
												2: rMaxState <= 6;
												3: rMaxState <= 8;
												5: rMaxState <= 6;
												6: rMaxState <= 8;
												7: rMaxState <= 6;
												default: rMaxState <= 10; 												
											endcase
										end
									default:
										;									
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

assign spi_io[3:0] = cmd_i == CMD_READ ? wSDataI : wSDataO;

MUX_MSB mux_msb_int1(.sdata_o(wSDataO), .pdata_i(rSPIData), .idx_i(rCurIdx), .mode_i(rSPIMode));

endmodule