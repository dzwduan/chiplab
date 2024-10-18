`include "mycpu.vh"
`default_nettype none
module exe_stage (
    input  wire                         clk,
    input  wire                         reset,
    //allowin
    input  wire                         ms_allowin,
    output wire                         es_allowin,
    //from ds
    input  wire                         ds_to_es_valid,
    input  wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,
    //to ms
    output wire                         es_to_ms_valid,
    output wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    //to ds
    output wire [`ES_TO_DS_BUS_WD -1:0] es_to_ds_forward_bus,
    output wire                         es_to_ds_valid,
    //div_mul
    output wire                         es_div_enable,
    output wire                         es_mul_div_sign,
    output wire [                 31:0] es_rj_value,
    output wire [                 31:0] es_rkd_value,
    input  wire                         div_complete,
    // exception
    input  wire                         excp_flush,
    input  wire                         ertn_flush,
    // to data sram
    output wire                         data_sram_en,
    output wire [                  3:0] data_sram_we,
    output wire [                 31:0] data_sram_addr,
    output wire [                 31:0] data_sram_wdata
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
  wire                         es_mem_sign_exted;
  wire [                  1:0] es_mem_size;
  wire [                  3:0] es_mul_div_op;
  wire [                 31:0] es_alu_result;
  wire [                 31:0] es_alu_src1;
  wire [                 31:0] es_alu_src2;
  wire                         dest_zero;
  wire                         forward_enable;
  wire                         dep_need_stall;
  wire                         es_mul_enable;
  wire                         div_stall;
  wire [                  1:0] sram_addr_low2bit;

  wire [                  8:0] es_excp_num;
  wire                         es_csr_mask;
  wire                         es_csr_we;
  wire [                 13:0] es_csr_idx;
  wire                         es_res_from_csr;
  wire [                 31:0] es_csr_data;
  wire                         es_inst_ertn;
  wire                         es_excp;
  wire [                 31:0] es_result;
  wire [                 31:0] es_csr_result;
  wire [                 31:0] csr_mask_result;
  wire                         flush_sign;
  wire                         excp_ale;
  wire                         excp;
  wire [                  9:0] excp_num;
  wire                         access_mem;

  assign {
      es_excp_num,
      es_csr_mask,
      es_csr_we,
      es_csr_idx,
      es_res_from_csr,
      es_csr_data,
      es_inst_ertn,
      es_excp,
      es_mem_sign_exted,  //160:160
      es_mem_size,  //159:158
      es_mul_div_op,  //157:154
      es_mul_div_sign,  //153:153
      es_alu_op,  //150:139
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
    es_mem_sign_exted,  //136
    excp_num,  //135:126
    es_csr_we,  //125:125
    es_csr_idx,  //124:111
    es_csr_result,  //110:79
    es_inst_ertn,  //78:78
    excp,  //77:77
    es_mem_size,  //76:75
    es_mul_div_op,  //74:71
    es_load_op,  //70:70
    es_gr_we,  //69:69
    es_dest,  //68:64
    es_result,  //63:32
    es_pc  //31:0
  };



  assign es_ready_go = !div_stall;  // 没算完div，stall
  assign es_allowin = !es_valid || (es_ready_go && ms_allowin);
  assign es_to_ms_valid = es_valid && es_ready_go;
  assign flush_sign = excp_flush | ertn_flush;

  always @(posedge clk) begin
    if (reset | flush_sign) begin
      es_valid <= 1'b0;
    end else if (es_allowin) begin
      es_valid <= ds_to_es_valid;
      ds_to_es_bus_r <= ds_to_es_bus;
    end
  end

  assign es_alu_src1          = es_src1_is_pc ? es_pc : es_rj_value;
  assign es_alu_src2          = (es_src2_is_imm) ? es_imm : (es_src2_is_4) ? 32'd4 : es_rkd_value;

  assign es_div_enable        = (es_mul_div_op[2] | es_mul_div_op[3]) & es_valid;
  assign es_mul_enable        = es_mul_div_op[0] | es_mul_div_op[1];
  assign div_stall            = es_div_enable & ~div_complete;

  assign es_result            = es_res_from_csr ? es_csr_data : es_alu_result;
  // handle csrxchg, rj is mask, rd is old_value, csr_data for update
  assign csr_mask_result      = (es_rj_value & es_rkd_value) | (~es_rj_value & es_csr_data);
  // data for writing to rd
  assign es_csr_result        = es_csr_mask ? csr_mask_result : es_rkd_value;

  assign access_mem = es_load_op | es_store_op;
  // 检查地址对齐，b不需要考虑, h需要最低位为0， w需要最低两位为0
  assign excp_ale = access_mem && (es_mem_size[0] & 1'b0) |
                    (es_mem_size[1] & es_alu_result[0]) |
                    ((!es_mem_size[0] & !es_mem_size[1]) & (es_alu_result[0] | es_alu_result[1]));

  assign excp = es_excp | excp_ale;
  assign excp_num = {excp_ale, es_excp_num};

  // forward path
  assign dest_zero            = (es_dest == 5'b0);
  assign forward_enable       = es_valid & es_gr_we & !dest_zero;
  assign dep_need_stall       = es_load_op | es_div_enable | es_mul_enable;
  assign es_to_ds_forward_bus = {dep_need_stall, forward_enable, es_dest, es_result};
  assign es_to_ds_valid       = es_valid;

  alu u_alu (
      .alu_op    (es_alu_op),
      .alu_src1  (es_alu_src1),
      .alu_src2  (es_alu_src2),
      .alu_result(es_alu_result)
  );

  assign sram_addr_low2bit = {es_alu_result[1], es_alu_result[0]};

  // 00 : 0001
  // 01 : 0010
  // 10 : 0100
  // 11 : 1000
  wire [3:0] es_stb_wen = {
    sram_addr_low2bit == 2'b11,
    sram_addr_low2bit == 2'b10,
    sram_addr_low2bit == 2'b01,
    sram_addr_low2bit == 2'b00
  };

  // 00 : 0011
  // 01 : 0000
  // 10 : 1100
  // 11 : 0000
  wire [3:0] es_sth_wen = {
    sram_addr_low2bit == 2'b10,
    sram_addr_low2bit == 2'b10,
    sram_addr_low2bit == 2'b00,
    sram_addr_low2bit == 2'b00
  };

  wire [31:0] es_stb_cont = {
    {8{es_stb_wen[3]}} & es_rkd_value[7:0],
    {8{es_stb_wen[2]}} & es_rkd_value[7:0],
    {8{es_stb_wen[1]}} & es_rkd_value[7:0],
    {8{es_stb_wen[0]}} & es_rkd_value[7:0]
  };


  wire [31:0] es_sth_cont = {
    {16{es_sth_wen[3]}} & es_rkd_value[15:0], {16{es_sth_wen[0]}} & es_rkd_value[15:0]
  };

  assign data_sram_en = |(es_store_op | es_load_op) & es_valid;
  assign data_sram_we = {4{es_store_op}} & (es_mem_size[0] ? es_stb_wen : es_mem_size[1] ? es_sth_wen : !es_mem_size ? 4'b1111 : 4'b0000);
  assign data_sram_addr = es_alu_result;
  assign data_sram_wdata = ({32{es_mem_size[0]}} & es_stb_cont) |
                           ({32{es_mem_size[1]}} & es_sth_cont) |
                           ({32{!es_mem_size}}   & es_rkd_value);

endmodule
