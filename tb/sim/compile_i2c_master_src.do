vcom -2008 -work work ../../src/basics_p.vhd
vcom -work work ../../src/i2c_master.vhd
vlog -work work -sv ../models/i2c_slave_model.sv