`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:31:55 09/06/2016 
// Design Name: 
// Module Name:    SingleSPI 
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
module SingleSPIF
#(parameter MAXWIDTH = 128)
(
	input 	wire iClk,
	input 	wire iTrig,
	input 	wire iAutoUpdate,
	input 	wire iUpdate,
	input 	wire [7:0] iDataWidth,
	input 	wire [MAXWIDTH-1:0] iData,
	output 	wire oData,
	output 	wire oCS,
	output 	wire oUpdate,
	output 	wire oClk,
	output 	wire oReady
);

localparam S_IDLE 	= 1'h0;
localparam S_RUN  	= 1'h1;
reg rState 				= S_IDLE;

reg rTrig 			   = 0;
reg rReady 				= 1;
reg rCS 					= 1;
reg rUpdate				= 0;
reg [MAXWIDTH-1 : 0] rData = 0;
reg [7:0] 				rIdx  = 255;

assign oClk 	= iClk;
assign oCS		= rCS;
assign oReady 	= rReady;
assign oData 	= rData[MAXWIDTH-1];
assign oUpdate = iAutoUpdate ? rUpdate : (iUpdate && rReady);

always @ (posedge iClk)	rTrig <= iTrig;

always @ (negedge iClk)
begin
	case (rState)
	S_IDLE:
	   begin
			rData 				<= iData;
			rUpdate				<= 0;
			if (rTrig)
				begin
					rCS 			<= 0;
					rReady 		<= 0;
					rState 		<= S_RUN;
					rIdx 			<= iDataWidth;
				end
			else
				begin
					rIdx  		<= 255;
					rReady 		<= 1;
				end
		end
	S_RUN:
		begin
			rIdx  	<= rIdx - 1;
			rData 	<= {rData[MAXWIDTH - 2:0], 1'b0};
			rReady 	<= rIdx == 1 ? 1 : 0;
			rState 	<= rIdx == 1 ? S_IDLE : S_RUN;
			rCS   	<= rIdx == 1 ? 1 : 0;
			rUpdate 	<= rIdx == 1 ? 1 : 0;
		end
	endcase
end
endmodule

//////////////////////////////////////////////////////////

module SingleSPI
#(parameter MAXWIDTH = 128,
  parameter UPDATEDELAY = 0)
(
	input 	wire iClk,
	input    wire iClk180,
	input 	wire iTrig,
	input 	wire iAutoUpdate,
	input 	wire iUpdate,
	input 	wire [7:0] iDataWidth,
	input 	wire [MAXWIDTH-1:0] iData,
	output 	wire oData,
	output 	wire oCS,
	output 	wire oUpdate,
	output 	wire oClk,
	output 	wire oReady
);

localparam S_IDLE 	= 2'h0;
localparam S_RUN  	= 2'h1;
localparam S_WAIT    = 2'h2;
reg [1:0] rState 		= S_IDLE;

reg rReady 				= 1;
reg rCS 					= 1;
reg rUpdate				= 0;
reg [MAXWIDTH-1 : 0] rData = 0;
reg [7:0] 				rIdx  = 255;

assign oClk 	= iClk180;
assign oCS		= rCS;
assign oReady 	= rReady;
assign oData 	= rData[MAXWIDTH-1];
assign oUpdate = iAutoUpdate ? rUpdate : (iUpdate && rReady);

reg [3:0] rUpdateDelay = 4'b0;

always @ (posedge iClk)
begin
	case (rState)
	S_IDLE:
	   begin
			rData 				<= iData;
			rUpdate				<= 0;
			if (iTrig)
				begin
					rCS 			<= 0;
					rReady 		<= 0;
					rState 		<= S_RUN;
					rIdx 			<= iDataWidth;
				end
			else
				begin
					rIdx  		<= 255;
					rReady 		<= 1;
				end
		end
	S_RUN:
		begin
			rIdx  	<= rIdx - 1;
			rData 	<= {rData[MAXWIDTH - 2:0], 1'b0};
			rCS   	<= rIdx == 1 ? 1 : 0;
			
			if (rIdx == 1)
				begin
					if (UPDATEDELAY)
						begin
							rUpdateDelay <= UPDATEDELAY;
							rState 		 <= S_WAIT;
						end
					else
						begin
							rState <= S_IDLE;
							rReady <= 1;
							rUpdate <= 1;
						end
				end				
		end
	S_WAIT: //delay to IOUPDATE
		begin
			if (rUpdateDelay == 1)
				begin
					rState  <= S_IDLE;
					rUpdate <= 1;
					rReady  <= 1;
				end
			else
				rUpdateDelay <= rUpdateDelay - 1;
		end
	endcase
end
endmodule

//////////////////////////////////////////////////////////

module SingleSPIG
#(parameter MAXWIDTH = 128,
parameter UPDATEDELAY = 0)
(
	input 	wire iClk,
	input    wire iClk180,
	input 	wire iTrig,
	input 	wire iAutoUpdate,
	input 	wire iUpdate,
	input 	wire [7:0] iDataWidth,
	input 	wire [MAXWIDTH-1:0] iData,
	output 	wire oData,
	output 	wire oCS,
	//output 	wire oUpdate,
	output 	wire oClk,
	output 	wire oReady
);

localparam S_IDLE 	= 2'h0;
localparam S_RUN  	= 2'h1;
localparam S_WAIT   = 2'h2;
reg [1:0]  rState	= S_IDLE;

reg rReady 			= 1;
reg rCS 			= 1;
reg rUpdate			= 0;
reg [MAXWIDTH-1 : 0] rData = 0;
reg [7:0] 			 rIdx  = 255;

assign oClk 	= ~rCS & iClk180;
assign oCS		= rCS;
assign oReady 	= rReady;
assign oData 	= rData[MAXWIDTH-1];
//assign oUpdate  = iAutoUpdate ? rUpdate : (iUpdate && rReady);

reg [3:0] rUpdateDelay = 4'b0;

always @ (posedge iClk)
begin
	case (rState)
	S_IDLE:
	   begin
			rData 				<= iData;
			//rUpdate				<= 0;
			if (iTrig)
				begin
					rCS 		<= 0;
					rReady 		<= 0;
					rState 		<= S_RUN;
					rIdx 		<= iDataWidth;
				end
			else
				begin
					rIdx  		<= 255;
					rReady 		<= 1;
				end
		end
	S_RUN:
		begin
			rIdx  	<= rIdx - 1;
			rData 	<= {rData[MAXWIDTH - 2:0], 1'b0};
			rCS   	<= rIdx == 1 ? 1'b1 : 1'b0;
			
			if (rIdx == 1)
			begin
				if (UPDATEDELAY)
					begin
						rState <= S_WAIT;
						rUpdateDelay <= UPDATEDELAY;
					end			
				else
					begin
						rReady 	<= 1;
						rState 	<= S_IDLE;
						//rUpdate  <= 1;
					end
			end
		end
	S_WAIT:
		begin
			if (rUpdateDelay == 1)
			begin
				rState  <= S_IDLE;
				//rUpdate <= 1;
				rReady  <= 1;
			end
			else
				rUpdateDelay <= rUpdateDelay - 1;
		end
	endcase
end
endmodule

//////////////////////////////////////////////////////////////////
//This implementation inverse the CS signal
//////////////////////////////////////////////////////////////////

module SingleSPIG_PCS
#(
parameter MAXWIDTH 		= 128,
parameter UPDATEDELAY 	= 0
)
(
	input 	wire iClk,
	input    wire iClk180,
	input 	wire iTrig,
	input 	wire iAutoUpdate,
	input 	wire iUpdate,
	input 	wire [7:0] iDataWidth,
	input 	wire [MAXWIDTH-1:0] iData,
	output 	wire oData,
	output 	wire oCSP,
	output 	wire oUpdate,
	output 	wire oClk,
	output 	wire oReady
);

localparam S_IDLE 	= 2'h0;
localparam S_RUN  	= 2'h1;
localparam S_WAIT    = 2'h2;
reg [1:0]  rState		= S_IDLE;

reg rReady 				= 1;
reg rCS 				= 0;
reg rUpdate				= 0;
reg [MAXWIDTH-1 : 0] rData = 0;
reg [7:0] 				rIdx  = 255;

assign oClk 	= rCS & iClk180;
assign oCSP		= rCS;
assign oReady 	= rReady;
assign oData 	= rData[MAXWIDTH-1];
assign oUpdate = iAutoUpdate ? rUpdate : (iUpdate && rReady);

reg [3:0] rUpdateDelay = 4'b0;

always @ (posedge iClk)
begin
	case (rState)
	S_IDLE:
	   begin
			rData 				<= iData;
			rUpdate				<= 0;
			if (iTrig)
				begin
					rCS 			<= 1;
					rReady 		<= 0;
					rState 		<= S_RUN;
					rIdx 			<= iDataWidth;
				end
			else
				begin
					rIdx  		<= 255;
					rReady 		<= 1;
				end
		end
	S_RUN:
		begin
			rIdx  	<= rIdx - 1;
			rData 	<= {rData[MAXWIDTH - 2:0], 1'b0};
			rCS   	<= rIdx == 1 ? 0 : 1;
			
			if (rIdx == 1)
			begin
				if (UPDATEDELAY)
					begin
						rState <= S_WAIT;
						rUpdateDelay <= UPDATEDELAY;
					end			
				else
					begin
						rReady 	<= 1;
						rState 	<= S_IDLE;
						rUpdate  <= 1;
					end
			end
		end
	S_WAIT:
		begin
			if (rUpdateDelay == 1)
			begin
				rState  <= S_IDLE;
				rUpdate <= 1;
				rReady  <= 1;
			end
			else
				rUpdateDelay <= rUpdateDelay - 1;
		end
	endcase
end
endmodule
