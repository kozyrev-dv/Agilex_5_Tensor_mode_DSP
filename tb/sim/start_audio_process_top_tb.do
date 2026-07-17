quit -sim

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
do compile_i2c_master_src.do
do compile_audio_process_top_src.do
vlog -work work -sv ../models/i2s_master_tx_model.sv
vlog -work work -sv ../models/i2s_master_rx_model.sv
vlog -work work -sv ../audio_process_top_tb.sv
vsim -voptargs="+acc" work.audio_process_top_tb

do wave_audio_process_top_tb.do
run -all