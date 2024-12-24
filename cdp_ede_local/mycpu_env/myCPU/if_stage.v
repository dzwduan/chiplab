`include "mycpu.vh"
`default_nettype none
module if_stage (
    input  wire                        clk,
    input  wire                        reset,
    //if <> id
    input  wire                        ds_allowin,
    output wire                        fs_to_ds_valid,
    output wire [`FS_TO_DS_BUS_WD-1:0] fs_to_ds_bus,
    output wire                        br_taken_r,
    // brbus
    input  wire [      `BR_BUS_WD-1:0] br_bus,
    // exception
    input  wire                        excp_flush,
    input  wire                        ertn_flush,
    input  wire                        refetch_flush,
    input  wire [                31:0] ws_pc,
    // from csr
    input  wire [                31:0] csr_era,
    input  wire [                31:0] csr_eentry,
    // inst sram interface
    // inst sram interface
    output wire                        inst_sram_req,
    output wire                        inst_sram_wr,
    output wire [                 1:0] inst_sram_size,
    output wire [                 3:0] inst_sram_wstrb,
    output wire [                31:0] inst_sram_addr,
    output wire [                31:0] inst_sram_wdata,
    input  wire                        inst_sram_addr_ok,
    input  wire                        inst_sram_data_ok,
    input  wire [                31:0] inst_sram_rdata
);

  reg         fs_valid;
  wire        fs_ready_go;
  wire        fs_allowin;
  wire        to_fs_valid;
  wire        pfs_ready_go;

  wire [31:0] seq_pc;
  wire [31:0] nextpc;
  wire [31:0] fs_inst;

  reg  [31:0] fs_pc;
  reg         fs_excp;
  reg         fs_excp_num;
  reg  [31:0] fs_inst_buf;
  reg         fs_inst_buf_en;
  reg         fs_inst_cancel;
  reg  [31:0] fs_br_target;
  reg         fs_br_taken;

  wire [31:0] br_target;
  wire        br_taken;
  wire        pfs_excp_adef;
  wire        pfs_excp;
  wire        pfs_excp_num;
  wire        flush_sign;
  wire [31:0] excp_entry;
  wire [31:0] flush_pc;
  wire        excp_num;  //TODO: 需要拓展到多位
  wire        excp;
  wire        br_stall;


  //=========================== pre IF stage ====================================
  assign flush_sign = excp_flush | ertn_flush | refetch_flush;
  assign pfs_excp_adef = nextpc[1] | nextpc[0];
  assign pfs_excp = pfs_excp_adef;
  assign pfs_excp_num = {pfs_excp_adef};

  assign pfs_ready_go = inst_sram_req & inst_sram_addr_ok;
  assign to_fs_valid = ~reset && pfs_ready_go;

  assign seq_pc = fs_pc + 32'h4;
  assign excp_entry = csr_eentry;  // 中断的入口地址
  assign flush_pc = {32{ertn_flush}} & csr_era | {32{refetch_flush}} & (ws_pc + 32'h4);
  assign nextpc = excp_flush                ?
                  excp_entry  : (ertn_flush | refetch_flush)?
                  flush_pc    : br_taken    ?
                  br_target   : fs_br_taken ? fs_br_target : seq_pc      ;

  assign inst_sram_req = ~reset & fs_allowin & ~br_stall;
  assign inst_sram_wr = 1'b0;
  assign inst_sram_size = 2'b10;
  assign inst_sram_addr = nextpc;
  assign inst_sram_wstrb = 4'b0000;
  assign inst_sram_wdata = 32'h0;

  always @(posedge clk) begin
    if (reset || (pfs_ready_go & fs_allowin)) begin
      fs_br_taken <= 1'b0;
      // fs_br_target <= 32'b0;
    end else if (br_taken) begin
      fs_br_taken  <= br_taken;
      fs_br_target <= br_target;
    end
  end


  //=========================== pre-IF to IF pipeline ===========================
  always @(posedge clk) begin
    if (reset) begin
      fs_valid <= 1'b0;
      fs_pc    <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset
      fs_excp  <= 1'b0;
    end else if (fs_allowin) begin
      fs_valid <= to_fs_valid;
    end

    if (to_fs_valid && fs_allowin) begin
      fs_excp     <= pfs_excp;
      fs_excp_num <= pfs_excp_num;
      fs_pc       <= nextpc;
    end
  end

  // exception cancel
  // 1. to_fs_valid
  // 2. fs_allowin & !fs_ready_go
  always @(posedge clk) begin
    if (reset) begin
      fs_inst_cancel <= 1'b0;
    end else if ((to_fs_valid || (fs_allowin & !fs_ready_go)) || flush_sign) begin
      fs_inst_cancel <= 1'b1;
    end else if (inst_sram_data_ok) begin
      fs_inst_cancel <= 1'b0;
    end
  end


  //========================== IF stage =========================================
  // 仅当该次请求的数据response ok, 才说明fs准备好发给ds
  assign fs_ready_go = inst_sram_data_ok | fs_inst_buf_en;
  assign fs_allowin = !fs_valid || fs_ready_go && ds_allowin || flush_sign;
  assign fs_to_ds_valid = fs_valid && fs_ready_go;

  //=========================== IF to ID pipeline =================================
  assign excp = fs_excp;
  assign excp_num = fs_excp_num;
  assign fs_inst = fs_inst_buf_en ? fs_inst_buf : inst_sram_rdata;
  assign fs_to_ds_bus = {excp, excp_num, fs_pc, fs_inst};

  //when if ready_go & !id_allowin, add fs_inst_buf
  always @(posedge clk) begin
    if (reset | flush_sign | fs_inst_cancel) begin
      fs_inst_buf_en <= 1'b0;
      fs_inst_buf <= 32'h0;
    end else if (fs_ready_go & !ds_allowin) begin
      fs_inst_buf_en <= 1'b1;
      fs_inst_buf <= fs_inst;
    end
  end


  //=========================== ID to pre-IF ============================================
  assign {br_stall, br_taken, br_target} = br_bus;
  assign  br_taken_r = fs_br_taken;

endmodule
