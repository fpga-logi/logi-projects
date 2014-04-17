
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name logibone_machine_vision -dir "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-machine-vision/logibone-hw/planAhead_run_1" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-machine-vision/logibone-hw/logibone_machine_vision.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/jpiat/development/FPGA/logi-family/logi-projects/logi-machine-vision/logibone-hw} {ipcore_dir} }
set_property target_constrs_file "logibone_ra2_1.ucf" [current_fileset -constrset]
add_files [list {logibone_ra2_1.ucf}] -fileset [get_property constrset [current_run]]
link_design
