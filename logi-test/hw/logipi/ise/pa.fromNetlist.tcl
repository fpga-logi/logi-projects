
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name logipi_test -dir "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-test/logipi-hw/planAhead_run_1" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/jpiat/development/FPGA/logi-family/logi-projects/logi-test/logipi-hw/logipi_test.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/jpiat/development/FPGA/logi-family/logi-projects/logi-test/logipi-hw} {ipcore_dir} }
set_property target_constrs_file "logipi_ra3.ucf" [current_fileset -constrset]
add_files [list {logipi_ra3.ucf}] -fileset [get_property constrset [current_run]]
link_design
