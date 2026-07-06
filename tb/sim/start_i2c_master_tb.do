quit -sim

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
do compile_i2c_master_src.do
vlog -work work -sv ../i2c_master_tb.sv
vsim -voptargs="+acc" work.i2c_master_tb
do wave_i2c_master_tb.do
run -all