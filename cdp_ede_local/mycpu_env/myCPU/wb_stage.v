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

  assign ws_ready_go    = 1'b1;
  assign ws_allowin     = ~ws_valid || ws_ready_go;
  assign ws_to_ds_valid = ws_valid;

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


  assign {ws_gr_we,  //69:69
      ws_dest,  //68:64
      ws_final_result,  //63:32
      ws_pc  //31:0
      } = ms_to_ws_bus_r;

  assign ws_to_rf_bus = {ws_gr_we, ws_dest, ws_final_result};

  // debug info generate
  assign debug_wb_pc = ws_pc & {32{ws_valid}};
  assign debug_wb_rf_we = {4{ws_gr_we}};
  assign debug_wb_rf_wnum = ws_dest & {5{ws_valid}};
  assign debug_wb_rf_wdata = ws_final_result & {32{ws_valid}};

endmodule
