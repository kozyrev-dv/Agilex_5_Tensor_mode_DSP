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
add wave -noupdate /i2s_slave_rxtx_tb/dat_rx_lr_out
add wave -noupdate /i2s_slave_rxtx_tb/dat_rx_valid_out
add wave -noupdate -divider Slave_rx
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/clk_i
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/reset_n_i
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/bclk_i
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/lrc_i
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/dat_i
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/dat_rx_o
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/dat_rx_lr_o
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/dat_rx_valid
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/bclk_prev
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/data_pointer
add wave -noupdate -group Slave_rx /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_rx_inst/start_channel
add wave -noupdate -divider Slave_tx
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/clk_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/reset_n_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/bclk_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/lrc_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_o
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/transacting_channel
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_cnt
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_tx_valid_i
add wave -noupdate -expand -group {Slave tx} -radix hexadecimal /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_tx_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_reg
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_tx_lr_i
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/lr_reg
add wave -noupdate -expand -group {Slave tx} /i2s_slave_rxtx_tb/i2s_slave_rxtx_inst/i2s_slave_tx_inst/dat_tx_busy_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8956 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 423
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
WaveRestoreZoom {0 ns} {70247 ns}
