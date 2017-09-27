`timescale 1ns / 1ps
//`include "PISO.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:43:12 01/10/2014 
// Design Name: 
// Module Name:    AWG_AD9958/59 
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
// the first 4 bits are command bits
// the frequency takes 28 bits;
// 
//////////////////////////////////////////////////////////////////////////////////

//module AWG_AD9958
//#(
//parameter BRD_IDX = 4'b0,
//parameter SYNC_DELAY = 4'b1)
//(
//	input wire [3:0] sel_i,
//	input wire reset_i,
//	
//	input wire clk_i,
//	
//	input wire start_trig_i,
//	output reg ready_o,
//	
//	input wire [15:0] addr_i,
//	input wire [31:0] mem_data_i,
//		
//	inout wire [15:0] wMemAddr_io,       //to memory controller
//	output wire [7:0] dds_spi_o         //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0},
//);
//
////sequence command
//localparam CMD_INIT = 4'h1;
//localparam CMD_FRQ = 4'h2;
//localparam CMD_PHS = 4'h3;
//localparam CMD_AMP = 4'h4;
//localparam CMD_DLY = 4'h5;
//localparam CMD_END = 4'hF;
//
////state
//localparam 	S_IDLE 		= 4'h0,
//				S_MEM  		= 4'h1,
//				S_SETUP 	= 4'h2,
//				S_DDS_CMD 	= 4'h3,
//				S_DDS_SYNC  = 4'h4,
//				S_DELAY 	= 4'h5;
//			
//reg [3:0] 	state;
//reg [5:0]	spi_idx;
//reg [5:0]  	max_spi_idx;
//reg [63:0] 	spi_data_reg;
//reg [23:0] 	delay_reg;
//reg [3:0]   sync_delay_reg;
//reg cbs_reg, io_reg;
//reg [15:0]	rMemAddr;
//
//assign wMemAddr_io = sel_i == BRD_IDX ? rMemAddr : 16'hZZZZ;
//
//assign dds_spi_o[4] = sel_i == BRD_IDX ? reset_i : 0;
//assign dds_spi_o[5] = sel_i == BRD_IDX ? (cbs_reg || ~clk_i) : 1;
//assign dds_spi_o[6] = sel_i == BRD_IDX ? cbs_reg : 1;
//assign dds_spi_o[7] = sel_i == BRD_IDX ? io_reg : 0;
//
//always @ (posedge clk_i)
//	if (sel_i == BRD_IDX)
//		begin
//		   if (reset_i)
//				begin
//					rMemAddr <= 0;
//					ready_o <= 1;
//					state <= S_IDLE;
//					
//					cbs_reg <= 1;
//					io_reg <= 0;
//					
//					spi_data_reg <= 0;
//					spi_idx <= 0;
//					max_spi_idx <= 0;
//					
//					delay_reg <= 0;
//				end
//			else
//				case (state)
//					S_IDLE:
//						begin
//							spi_idx <= 0;
//							if (start_trig_i)
//								begin
//									state <= S_MEM;
//									ready_o <= 0;
//									rMemAddr <= addr_i;	
//								end
//							else
//								begin
//									state <= S_IDLE;
//									ready_o <= 1;
//									rMemAddr <= 0;
//								end						   
//						end
//					S_MEM:  //wait for memory to update
//						begin
//							state <= S_SETUP;	
//						end
//					S_SETUP:
//						begin
//							io_reg <= 1'b0;
//							sync_delay_reg<= 4'b1;
//							rMemAddr <= rMemAddr + 16'b1;
//									
//							case (mem_data_i[31:28]) // read the command bits
//								CMD_INIT: //set the channel
//									begin
//										spi_data_reg[63:56] <= 8'b0;	//write on reg 0x0
//										spi_data_reg[55:48] <= {(2'h1 << mem_data_i[0]), 6'b110};
//										//spi_data_reg[55:48] <= {mem_data_i[1:0], 6'b110};
//										max_spi_idx <= 4;
//										spi_idx <= 1;
//										
//										cbs_reg <= 0;
//										state <= S_DDS_CMD;
//									end
//								CMD_FRQ:
//									begin
//										spi_data_reg[63:24] <= {8'h4, mem_data_i[27:0], 4'b0};
//										max_spi_idx <= 10;
//										spi_idx <= 1;
//										
//										cbs_reg <= 0;
//										state <= S_DDS_CMD;
//									end
//								CMD_PHS:
//									begin
//										spi_data_reg[63:40] <= {8'h5, 2'b0, mem_data_i[23:10]};
//										max_spi_idx <= 6;
//										spi_idx <= 1;
//										
//										cbs_reg <= 0;
//										state <= S_DDS_CMD;
//									end
//								CMD_AMP:
//									begin
//										spi_data_reg[63:32] <= {8'h6, 8'h0, 6'b100, mem_data_i[9:0]};
//										max_spi_idx <= 8;
//										spi_idx <= 1;
//										
//										cbs_reg <= 0;
//										state <= S_DDS_CMD;
//									end
//								CMD_DLY:
//									begin
//									   spi_idx <= 0;
//										
//										if (mem_data_i[23:0] < 2)
//											begin
//												state <= S_SETUP;
//												delay_reg <= 1;
//											end
//										else
//											begin
//												state <= S_DELAY;
//												delay_reg <= mem_data_i[23:0];
//											end
//									end									
//								CMD_END:
//									begin
//										state <= S_IDLE;
//										ready_o <= 1;
//									end
//								default:
//									begin
//										state <= S_IDLE;
//										ready_o <= 1;
//										spi_idx <= 0;
//									end
//							endcase
//						end
//					S_DDS_CMD:
//						begin
//							case (spi_idx) //spi_idx starts from 1
//								max_spi_idx:
//									begin
//										cbs_reg <= 1;
//										io_reg <= 1;
//										spi_idx <= 0;
//										
//										state <= SYNC_DELAY > 1 ? S_DDS_SYNC : S_SETUP;	
//										sync_delay_reg <= 1;						
//									end	
//								default:
//									begin
//										spi_idx <= spi_idx + 1;					
//									end
//							endcase						
//						end
//					S_DDS_SYNC:
//						begin
//							state <= (SYNC_DELAY == sync_delay_reg) ? S_SETUP : S_DDS_SYNC;
//							sync_delay_reg <= sync_delay_reg + 1;
//						end						
//					S_DELAY:
//						begin
//							if (delay_reg < 3)
//								begin
//									state <= S_SETUP;
//									delay_reg <= 0;
//								end
//							else
//								delay_reg <= delay_reg - 1;
//						end
//					default:
//						begin
//							state <= S_IDLE;
//						end
//				endcase
//		end
//		
//MUX_MSB mux_msb_int1(.sdata_o(dds_spi_o[3:0]), .pdata_i(spi_data_reg), .idx_i(spi_idx), .mode_i(1'b1));		//always in 4 bit mode
//endmodule

