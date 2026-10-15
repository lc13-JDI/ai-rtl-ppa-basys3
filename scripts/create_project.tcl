# Adapted from vivado/create_reaction_project.tcl; does not launch implementation.
set root_dir [file normalize [file join [file dirname [info script]] ..]]
set proj_dir [file join $root_dir build reaction_project]
if {[file exists $proj_dir]} {error "Project already exists: $proj_dir; choose a fresh output directory."}
create_project reaction_project $proj_dir -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
add_files -norecurse [glob [file join $root_dir rtl *.v]]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints basys3_reaction.xdc]
add_files -fileset sim_1 -norecurse [glob [file join $root_dir sim *.v]]
set_property top reaction_top [current_fileset]
set_property top tb_reaction_fsm [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Created project: $proj_dir"
