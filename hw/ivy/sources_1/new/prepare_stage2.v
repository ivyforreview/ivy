`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/19 15:56:13
// Design Name: 
// Module Name: prepare_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "bus_def.vh"
`include "ipu_def.vh"
`include "node_def.vh"
`include "stage.vh"
`include "ins_type.vh"
module prepare_stage (
    input wire                 clk,
    input wire                 rst_n,      // active low reset
    input wire [`CP_BUS_W-1:0] cp_bus,
    input wire [`FORWARD_BUS_W-1:0] from_bus,
    output wire [`PW_BUS_W-1:0] pw_bus
);

//Variables
//reg for input, from_bus not registered here
reg [`CP_BUS_W-1:0] cp_bus_reg;

wire [`RC_BUS_W-1:0] rc_bus;
// Extracted signal from rc_bus
wire [`INS_TYPE_W-1:0] rc_bus_ins_type;
wire [`INS_R1_W-1:0] rc_bus_r1;
wire [`INS_R2_W-1:0] rc_bus_r2;
wire rc_bus_is_in;
// Signal for Compare node
wire [`NODE_WIDTH-1:0] cmp_node_data;
wire cmp_node_is_root;
wire [`RANK_WIDTH-1:0] cmp_node_lvalue;
wire [`METADATA_WIDTH-1:0] cmp_node_lmeta;
wire [`RANK_WIDTH-1:0] cmp_node_rvalue;
wire [`METADATA_WIDTH-1:0] cmp_node_rmeta;
wire cmp_node_lchild_valid;
wire [`ADDR_W-1:0] cmp_node_lchild;
wire cmp_node_rchild_valid;
wire [`ADDR_W-1:0] cmp_node_rchild;
wire [`COUNT_WIDTH-1:0] cmp_node_count;
// Signals for mux push/pop
wire [`CMP_RESULT_W-1:0] final_cmp_result;
wire final_flag;
wire [`COUNT_WIDTH-1:0] final_count;
wire final_clear;

//signals for from_bus
wire [`INS_TYPE_W:0] from_bus_ins_type;
wire [`INS_R1_W-1:0] from_bus_r1;
wire [`INS_R2_W-1:0] from_bus_r2;
wire from_bus_clear;
//signals for pw_bus
wire [`CP_BUS_W-1:0] pw_bus_cp_pass;
wire [`INS_R2_W-1:0] pw_bus_wv;
wire pw_bus_clear;
//signals for inf
wire [`RANK_WIDTH-1:0] inf;
wire [`METADATA_WIDTH-1:0] zerometa;
/*MicroModules*/
// Synchronize cp_bus
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cp_bus_reg <= {`CP_BUS_W{1'b0}};
    end else begin
        cp_bus_reg <= cp_bus;
    end
end

assign {rc_bus,cmp_node_data,final_cmp_result,final_flag,final_count,final_clear}=cp_bus_reg;
assign {cmp_node_is_root,cmp_node_lvalue,cmp_node_lmeta,cmp_node_rvalue,cmp_node_rmeta,cmp_node_lchild_valid,cmp_node_lchild,cmp_node_rchild_valid,cmp_node_rchild,cmp_node_count}=cmp_node_data;
//Set pw_bus
//Description: generate pw_bus by cp_bus_reg and from_bus
//Input: cp_bus_reg, from_bus
//OUTPUT: pw_bus


assign pop_count = (cmp_node_is_root && final_flag)?cmp_node_count-1:
                   (cmp_node_is_root && !cmp_node_rchild_valid)? cmp_node_count-1:
                   (cmp_node_is_root)? cmp_node_count:
                   (final_flag)? cmp_node_count-1:cmp_node_count+1;
assign push_count = (rc_bus_ins_type == `OP_PUSHROOT)?
    ((final_flag)?cmp_node_count+1:cmp_node_count):
    ((final_flag)?cmp_node_count+1:cmp_node_count-1);

// assign final_count=(rc_bus_ins_type == `OP_PUSHROOT || rc_bus==`OP_PUSHLEAF)?push_count:pop_count;

assign inf=`INF;
assign zerometa={`METADATA_WIDTH{1'b0}};
assign {from_bus_ins_type, from_bus_r1, from_bus_r2, from_bus_clear} = from_bus;
assign pw_bus_cp_pass=cp_bus_reg;
assign pw_bus_wv=(from_bus_ins_type==`OP_POPROOT || from_bus_ins_type==`OP_POPLEAF)?
                 from_bus_r2:{inf,zerometa};
assign pw_bus_clear=(from_bus_ins_type==`OP_POPROOT || from_bus_ins_type==`OP_POPLEAF)?
                   from_bus_clear:1'b0;
assign pw_bus={pw_bus_cp_pass, pw_bus_wv, pw_bus_clear};

endmodule