////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 13.1
//  \   \         Application : xaw2verilog
//  /   /         Filename : divider.v
// /___/   /\     Timestamp : 10/10/2011 13:00:15
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: xaw2verilog -st /home/brownlab/Documents/Spencer/DDS_Spencer/./divider.xaw /home/brownlab/Documents/Spencer/DDS_Spencer/./divider
//Design Name: divider
//Device: xc3s1000-4fg320
//
// Module divider
// Generated by Xilinx Architecture Wizard
// Written for synthesis tool: XST
`timescale 1ns / 1ps

module divider(CLKIN_IN, 
               RST_IN, 
               CLKDV_OUT, 
               CLKIN_IBUFG_OUT, 
               CLK0_OUT, 
               LOCKED_OUT);

    input CLKIN_IN;
    input RST_IN;
   output CLKDV_OUT;
   output CLKIN_IBUFG_OUT;
   output CLK0_OUT;
   output LOCKED_OUT;
   
   wire CLKDV_BUF;
   wire CLKFB_IN;
   wire CLKIN_IBUFG;
   wire CLK0_BUF;
   wire GND_BIT;
   
   assign GND_BIT = 0;
   assign CLKIN_IBUFG_OUT = CLKIN_IBUFG;
   assign CLK0_OUT = CLKFB_IN;
   BUFG  CLKDV_BUFG_INST (.I(CLKDV_BUF), 
                         .O(CLKDV_OUT));
   //IBUFG  CLKIN_IBUFG_INST (.I(CLKIN_IN), 
   //                        .O(CLKIN_IBUFG));
   assign CLKIN_IBUFG = CLKIN_IN;
   BUFG  CLK0_BUFG_INST (.I(CLK0_BUF), 
                        .O(CLKFB_IN));
   DCM #( .CLK_FEEDBACK("1X"), .CLKDV_DIVIDE(2.0), .CLKFX_DIVIDE(1), 
         .CLKFX_MULTIPLY(4), .CLKIN_DIVIDE_BY_2("FALSE"), 
         .CLKIN_PERIOD(20.833), .CLKOUT_PHASE_SHIFT("NONE"), 
         .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), .DFS_FREQUENCY_MODE("LOW"), 
         .DLL_FREQUENCY_MODE("LOW"), .DUTY_CYCLE_CORRECTION("TRUE"), 
         .FACTORY_JF(16'h8080), .PHASE_SHIFT(0), .STARTUP_WAIT("FALSE") ) 
         DCM_INST (.CLKFB(CLKFB_IN), 
                 .CLKIN(CLKIN_IBUFG), 
                 .DSSEN(GND_BIT), 
                 .PSCLK(GND_BIT), 
                 .PSEN(GND_BIT), 
                 .PSINCDEC(GND_BIT), 
                 .RST(RST_IN), 
                 .CLKDV(CLKDV_BUF), 
                 .CLKFX(), 
                 .CLKFX180(), 
                 .CLK0(CLK0_BUF), 
                 .CLK2X(), 
                 .CLK2X180(), 
                 .CLK90(), 
                 .CLK180(), 
                 .CLK270(), 
                 .LOCKED(LOCKED_OUT), 
                 .PSDONE(), 
                 .STATUS());
endmodule
