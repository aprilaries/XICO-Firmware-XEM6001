
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name DDS -dir "C:/Users/Admin/Xilinx Projects/BlackDDS_LR_AS_ND - Copy/planAhead_run_2" -part xc3s1500fg320-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "ddsconnections.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {PISO.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
add_files [list {okCore.ngc}]
set hdlfile [add_files [list {ppseq.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ppmem.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {pipectrl.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
add_files [list {okWireOut.ngc}]
add_files [list {okWireIn.ngc}]
add_files [list {okTriggerIn.ngc}]
add_files [list {okPipeOut.ngc}]
add_files [list {okPipeIn.ngc}]
set hdlfile [add_files [list {okLibrary.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {clock_top.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {AWG_AD9958.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {AD9958Dr.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {DDSfirmware.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
add_files [list {ppmem.ngc}]
set_property top DDSfirmware $srcset
add_files [list {ddsconnections.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s1500fg320-4
