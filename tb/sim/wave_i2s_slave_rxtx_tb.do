onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2s_slave_rxtx_tb/clk_i
add wave -noupdate /i2s_slave_rxtx_tb/reset_n_i
add wave -noupdate /i2s_slave_rxtx_tb/mclk_i
add wave -noupdate -label {tx master model send val} -radix hexadecimal -radixshowbase 0 /i2s_slave_rxtx_tb/i2s_master_tx_model_inst/send_data/val
add wave -noupdate /i2s_slave_rxtx_tb/i2s_bclk_tx_out
add wave -noupdate /i2s_slave_rxtx_tb/i2s_recdat_tx_out
add wave -noupdate /i2s_slave_rxtx_tb/i2s_reclr_tx_out
add wave -noupdate -radix hexadecimal /i2s_slave_rxtx_tb/dat_rx_out
add wave -noupdate -radix hexadecimal /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/dat_rx_out
add wave -noupdate /i2s_slave_rxtx_tb/dat_rx_lr_out
add wave -noupdate /i2s_slave_rxtx_tb/dat_rx_valid_out
add wave -noupdate -label {rx_main_p data_pointer} -radix unsigned -radixshowbase 0 /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/main_p/data_pointer
add wave -noupdate /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/main_p/is_startup
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7365 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 338
configure wave -valuecolwidth 82
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
WaveRestoreZoom {7155 ns} {8076 ns}
