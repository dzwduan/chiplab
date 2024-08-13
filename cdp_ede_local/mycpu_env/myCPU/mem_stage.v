`include "mycpu.vh"

module mem_stage(
    input                              clk           ,
    input                              reset         ,
    //allowin
    input                              ws_allowin    ,
    output                             ms_allowin    ,
    //from es
    input                              es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0]     es_to_ms_bus  ,
    //to ws
    output                             ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0]     ms_to_ws_bus  ,

    input  [31:0]                      data_sram_rdata
);

wire [31:0] mem_result;
wire [31:0] final_result;







assign mem_result   = data_sram_rdata ;
assign final_result = res_from_mem ? mem_result : alu_result;

endmodule