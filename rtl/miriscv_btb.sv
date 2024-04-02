module miriscv_btb
#(
  parameter BTB_SIZE = 1024
)
(
  input  logic        clk_i,
  input  logic        arstn_i,

  input  logic [31:0] pc_i,
  
  output logic        btb_hit_o,
  output logic [31:0] btb_target_o,
  output logic        btb_branch_o,
  output logic        btb_jal_o,
  output logic        btb_jalr_o,

  input  logic        fb_btb_upd_i,
  input  logic [31:0] fb_btb_pc_i,
  input  logic [31:0] fb_btb_target_i,
  input  logic        fb_btb_branch_i,
  input  logic        fb_btb_jal_i,
  input  logic        fb_btb_jalr_i,

  input  logic        fb_btb_flush_i,

  output logic        btb_init_o
);

localparam PC_LEN = 32;

localparam BTB_ADDR_W = PC_LEN-2;

localparam BTB_IDX_W = $clog2(BTB_SIZE);
localparam BTB_IDX_POS_L = 2;
localparam BTB_IDX_POS_H = BTB_IDX_POS_L + BTB_IDX_W - 1;

localparam BTB_TAG_W = BTB_ADDR_W - BTB_IDX_W;

localparam BTB_TAG_POS_L = BTB_IDX_POS_H + 1;
localparam BTB_TAG_POS_H = BTB_TAG_POS_L + BTB_TAG_W - 1;


logic                 btb_valid  [BTB_SIZE-1:0];
logic [BTB_TAG_W-1:0] btb_tag    [BTB_SIZE-1:0];
logic [PC_LEN-1:0]    btb_target [BTB_SIZE-1:0];
logic                 btb_branch [BTB_SIZE-1:0];
logic                 btb_jal    [BTB_SIZE-1:0];
logic                 btb_jalr   [BTB_SIZE-1:0];



  // Update logic

  
  logic init_ff;
  logic [BTB_IDX_W-1:0] init_cnt_ff;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      init_ff <= '1;
    else if (init_cnt_ff == BTB_SIZE)
      init_ff <= '0;
  end

  assign btb_init_o = init_ff;

  always_ff @(posedge clk_i or negedge arstn_i) begin
    if (~arstn_i)
      init_cnt_ff <= '0;
    else if (init_ff)
      init_cnt_ff <= init_cnt_ff + 1;
  end

  logic btb_valid_we;
  logic btb_valid_wdata;
  logic [BTB_IDX_W-1:0] btb_valid_waddr;

  assign btb_valid_we = init_ff | fb_btb_upd_i;
  assign btb_valid_wdata = init_ff ? '0 : ~fb_btb_flush_i;
  assign btb_valid_waddr = init_ff ? init_cnt_ff : fb_btb_pc_i[BTB_IDX_POS_H:BTB_IDX_POS_L];

  // memory here
  always_ff @(posedge clk_i) begin
    if (btb_valid_we)
      btb_valid[btb_valid_waddr] <= btb_valid_wdata;
  end
  //

  logic btb_data_we;
  logic [PC_LEN-1:0] btb_data_waddr;
  logic [BTB_TAG_W-1:0] btb_data_wtag;

  assign btb_data_we = fb_btb_upd_i & ~fb_btb_flush_i;
  assign btb_data_waddr = fb_btb_pc_i[BTB_IDX_POS_H:BTB_IDX_POS_L];

  assign btb_data_wtag = fb_btb_pc_i[BTB_TAG_POS_H:BTB_TAG_POS_L];

  // memory here
  always_ff @(posedge clk_i) begin
    if (btb_data_we) begin
      btb_tag    [btb_data_waddr] <= btb_data_wtag;
      btb_target [btb_data_waddr] <= fb_btb_target_i;
      btb_branch [btb_data_waddr] <= fb_btb_branch_i;
      btb_jal    [btb_data_waddr] <= fb_btb_jal_i;
      btb_jalr   [btb_data_waddr] <= fb_btb_jalr_i;
    end
  end
  //


  // Read logic

  logic                 read_btb_valid;
  logic [BTB_TAG_W-1:0] read_btb_tag;
  logic [PC_LEN-1:0]    read_btb_target;
  logic                 read_btb_branch;
  logic                 read_btb_jal;
  logic                 read_btb_jalr;

  logic [PC_LEN-1:0] btb_raddr;

  logic [BTB_TAG_W-1:0] req_tag_ff;

  assign btb_raddr = pc_i[BTB_IDX_POS_H:BTB_IDX_POS_L];

  always_ff @(posedge clk_i) begin
    req_tag_ff <= pc_i[BTB_TAG_POS_H:BTB_TAG_POS_L];
  end

  always_ff @(posedge clk_i) begin
    read_btb_valid <= btb_valid[btb_raddr];
    read_btb_tag <= btb_tag[btb_raddr];
    read_btb_target <= btb_target[btb_raddr];
    read_btb_branch <= btb_branch[btb_raddr];
    read_btb_jal <= btb_jal[btb_raddr];
    read_btb_jalr <= btb_jalr[btb_raddr];
  end

  // hit check here
  assign btb_hit_o = read_btb_valid
                   & (req_tag_ff == read_btb_tag);

  assign btb_target_o = read_btb_target;
  assign btb_branch_o = read_btb_branch;
  assign btb_jal_o = read_btb_jal;
  assign btb_jalr_o = read_btb_jalr;

endmodule
