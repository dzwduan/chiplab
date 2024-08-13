`include "mycpu.vh"

module wb_stage(
    input                           clk            ,
    input                           reset          ,
    //allowin
    output                          ws_allowin     ,
    //from ms
    input                           ms_to_ws_valid ,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus   ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus   ,
    //to ds
    output                          ws_to_ds_valid ,

        //trace debug interface
    output [31:0] debug_wb_pc                      ,
    output [ 3:0] debug_wb_rf_wen                  ,
    output [ 4:0] debug_wb_rf_wnum                 ,
    output [31:0] debug_wb_rf_wdata                                  
);



endmodule