module AWG_AD9959
#(
parameter BRD_IDX = 4'b0,
parameter SYNC_DELAY = 4'b1)
(
	input wire [3:0] sel_i,
	input wire reset_i,
	
	input wire clk_i,
	
	input wire start_trig_i,
	output wire ready_o,
	
	input wire [15:0] addr_i,
	input wire [31:0] mem_data_i,
		
	inout wire [15:0] wMemAddr_io,       //to memory controller
	output wire [7:0] dds_spi_o         //{IO_UPDATE, CSB, SCLK, RSET, SDIO_3, SDIO_2, SDIO_1, SDIO_0},
);

//sequence command
localparam CMD_INIT = 4'h1;
localparam CMD_FRQ = 4'h2;
localparam CMD_PHS = 4'h3;
localparam CMD_AMP = 4'h4;
localparam CMD_DLY = 4'h5;
localparam CMD_END = 4'hF;

//state
localparam 		S_IDLE 			= 4'h0,
				S_MEM  		= 4'h1,
				S_SETUP 	= 4'h2,
				S_DDS_CMD 	= 4'h3,
				S_DDS_SYNC  = 4'h4,
				S_DELAY 	= 4'h5;
			
reg [3:0] 	state;
reg [4:0]	spi_idx;
reg [4:0]  	max_spi_idx;
reg [63:0] 	spi_data_reg;
reg [23:0] 	delay_reg;
reg [3:0]   sync_delay_reg;
reg cbs_reg, io_reg;
reg [15:0]	rMemAddr;
reg 			rReady;

assign wMemAddr_io = sel_i == BRD_IDX ? rMemAddr : 16'hZZZZ;

