/***********************************************************************************
 * Copyright (C) 2023 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * See LICENSE file for licensing details.
 *
 * This file is a part of miriscv core.
 *
 ***********************************************************************************/

module miriscv_control_unit
  import miriscv_pkg::XLEN;
  import miriscv_gpr_pkg::GPR_ADDR_W;
  import miriscv_decode_pkg::NO_BYPASS;
  import miriscv_decode_pkg::BYPASS_E;
  import miriscv_decode_pkg::BYPASS_M;
  import miriscv_decode_pkg::BYPASS_MP;
(
  input  logic                  clk_i,
  input  logic                  arstn_i,

  input  logic [XLEN-1:0]       boot_addr_i,

  input  logic                  f_stall_req_i,
  input  logic                  d_stall_req_i,
  input  logic                  e_stall_req_i,
  input  logic                  m_stall_req_i,
  input  logic                  mp_stall_req_i,

  input  logic [GPR_ADDR_W-1:0] f_cu_rs1_addr_i,
  input  logic                  f_cu_rs1_req_i,
  input  logic [GPR_ADDR_W-1:0] f_cu_rs2_addr_i,
  input  logic                  f_cu_rs2_req_i,

  input  logic [GPR_ADDR_W-1:0] d_cu_rd_addr_i,
  input  logic                  d_cu_rd_we_i,

  input  logic [GPR_ADDR_W-1:0] e_cu_rd_addr_i,
  input  logic                  e_cu_rd_we_i,

  input  logic [GPR_ADDR_W-1:0] m_cu_rd_addr_i,
  input  logic                  m_cu_rd_we_i,

  input  logic                  d_mem_req_i,
  input  logic                  d_mem_we_i,

  input  logic                  e_mem_req_i,
  input  logic                  e_mem_we_i,

  input  logic                  m_mem_req_i,
  input  logic                  m_mem_we_i,

  input  logic                  f_valid_i,
  input  logic                  d_valid_i,
  input  logic                  e_valid_i,
  input  logic                  m_valid_i,
  input  logic                  mp_valid_i,

  input  logic                  mp_branch_i,
  input  logic                  mp_jal_i,
  input  logic                  mp_jalr_i,
  input  logic [XLEN-1:0]       mp_target_pc_i,
  input  logic [XLEN-1:0]       mp_next_pc_i,
  input  logic                  mp_prediction_i,
  input  logic                  mp_br_j_taken_i,

  output logic [1:0]            byp_sel1_o,
  output logic [1:0]            byp_sel2_o,

  output logic                  cu_stall_f_o,
  output logic                  cu_stall_d_o,
  output logic                  cu_stall_e_o,
  output logic                  cu_stall_m_o,
  output logic                  cu_stall_mp_o,

  output logic                  cu_kill_f_o,
  output logic                  cu_kill_d_o,
  output logic                  cu_kill_e_o,
  output logic                  cu_kill_m_o,
  output logic                  cu_kill_mp_o,

  output logic [XLEN-1:0]       cu_force_pc_o,
  output logic                  cu_force_f_o
);


  ////////////////////////
  // Local declarations //
  ////////////////////////

  logic [1:0] boot_addr_load_ff;
  logic       cu_boot_addr_load_en;
  logic       cu_mispredict;

  logic       e_raw_hazard_rs1;
  logic       e_raw_hazard_rs2;
  logic       e_raw_hazard_stall;

  logic       m_raw_hazard_rs1;
  logic       m_raw_hazard_rs2;
  logic       m_raw_hazard_stall;

  logic       mp_raw_hazard_rs1;
  logic       mp_raw_hazard_rs2;
  logic       mp_raw_hazard_stall;

  //////////////////////
  // Pipeline control //
  //////////////////////

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if(~arstn_i) begin
      boot_addr_load_ff <= 2'b00;
    end
    else begin
      boot_addr_load_ff <= {boot_addr_load_ff[0], 1'b1};
    end
  end

  assign cu_boot_addr_load_en = ~boot_addr_load_ff[1];


  assign e_raw_hazard_rs1 = f_cu_rs1_req_i & f_valid_i
                          & d_cu_rd_we_i   & d_valid_i
                          & (f_cu_rs1_addr_i == d_cu_rd_addr_i)
                          & (d_cu_rd_addr_i != '0); // No hazards for x0

  assign e_raw_hazard_rs2 = f_cu_rs2_req_i & f_valid_i
                          & d_cu_rd_we_i   & d_valid_i
                          & (f_cu_rs2_addr_i == d_cu_rd_addr_i)
                          & (d_cu_rd_addr_i != '0); // No hazards for x0

  assign e_raw_hazard_stall = (e_raw_hazard_rs1 | e_raw_hazard_rs2)
                            &  d_mem_req_i & (!d_mem_we_i);

  assign m_raw_hazard_rs1 = f_cu_rs1_req_i & f_valid_i
                          & e_cu_rd_we_i & e_valid_i
                          & (f_cu_rs1_addr_i == e_cu_rd_addr_i)
                          & (e_cu_rd_addr_i != '0); // No hazards for x0

  assign m_raw_hazard_rs2 = f_cu_rs2_req_i & f_valid_i
                          & e_cu_rd_we_i & e_valid_i
                          & (f_cu_rs2_addr_i == e_cu_rd_addr_i)
                          & (e_cu_rd_addr_i != '0); // No hazards for x0

  assign m_raw_hazard_stall = (m_raw_hazard_rs1 | m_raw_hazard_rs2)
                            &  e_mem_req_i & (!e_mem_we_i);


  assign mp_raw_hazard_rs1 = f_cu_rs1_req_i & f_valid_i
                           & m_cu_rd_we_i & m_valid_i
                           & (f_cu_rs1_addr_i == m_cu_rd_addr_i)
                           & (m_cu_rd_addr_i != '0); // No hazards for x0

  assign mp_raw_hazard_rs2 = f_cu_rs2_req_i & f_valid_i
                           & m_cu_rd_we_i & m_valid_i
                           & (f_cu_rs2_addr_i == m_cu_rd_addr_i)
                           & (m_cu_rd_addr_i != '0); // No hazards for x0

  assign mp_raw_hazard_stall = (mp_raw_hazard_rs1 | mp_raw_hazard_rs2)
                             &  m_mem_req_i & (!m_mem_we_i);


  assign cu_stall_f_o = mp_stall_req_i | m_stall_req_i | e_stall_req_i | d_stall_req_i | e_raw_hazard_stall | m_raw_hazard_stall | mp_raw_hazard_stall;
  assign cu_stall_d_o = mp_stall_req_i | m_stall_req_i | e_stall_req_i | d_stall_req_i;
  assign cu_stall_e_o = mp_stall_req_i | m_stall_req_i | e_stall_req_i;
  assign cu_stall_m_o = mp_stall_req_i | m_stall_req_i;
  assign cu_stall_mp_o = mp_stall_req_i;


  always_comb begin
    if (e_raw_hazard_rs1)
      byp_sel1_o = BYPASS_E;
    else if (m_raw_hazard_rs1)
      byp_sel1_o = BYPASS_M;
    else if (mp_raw_hazard_rs1)
      byp_sel1_o = BYPASS_MP;
    else
      byp_sel1_o = NO_BYPASS;
  end

  always_comb begin
    if (e_raw_hazard_rs2)
      byp_sel2_o = BYPASS_E;
    else if (m_raw_hazard_rs2)
      byp_sel2_o = BYPASS_M;
    else if (mp_raw_hazard_rs2)
      byp_sel2_o = BYPASS_MP;
    else
      byp_sel2_o = NO_BYPASS;
  end

  assign cu_mispredict = mp_valid_i & (mp_prediction_i ^ mp_br_j_taken_i) ;

  assign cu_kill_f_o = cu_mispredict;
  assign cu_kill_d_o = cu_mispredict;
  assign cu_kill_e_o = cu_mispredict;
  assign cu_kill_m_o = cu_mispredict;
  assign cu_kill_mp_o = cu_mispredict;


  assign cu_force_pc_o = cu_boot_addr_load_en ? boot_addr_i
                                              : mp_br_j_taken_i ? mp_target_pc_i
                                                                : mp_next_pc_i;

  assign cu_force_f_o = cu_boot_addr_load_en | cu_mispredict;

endmodule
