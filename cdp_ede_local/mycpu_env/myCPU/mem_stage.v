`include "mycpu.vh"
`default_nettype none
module mem_stage (
    input                          clk,
    input                          reset,
    //allowin
    input                          ws_allowin,
    output                         ms_allowin,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,

    input [31:0] data_sram_rdata
);

  reg                           ms_valid;
  reg  [`ES_TO_MS_BUS_WD-1 : 0] es_to_ms_bus_r;
  wire                          ms_ready_go;
  wire                          ms_store_op;
  wire                          ms_load_op;
  wire                          ms_gr_we;
  wire [                   4:0] ms_dest;
  wire [                  31:0] ms_exe_result;
  wire [                  31:0] ms_pc;
  wire [                  31:0] mem_result;
  wire [                  31:0] ms_final_result;
  wire                          res_from_mem;

  assign ms_ready_go = 1'b1;
  assign ms_allowin = ~ms_valid || ms_ready_go && ws_allowin;
  assign ms_to_ws_valid = ms_valid && ms_ready_go;

  always @(posedge clk) begin
    if (reset) begin
      ms_valid <= 1'b0;
    end else if (ms_allowin) begin
      ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
      es_to_ms_bus_r <= es_to_ms_bus;
    end
  end

  assign {
    ms_store_op,
    ms_load_op,
    ms_gr_we,
    ms_dest,
    ms_exe_result,
    ms_pc
  } = es_to_ms_bus_r;

  assign ms_to_ws_bus = {
    ms_gr_we,         //69:69
    ms_dest,          //68:64
    ms_final_result,  //63:32
    ms_pc             //31:0
  };

  assign res_from_mem = ms_load_op && ms_valid;
  assign mem_result = data_sram_rdata;
  assign ms_final_result = res_from_mem ? mem_result : ms_exe_result;

endmodule
