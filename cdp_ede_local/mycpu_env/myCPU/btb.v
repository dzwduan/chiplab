module btb #(
    parameter BTBNUM = 32,
    parameter RASNUM = 16
) (
    input wire clk,
    input wire reset,

    //from/to if
    input  wire [31:0] fetch_pc,
    input  wire        fetch_en,
    output wire [31:0] ret_pc,
    output wire        taken,
    output wire        ret_en,
    output wire [ 4:0] ret_index,
    //from wire id
    input  wire        operate_en,
    input  wire [31:0] operate_pc,
    input  wire [ 4:0] operate_index,
    input  wire        pop_ras,
    input  wire        push_ras,
    input  wire        add_entry,
    input  wire        delete_entry,
    input  wire        pre_error,
    input  wire        pre_right,
    input  wire        target_error,
    input  wire        right_orien,
    input  wire [31:0] right_target
);

    





endmodule
