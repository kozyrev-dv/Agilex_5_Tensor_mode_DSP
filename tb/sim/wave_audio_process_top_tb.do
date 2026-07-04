onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /audio_process_top_tb/clk
add wave -noupdate /audio_process_top_tb/clk_aud
add wave -noupdate /audio_process_top_tb/reset_n
add wave -noupdate /audio_process_top_tb/dut/reset_hard_n
add wave -noupdate /audio_process_top_tb/dut/state
add wave -noupdate /audio_process_top_tb/dut/ssm2603_config_inst/state
add wave -noupdate /audio_process_top_tb/dut/ssm2603_config_inst/delay_cnt
add wave -noupdate /audio_process_top_tb/dut/busy_aud_config
add wave -noupdate /audio_process_top_tb/dut/i2c_master_inst/state
add wave -noupdate /audio_process_top_tb/dut/i2c_master_inst/addr_rw
add wave -noupdate /audio_process_top_tb/dut/i2c_master_inst/data_wr_i
add wave -noupdate /audio_process_top_tb/dut/i2c_master_inst/data_tx
add wave -noupdate /audio_process_top_tb/dut/i2c_master_inst/data_clk
add wave -noupdate /audio_process_top_tb/dut/i2c_busy
add wave -noupdate /audio_process_top_tb/FPGA_I2C_SDA
add wave -noupdate /audio_process_top_tb/FPGA_I2C_SCL
add wave -noupdate /audio_process_top_tb/AUD_XCK
add wave -noupdate /audio_process_top_tb/AUD_BCLK
add wave -noupdate /audio_process_top_tb/AUD_ADCLRCK
add wave -noupdate /audio_process_top_tb/AUD_ADCDAT
add wave -noupdate /audio_process_top_tb/AUD_DACLRCK
add wave -noupdate /audio_process_top_tb/AUD_DACDAT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1999970 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 331
configure wave -valuecolwidth 124
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1999857 ns} {2000219 ns}
