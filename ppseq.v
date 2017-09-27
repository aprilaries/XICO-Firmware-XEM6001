`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Pulse Programmer Core
//2013.3.28 add PP_MUL, PP_SUB, PP_WAITL, change ppseq variable order by Rick
//
//////////////////////////////////////////////////////////////////////////////////
`define DIM_MEMADDR 14

module ppseq(
	input wire 						linetrig_i,		//line trigger added by Rick 2013.3.28
	input wire						clk_i,
	input wire						reset_i,
	input wire						start_i,		   // start trigger (one cycle high)
	input wire						stop_i,			// stop trigger (one cycle high)
	input wire signed [31:0]	pp_din_i,		// pp memory output
	input wire						pmt_i,		   // PMT signal (single clk cycle high)
	input wire						pmta_i,			//accumulated PMT count
	input wire						hw_ready_i,
	//correlator
	output reg						rPCStart_o,
	output reg	[31:0]			rPCTao1_o,
	output reg	[31:0]			rPCTao2_o,
	input  wire [31:0]			i_PCTimeSpan,
	input  wire 					i_PCDone,
	input  wire						i_PCBright,
	input  wire [1:0]				i_PCArrival,
	
	output wire [`DIM_MEMADDR - 1 : 0]				pp_addr_o,	   	// pp memory address
	output wire						pp_we_o,		// pp memory we
	output wire [31:0]			pp_dout_o,	   	// pp memory input
	
	//DDS board
	output reg  [3:0]				rDDSBrdIdx_o,
	output reg						rDDSTrig_o,
	
	//for AD9959
	output reg 	[31:0]		rAD9959Data_o,
	output reg 	[3:0]			rAD9959Cmd_o,	
	
	//for AD9910
	output reg [33:0]			rAD9910Cmd_o,
	
	//AWG
	output reg  [3:0]       rAWGIdx_o,
	output reg					rAWGTrig_o,
	//for AWG9959	
	output reg  [15:0]		rAWG9959StartAddr_o,	
	//for AWG9910
	output reg  [15:0]	   rAWG9910StartAddr_o,
	
   //for digital click	
	output reg              rDCTrig_o,
	output reg	[15:0]		rDCStep_o,
	output reg  [15:0]		rDCDelay_o,
	output reg  				rDCHlvl_o,
	
	output reg 	[3:0]			rShutter_o,		// BNC shutter outputs
	output wire					pp_active_o,	// 1=active, 0=idle
	// status outputs:
	output wire [`DIM_MEMADDR - 1 : 0]				PC_o,			// program counter
	output wire [7:0]			cmd_o,			// current command
	output wire [23:0]		data_o,			// current data or delay_count
	output wire [31:0]		W_o,				// W register
	output wire [3:0]			state_o
	
);	


