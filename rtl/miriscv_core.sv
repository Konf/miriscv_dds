/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_core
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_alu_pkg::ALU_OP_W;
  import miriscv_mdu_pkg::MDU_OP_W;
  import miriscv_lsu_pkg::MEM_ACCESS_W;
  import miriscv_decode_pkg::WB_SRC_W;
(
  // Clock, reset
  input  logic              clk_i,
  input  logic              arstn_i,

  input  logic [XLEN-1:0]   boot_addr_i,

  // Instruction memory interface
  input  logic              instr_rvalid_i,
  input  logic [XLEN-1:0]   instr_rdata_i,
  output logic              instr_req_o,
  output logic [XLEN-1:0]   instr_addr_o,

  // Data memory interface
  input  logic              data_rvalid_i,
  input  logic [XLEN-1:0]   data_rdata_i,
  output logic              data_req_o,
  output logic              data_we_o,
  output logic [XLEN/8-1:0] data_be_o,
  output logic [XLEN-1:0]   data_addr_o,
  output logic [XLEN-1:0]   data_wdata_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  localparam f = 3'd0; // fetch
  localparam d = 3'd1; // decode
  localparam e = 3'd2; // execute
  localparam m = 3'd3; // memory
  localparam w = 3'd4; // writeback

  logic [XLEN-1:0]         current_pc      [f:f];
  logic [XLEN-1:0]         next_pc         [f:m];

  logic [ILEN-1:0]         instr           [f:f];
  logic                    valid           [f:m];

  logic                    gpr_wr_en       [d:m];
  logic [GPR_ADDR_W-1:0]   gpr_wr_addr     [d:m];
  logic [WB_SRC_W-1:0]     gpr_src_sel     [d:e];
  logic [XLEN-1:0]         gpr_wr_data     [m:m];

  logic [XLEN-1:0]         op1             [d:d];
  logic [XLEN-1:0]         op2             [d:d];

  logic [XLEN-1:0]         alu_result      [e:e];
  logic [XLEN-1:0]         mdu_result      [e:e];

  logic [ALU_OP_W-1:0]     alu_operation   [d:d];
  logic                    mdu_req         [d:d];
  logic [MDU_OP_W-1:0]     mdu_operation   [d:d];

  logic                    mem_req         [d:e];
  logic                    mem_we          [d:e];
  logic [MEM_ACCESS_W-1:0] mem_size        [d:e];
  logic [XLEN-1:0]         mem_addr        [d:e];
  logic [XLEN-1:0]         mem_data        [d:e];

  logic                    branch          [d:m];
  logic                    jal             [d:m];
  logic                    jalr            [d:m];
  logic [XLEN-1:0]         target_pc       [d:m];
  logic                    prediction      [d:m];
  logic                    br_j_taken      [d:m];

  logic                    cu_stall_req    [f:m];
  logic                    cu_stall        [f:m];
  logic                    cu_kill         [f:m];
  logic                    cu_force        [f:f];
  logic [XLEN-1:0]         cu_force_pc     [f:f];

  logic [GPR_ADDR_W-1:0]   cu_rs1_addr     [f:f];
  logic                    cu_rs1_req      [f:f];
  logic [GPR_ADDR_W-1:0]   cu_rs2_addr     [f:f];
  logic                    cu_rs2_req      [f:f];

  /////////////////
  // Fetch stage //
  /////////////////

  miriscv_fetch_stage
  i_fetch_stage
  (
    .clk_i          ( clk_i              ),
    .arstn_i        ( arstn_i            ),

    .cu_kill_f_i    ( cu_kill        [f] ),
    .cu_stall_f_i   ( cu_stall       [f] ),
    .cu_force_f_i   ( cu_force       [f] ),
    .cu_force_pc_i  ( cu_force_pc    [f] ),
    .f_stall_req_o  ( cu_stall_req   [f] ),

    .instr_rvalid_i ( instr_rvalid_i     ),
    .instr_rdata_i  ( instr_rdata_i      ),
    .instr_req_o    ( instr_req_o        ),
    .instr_addr_o   ( instr_addr_o       ),

    .f_instr_o      ( instr          [f] ),
    .f_current_pc_o ( current_pc     [f] ),
    .f_next_pc_o    ( next_pc        [f] ),
    .f_valid_o      ( valid          [f] )
  );


  //////////////////
  // Decode stage //
  //////////////////

  miriscv_decode_stage
  i_decode_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_d_i         ( cu_kill         [d] ),
    .cu_stall_d_i        ( cu_stall        [d] ),
    .cu_stall_f_i        ( cu_stall        [f] ),
    .d_stall_req_o       ( cu_stall_req    [d] ),

    .f_instr_i           ( instr           [f] ),
    .f_current_pc_i      ( current_pc      [f] ),
    .f_next_pc_i         ( next_pc         [f] ),
    .f_valid_i           ( valid           [f] ),

    .m_gpr_wr_en_i       ( gpr_wr_en       [m] ),
    .m_gpr_wr_data_i     ( gpr_wr_data     [m] ),
    .m_gpr_wr_addr_i     ( gpr_wr_addr     [m] ),

    .d_valid_o           ( valid           [d] ),

    .d_op1_o             ( op1             [d] ),
    .d_op2_o             ( op2             [d] ),

    .d_alu_operation_o   ( alu_operation   [d] ),
    .d_mdu_req_o         ( mdu_req         [d] ),
    .d_mdu_operation_o   ( mdu_operation   [d] ),

    .d_mem_req_o         ( mem_req         [d] ),
    .d_mem_we_o          ( mem_we          [d] ),
    .d_mem_size_o        ( mem_size        [d] ),
    .d_mem_addr_o        ( mem_addr        [d] ),
    .d_mem_data_o        ( mem_data        [d] ),

    .d_gpr_wr_en_o       ( gpr_wr_en       [d] ),
    .d_gpr_wr_addr_o     ( gpr_wr_addr     [d] ),
    .d_gpr_src_sel_o     ( gpr_src_sel     [d] ),

    .d_branch_o          ( branch          [d] ),
    .d_jal_o             ( jal             [d] ),
    .d_jalr_o            ( jalr            [d] ),
    .d_target_pc_o       ( target_pc       [d] ),
    .d_next_pc_o         ( next_pc         [d] ),
    .d_prediction_o      ( prediction      [d] ),
    .d_br_j_taken_o      ( br_j_taken      [d] ),

    .f_cu_rs1_addr_o     ( cu_rs1_addr     [f] ),
    .f_cu_rs1_req_o      ( cu_rs1_req      [f] ),
    .f_cu_rs2_addr_o     ( cu_rs2_addr     [f] ),
    .f_cu_rs2_req_o      ( cu_rs2_req      [f] )
  );


  ///////////////////
  // Execute stage //
  ///////////////////

  miriscv_execute_stage
  i_execute_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_e_i         ( cu_kill         [e] ),
    .cu_stall_e_i        ( cu_stall        [e] ),
    .e_stall_req_o       ( cu_stall_req    [e] ),

    .d_valid_i           ( valid           [d] ),

    .d_op1_i             ( op1             [d] ),
    .d_op2_i             ( op2             [d] ),

    .d_alu_operation_i   ( alu_operation   [d] ),
    .d_mdu_req_i         ( mdu_req         [d] ),
    .d_mdu_operation_i   ( mdu_operation   [d] ),

    .d_mem_req_i         ( mem_req         [d] ),
    .d_mem_we_i          ( mem_we          [d] ),
    .d_mem_size_i        ( mem_size        [d] ),
    .d_mem_addr_i        ( mem_addr        [d] ),
    .d_mem_data_i        ( mem_data        [d] ),

    .d_gpr_wr_en_i       ( gpr_wr_en       [d] ),
    .d_gpr_wr_addr_i     ( gpr_wr_addr     [d] ),
    .d_gpr_src_sel_i     ( gpr_src_sel     [d] ),

    .d_branch_i          ( branch          [d] ),
    .d_jal_i             ( jal             [d] ),
    .d_jalr_i            ( jalr            [d] ),
    .d_target_pc_i       ( target_pc       [d] ),
    .d_next_pc_i         ( next_pc         [d] ),
    .d_prediction_i      ( prediction      [d] ),
    .d_br_j_taken_i      ( br_j_taken      [d] ),

    .e_valid_o           ( valid           [e] ),

    .e_alu_result_o      ( alu_result      [e] ),
    .e_mdu_result_o      ( mdu_result      [e] ),

    .e_mem_req_o         ( mem_req         [e] ),
    .e_mem_we_o          ( mem_we          [e] ),
    .e_mem_size_o        ( mem_size        [e] ),
    .e_mem_addr_o        ( mem_addr        [e] ),
    .e_mem_data_o        ( mem_data        [e] ),

    .e_gpr_wr_en_o       ( gpr_wr_en       [e] ),
    .e_gpr_wr_addr_o     ( gpr_wr_addr     [e] ),
    .e_gpr_src_sel_o     ( gpr_src_sel     [e] ),

    .e_branch_o          ( branch          [e] ),
    .e_jal_o             ( jal             [e] ),
    .e_jalr_o            ( jalr            [e] ),
    .e_target_pc_o       ( target_pc       [e] ),
    .e_next_pc_o         ( next_pc         [e] ),
    .e_prediction_o      ( prediction      [e] ),
    .e_br_j_taken_o      ( br_j_taken      [e] )
  );


  //////////////////
  // Memory stage //
  //////////////////

  miriscv_memory_stage
  i_memory_stage
  (
    .clk_i               ( clk_i               ),
    .arstn_i             ( arstn_i             ),

    .cu_kill_m_i         ( cu_kill         [m] ),
    .cu_stall_m_i        ( cu_stall        [m] ),
    .m_stall_req_o       ( cu_stall_req    [m] ),

    .e_valid_i           ( valid           [e] ),

    .e_alu_result_i      ( alu_result      [e] ),
    .e_mdu_result_i      ( mdu_result      [e] ),

    .e_mem_req_i         ( mem_req         [e] ),
    .e_mem_we_i          ( mem_we          [e] ),
    .e_mem_size_i        ( mem_size        [e] ),
    .e_mem_addr_i        ( mem_addr        [e] ),
    .e_mem_data_i        ( mem_data        [e] ),

    .e_gpr_wr_en_i       ( gpr_wr_en       [e] ),
    .e_gpr_wr_addr_i     ( gpr_wr_addr     [e] ),
    .e_gpr_src_sel_i     ( gpr_src_sel     [e] ),

    .e_branch_i          ( branch          [e] ),
    .e_jal_i             ( jal             [e] ),
    .e_jalr_i            ( jalr            [e] ),
    .e_target_pc_i       ( target_pc       [e] ),
    .e_next_pc_i         ( next_pc         [e] ),
    .e_prediction_i      ( prediction      [e] ),
    .e_br_j_taken_i      ( br_j_taken      [e] ),

    .m_valid_o           ( valid           [m] ),
    .m_gpr_wr_en_o       ( gpr_wr_en       [m] ),
    .m_gpr_wr_addr_o     ( gpr_wr_addr     [m] ),
    .m_gpr_wr_data_o     ( gpr_wr_data     [m] ),

    .m_branch_o          ( branch          [m] ),
    .m_jal_o             ( jal             [m] ),
    .m_jalr_o            ( jalr            [m] ),
    .m_target_pc_o       ( target_pc       [m] ),
    .m_next_pc_o         ( next_pc         [m] ),
    .m_prediction_o      ( prediction      [m] ),
    .m_br_j_taken_o      ( br_j_taken      [m] ),

    .data_rvalid_i       ( data_rvalid_i       ),
    .data_rdata_i        ( data_rdata_i        ),
    .data_req_o          ( data_req_o          ),
    .data_we_o           ( data_we_o           ),
    .data_be_o           ( data_be_o           ),
    .data_addr_o         ( data_addr_o         ),
    .data_wdata_o        ( data_wdata_o        )
  );


  //////////////////
  // Control Unit //
  //////////////////

  miriscv_control_unit
  i_control_unit
  (
    .clk_i              ( clk_i              ),
    .arstn_i            ( arstn_i            ),

    .boot_addr_i        ( boot_addr_i        ),

    .f_stall_req_i      ( cu_stall_req   [f] ),
    .d_stall_req_i      ( cu_stall_req   [d] ),
    .e_stall_req_i      ( cu_stall_req   [e] ),
    .m_stall_req_i      ( cu_stall_req   [m] ),

    .f_valid_i          ( valid          [f] ),
    .d_valid_i          ( valid          [d] ),
    .e_valid_i          ( valid          [e] ),
    .m_valid_i          ( valid          [m] ),

    .f_cu_rs1_addr_i    ( cu_rs1_addr    [f] ),
    .f_cu_rs1_req_i     ( cu_rs1_req     [f] ),
    .f_cu_rs2_addr_i    ( cu_rs2_addr    [f] ),
    .f_cu_rs2_req_i     ( cu_rs2_req     [f] ),

    .d_cu_rd_addr_i     ( gpr_wr_addr    [d] ),
    .d_cu_rd_we_i       ( gpr_wr_en      [d] ),

    .e_cu_rd_addr_i     ( gpr_wr_addr    [e] ),
    .e_cu_rd_we_i       ( gpr_wr_en      [e] ),

    .m_branch_i         ( branch         [m] ),
    .m_jal_i            ( jal            [m] ),
    .m_jalr_i           ( jalr           [m] ),
    .m_target_pc_i      ( target_pc      [m] ),
    .m_next_pc_i        ( next_pc        [m] ),
    .m_prediction_i     ( prediction     [m] ),
    .m_br_j_taken_i     ( br_j_taken     [m] ),

    .cu_stall_f_o       ( cu_stall       [f] ),
    .cu_stall_d_o       ( cu_stall       [d] ),
    .cu_stall_e_o       ( cu_stall       [e] ),
    .cu_stall_m_o       ( cu_stall       [m] ),

    .cu_kill_f_o        ( cu_kill        [f] ),
    .cu_kill_d_o        ( cu_kill        [d] ),
    .cu_kill_e_o        ( cu_kill        [e] ),
    .cu_kill_m_o        ( cu_kill        [m] ),

    .cu_force_pc_o      ( cu_force_pc    [f] ),
    .cu_force_f_o       ( cu_force       [f] )
  );

endmodule
