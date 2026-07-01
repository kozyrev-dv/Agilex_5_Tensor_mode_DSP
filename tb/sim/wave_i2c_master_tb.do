onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2c_master_tb/clk_i
add wave -noupdate /i2c_master_tb/dut/data_clk
add wave -noupdate /i2c_master_tb/reset_n_i
add wave -noupdate /i2c_master_tb/ena_i
add wave -noupdate /i2c_master_tb/addr_i
add wave -noupdate /i2c_master_tb/rw_i
add wave -noupdate /i2c_master_tb/data_wr_i
add wave -noupdate /i2c_master_tb/busy_o
add wave -noupdate /i2c_master_tb/data_rd_o
add wave -noupdate /i2c_master_tb/ack_error_o
add wave -noupdate /i2c_master_tb/sda_io
add wave -noupdate /i2c_master_tb/scl_io
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4128 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 252
configure wave -valuecolwidth 100
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
WaveRestoreZoom {3058 ns} {4585 ns}
