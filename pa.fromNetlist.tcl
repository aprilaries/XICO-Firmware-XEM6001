
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name DDS -dir "C:/Users/Admin/Xilinx Projects/BlackDDS_LR_AS_ND_TAC/planAhead_run_4" -part xc3s1500fg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Admin/Xilinx Projects/BlackDDS_LR_AS_ND_TAC/DDSfirmware.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Admin/Xilinx Projects/BlackDDS_LR_AS_ND_TAC} }
set_property target_constrs_file "ddsconnections.ucf" [current_fileset -constrset]
add_files [list {ddsconnections.ucf}] -fileset [get_property constrset [current_run]]
link_design
