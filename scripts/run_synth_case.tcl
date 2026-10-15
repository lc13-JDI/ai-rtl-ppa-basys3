# Adapted from the original course synthesis comparison script.
set_param general.maxThreads 8
if {$argc != 1 || [lsearch -exact {baseline ai_draft} [lindex $argv 0]] < 0} {
    puts "Usage: vivado -mode batch -source scripts/run_synth_case.tcl -tclargs baseline|ai_draft"
    exit 1
}
set case_name [lindex $argv 0]
set root_dir [file normalize [file join [file dirname [info script]] ..]]
set report_dir [file join $root_dir build synth $case_name]
file mkdir $report_dir
set replaced_modules {lfsr_random.v score_history.v buzzer_player.v}
foreach src [lsort [glob [file join $root_dir rtl *.v]]] {
    if {$case_name eq "ai_draft" && [lsearch -exact $replaced_modules [file tail $src]] >= 0} {continue}
    read_verilog $src
}
if {$case_name eq "ai_draft"} {
    foreach src [lsort [glob [file join $root_dir ai_drafts *.v]]] {read_verilog $src}
}
read_xdc [file join $root_dir constraints basys3_reaction.xdc]
synth_design -top reaction_top -part xc7a35tcpg236-1
report_utilization -file [file join $report_dir utilization.rpt]
report_utilization -hierarchical -file [file join $report_dir utilization_hierarchical.rpt]
report_timing_summary -max_paths 10 -report_unconstrained -file [file join $report_dir timing_summary.rpt]
report_timing -max_paths 5 -sort_by slack -file [file join $report_dir setup_paths.rpt]
puts "Synthesis case '$case_name' complete: $report_dir"
