`include "mycpu.vh"
`default_nettype none
module exe_stage (
    input                          clk,
    input                          reset,
    //allowin
    input                          ms_allowin,
    output                         es_allowin,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    // to data sram
    output                         data_sram_en,
    output [                  3:0] data_sram_we,
    output [                 31:0] data_sram_addr,
    output [                 31:0] data_sram_wdata
);


  reg                          es_valid;
  reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
  wire                         es_ready_go;
  wire [                 11:0] es_alu_op;
  wire                         es_src1_is_pc;
  wire                         es_src2_is_imm;
  wire                         es_src2_is_4;
  wire                         es_gr_we;
  wire                         es_store_op;
  wire                         es_load_op;
  wire [                  4:0] es_dest;
  wire [                 31:0] es_imm;
  wire [                 31:0] es_pc;
  wire [                 31:0] es_rj_value;
  wire [                 31:0] es_rkd_value;
  wire                         es_mem_we;
  wire [                 31:0] es_alu_result;
  wire [                 31:0] es_alu_src1;
  wire [                 31:0] es_alu_src2;

  assign {
      es_alu_op,  //152:139
      es_load_op,  //138:138
      es_src1_is_pc,  //137:137
      es_src2_is_imm,  //136:136
      es_src2_is_4,  //135:135
      es_gr_we,  //134:134
      es_store_op,  //133:133
      es_dest,  //132:128
      es_imm,  //127:96
      es_rj_value,  //95 :64
      es_rkd_value,  //63 :32
      es_pc  //31 :0
      } = ds_to_es_bus_r;


  assign es_to_ms_bus = {
    es_store_op,  //71:71
    es_load_op,  //70:70
    es_gr_we,  //69:69
    es_dest,  //68:64
    es_alu_result,  //63:32
    es_pc  //31:0
  };


  assign es_ready_go = 1'b1;
  assign es_allowin = !es_valid || es_ready_go && ms_allowin;
  assign es_to_ms_valid = es_valid && es_ready_go;

  always @(posedge clk) begin
    if (reset) begin
      es_valid <= 1'b0;
    end else if (es_allowin) begin
      es_valid <= ds_to_es_valid;
      ds_to_es_bus_r <= ds_to_es_bus;
    end
  end

  assign es_mem_we   = es_load_op || es_store_op;
  assign es_alu_src1 = es_src1_is_pc ? es_pc : es_rj_value;
  assign es_alu_src2 = (es_src2_is_imm) ? es_imm : (es_src2_is_4) ? 32'd4 : es_rkd_value;

  alu u_alu (
      .alu_op    (es_alu_op),
      .alu_src1  (es_alu_src1),
      .alu_src2  (es_alu_src2),
      .alu_result(es_alu_result)
  );

  assign data_sram_we    = {4{es_mem_we && es_valid}}; //TODO: add sb sh sw sd
  assign data_sram_addr  = es_alu_result;
  assign data_sram_wdata = es_rkd_value ;

endmodule
