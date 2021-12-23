vlib work
vlib activehdl

vlib activehdl/fifo_generator_v13_2_5
vlib activehdl/xil_defaultlib

vmap fifo_generator_v13_2_5 activehdl/fifo_generator_v13_2_5
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work fifo_generator_v13_2_5  -v2k5 \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_5 -93 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_5  -v2k5 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../Sources/Core/fifo_w32_1024_r256_128/sim/fifo_w32_1024_r256_128.v" \


vlog -work xil_defaultlib \
"glbl.v"

