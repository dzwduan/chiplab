`include "mycpu.vh"
`include "csr.vh"
`default_nettype none
module mycpu_top (
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
  reg reset;
  always @(posedge clk) reset <= ~resetn;

  wire                         ds_allowin;
  wire                         es_allowin;
  wire                         ms_allowin;
  wire                         ws_allowin;
  wire                         fs_to_ds_valid;
  wire                         ds_to_es_valid;
  wire                         es_to_ms_valid;
  wire                         ms_to_ws_valid;
  wire                         es_to_ds_valid;
  wire                         ms_to_ds_valid;
  wire                         ws_to_ds_valid;
  wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
  wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
  wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
  wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
  wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
  wire [`BR_BUS_WD       -1:0] br_bus;
  wire [`ES_TO_DS_BUS_WD -1:0] es_to_ds_forward_bus;
  wire [`MS_TO_DS_BUS_WD -1:0] ms_to_ds_forward_bus;

  wire                         es_div_enable;
  wire                         es_mul_div_sign;
  wire [                 31:0] es_rj_value;
  wire [                 31:0] es_rkd_value;
  wire                         div_complete;
  wire [                 31:0] div_result;
  wire [                 31:0] mod_result;
  wire [                 63:0] mul_result;
  wire [                 31:0] rd_csr_data;
  wire [                 13:0] rd_csr_addr;
  wire [                  1:0] csr_plv;
  wire                         has_int;
  wire [                 63:0] timer_64;
  wire [                 31:0] csr_tid;
  wire                         excp_flush;
  wire                         ertn_flush;
  wire [                 31:0] csr_era;
  wire [                 31:0] csr_eentry;
  wire [                  8:0] csr_esubcode;
  wire [                  5:0] csr_ecode;
  wire                         csr_wr_en;
  wire [                 13:0] wr_csr_addr;
  wire [                 31:0] wr_csr_data;
  wire                         va_error;
  wire [                 31:0] bad_va;
  wire [                 13:0] rd_addr;
  wire [                 31:0] rd_data;
  wire [                 13:0] wr_addr;
  wire [                 31:0] wr_data;
  wire [                 31:0] era_in;
  wire [                  8:0] esubcode_in;
  wire [                  5:0] ecode_in;

  if_stage u_if_stage (
      .clk            (clk),
      .reset          (reset),
      //if <> id
      .ds_allowin     (ds_allowin),
      .fs_to_ds_valid (fs_to_ds_valid),
      .fs_to_ds_bus   (fs_to_ds_bus),
      // brbus
      .br_bus         (br_bus),
      // exception
      .excp_flush     (excp_flush),
      .ertn_flush     (ertn_flush),
      .csr_era        (csr_era),
      .csr_eentry     (csr_eentry),
      // inst sram interface
      .inst_sram_en   (inst_sram_en),
      .inst_sram_we   (inst_sram_we),
      .inst_sram_addr (inst_sram_addr),
      .inst_sram_wdata(inst_sram_wdata),
      .inst_sram_rdata(inst_sram_rdata)
  );



  id_stage u_id_stage (
      .clk                 (clk),
      .reset               (reset),
      //allowin
      .es_allowin          (es_allowin),
      .ds_allowin          (ds_allowin),
      //from fsF
      .fs_to_ds_valid      (fs_to_ds_valid),
      .fs_to_ds_bus        (fs_to_ds_bus),
      //to es
      .ds_to_es_valid      (ds_to_es_valid),
      .ds_to_es_bus        (ds_to_es_bus),
      //to fs
      .br_bus              (br_bus),
      //to rf: for write back
      .ws_to_rf_bus        (ws_to_rf_bus),
      //csr
      .rd_csr_data         (rd_csr_data),
      .rd_csr_addr         (rd_csr_addr),
      .csr_plv             (csr_plv),
      //interrupt
      .has_int             (has_int),
      //exception
      .excp_flush          (excp_flush),
      .ertn_flush          (ertn_flush),
      //timer 64
      .timer_64            (timer_64),
      .csr_tid             (csr_tid),
      // RAW hazard
      .es_to_ds_forward_bus(es_to_ds_forward_bus),
      .ms_to_ds_forward_bus(ms_to_ds_forward_bus),
      .es_to_ds_valid      (es_to_ds_valid),
      .ms_to_ds_valid      (ms_to_ds_valid),
      .ws_to_ds_valid      (ws_to_ds_valid)
  );

  div u_div (
      .div_clk   (clk),
      .reset     (reset),
      .div       (es_div_enable),
      .div_signed(es_mul_div_sign),
      .x         (es_rj_value),
      .y         (es_rkd_value),
      .s         (div_result),
      .r         (mod_result),
      .complete  (div_complete)
  );

  mul u_mul (
      .mul_clk   (clk),
      .reset     (reset),
      .mul_signed(es_mul_div_sign),
      .x         (es_rj_value),
      .y         (es_rkd_value),
      .result    (mul_result)
  );


  exe_stage u_exe_stage (
      .clk                 (clk),
      .reset               (reset),
      //allowin
      .ms_allowin          (ms_allowin),
      .es_allowin          (es_allowin),
      //from ds
      .ds_to_es_valid      (ds_to_es_valid),
      .ds_to_es_bus        (ds_to_es_bus),
      //to ms
      .es_to_ms_valid      (es_to_ms_valid),
      .es_to_ms_bus        (es_to_ms_bus),
      //to ds
      .es_to_ds_forward_bus(es_to_ds_forward_bus),
      .es_to_ds_valid      (es_to_ds_valid),
      //div_mul
      .es_div_enable       (es_div_enable),
      .es_mul_div_sign     (es_mul_div_sign),
      .es_rj_value         (es_rj_value),
      .es_rkd_value        (es_rkd_value),
      .div_complete        (div_complete),
      // exception
      .excp_flush          (excp_flush),
      .ertn_flush          (ertn_flush),
      // to data sram
      .data_sram_en        (data_sram_en),
      .data_sram_we        (data_sram_we),
      .data_sram_addr      (data_sram_addr),
      .data_sram_wdata     (data_sram_wdata)
  );


  mem_stage u_mem_stage (
      .clk                 (clk),
      .reset               (reset),
      //allowin
      .ws_allowin          (ws_allowin),
      .ms_allowin          (ms_allowin),
      //from es
      .es_to_ms_valid      (es_to_ms_valid),
      .es_to_ms_bus        (es_to_ms_bus),
      //to ws
      .ms_to_ws_valid      (ms_to_ws_valid),
      .ms_to_ws_bus        (ms_to_ws_bus),
      //to ds
      .ms_to_ds_forward_bus(ms_to_ds_forward_bus),
      .ms_to_ds_valid      (ms_to_ds_valid),
      .data_sram_rdata     (data_sram_rdata),
      //div mul
      .div_result          (div_result),
      .mod_result          (mod_result),
      .mul_result          (mul_result),
      //excp
      .excp_flush          (excp_flush),
      .ertn_flush          (ertn_flush)
  );




  wb_stage u_wb_stage (
      .clk              (clk),
      .reset            (reset),
      //allowin
      .ws_allowin       (ws_allowin),
      //from ms
      .ms_to_ws_valid   (ms_to_ws_valid),
      .ms_to_ws_bus     (ms_to_ws_bus),
      //to rf: for write back
      .ws_to_rf_bus     (ws_to_rf_bus),
      //to ds
      .ws_to_ds_valid   (ws_to_ds_valid),
      //flush
      .excp_flush       (excp_flush),
      .ertn_flush       (ertn_flush),
      //exception
      .csr_era          (csr_era),
      .csr_esubcode     (csr_esubcode),
      .csr_ecode        (csr_ecode),
      .csr_wr_en        (csr_wr_en),
      .wr_csr_addr      (wr_csr_addr),
      .wr_csr_data      (wr_csr_data),
      .va_error         (va_error),
      .bad_va           (bad_va),
      //trace debug interface
      .debug_wb_pc      (debug_wb_pc),
      .debug_wb_rf_we   (debug_wb_rf_we),
      .debug_wb_rf_wnum (debug_wb_rf_wnum),
      .debug_wb_rf_wdata(debug_wb_rf_wdata)
  );



  csr u_csr (
      .clk        (clk),
      .reset      (reset),
      // from to ds
      .rd_addr    (rd_addr),
      .rd_data    (rd_data),
      .has_int    (has_int),
      // from ws
      .csr_wr_en  (csr_wr_en),
      .wr_addr    (wr_addr),
      .wr_data    (wr_data),
      .excp_flush (excp_flush),
      .ertn_flush (ertn_flush),
      .era_in     (era_in),
      .esubcode_in(esubcode_in),
      .ecode_in   (ecode_in)
    //   .interrupt  (interrupt)     // input wire [7:0] interrupt
  );


endmodule
