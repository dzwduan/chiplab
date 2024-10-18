`include "mycpu.vh"
`default_nettype none
module mem_stage (
    input  wire                         clk,
    input  wire                         reset,
    //allowin
    input  wire                         ws_allowin,
    output wire                         ms_allowin,
    //from es
    input  wire                         es_to_ms_valid,
    input  wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    //to ws
    output wire                         ms_to_ws_valid,
    output wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    //to ds
    output wire [`MS_TO_DS_BUS_WD -1:0] ms_to_ds_forward_bus,
    output wire                         ms_to_ds_valid,
    input  wire [                 31:0] data_sram_rdata,
    //div mul
    input  wire [                 31:0] div_result,
    input  wire [                 31:0] mod_result,
    input  wire [                 63:0] mul_result,
    //excp
    input  wire                         excp_flush,
    input  wire                         ertn_flush
);

  reg                           ms_valid;
  reg  [`ES_TO_MS_BUS_WD-1 : 0] es_to_ms_bus_r;
  wire                          ms_ready_go;
  wire                          ms_load_op;
  wire                          ms_gr_we;
  wire [                   4:0] ms_dest;
  wire [                  31:0] ms_exe_result;
  wire [                  31:0] ms_pc;
  wire [                  31:0] mem_result;
  wire [                  31:0] ms_final_result;
  wire                          res_from_mem;
  wire                          dest_zero;
  wire                          forward_enable;
  wire                          dep_need_stall;
  wire                          ms_mem_sign_exted;
  wire [                   1:0] ms_mem_size;
  wire [                   3:0] ms_mul_div_op;
  wire [                   1:0] sram_addr_low2bit;
  wire [                   7:0] mem_byteLoaded;
  wire [                  15:0] mem_halfLoaded;
  wire [                  31:0] ms_rdata;
  wire [                   6:0] ms_excp_num;
  wire                          ms_csr_we;
  wire [                  13:0] ms_csr_idx;
  wire                          ms_inst_ertn;
  wire                          ms_excp;
  wire [                  31:0] ms_csr_result;
  wire                          flush_sign;

  assign ms_ready_go = 1'b1;
  assign ms_allowin = ~ms_valid || ms_ready_go && ws_allowin;
  assign ms_to_ws_valid = ms_valid && ms_ready_go;
  assign flush_sign = excp_flush | ertn_flush;

  always @(posedge clk) begin
    if (reset | flush_sign) begin
      ms_valid <= 1'b0;
    end else if (ms_allowin) begin
      ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
      es_to_ms_bus_r <= es_to_ms_bus;
    end
  end

  assign {ms_mem_sign_exted,  //136
      ms_excp_num,  //135:126
      ms_csr_we,  //125:125
      ms_csr_idx,  //124:111
      ms_csr_result,  //110:79
      ms_inst_ertn,  //78:78
      ms_excp,  //77:77
      ms_mem_size,  //76:75
      ms_mul_div_op,  //74:71
      ms_load_op,  //70:70
      ms_gr_we,  //69:69
      ms_dest,  //68:64
      ms_exe_result,  //63:32
      ms_pc  //31:0c
      } = es_to_ms_bus_r;

  assign ms_to_ws_bus = {
    ms_excp_num,  //128:119
    ms_csr_we,  //118:118
    ms_csr_idx,  //117:104
    ms_csr_result,  //103:72
    ms_inst_ertn,  //71:71
    ms_excp,  //70:70
    ms_gr_we,  //69:69
    ms_dest,  //68:64
    ms_final_result,  //63:32
    ms_pc
  };


  // forward path
  assign dest_zero = (ms_dest == 5'b0);
  assign forward_enable = ms_valid & ms_gr_we & !dest_zero;
  assign dep_need_stall = ms_load_op;
  assign ms_to_ds_forward_bus = {dep_need_stall, forward_enable, ms_dest, ms_final_result};
  assign ms_to_ds_valid = ms_valid;


  assign ms_rdata = data_sram_rdata;
  assign sram_addr_low2bit = {ms_exe_result[1], ms_exe_result[0]};
  assign mem_byteLoaded =   ({8{sram_addr_low2bit==2'b00}} & ms_rdata[ 7: 0]) |
                            ({8{sram_addr_low2bit==2'b01}} & ms_rdata[15: 8]) |
                            ({8{sram_addr_low2bit==2'b10}} & ms_rdata[23:16]) |
                            ({8{sram_addr_low2bit==2'b11}} & ms_rdata[31:24]) ;

  assign mem_halfLoaded = ({16{sram_addr_low2bit==2'b00}} & ms_rdata[15: 0]) |
                          ({16{sram_addr_low2bit==2'b10}} & ms_rdata[31:16]) ;
  assign mem_result =
                    ({32{ms_mem_size[0] &&  ms_mem_sign_exted}} & {{24{mem_byteLoaded[ 7]}}, mem_byteLoaded})|
                    ({32{ms_mem_size[0] && ~ms_mem_sign_exted}} & { 24'b0                  , mem_byteLoaded})|
                    ({32{ms_mem_size[1] &&  ms_mem_sign_exted}} & {{16{mem_halfLoaded[15]}}, mem_halfLoaded})|
                    ({32{ms_mem_size[1] && ~ms_mem_sign_exted}} & { 16'b0                  , mem_halfLoaded})|
                    ({32{!ms_mem_size}}                         &   ms_rdata  );

  assign ms_final_result =({32{ms_load_op      }} & mem_result       )  |
                         ({32{ms_mul_div_op[0]}} & mul_result[31:0] )  |
                         ({32{ms_mul_div_op[1]}} & mul_result[63:32])  |
                         ({32{ms_mul_div_op[2]}} & div_result       )  |
                         ({32{ms_mul_div_op[3]}} & mod_result       )  |
                         ({32{!ms_mul_div_op && !ms_load_op}} & ms_exe_result);

endmodule

//TODO: fix ms to ws bus
