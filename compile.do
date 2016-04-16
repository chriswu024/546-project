# Compilation File for Modelsim

vlib work
vlib mti_lib

vlog mc_decoder.v

vlog -sv instructions.sv
vlog -sv definition.svh
vlog -sv interface.sv
vlog -sv generator.sv
vlog -sv driver.sv
vlog -sv scoreboard.sv
vlog -sv monitor_new.sv
vlog -sv environment_new.sv
vlog -sv testbench.sv
vlog -sv top.sv

vsim -novopt mti_lib.top 

