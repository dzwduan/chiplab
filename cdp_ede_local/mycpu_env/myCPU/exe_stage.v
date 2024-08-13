`include "mycpu.vh"

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
    // output                          data_sram_en,
    // output [3:0]                    data_sram_we,
    output        data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata
);

  wire es_ready_go;

  assign es_ready_go = 1'b1;

  assign data_sram_we    = mem_we && valid;
  assign data_sram_addr  = alu_result;
  assign data_sram_wdata = rkd_value ;

endmodule
