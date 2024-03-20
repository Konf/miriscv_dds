vlib work
vmap work

vlog rtl/include/miriscv_pkg.sv
vlog rtl/include/miriscv_alu_pkg.sv
vlog rtl/include/miriscv_cu_pkg.sv
vlog rtl/include/miriscv_decode_pkg.sv
vlog rtl/include/miriscv_gpr_pkg.sv
vlog rtl/include/miriscv_lsu_pkg.sv
vlog rtl/include/miriscv_mdu_pkg.sv
vlog rtl/include/miriscv_opcodes_pkg.sv

vlog rtl/miriscv_alu.sv
vlog rtl/miriscv_control_unit.sv
vlog rtl/miriscv_core.sv
vlog rtl/miriscv_decoder.sv
vlog rtl/miriscv_decode_stage.sv
vlog rtl/miriscv_div.sv
vlog rtl/miriscv_execute_stage.sv
vlog rtl/miriscv_fetch_stage.sv
vlog rtl/miriscv_fetch_unit.sv
vlog rtl/miriscv_gpr.sv
vlog rtl/miriscv_lsu.sv
vlog rtl/miriscv_mdu.sv
vlog rtl/miriscv_memory_stage.sv
vlog rtl/miriscv_rvfi_controller.sv
vlog rtl/miriscv_signextend.sv

vlog testsoc/miriscv_ram.sv
vlog testsoc/miriscv_test_soc.sv
vlog testsoc/apb_timer/apb_timer.sv
vlog testsoc/apb_timer/timer.sv

vcom testsoc/apb_uart/apb_uart.vhd
vcom testsoc/apb_uart/slib_fifo.vhd
vcom testsoc/apb_uart/uart_baudgen.vhd
vcom testsoc/apb_uart/slib_clock_div.vhd
vcom testsoc/apb_uart/slib_input_filter.vhd
vcom testsoc/apb_uart/uart_interrupt.vhd
vcom testsoc/apb_uart/slib_counter.vhd
vcom testsoc/apb_uart/slib_input_sync.vhd
vcom testsoc/apb_uart/uart_receiver.vhd
vcom testsoc/apb_uart/slib_edge_detect.vhd
vcom testsoc/apb_uart/slib_mv_filter.vhd
vcom testsoc/apb_uart/uart_transmitter.vhd

vlog tb/tb_miriscv_test_soc.sv

vsim -suppress 7061 tb_miriscv_test_soc

add log -r /*

run -all