///////////////////////////////////////////////////
// pulse sequencer instruction definitions
// The D subfix means the operand is a direct number
///////////////////////////////////////////////////
	localparam			PP_NOP		= 8'h00;	// no operation	
	localparam			PP_DDSFRQ	= 8'h01;    // set dds frequency
	localparam			PP_DDSAMP	= 8'h02;	// set dds amplitude
	localparam			PP_DDSPHS	= 8'h03;	// set dds phase
	localparam			PP_DDSCHN	= 8'h04;	// set dds channel	
	localparam			PP_SHUTTER  = 8'h05;    // set shutter state	
	localparam			PP_COUNT		= 8'h06;	// Delay n cycles, adding photon counts to W
	localparam        PP_COUNTD 	= 8'h07;
	localparam			PP_DELAY		= 8'h08;	// Delay n cycles, no photon counting
	localparam			PP_DELAYD 	= 8'h09;	
	localparam			PP_LDWR		= 8'h0A;	// W <= *REG
	localparam			PP_LDWRD		= 8'h0B;	// W <= REG
	localparam			PP_LDWI		= 8'h0C;	// W <= *INDF (store *INDF into W)
	localparam			PP_STWR		= 8'h0D;	// *REG <= W
	localparam			PP_STWI		= 8'h0E;	// *INDF <= W (store W into location at INDF)
	localparam			PP_LDINDF	= 8'h0F;	// INDF <= *REG
	localparam			PP_ANDW		= 8'h10;	// W = W & *REG
	localparam			PP_ANDWD		= 8'h11;
	localparam			PP_ADDW		= 8'h12;	// W = W + *REG
	localparam			PP_ADDWD		= 8'h13; 
	localparam			PP_INC		= 8'h14;	// W = *REG + 1
	localparam			PP_DEC		= 8'h15;	// W = *REG - 1
	localparam			PP_CLRW		= 8'h16;    // W = 0
	localparam			PP_CMP		= 8'h17;	// W <= W - *REG
	localparam			PP_CMPD		= 8'h18;
	localparam			PP_JMP		= 8'h19;	// Jump
	localparam			PP_JMPZ		= 8'h1A;	// Jump to specified location if W = 0
	localparam			PP_JMPNZ		= 8'h1B;	// Jump to specified location if W != 0
	//additional operators by Rick:
	localparam			PP_MUL		= 8'h1C; 	//W <= W * REG
	localparam			PP_MULD		= 8'h1D;
	localparam        PP_SUB      = 8'h1E; 	//W <= W - REG
	localparam			PP_SUBD		= 8'h1F;
	localparam			PP_SHL		= 8'h20;	  //W <= W << REG;
	localparam			PP_SHLD		= 8'h21;
	localparam			PP_SHR		= 8'h22;	  //W <= W >> REG;
	localparam			PP_SHRD		= 8'h23;
	//corrector debug commands
	localparam        PP_PCSD		= 8'h24;	//state detection with correlation method. PP_PCSD threshold. W = 1 for bright, 0 for dark.
	localparam			PP_PCTA		= 8'h25;	//tao 1
	localparam        PP_PCTB     = 8'h26; //tao 2
	localparam			PP_PCW		= 8'h27;	//dt0
	localparam			PP_PCSW		= 8'h28;	//expire time
	//Rick modification
	localparam			PP_JMPGZ		= 8'h29;	//Jump if W > 0
	localparam			PP_JMPLZ		= 8'h2A; //Jump if W < 0
	localparam			PP_JMPGE    = 8'h2B;	//Jump if W >= 0
	localparam        PP_JMPLE  	= 8'h2C; //Jump if W <= 0
	//Rick Modification
	localparam			PP_CNT2W    = 8'h2D;		//W <= pmta_i - r_PMTRef, r_PMTLast <= pmta_i;
	localparam			PP_CNTD2W   = 8'h2E;		//W <= pmta_i - r_PMTLast, r_PMTLast <= pmta_i;
	localparam        PP_ZCNT		= 8'h2F;		//r_PMTRef <= pmta_i 
	//Rick Modification
	localparam        PP_ZTS		= 8'h30;        //r_TimeRef <= r_TimeStick
	localparam			PP_TS2W		= 8'h31;        //W <= r_TimeStick - r_TimeRef
	//Digial Click command
	localparam			PP_DCLK		= 8'h32;		 //rDCDelay_o <= REG
	localparam        PP_DSTEPH   = 8'h33;        //rDCStep_o <= REG, rDCTrig_o <= 1;
	localparam			PP_DSTEPL   = 8'h34;        //rDCStep_o <= REG, rDCTrig_o <= 1; but no real pulse out;
	//AWG command
	localparam        PP_AWG		= 8'h35;        //start AWG
	localparam        PP_WAITL    = 8'h36; 		  //wait for line trigger
	localparam			PP_STOP		= 8'hFF;		  // end program
	
	
	//9959/58
	localparam	C_DDS_INIT = 4'h0;
	localparam 	C_DDS_CH = 4'h1;
	localparam  C_DDS_FRQ = 4'h2;
	localparam  C_DDS_PH = 4'h3;
	localparam  C_DDS_AMP = 4'h4;
	
	//9910
	localparam 	C_DDSS_INIT	= 2'h3;
	localparam 	C_DDSS_FRQ 	= 2'h2;
	localparam 	C_DDSS_PHS 	= 2'h1;
	localparam 	C_DDSS_AMP 	= 2'h0;
	
	// Register definitions
	reg 			[31:0]			CMD;
	reg signed 		[31:0]			W;
	reg 			[`DIM_MEMADDR - 1:0]			PC, INDF;
	reg 			[23:0]			delay_counter_f;
	reg								ltrig_arm;		//line trigger related, added by Rick
	reg				[1:0]			ls;
	integer 						i;
	//PMT Monitor
	reg				[31:0]		r_PMTRef;
	reg				[31:0]		r_PMTLast;

   // synthesis attribute INIT of state_f is "R"
	reg [3:0]			state_f;			//changed from 2bit to 32bit.
	localparam			STATE_STOP		=  4'h0;
	localparam			STATE_SETUP	  	=  4'h1;
	localparam			STATE_EXEC		=  4'h2;
	localparam			STATE_WAIT		=  4'h3;
	localparam			STATE_HOLD		=  4'h4;
	//correlator
	localparam        STATE_PC_START	=  4'h5;
	localparam			STATE_PC_BUSY  	=  4'h6;
	localparam			STATE_PC_FINISH	=  4'h7;
	localparam			START_VECT		=  4'h0;
	
	wire					delay;
	wire [7:0]			cmd_code;
	wire [23:0]			cmd_data;
	
	assign				cmd_code = (state_f == STATE_SETUP) ? pp_din_i[31:24] : CMD[31:24];
	assign				cmd_data = (state_f == STATE_SETUP) ? pp_din_i[23:0] : CMD[23:0];
	assign				delay = (state_f == STATE_EXEC) ? (|pp_din_i[23:0] & cmd_code == PP_DELAY) |
														  (cmd_code == PP_COUNT) |
														  (cmd_code == PP_DDSAMP)|
														  (cmd_code == PP_DDSFRQ)|
														  (cmd_code == PP_DDSPHS)|
														  (cmd_code == PP_DDSCHN)|
														  (cmd_code == PP_DSTEPH)|
														  (cmd_code == PP_DSTEPL)|
														  (cmd_code == PP_AWG): (|delay_counter_f) | (~(&hw_ready_i)) | rDDSTrig_o | rDCTrig_o | rAWGTrig_o; 
	
	assign				pp_active_o = ~(state_f == STATE_STOP);	
	assign				PC_o = PC;
	assign				W_o = W;
	assign				cmd_o = cmd_code;
	assign				data_o = (state_f == STATE_WAIT)? delay_counter_f : cmd_data;


	// Memory address control
	wire					wNeedIndfAddr;
	assign 				wNeedIndfAddr = (cmd_code == PP_LDWI) | (cmd_code == PP_STWI);

	assign 				pp_addr_o = (state_f != STATE_SETUP) ? PC :
									(wNeedIndfAddr) ? INDF : cmd_data[`DIM_MEMADDR - 1 : 0];

	// Memory write control
	assign 				pp_we_o = (state_f == STATE_SETUP) & 
								  ((cmd_code == PP_STWI) | (cmd_code == PP_STWR));

	assign				pp_dout_o = W;
	assign				state_o = state_f;

	// State machine - combinatorial part
	function 			[3:0] 	next_state;
		input 			[3:0]	state;
		input					start;
		input				    stop;
		input				    delay;
		input              trig_arm;
		input           	lt;
		input			 		i_PCStart;
		input					i_PCFinish;
	
	case (state)
	STATE_STOP:
		if (start) next_state = STATE_SETUP;
		else next_state = STATE_STOP;
	STATE_SETUP:
		if (stop) next_state = STATE_STOP;
		//else if (delay) next_state = STATE_WAIT;
		else next_state = STATE_EXEC;
	STATE_EXEC:
		if (stop) next_state = STATE_STOP;
		else if (delay) next_state = STATE_WAIT;
		else if (trig_arm) next_state = STATE_HOLD;
		else if (i_PCStart) next_state = STATE_PC_START;
		else next_state = STATE_SETUP;
	STATE_WAIT:
		if (stop) next_state = STATE_STOP;
		else if (delay) next_state = STATE_WAIT;
		else next_state = STATE_SETUP;
	STATE_HOLD:
		if (stop) 
			next_state = STATE_STOP;
		else if (lt) // trigger recieved
			next_state = STATE_SETUP;
		else
			next_state = STATE_HOLD;
			
	STATE_PC_START:
		if (i_PCStart) next_state = STATE_PC_BUSY;
		else next_state = STATE_PC_START;
	STATE_PC_BUSY:
		if (stop) next_state = STATE_STOP;
		else if (i_PCFinish) next_state = STATE_PC_FINISH;
		else next_state = STATE_PC_BUSY;
	STATE_PC_FINISH: next_state = STATE_SETUP;
	
	
			
	default:
		    next_state = STATE_STOP;
	endcase // case(state)
	endfunction // next_state	
		
	//clock monitor
	reg [63:0] r_TimeStick, r_TimeRef;
	always @ (posedge clk_i) 
	begin
		if (reset_i)
			r_TimeStick <= 0;
			
		else
			r_TimeStick <= r_TimeStick + 1;
	end

	//line trigger monitor
	reg [31:0]  r_linetrig_delay, r_linetrig_cnt;
	reg lts_state;
	reg lt;
	
	localparam lts_idle = 1'b0;
	localparam lts_wait = 1'b1;
	
		
	always @(posedge clk_i)
	begin
		if (reset_i)
			begin
				ls <= 2'b0;
				lts_state <= lts_idle;
				lt <= 0;
				r_linetrig_cnt <= 0;
			end
		else
			begin
				case (lts_state)
				lts_idle:
					begin
						ls <= {ls[0], linetrig_i};		
						lt <= 1'b0;
						r_linetrig_cnt <= 0;
						if (!ls[1] && ls[0])
						begin
							lt <= 1'b1;
							lts_state <= lts_wait;
						end						
					end
				lts_wait:
					begin
						lt <= 1'b0;
						r_linetrig_cnt <= r_linetrig_cnt + 1;
						if (r_linetrig_cnt >= r_linetrig_delay)
							lts_state <= lts_idle;
						else
							lts_state <= lts_wait;
					end			
				endcase
			end			
	end
	

	//correlator local parameters
	reg r_PCDone, r_PCBright;
	reg [31:0] r_PCTimeSpan;
	
	always @ (posedge clk_i) begin
		r_PCTimeSpan <= i_PCTimeSpan;
		r_PCDone <= i_PCDone;
		r_PCBright <= i_PCBright;
		end
		
	reg [1:0]  rCmpResult;
	localparam C_CMP_E 	= 2'b0;
	localparam C_CMP_G   = 2'b1;
	localparam C_CMP_L	= 2'b10;
		
	always @(posedge clk_i)
		if (reset_i) 
		begin
			CMD <= {PP_NOP, 24'h0};
			state_f <= STATE_STOP;
			W <= 32'h0;
			delay_counter_f <= 24'h0;
			rDDSTrig_o <= 1'b0;
			rDCTrig_o <= 0;
			rAWGTrig_o <= 0;
			rAD9959Cmd_o <= 4'h0;	
			INDF <= `DIM_MEMADDR'b0;
			rCmpResult <= 0;
						
			rDCStep_o <= 0;
			rDCDelay_o <= 2;
			rDCHlvl_o <= 1;
			
			ltrig_arm <= 1'b0;
			
			rPCStart_o <= 1'b0;
			rPCTao1_o <= 1;
			rPCTao2_o <= 1; //default value
			r_PMTLast <= pmta_i;
			
			r_linetrig_delay <= 18;
			
			rDDSBrdIdx_o 	<= 4'hF;
			rAWGIdx_o 		<= 4'hF;
		end 
		else 
		begin
			state_f <= next_state(state_f, start_i, stop_i | (cmd_code == PP_STOP), delay, ltrig_arm, lt, rPCStart_o, r_PCDone);
			case (state_f)
			STATE_STOP: begin
				CMD 			<= {PP_NOP, 24'h0};
				PC 			<= `DIM_MEMADDR'b0; //START_VECT;
				INDF 			<= `DIM_MEMADDR'b0;
				delay_counter_f <= 24'h0;
				W 				<= 32'h0;
				rDDSTrig_o <= 1'b0;
				ltrig_arm  	<= 1'b0;
			    rPCTao1_o 	<= 1;
				rPCTao2_o 	<= 1; //default value
				r_PMTLast 	<= pmta_i;
				
				rDCStep_o 	<= 0;
			   rDCDelay_o 	<= 2;
				end
				
			STATE_SETUP: begin 
				if (
				((cmd_code == PP_JMPZ)  & (rCmpResult == C_CMP_E)) | 
				((cmd_code == PP_JMPNZ) & (rCmpResult != C_CMP_E)) |
				((cmd_code == PP_JMPGZ) & (rCmpResult == C_CMP_G)) | 
				((cmd_code == PP_JMPLZ) & (rCmpResult == C_CMP_L)) |
				((cmd_code == PP_JMPGE) & (rCmpResult != C_CMP_L))|
				((cmd_code == PP_JMPLE) & (rCmpResult != C_CMP_G))|
				(cmd_code == PP_JMP)
				)
					PC <= cmd_data[`DIM_MEMADDR - 1 : 0];  //An address
				else
					PC <= PC + 14'b1;
				CMD <= pp_din_i;		  // Remember current command
			end // case: STATE_SETUP
			STATE_EXEC: begin		
				case (cmd_code)
				// dds commands: board index stored in cmd_data[23:20], channel stored in cmd_data[19:16]
				PP_DDSFRQ: 
					begin
						rDDSBrdIdx_o <= cmd_data[23:20];
						rDDSTrig_o 	 <= 1'b1;
						
						rAD9959Cmd_o 	<= C_DDS_FRQ;							
						rAD9959Data_o 	<= pp_din_i;
						
						rAD9910Cmd_o 	<= {C_DDSS_FRQ, pp_din_i};
					end
				PP_DDSAMP: begin
				    rDDSBrdIdx_o <= cmd_data[23:20];
					rDDSTrig_o 	<= 1'b1;
					
					rAD9959Cmd_o 	<= C_DDS_AMP;
					rAD9959Data_o 	<= {22'h0, pp_din_i[9:0]};							

					rAD9910Cmd_o 	<= {C_DDSS_AMP, 18'b0, pp_din_i[13:0]};
				end
				PP_DDSPHS: begin
				   rDDSBrdIdx_o 	<= cmd_data[23:20];
					rDDSTrig_o 		<= 1'b1;

					rAD9959Cmd_o <= C_DDS_PH;
					rAD9959Data_o <= {18'h0, pp_din_i[13:0]};
					
					rAD9910Cmd_o <= {C_DDSS_PHS, 16'b0, pp_din_i[15:0]};
				end
				PP_DDSCHN: begin
					rDDSBrdIdx_o <= {cmd_data[23:20]};
					rDDSTrig_o <= 1'b1;

					rAD9959Cmd_o <= C_DDS_CH;							
					rAD9959Data_o <= {28'h0, cmd_data[19:16]};  
				end

				PP_DCLK: rDCDelay_o <= pp_din_i[15:0];
				PP_DSTEPH:
					begin
							rDCStep_o <= pp_din_i[15:0];
							rDCTrig_o <= 1'b1;
							rDCHlvl_o <= 1'b1;
					end
				PP_DSTEPL:
					begin
							rDCStep_o <= pp_din_i[15:0];
							rDCTrig_o <= 1'b1;
							rDCHlvl_o <= 1'b0;
					end
				PP_AWG:
					begin
						  rAWGIdx_o 				<= cmd_data[23:20];
						  rAWGTrig_o 				<= 1'b1;
						  rAWG9959StartAddr_o 	<= pp_din_i[15:0];
						  rAWG9910StartAddr_o 	<= pp_din_i[15:0];
					end
				PP_SHUTTER: rShutter_o <= cmd_data[3:0];

				// Logic commands
				PP_COUNT: 
				begin
					W <= 32'h0;
					delay_counter_f <= pp_din_i[23:0];
				end
				PP_COUNTD:
					begin
						W <= 32'h0;
						delay_counter_f <= {9'b0, cmd_data[23:1]};
					end
				PP_DELAY: 
					delay_counter_f <= |pp_din_i[23:0] ? pp_din_i[23:0] - 24'h1 : 24'h0;
				
				//correlator command
				PP_PCTA:	rPCTao1_o <= {8'b0, pp_din_i[23:0]}*20;
				PP_PCTB: rPCTao2_o <= {8'b0, pp_din_i[23:0]}*20;
				PP_PCSD:	rPCStart_o <= 1'b1;
				PP_PCW:		W <= r_PCBright;
				PP_PCSW:	
				begin
					case(pp_din_i[1:0])	//0 for timespan, 1 for Tao1, 2 for Tao2
					2'b0:	   W <= i_PCTimeSpan;
					2'b1: 	W <= rPCTao1_o;
					2'b10: 	W <= rPCTao2_o;
					2'b11: 	W <= i_PCArrival;
					default: W <= r_PCBright;
					endcase
				end
				
				PP_LDWR: W <= pp_din_i;
				PP_LDWRD: W <= {9'b0, cmd_data[23:1]};
				PP_LDWI: W <= pp_din_i;
				PP_LDINDF:  INDF <= pp_din_i[`DIM_MEMADDR - 1 : 0];
				PP_ANDW: W <= W & pp_din_i;
				PP_ANDWD: W <= W & {9'b0, cmd_data[23:1]};
				PP_ADDW: W <= W + pp_din_i;
				PP_ADDWD: W <= W + {9'h0, cmd_data[23:1]};
				PP_INC:  W <= pp_din_i + 32'h1;
				PP_DEC:  W <= pp_din_i - 32'h1;
				PP_CMP:  rCmpResult <= W > pp_din_i ? C_CMP_G : (W == pp_din_i ? C_CMP_E : C_CMP_L);
				PP_CMPD: rCmpResult <= W[22:0] > cmd_data[23:1] ? C_CMP_G : ( W[22:0] == cmd_data[23:1] ? C_CMP_E : C_CMP_L );
				PP_CLRW: W <= 32'h0;
				PP_MUL:	 W <= W * pp_din_i;
				PP_MULD:  W <= W * {9'b0, cmd_data[23:1]};
				PP_SUB:	 W <= W - pp_din_i;
				PP_SUBD:  W <= W - {9'b0, cmd_data[23:1]};
				PP_SHL:	 W <= W <<< pp_din_i;	
				PP_SHLD:  W <= W <<< cmd_data[23:1];
				PP_SHR:	 W <= W >>> pp_din_i;
				PP_SHR:	 W <= W >> cmd_data[23:1];
				PP_WAITL: 
					begin
						r_linetrig_delay <= pp_din_i;
						ltrig_arm <= 1'b1;
					end
				PP_CNT2W:  
				begin
					W <= pmta_i - r_PMTRef;
					r_PMTLast <= pmta_i;
				end
				PP_CNTD2W:
				begin
					W <= pmta_i - r_PMTLast;
					r_PMTLast <= pmta_i;
				end
				PP_ZCNT:	r_PMTRef <= pmta_i;
				
				PP_ZTS:	r_TimeRef <= r_TimeStick;
				PP_TS2W:	W <= r_TimeStick - r_TimeRef;
								
				endcase
			end // case: STATE_EXEC
						
			//correlator states
			STATE_PC_START: ;
			STATE_PC_BUSY:	rPCStart_o <= 1'b0;
			STATE_PC_FINISH: W <= r_PCBright;
			
			STATE_WAIT: begin
				rDDSTrig_o <= 1'b0;
				rDCTrig_o <= 1'b0;
				rAWGTrig_o <= 1'b0;
				
				if (|delay_counter_f) delay_counter_f <= delay_counter_f - 24'h1;
				if (cmd_code == PP_COUNT) W <= W + pmt_i;
			end

			STATE_HOLD:
			begin
				if (ltrig_arm) //reset ltrig_arm
					ltrig_arm <= 1'b0;
			end

			default: ;
			endcase // case(state_f)
		end

endmodule
