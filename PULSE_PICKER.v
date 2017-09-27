`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:53:24 10/13/2015 
// Design Name: 
// Module Name:    PULSE_PICKER 
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
module PULSE_PICKER(
    input 	wRegPulse_i,         //pulses regulated by comparator
    input 	[7:0] wDelay_i,      //delay between the output pulse and the pulse
	 input 	wTrig_i,				 	
	 input 	[7:0] wWidth_i,		 //width of the pulse
    output  wOutput_o,			 //output
    input 	wReset_i,
	 input 	wInit_i,              //extra initialization in case of losing pulses
	 output  wMonitor_o,
	 output  wReady_o
);
	 
wire wClkX, wClk;
wire wClkStop;
	 
PULSE_CLK QCLK
 (	.RESET(wReset_i),
	.PULSE_IN(wRegPulse_i),
   .CLKX(wClkX),
	.INPUT_CLK_STOPPED(wClkStop)
 );
 
 assign wClk = wClkX; 
 assign wMonitor_o = wRegPulse_i;
 
 reg [1:0] rTrigEdge;
 wire      wTrig;
 reg [1:0] rPulseEdge;
 wire		  wPulse;
 
 reg rOutput = 1'b0;
 assign wOutput_o = rOutput; 

 reg [15:0] rDelay;
 reg [7:0]  rWidth; 
 reg [1:0]  rState = S_IDLE;
 
 localparam S_IDLE 	= 2'b0; 
 localparam S_WAIT 	= 2'b1;
 localparam S_PULSE 	= 2'b10;
 localparam S_DELAY 	= 2'b11;
 //trigger edge
 assign wTrig 	= ~rTrigEdge[1]  && rTrigEdge[0];
 //pulse edge
 assign wPulse = ~rPulseEdge[1] && rPulseEdge[0];
 assign wReady_o = (rState == S_IDLE);
  
 //high speed logic
 always @ ( posedge wClk )
 begin
	rPulseEdge 	<= { rPulseEdge[0], wRegPulse_i};	//pulse edge detection
	rTrigEdge 	<= { rTrigEdge[0], wTrig_i};
	
	if (wInit_i)
		begin
			rState      	<= S_IDLE;			
			rOutput     	<= 0;
		end
	else
			case (rState)
				S_IDLE:
					if (wTrig) 
						begin
							rState		<= S_WAIT;			//wait for the actual pulse
							rDelay  		<= wDelay_i;			
							rWidth  		<= wWidth_i;
						end
				S_WAIT:
					if (wPulse)  								//start a pulse
						begin
							rState  		<= rDelay > 1 ? S_DELAY : S_PULSE;
							rOutput	 	<= rDelay > 1 ? 0 : 1;
						end					
				S_PULSE:
					begin
						rState 	 <= rWidth 	> 1 ? S_PULSE : S_IDLE;
						rOutput	 <= rWidth 	> 1 ? 1: 0;
						rWidth 	 <= rWidth 	> 1 ? rWidth - 1 : 1;
					end
				S_DELAY:
					begin
						rState 	 <= rDelay 	> 1 ? S_DELAY : S_PULSE;
						rOutput	 <= rDelay  > 1 ? 0 		  : 1;
						rDelay 	 <= rDelay 	> 1 ? rDelay - 1 : 1;						
					end					
			endcase
 end 
endmodule
