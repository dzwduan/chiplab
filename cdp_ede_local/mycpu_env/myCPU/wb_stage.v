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

wire [31:0] ws_pc;
wire [ 3:0] rf_we;
wire [ 4:0] dest;
wire [31:0] final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_we   = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

endmodule