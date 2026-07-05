if {![file exists work]} {
    vlib work
}
vcom -2008 -work work ../../src/i2s_slave_rx.vhd
vcom -2008 -work work ../../src/i2s_slave_tx.vhd
vcom -2008 -work work ../../src/i2s_slave_rxtx.vhd