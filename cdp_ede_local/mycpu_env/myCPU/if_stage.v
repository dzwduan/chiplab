`include "mycpu.vh"
`default_nettype none
module if_stage (
    input  wire                        clk,
    input  wire                        reset,
    //if <> id
    input  wire                        ds_allowin,
    output wire                        fs_to_ds_valid,
    output wire [`FS_TO_DS_BUS_WD-1:0] fs_to_ds_bus,
    // brbus
    input  wire [      `BR_BUS_WD-1:0] br_bus,
    // exception
    input  wire                        excp_flush,
    input  wire                        ertn_flush,
    // input  wire                        refetch_flush,
    input  wire [                31:0] ws_pc,
    // from csr
    input  wire [                31:0] csr_era,
    input  wire [                31:0] csr_eentry,
    // inst sram interface
    output wire                        inst_sram_en,
    output wire [                 3:0] inst_sram_we,
    output wire [                31:0] inst_sram_addr,
    output wire [                31:0] inst_sram_wdata,
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



  assign {br_taken, br_target} = br_bus;
  assign fs_to_ds_bus = {excp, excp_num, fs_pc, fs_inst};


  assign flush_sign = excp_flush | ertn_flush;
  assign pfs_excp_adef = nextpc[1] | nextpc[0];
  assign pfs_excp = pfs_excp_adef;
  assign pfs_excp_num = {pfs_excp_adef};
  assign excp_entry = csr_eentry;  // 中断的入口地址
  // assign flush_pc = {32{ertn_flush}} & csr_era | {32{refetch_flush}} & (ws_pc + 32'h4);
  assign flush_pc = {32{ertn_flush}} & csr_era;
  assign excp = fs_excp;
  assign excp_num = fs_excp_num;



  assign pfs_ready_go = 1'b1;
  assign to_fs_valid = ~reset && pfs_ready_go;
  assign seq_pc = fs_pc + 32'h4;
  assign nextpc = excp_flush                ?
                  excp_entry  : (ertn_flush)?
                  flush_pc    : br_taken    ?
                  br_target   : seq_pc;


  // prf -> fs pipeline
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


  assign fs_ready_go     = 1'b1;
  assign fs_allowin      = !fs_valid || fs_ready_go && ds_allowin || flush_sign;
  assign fs_to_ds_valid  = fs_valid && fs_ready_go;

  assign inst_sram_en    = ~reset && fs_allowin;
  assign inst_sram_we    = 4'b0;
  assign inst_sram_addr  = nextpc;  // 在pre fetch阶段提前给addr，因为sram是同步的
  assign inst_sram_wdata = 32'b0;
  assign fs_inst         = inst_sram_rdata;


endmodule
