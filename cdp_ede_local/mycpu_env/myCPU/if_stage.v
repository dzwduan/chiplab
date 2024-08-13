`include "mycpu.vh"

module if_stage (
    input         clk,
    input         resetn,
    //if <> id
    input         ds_allow_in,
    output        fs_to_ds_valid,
    output [`FS_TO_DS_BUS_WD-1:0] fs_to_ds_bus,
    // brbus
    input [`BR_BUS_WD-1:0] brbus,

    // inst sram interface
    output        inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,

    output [31:0] pc,
    output [31:0] inst
);









endmodule
