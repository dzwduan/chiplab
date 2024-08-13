`include "mycpu.vh"

module if_stage (
    input                         clk,
    input                         resetn,
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
    input  [31:0] inst_sram_rdata,

    output [31:0] pc,
    output [31:0] inst
);

  wire [31:0] seq_pc;
  wire [31:0] nextpc;
  wire        br_taken;
  wire [31:0] br_target;
//   wire [31:0] pc;
//   wire [31:0] inst;

    reg [31:0] if_pc;


  assign seq_pc = pc + 3'h4;
  assign nextpc = br_taken ? br_target : seq_pc;

  always @(posedge clk) begin
    if (~resetn) begin
      pc <= 32'h1bfffffc;  //trick: to make nextpc be 0x1c000000 during reset 
    end else begin
      pc <= nextpc;
    end
  end


assign inst_sram_we    = 1'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;



endmodule