assign dds_spi_o[4] = sel_i == BRD_IDX ? reset_i : 1'b0;
assign dds_spi_o[5] = ~clk_i; //clk180_i;//sel_i == BRD_IDX ? (cbs_reg || ~clk_i) : 1'b1;
assign dds_spi_o[6] = sel_i == BRD_IDX ? cbs_reg : 1'b1;
assign dds_spi_o[7] = sel_i == BRD_IDX ? io_reg : 1'b0;
//assign ready_o = sel_i == BRD_IDX ? (state == S_IDLE ? (io_reg ? 1'b0 : 1'b1) : 1'b0) : 1'b1;
assign ready_o = rReady;

always @ (posedge clk_i)
		begin
		   if (reset_i)
				begin
					rMemAddr <= 0;
					state <= S_IDLE;
					
					cbs_reg <= 1;
					io_reg <= 0;
					
					spi_data_reg <= 0;
					spi_idx <= 0;
					max_spi_idx <= 0;
					
					delay_reg <= 0;
					rReady <= 1;
				end
			else
				case (state)
					S_IDLE:
						begin
							spi_idx <= 0;
							if (start_trig_i && sel_i == BRD_IDX)
								begin
									state <= S_MEM;
									rMemAddr <= addr_i;	
									rReady <= 0;
								end
							else
								begin
									state <= S_IDLE;
									rMemAddr <= 0;
									rReady <= 1;
								end						   
						end
					S_MEM:  //wait for memory to update
						begin
							state <= S_SETUP;	
						end
					S_SETUP:
						begin
							io_reg <= 1'b0;
							sync_delay_reg<= 4'b1;
							rMemAddr <= rMemAddr + 16'b1;
									
							case (mem_data_i[31:28]) // read the command bits
								CMD_INIT: //set the channel
									begin
										spi_data_reg[63:56] <= 8'b0;	//write on reg 0x0
										spi_data_reg[55:48] <= {mem_data_i[3:0], 4'b110};
										max_spi_idx <= 4;
										spi_idx <= 1;
										
										cbs_reg <= 0;
										state <= S_DDS_CMD;
									end
								CMD_FRQ:
									begin
										spi_data_reg[63:24] <= {8'h4, mem_data_i[27:0], 4'b0};
										max_spi_idx <= 10;
										spi_idx <= 1;
										
										cbs_reg <= 0;
										state <= S_DDS_CMD;
									end
								CMD_PHS:
									begin
										spi_data_reg[63:40] <= {8'h5, 2'b0, mem_data_i[23:10]};
										max_spi_idx <= 6;
										spi_idx <= 1;
										
										cbs_reg <= 0;
										state <= S_DDS_CMD;
									end
								CMD_AMP:
									begin
										spi_data_reg[63:32] <= {8'h6, 8'h0, 6'b100, mem_data_i[9:0]};
										max_spi_idx <= 8;
										spi_idx <= 1;
										
										cbs_reg <= 0;
										state <= S_DDS_CMD;
									end
								CMD_DLY:
									begin
									   spi_idx <= 0;
										
										if (mem_data_i[23:0] < 2)
											begin
												state <= S_SETUP;
												delay_reg <= 1;
											end
										else
											begin
												state <= S_DELAY;
												delay_reg <= mem_data_i[23:0];
											end
									end									
								CMD_END:
									begin
										state <= S_IDLE;
									end
								default:
									begin
										state <= S_IDLE;
										spi_idx <= 0;
									end
							endcase
						end
					S_DDS_CMD:
						begin
							case (spi_idx) //spi_idx starts from 1
								max_spi_idx:
									begin
										cbs_reg <= 1;
										io_reg <= 1;
										spi_idx <= 0;
										
										state <= SYNC_DELAY > 1 ? S_DDS_SYNC : S_SETUP;	
										sync_delay_reg <= 1;						
									end	
								default:
									begin
										spi_idx <= spi_idx + 1;					
									end
							endcase						
						end
					S_DDS_SYNC:
						begin
							state <= (SYNC_DELAY == sync_delay_reg) ? S_SETUP : S_DDS_SYNC;
							sync_delay_reg <= sync_delay_reg + 1;
						end						
					S_DELAY:
						begin
							if (delay_reg < 3)
								begin
									state <= S_SETUP;
									delay_reg <= 0;
								end
							else
								delay_reg <= delay_reg - 1;
						end
					default:
						begin
							state <= S_IDLE;
						end
				endcase
		end
		
MUX_MSB mux_msb_int1(.sdata_o(dds_spi_o[3:0]), .pdata_i(spi_data_reg), .idx_i(spi_idx), .mode_i(1'b1));		//always in 4 bit mode
endmodule