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
  wire [31:0] excp_pc;
  wire [31:0] ertn_pc;
  wire        excp_num;  //TODO: 需要拓展到多位
  wire        excp;



  assign {br_taken, br_target} = br_bus;
  assign fs_to_ds_bus = {excp, excp_num, fs_pc, fs_inst};


  assign flush_sign = excp_flush | ertn_flush;
  assign pfs_excp_adef = nextpc[1] | nextpc[0];
  assign pfs_excp = pfs_excp_adef;
  assign pfs_excp_num = {pfs_excp_adef};
  assign excp_pc = csr_eentry;  // 中断的入口地址
  assign ertn_pc = csr_era;  // 例外的返回地址
  assign excp = fs_excp;
  assign excp_num = fs_excp_num;


  /**
  主要包括各阶段的 valid、readygo、allowin.
  valid   用来判断当前阶段是否有效；
  readygo 用来判断当前阶段进行的操作是否能在一拍内完成;
  allowin 用来判断是否允许前一个模块的数据传入
  */


  assign pfs_ready_go = 1'b1;
  assign to_fs_valid = ~reset && pfs_ready_go;
  assign seq_pc = fs_pc + 32'h4;
  assign nextpc = excp_flush ? excp_pc :
                  ertn_flush ? ertn_pc :
                  br_taken ? br_target :
                  seq_pc;

  //flush时，nextpc正确更新为excp_pc，下一拍fs unvalid，但是此时的nextpc已经变了，fs_pc
  //为什么8010是两拍？

  // prf -> fs pipeline
  always @(posedge clk) begin
    if (reset) begin
      fs_valid    <= 1'b0;
      fs_pc       <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset
      fs_excp     <= 1'b0;
    end
    else if (fs_allowin) begin
      fs_valid <= to_fs_valid;
    end

    if (to_fs_valid && fs_allowin) begin
      fs_excp     <= pfs_excp;
      fs_excp_num <= pfs_excp_num;
      fs_pc       <= nextpc;
    end
  end


  assign fs_ready_go     = 1'b1;
  assign fs_allowin      = !fs_valid || fs_ready_go && ds_allowin;
  assign fs_to_ds_valid  = fs_valid && fs_ready_go;

  assign inst_sram_en    = ~reset && fs_allowin;
  assign inst_sram_we    = 4'b0;
  assign inst_sram_addr  = nextpc;  // 在pre fetch阶段提前给addr，因为sram是同步的
  assign inst_sram_wdata = 32'b0;
  assign fs_inst         = inst_sram_rdata;


endmodule
