`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/19 17:07:13
// Design Name: 
// Module Name: write_stage
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
module write_stage (
    input wire                 clk,
    input wire                 rst_n,      // active low reset
    input wire [`PW_BUS_W-1:0] pw_bus,
    output wire [`WRITE_BUS_W-1:0] write_bus
);

// Variables
// reg for input
reg [`PW_BUS_W-1:0] pw_bus_reg;

// Extracted signal from pw_bus
wire [`INS_TYPE_W-1:0] pw_bus_ins_type;
wire [`INS_R1_W-1:0] pw_bus_r1;
wire [`INS_R2_W-1:0] pw_bus_r2;
wire [`NODE_WIDTH-1:0] pw_bus_node_data;
wire [`CMP_RESULT_W-1:0] pw_bus_cmp_result;
wire pw_bus_flag;
wire [`SVC_W-1:0] pw_bus_svc;
wire pw_bus_valid;
wire [`FORWARDV_W-1:0] pw_bus_forwardv;
wire pw_bus_clear;
//Extracted node from signal
wire pw_bus_node_is_root;
wire [`RANK_WIDTH-1:0] pw_bus_node_lvalue;
wire [`METADATA_WIDTH-1:0] pw_bus_node_lmeta;
wire [`RANK_WIDTH-1:0] pw_bus_node_rvalue;
wire [`METADATA_WIDTH-1:0] pw_bus_node_rmeta;
wire pw_bus_node_lchild_valid;
wire [`ADDR_W-1:0] pw_bus_node_lchild;
wire pw_bus_node_rchild_valid;
wire [`ADDR_W-1:0] pw_bus_node_rchild;
wire [`COUNT_WIDTH-1:0] pw_bus_node_count;

// Signals
wire ena;
wire [`ADDR_W-1:0] addra;
wire [`NODE_WIDTH-1:0] dataa;
// Extracted node from signal
wire dataa_is_root;
wire [`RANK_WIDTH-1:0] dataa_lvalue;
wire [`METADATA_WIDTH-1:0] dataa_lmeta;
wire [`RANK_WIDTH-1:0] dataa_rvalue;
wire [`METADATA_WIDTH-1:0] dataa_rmeta;
wire dataa_lchild_valid;
wire [`ADDR_W-1:0] dataa_lchild;
wire dataa_rchild_valid;
wire [`ADDR_W-1:0] dataa_rchild;
wire [`COUNT_WIDTH-1:0] dataa_count;



/*MicroModules*/
// Synchronize
// Description: Register the pw_bus
// Input: pw_bus
// Output: pw_bus_reg

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pw_bus_reg <= 0;
    end else begin
        pw_bus_reg <= pw_bus;
    end
end

// Extract signals
assign {pw_bus_ins_type, pw_bus_r1, pw_bus_r2, pw_bus_node_data, 
pw_bus_cmp_result, pw_bus_flag, pw_bus_svc, pw_bus_valid,
pw_bus_forwardv, pw_bus_clear}=pw_bus_reg;

assign {pw_bus_node_is_root, pw_bus_node_lvalue, pw_bus_node_lmeta, pw_bus_node_rvalue, pw_bus_node_rmeta,
pw_bus_node_lchild_valid, pw_bus_node_lchild, pw_bus_node_rchild_valid, //pw_bus_node_rchild,
pw_bus_node_count
}=pw_bus_node_data;

// Setting write_bus
// Description: Set write_bus
// Input: pw_bus_reg
// Output: write_bus

assign ena= pw_bus_ins_type != `OP_NOP;
assign addra = pw_bus_r1;
assign dataa_is_root = pw_bus_node_is_root;
assign dataa_lvalue = (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)? 
                      ((pw_bus_flag)?pw_bus_forwardv[`CMP_RESULT_W-1:`METADATA_WIDTH]: pw_bus_node_lvalue) :
                      (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)? 
                      ((pw_bus_flag)?pw_bus_cmp_result[`CMP_RESULT_W-1:`METADATA_WIDTH]: pw_bus_node_lvalue) :
                      pw_bus_node_lvalue;
assign dataa_lmeta =  (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)? 
                     ((pw_bus_flag)?pw_bus_forwardv[`METADATA_WIDTH-1:0]: pw_bus_node_lmeta) :
                     (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)? 
                     ((pw_bus_flag)?pw_bus_cmp_result[`METADATA_WIDTH-1:0]: pw_bus_node_lmeta) :
                     pw_bus_node_lmeta;
assign dataa_rvalue = (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)? 
                      ((!pw_bus_flag)?pw_bus_forwardv[`CMP_RESULT_W-1:`METADATA_WIDTH]: pw_bus_node_rvalue) :
                      (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)? 
                      ((!pw_bus_flag)?pw_bus_cmp_result[`CMP_RESULT_W-1:`METADATA_WIDTH]: pw_bus_node_rvalue) :
                      pw_bus_node_rvalue;
assign dataa_rmeta =  (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)? 
                     ((!pw_bus_flag)?pw_bus_forwardv[`METADATA_WIDTH-1:0]: pw_bus_node_rmeta) :
                     (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)? 
                     ((!pw_bus_flag)?pw_bus_cmp_result[`METADATA_WIDTH-1:0]: pw_bus_node_rmeta) :
                     pw_bus_node_rmeta;
assign dataa_lchild_valid = (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)?
                            ((pw_bus_flag)?pw_bus_clear: pw_bus_node_lchild_valid) :
                            (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)?
                            ((pw_bus_flag)?pw_bus_valid: pw_bus_node_lchild_valid) :
                            pw_bus_node_lchild_valid;
assign dataa_lchild = pw_bus_node_lchild;
assign dataa_rchild_valid = (pw_bus_ins_type == `OP_POPROOT || pw_bus_ins_type == `OP_POPLEAF)?
                            ((!pw_bus_flag)?pw_bus_clear: pw_bus_node_rchild_valid) :
                            (pw_bus_ins_type == `OP_PUSHROOT || pw_bus_ins_type == `OP_PUSHLEAF)?
                            ((!pw_bus_flag)?pw_bus_valid: pw_bus_node_rchild_valid) :
                            pw_bus_node_rchild_valid;
// assign dataa_rchild = pw_bus_node_rchild;
assign dataa_count = pw_bus_svc;
assign dataa = {dataa_is_root, dataa_lvalue, dataa_lmeta, dataa_rvalue, dataa_rmeta,
dataa_lchild_valid, dataa_lchild, dataa_rchild_valid, //dataa_rchild,
 dataa_count};

assign write_bus = {ena, addra, dataa};

endmodule