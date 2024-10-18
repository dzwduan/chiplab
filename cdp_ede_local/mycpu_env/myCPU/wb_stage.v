`include "mycpu.vh"
`include "csr.vh"
`default_nettype none
module wb_stage (
    input  wire                         clk,
    input  wire                         reset,
    //allowin
    output wire                         ws_allowin,
    //from ms
    input  wire                         ms_to_ws_valid,
    input  wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    //to rf: for write back
    output wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    //to ds
    output wire                         ws_to_ds_valid,
    //flush
    output wire                         excp_flush,
    output wire                         ertn_flush,
    //exception
    output      [                 31:0] csr_era,
    output      [                  8:0] csr_esubcode,
    output      [                  5:0] csr_ecode,
    output                              csr_wr_en,
    output      [                 13:0] wr_csr_addr,
    output      [                 31:0] wr_csr_data,
    output                              va_error,
    output      [                 31:0] bad_va,
    //trace debug interface
    output wire [                 31:0] debug_wb_pc,
    output wire [                  3:0] debug_wb_rf_we,
    output wire [                  4:0] debug_wb_rf_wnum,
    output wire [                 31:0] debug_wb_rf_wdata
);

  reg                         ws_valid;
  reg  [`MS_TO_WS_BUS_WD-1:0] ms_to_ws_bus_r;
  wire                        ws_ready_go;
  wire                        ws_gr_we;
  wire [                 4:0] ws_dest;
  wire [                31:0] ws_final_result;
  wire [                31:0] ws_pc;
  wire [                 6:0] ws_excp_num;
  wire                        ws_csr_we;
  wire [                13:0] ws_csr_idx;
  wire                        ws_inst_ertn;
  wire                        ws_excp;
  wire [                31:0] ws_result;
  wire [                31:0] ws_csr_result;
  wire                        flush_sign;


  assign ws_ready_go    = 1'b1;
  assign ws_allowin     = ~ws_valid || ws_ready_go;
  assign ws_to_ds_valid = ws_valid & ws_gr_we;

  assign flush_sign = excp_flush | ertn_flush;

  always @(posedge clk) begin
    if (reset | flush_sign) begin
      ws_valid <= 1'b0;
    end else if (ws_allowin) begin
      ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
      ms_to_ws_bus_r <= ms_to_ws_bus;
    end
  end


  assign {ws_excp_num,  //134:119
      ws_csr_we,  //118:118
      ws_csr_idx,  //117:104
      ws_csr_result,  //103:72
      ws_inst_ertn,  //71:71
      ws_excp,  //70:70
      ws_gr_we,  //69:69
      ws_dest,  //68:64
      ws_final_result,  //63:32
      ws_pc} = ms_to_ws_bus_r;


  assign excp_flush = ws_excp & ws_valid;
  assign ertn_flush = ws_inst_ertn & ws_valid;  //TODO: if both excp ans etrn ?
  assign csr_era = ws_pc;  // 用于中断恢复执行的pc，异常时，当前ws_valid=0，指令无效，所以下一次从该指令继续执行
  assign csr_wr_en = ws_csr_we & ws_valid;
  assign wr_csr_addr = ws_csr_idx;
  assign wr_csr_data = ws_csr_result;  // 被csrrwr/csrxchg 写入到csr的data


/*
excp_num[0]  int     va_error = 0, badv = 0
        [1]  adef    va_error = 1, badv = ws_pc
        [2]  syscall va_error = 0, badv = 0
        [3]  brk     va_error = 0, badv = 0
        [4]  ine     va_error = 0, badv = 0
        [5]  ipe     va_error = 0, badv = 0
        [6]  ale     va_error = 1, badv = ws_pc
     */
  assign {
    csr_ecode,
    va_error,
    bad_va,
    csr_esubcode
  } = ws_excp_num[0] ? {`ECODE_INT, 1'b0, 32'b0, 9'b0} :
      ws_excp_num[1] ? {`ECODE_ADEF, ws_valid, ws_pc,  `ESUBCODE_ADEF} :
      ws_excp_num[2] ? {`ECODE_SYS, 1'b0, 32'b0, 9'b0} :
      ws_excp_num[3] ? {`ECODE_BRK, 1'b0, 32'b0, 9'b0} :
      ws_excp_num[4] ? {`ECODE_INE, 1'b0, 32'b0, 9'b0} :
      ws_excp_num[5] ? {`ECODE_IPE, 1'b0, 32'b0, 9'b0} :
      ws_excp_num[6] ? {`ECODE_ALE, ws_valid, ws_pc,  9'b0} : 48'b0;

  assign ws_to_rf_bus = {ws_gr_we, ws_dest, ws_final_result};

  // debug info generate
  assign debug_wb_pc = ws_pc & {32{ws_valid}};
  assign debug_wb_rf_we = {4{ws_gr_we & ws_valid}};
  assign debug_wb_rf_wnum = ws_dest & {5{ws_valid}};
  assign debug_wb_rf_wdata = ws_final_result & {32{ws_valid}};

endmodule
