vlib work
vmap work

vlog \
rtl/include/miriscv_pkg.sv \
rtl/include/miriscv_alu_pkg.sv \
rtl/include/miriscv_cu_pkg.sv \
rtl/include/miriscv_decode_pkg.sv \
rtl/include/miriscv_gpr_pkg.sv \
rtl/include/miriscv_lsu_pkg.sv \
rtl/include/miriscv_mdu_pkg.sv \
rtl/include/miriscv_opcodes_pkg.sv \
rtl/miriscv_alu.sv \
rtl/miriscv_control_unit.sv \
rtl/miriscv_core.sv \
rtl/miriscv_decoder.sv \
rtl/miriscv_decode_stage.sv \
rtl/miriscv_div.sv \
rtl/miriscv_execute_stage.sv \
rtl/miriscv_fetch_stage.sv \
rtl/miriscv_fetch_unit.sv \
rtl/miriscv_gpr.sv \
rtl/miriscv_lsu.sv \
rtl/miriscv_mdu.sv \
rtl/miriscv_memory_stage.sv \
rtl/miriscv_signextend.sv \
testsoc/miriscv_ram.sv \
testsoc/miriscv_test_soc.sv \
testsoc/apb_timer/apb_timer.sv \
testsoc/apb_timer/timer.sv \
tb/tb_miriscv_coremark.sv

vcom \
testsoc/apb_uart/apb_uart.vhd \
testsoc/apb_uart/slib_fifo.vhd \
testsoc/apb_uart/uart_baudgen.vhd \
testsoc/apb_uart/slib_clock_div.vhd \
testsoc/apb_uart/slib_input_filter.vhd \
testsoc/apb_uart/uart_interrupt.vhd \
testsoc/apb_uart/slib_counter.vhd \
testsoc/apb_uart/slib_input_sync.vhd \
testsoc/apb_uart/uart_receiver.vhd \
testsoc/apb_uart/slib_edge_detect.vhd \
testsoc/apb_uart/slib_mv_filter.vhd \
testsoc/apb_uart/uart_transmitter.vhd

vsim -suppress 7061 tb_miriscv_coremark

# add log -r /*

# add wave -divider "******* SoC *******"
# add wave sim:/DUT/*
run -all
# wave zoom full
