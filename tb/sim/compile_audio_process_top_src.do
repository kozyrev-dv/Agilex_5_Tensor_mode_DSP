if {![file exists work]} {
    vlib work
}
do compile_i2c_master_src.do
do compile_ssm2603_config_src.do
vcom -2008 -work work ../../src/audio_process_top.vhd