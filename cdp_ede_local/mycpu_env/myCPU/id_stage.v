`include "mycpu.vh"

module id_stage (
    input                          clk,
    input                          reset,
    //allowin
    input                          es_allowin,
    output                         ds_allowin,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus,

    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus,
    //to rf: for write back
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus
);



endmodule
