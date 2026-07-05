onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2s_slave_rxtx_tb/mclk_i
add wave -noupdate /i2s_slave_rxtx_tb/reset_n_i
add wave -noupdate /i2s_slave_rxtx_tb/bclk_o
add wave -noupdate /i2s_slave_rxtx_tb/recdat_o
add wave -noupdate /i2s_slave_rxtx_tb/reclr_o
add wave -noupdate /i2s_slave_rxtx_tb/i2s_master_tx_model_inst/send_data/val
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1163 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 211
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
WaveRestoreZoom {0 ns} {11195 ns}
