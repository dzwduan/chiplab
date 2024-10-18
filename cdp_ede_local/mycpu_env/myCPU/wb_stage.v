`include "mycpu.vh"
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
  wire [                 8:0] ws_excp_num;
  wire                        ws_csr_we;
  wire [                13:0] ws_csr_idx;
  wire                        ws_inst_ertn;
  wire                        ws_excp;
  wire [                31:0] ws_result;
  wire [                31:0] ws_csr_result;


  assign ws_ready_go    = 1'b1;
  assign ws_allowin     = ~ws_valid || ws_ready_go;
  assign ws_to_ds_valid = ws_valid & ws_gr_we;

  always @(posedge clk) begin
    if (reset) begin
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
  assign ertn_flush = ws_inst_ertn & ws_valid; //TODO: if both excp ans etrn ?

  assign ws_to_rf_bus = {ws_gr_we, ws_dest, ws_final_result};

  // debug info generate
  assign debug_wb_pc = ws_pc & {32{ws_valid}};
  assign debug_wb_rf_we = {4{ws_gr_we & ws_valid}};
  assign debug_wb_rf_wnum = ws_dest & {5{ws_valid}};
  assign debug_wb_rf_wdata = ws_final_result & {32{ws_valid}};

endmodule
