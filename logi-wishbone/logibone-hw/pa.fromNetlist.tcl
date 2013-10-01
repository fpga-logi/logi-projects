
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name logibone-wishbone -dir "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-wishbone/logibone-hw/planAhead_run_1" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-wishbone/logibone-hw/logibone_wishbone.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/jpiat/development/FPGA/logi-family/logi-projects/logi-wishbone/logibone-hw} {ipcore_dir} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "logibone_ra2.ucf" [current_fileset -constrset]
add_files [list {logibone_ra2.ucf}] -fileset [get_property constrset [current_run]]
link_design
