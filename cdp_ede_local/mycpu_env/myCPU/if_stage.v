`include "mycpu.vh"

module if_stage (
    input                         clk,
    input                         reset,
    //if <> id
    input                         ds_allow_in,
    output                        fs_to_ds_valid,
    output [`FS_TO_DS_BUS_WD-1:0] fs_to_ds_bus,
    // brbus
    input  [      `BR_BUS_WD-1:0] brbus,

    // inst sram interface
    output        inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata
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

  wire [31:0] br_target;
  wire        br_taken;


  assign {br_taken, br_target} = brbus;
  assign fs_to_ds_bus = {fs_pc, fs_inst};

  /**
  主要包括各阶段的 valid、readygo、allowin.
  valid   用来判断当前阶段是否有效；
  readygo 用来判断当前阶段进行的操作是否能在一拍内完成;
  allowin 用来判断是否允许前一个模块的数据传入
  */


  assign pfs_ready_go = 1'b1;  //TODO: add分支预测失效
  assign to_fs_valid = ~reset && pfs_ready_go;
  assign seq_pc = fs_pc + 32'h4;
  assign nextpc = br_taken ? br_target : seq_pc;  //TODO: add flush

  always @(posedge clk) begin
    if(reset) begin
      fs_valid <= 1'b0;
    end else if (fs_allowin) begin
      fs_valid <= to_fs_valid;
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      fs_pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset
    end else if (to_fs_valid && fs_allowin) begin
      fs_pc <= nextpc;
    end
  end

  assign fs_ready_go     = 1'b1;
  assign fs_allowin      = !fs_valid || fs_ready_go && ds_allow_in;
  assign fs_to_ds_valid  = fs_valid && fs_ready_go;


  assign inst_sram_we    = 1'b0;
  assign inst_sram_addr  = nextpc;  // 在pre fetch阶段提前给addr，因为sram是同步的
  assign inst_sram_wdata = 32'b0;
  assign inst            = inst_sram_rdata;


endmodule
