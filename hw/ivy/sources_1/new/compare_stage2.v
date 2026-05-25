`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 16:07:13
// Design Name: 
// Module Name: compare_stage
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
module compare_stage (
    input  wire                 clk,
    input  wire                 rst_n,      // active low reset
    input  wire [`RC_BUS_W-1:0] rc_bus,
    input  wire [`PW_BUS_W-1:0] pw_bus_forward,
    input  wire [`WRITE_BUS_W-1:0] write_bus_forward,
    output wire [`CP_BUS_W-1:0] cp_bus,
    output wire [`INTER_BUS_W-1:0] lower_bus,
    output wire [`FORWARD_BUS_W-1:0] to_bus,
    input  wire [`NODE_WIDTH-1:0] doutb,
    input wire [`COUNT_WIDTH-1:0] config_length,
    output wire [`OUTBUS_W-1:0] out_bus
);

//TODO: Forward Write_bus

// Variables
// reg for input
reg [`RC_BUS_W-1:0] rc_bus_reg;
// reg [`PW_BUS_W-1:0] pw_bus_forward_reg;
// // reg [`NODE_WIDTH-1:0] doutb_reg;
// reg [`WRITE_BUS_W-1:0] write_bus_forward_reg;

// reg for length
reg [`COUNT_WIDTH-1:0] length_reg;
// Extracted signal from rc_bus
wire [`INS_TYPE_W-1:0] rc_bus_ins_type;
wire [`INS_R1_W-1:0] rc_bus_r1;
wire [`INS_R2_W-1:0] rc_bus_r2;
wire rc_bus_is_in;
// Extracted signal from pw_bus_forward
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
//Extracted signal from pw_bus_node_data
wire pw_node_is_root;
wire [`RANK_WIDTH-1:0] pw_node_lvalue;
wire [`METADATA_WIDTH-1:0] pw_node_lmeta;
wire [`RANK_WIDTH-1:0] pw_node_rvalue;
wire [`METADATA_WIDTH-1:0] pw_node_rmeta;
wire pw_node_lchild_valid;
wire [`ADDR_W-1:0] pw_node_lchild;
wire pw_node_rchild_valid;
wire [`ADDR_W-1:0] pw_node_rchild;
wire [`COUNT_WIDTH-1:0] pw_node_count;
// Extracted signal from write_bus_forward
wire write_bus_valid;
wire [`ADDR_W-1:0] write_bus_addr;
wire [`NODE_WIDTH-1:0] write_bus_node_data;
// Extracted signal from write_bus_node_data
wire write_node_is_root;
wire [`RANK_WIDTH-1:0] write_node_lvalue;
wire [`METADATA_WIDTH-1:0] write_node_lmeta;
wire [`RANK_WIDTH-1:0] write_node_rvalue;
wire [`METADATA_WIDTH-1:0] write_node_rmeta;
wire write_node_lchild_valid;
wire [`ADDR_W-1:0] write_node_lchild;
wire write_node_rchild_valid;
wire [`ADDR_W-1:0] write_node_rchild;
wire [`COUNT_WIDTH-1:0] write_node_count;

// Extracted signal from doutb_reg
wire rc_node_is_root;
wire [`RANK_WIDTH-1:0] rc_node_lvalue;
wire [`METADATA_WIDTH-1:0] rc_node_lmeta;
wire [`RANK_WIDTH-1:0] rc_node_rvalue;
wire [`METADATA_WIDTH-1:0] rc_node_rmeta;
wire rc_node_lchild_valid;
wire [`ADDR_W-1:0] rc_node_lchild;
wire rc_node_rchild_valid;
wire [`ADDR_W-1:0] rc_node_rchild;
wire [`COUNT_WIDTH-1:0] rc_node_count;

// Signal for Forward
wire forward_j1;
wire is_forward_pw;
wire is_forward_write;

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

// Signal for POP logic
wire [`CMP_RESULT_W-1:0] pop_cmp_result;
wire pop_flag;
wire [`COUNT_WIDTH-1:0] pop_count;
wire pop_clear;
// Signal for PUSH logic
wire [`CMP_RESULT_W-1:0] push_cmp_result;
wire [`CMP_RESULT_W-1:0] push_push_result;
wire push_flag;
wire [`COUNT_WIDTH-1:0] push_count;
wire push_clear;
// PUSH logic Interval
wire [`RANK_WIDTH-1:0] push_cmp_a_value;
wire [`METADATA_WIDTH-1:0] push_cmp_a_meta;
wire [`RANK_WIDTH-1:0] push_cmp_b_value;
wire [`METADATA_WIDTH-1:0] push_cmp_b_meta;
wire empty_left;
wire empty_right;
// Signals for mux push/pop
wire [`CMP_RESULT_W-1:0] final_cmp_result;
wire final_flag;
wire [`COUNT_WIDTH-1:0] final_count;
wire final_clear;

// Signals for lower bus
wire [`INS_TYPE_W-1:0] lower_ins_type;
wire [`INS_R1_W-1:0] lower_ins_r1;
wire [`INS_R2_W-1:0] lower_ins_r2;

// Signals for to bus
wire [`INS_TYPE_W-1:0] to_bus_ins_type;
wire [`INS_R1_W-1:0] to_bus_ins_r1;
wire [`INS_R2_W-1:0] to_bus_ins_r2;
wire to_bus_clear;

/*MicroModules:*/
// Synchronize
// Description: Register the input buses
// Input: rc_bus, pw_bus_forward, write_bus_forward
// Output: rc_bus_reg, pw_bus_forward_reg, write_bus_forward_reg

//Newly : removed reg signal for forward bus!

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rc_bus_reg <= {`RC_BUS_W{1'b0}};
        // pw_bus_forward_reg <= {`PW_BUS_W{1'b0}};
        // write_bus_forward_reg <= {`WRITE_BUS_W{1'b0}};
    end else begin
        rc_bus_reg <= rc_bus;
        // pw_bus_forward_reg <= pw_bus_forward;
        // write_bus_forward_reg <= write_bus_forward;
    end
end

//Synchronize
// Description: Register the doutb
// Input doutb
// Output: doutb_reg

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         doutb_reg <= {`NODE_WIDTH{1'b0}};
//     end else begin
//         doutb_reg <= doutb;
//     end
// end

// Set Length
// Description: Register the length of the config
// Input: config_length
// Output: length_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        length_reg <= {`COUNT_WIDTH{1'b0}};
    end else 
        length_reg <= config_length;
end

// Extract signals from rc_bus_reg
// Description: Extract necessary fields from rc_bus_reg
// Input: rc_bus_reg
// Output: rc_bus_ins_type, rc_bus_r1, rc_bus_r2
// assign rc_bus_ins_type = rc_bus_reg[`RC_BUS_W-1:`RC_INS_TYPE_POS];
// assign rc_bus_r1 = rc_bus_reg[`RC_INS_TYPE_POS-1:`RC_R1_POS];
// assign rc_bus_r2 = rc_bus_reg[`RC_R1_POS-1:0];
assign {rc_bus_is_in,rc_bus_ins_type, rc_bus_r1, rc_bus_r2} = rc_bus_reg;

// Extract signals from pw_bus_forward_reg
// Description: Extract necessary fields from pw_bus_forward_reg
// Input: pw_bus_forward_reg
// Output: pw_bus_ins_type, pw_bus_r1, pw_bus_r2
// pw_bus_node_data
// pw_bus_cmp_result, pw_bus_flag, pw_bus_svc, pw_bus_valid
// pw_bus_forwardv
assign {pw_bus_ins_type, pw_bus_r1, pw_bus_r2, 
pw_bus_node_data, 
pw_bus_cmp_result, pw_bus_flag, pw_bus_svc, pw_bus_valid, 
pw_bus_forwardv,pw_bus_clear} = pw_bus_forward; 
// Extract signals from pw_bus_node_data
// Description: Extract necessary fields from pw_bus_node_data
assign {
    pw_node_is_root,
    pw_node_lvalue,pw_node_lmeta,pw_node_rvalue,pw_node_rmeta,
    pw_node_lchild_valid,pw_node_lchild,
    pw_node_rchild_valid,pw_node_rchild,
    pw_node_count
} = pw_bus_node_data;

// Extract signals from write_bus_forward_reg
// Description: Extract necessary fields from write_bus_forward_reg
// Input: write_bus_forward_reg
// Output: write_bus_valid, write_bus_addr, write_bus_node_data
assign {write_bus_valid, write_bus_addr, write_bus_node_data} = write_bus_forward;

// Extract signals from write_bus_node_data
// Description: Extract necessary fields from write_bus_node_data
assign {
    write_node_is_root,
    write_node_lvalue,write_node_lmeta,write_node_rvalue,write_node_rmeta,
    write_node_lchild_valid,write_node_lchild,
    write_node_rchild_valid,write_node_rchild,
    write_node_count
} = write_bus_node_data;

// Extract signals from doutb
// Description: Extract necessary fields from doutb
// Input: doutb
// Output: rc_node_is_root, 
// rc_node_lvalue, rc_node_lmeta, rc_node_rvalue, rc_node_rmeta,
// rc_node_lchild_valid, rc_node_lchild,
// rc_node_rchild_valid, rc_node_rchild,
// rc_node_count
assign {
    rc_node_is_root,
    rc_node_lvalue,rc_node_lmeta,rc_node_rvalue,rc_node_rmeta,
    rc_node_lchild_valid,rc_node_lchild,
    rc_node_rchild_valid,rc_node_rchild,
    rc_node_count
} = doutb;

// Mux CP Node Data
// Description: decide using pw_bus_node_data or doutb
// Input: pw_bus_node_data bundle, doutb bundle
// Output: cp_node_data bundle

assign forward_j1 = 
    ((rc_bus_ins_type == `OP_POPROOT) && (pw_bus_ins_type == `OP_PUSHROOT)) ||
    ((rc_bus_ins_type == `OP_POPLEAF) && (pw_bus_ins_type == `OP_PUSHLEAF)) ||
    ((rc_bus_ins_type == `OP_PUSHROOT) && (pw_bus_ins_type == `OP_POPROOT)) ||
    ((rc_bus_ins_type == `OP_PUSHLEAF) && (pw_bus_ins_type == `OP_POPLEAF));

assign is_forward_pw = forward_j1 && (pw_bus_r1 == rc_bus_r1);
assign is_forward_write = (rc_bus_ins_type!=`OP_NOP) && write_bus_valid && (write_bus_addr == rc_bus_r1);

assign cmp_node_is_root = rc_node_is_root;
assign cmp_node_lvalue = (is_forward_pw && pw_bus_flag)?pw_bus_cmp_result[`CMP_RESULT_W-1:`METADATA_WIDTH]:
                         (is_forward_write)?write_node_lvalue: rc_node_lvalue;
assign cmp_node_lmeta = (is_forward_pw && pw_bus_flag)?pw_bus_cmp_result[`METADATA_WIDTH-1:0]:
                        (is_forward_write)?write_node_lmeta:rc_node_lmeta;
assign cmp_node_rvalue = (is_forward_pw && !pw_bus_flag)?pw_bus_cmp_result[`CMP_RESULT_W-1:`METADATA_WIDTH]:
                         (is_forward_write)?write_node_rvalue: rc_node_rvalue;
assign cmp_node_rmeta = (is_forward_pw && !pw_bus_flag)?pw_bus_cmp_result[`METADATA_WIDTH-1:0]:
                        (is_forward_write)?write_node_rmeta:rc_node_rmeta;
assign cmp_node_lchild_valid = (is_forward_pw && pw_bus_flag)?pw_bus_valid:
                               (is_forward_write)?write_node_lchild_valid:rc_node_lchild_valid;
assign cmp_node_lchild = rc_node_lchild;
assign cmp_node_rchild_valid = (is_forward_pw && !pw_bus_flag)?pw_bus_valid:
                               (is_forward_write)?write_node_rchild_valid: rc_node_rchild_valid;
assign cmp_node_rchild = rc_node_rchild;
assign cmp_node_count = (is_forward_pw)?pw_bus_svc:(is_forward_write)?write_node_count:rc_node_count;

//--------------------------------------------
// Decode instruction types for RC bus
//--------------------------------------------
// wire rc_is_poproot  = (rc_bus_ins_type == `OP_POPROOT);
// wire rc_is_popleaf  = (rc_bus_ins_type == `OP_POPLEAF);
// wire rc_is_pushroot = (rc_bus_ins_type == `OP_PUSHROOT);
// wire rc_is_pushleaf = (rc_bus_ins_type == `OP_PUSHLEAF);

// wire rc_is_root = rc_is_poproot  | rc_is_pushroot;
// wire rc_is_leaf = rc_is_popleaf  | rc_is_pushleaf;

// wire rc_is_push = rc_is_pushroot | rc_is_pushleaf;


// //--------------------------------------------
// // Decode instruction types for PW bus
// //--------------------------------------------
// wire pw_is_poproot  = (pw_bus_ins_type == `OP_POPROOT);
// wire pw_is_popleaf  = (pw_bus_ins_type == `OP_POPLEAF);
// wire pw_is_pushroot = (pw_bus_ins_type == `OP_PUSHROOT);
// wire pw_is_pushleaf = (pw_bus_ins_type == `OP_PUSHLEAF);

// wire pw_is_root = pw_is_poproot  | pw_is_pushroot;
// wire pw_is_leaf = pw_is_popleaf  | pw_is_pushleaf;

// wire pw_is_push = pw_is_pushroot | pw_is_pushleaf;


// //--------------------------------------------
// // Forward_j1 condition optimization
// //--------------------------------------------

// wire same_tree_type = (rc_is_root & pw_is_root) |
//                       (rc_is_leaf & pw_is_leaf);

// wire push_pop_op = rc_is_push ^ pw_is_push;

// assign forward_j1 = push_pop_op;


// //--------------------------------------------
// // Forward PW conditions (unchanged semantic)
// //--------------------------------------------
// assign is_forward_pw = forward_j1 & (pw_bus_r1 == rc_bus_r1);

// assign is_forward_write =
//     (rc_bus_ins_type != `OP_NOP) &&
//     write_bus_valid &&
//     (write_bus_addr == rc_bus_r1);


// //--------------------------------------------
// // Unified selection signals
// //--------------------------------------------
// wire sel_pw    = is_forward_pw;
// wire sel_write = ~sel_pw & is_forward_write;
// wire sel_orig  = ~sel_pw & ~sel_write;


// //--------------------------------------------
// // Convenience wires for PW / WRITE sources
// //--------------------------------------------

// // PW bus CMP result decomposition
// wire [`CMP_RESULT_W-1:`METADATA_WIDTH] pw_val  = pw_bus_cmp_result[`CMP_RESULT_W-1:`METADATA_WIDTH];
// wire [`METADATA_WIDTH-1:0]             pw_meta = pw_bus_cmp_result[`METADATA_WIDTH-1:0];

// wire use_pw_left  = sel_pw &  pw_bus_flag;
// wire use_pw_right = sel_pw & ~pw_bus_flag;


// //--------------------------------------------
// // CMP node left value / metadata
// //--------------------------------------------
// assign cmp_node_lvalue =
//     use_pw_left ? pw_val :
//     sel_write   ? write_node_lvalue :
//                   rc_node_lvalue;

// assign cmp_node_lmeta  =
//     use_pw_left ? pw_meta :
//     sel_write   ? write_node_lmeta :
//                   rc_node_lmeta;


// //--------------------------------------------
// // CMP node right value / metadata
// //--------------------------------------------
// assign cmp_node_rvalue =
//     use_pw_right ? pw_val :
//     sel_write    ? write_node_rvalue :
//                    rc_node_rvalue;

// assign cmp_node_rmeta  =
//     use_pw_right ? pw_meta :
//     sel_write    ? write_node_rmeta :
//                    rc_node_rmeta;


// //--------------------------------------------
// // Child valid
// //--------------------------------------------
// assign cmp_node_lchild_valid =
//     use_pw_left ? pw_bus_valid :
//     sel_write   ? write_node_lchild_valid :
//                   rc_node_lchild_valid;

// assign cmp_node_rchild_valid =
//     use_pw_right ? pw_bus_valid :
//     sel_write    ? write_node_rchild_valid :
//                    rc_node_rchild_valid;


// //--------------------------------------------
// // Child nodes: unchanged (always from RC)
// //--------------------------------------------
// assign cmp_node_lchild = rc_node_lchild;
// assign cmp_node_rchild = rc_node_rchild;


// //--------------------------------------------
// // Node count
// //--------------------------------------------
// assign cmp_node_count =
//     sel_pw    ? pw_bus_svc :
//     sel_write ? write_node_count :
//                 rc_node_count;


// //--------------------------------------------
// // cmp_node_is_root: direct mapping
// //--------------------------------------------
// assign cmp_node_is_root = rc_node_is_root;



assign cmp_node_data = {
    cmp_node_is_root,
    cmp_node_lvalue,cmp_node_lmeta,cmp_node_rvalue,cmp_node_rmeta,
    cmp_node_lchild_valid,cmp_node_lchild,
    cmp_node_rchild_valid,cmp_node_rchild,
    cmp_node_count
};

/* POP Logic */
// Description: POP logic in compare stage
// Input: cmp_node_data bundle
// Output: pop_cmp_result, pop_flag, pop_count, pop_clear,pop_next_valid 


assign pop_cmp_result = ($unsigned(cmp_node_lvalue) <= $unsigned(cmp_node_rvalue))?{cmp_node_lvalue,cmp_node_lmeta}:{cmp_node_rvalue,cmp_node_rmeta};
assign pop_flag = ($unsigned(cmp_node_lvalue) <= $unsigned(cmp_node_rvalue))?1'b1:1'b0;
// assign pop_count = (cmp_node_is_root && pop_flag)?cmp_node_count-1:
//                    (cmp_node_is_root && !cmp_node_rchild_valid)? cmp_node_count-1:
//                    (cmp_node_is_root)? cmp_node_count:
//                    (pop_flag)? cmp_node_count-1:cmp_node_count+1;
assign pop_clear = !((cmp_node_lvalue == `INF) || (cmp_node_rvalue == `INF));

/* PUSH Logic */
// Description: PUSH logic in compare stage
// Input: rc_bus_r2, cmp_node_data bundle
// Output: push_cmp_result, push_flag, push_count, push_clear

assign empty_left = (cmp_node_lvalue == `INF);
assign empty_right = (cmp_node_rvalue == `INF);
assign push_cmp_a_value=rc_bus_r2[`INS_R2_W-1:`METADATA_WIDTH];
assign push_cmp_a_meta=rc_bus_r2[`METADATA_WIDTH-1:0];
assign push_cmp_b_value=(rc_bus_ins_type == `OP_PUSHROOT)?
    ((cmp_node_count < length_reg)?cmp_node_lvalue:cmp_node_rvalue):
    ((cmp_node_count > 0)?cmp_node_lvalue:cmp_node_rvalue);
assign push_cmp_b_meta=(rc_bus_ins_type == `OP_PUSHROOT)?
    ((cmp_node_count < length_reg)?cmp_node_lmeta:cmp_node_rmeta):
    ((cmp_node_count > 0)?cmp_node_lmeta:cmp_node_rmeta);
assign push_cmp_result = ($unsigned(push_cmp_a_value) <= $unsigned(push_cmp_b_value))?{push_cmp_a_value,push_cmp_a_meta}:{push_cmp_b_value,push_cmp_b_meta};
assign push_push_result = ($unsigned(push_cmp_a_value) <= $unsigned(push_cmp_b_value))?{push_cmp_b_value,push_cmp_b_meta}:{push_cmp_a_value,push_cmp_a_meta};
assign push_flag = (rc_bus_ins_type == `OP_PUSHROOT)?
    ((cmp_node_count < length_reg && !(!empty_left && empty_right))?1'b1:1'b0):
    ((cmp_node_count > 0)?1'b0:1'b1);

assign push_count = (rc_bus_ins_type == `OP_PUSHROOT)?
    ((cmp_node_count < length_reg)?cmp_node_count+1:cmp_node_count):
    ((cmp_node_count > 0)?cmp_node_count-1:cmp_node_count+1);
assign push_clear = (!empty_left && !empty_right);

// MUX PUSH/POP
assign final_cmp_result = (rc_bus_ins_type == `OP_POPROOT || rc_bus_ins_type == `OP_POPLEAF)?pop_cmp_result:push_cmp_result;
assign final_flag = (rc_bus_ins_type == `OP_POPROOT || rc_bus_ins_type == `OP_POPLEAF)?pop_flag:push_flag;
assign final_count = (rc_bus_ins_type == `OP_POPROOT || rc_bus_ins_type == `OP_POPLEAF)?pop_count:push_count;
assign final_clear = (rc_bus_ins_type == `OP_POPROOT || rc_bus_ins_type == `OP_POPLEAF)?pop_clear:push_clear;

// Compose CP Bus
// Description: Compose the output cp_bus
// Input: final_cmp_result, final_flag, final_count, final_clear, rc_bus bundle,cmp_node_data bundle
// Output: cp_bus
/* Logic:
cp-bus: rc_bus, cmp_node_data, final_cmp_result, final_flag, final_count, final_clear
*/
assign cp_bus = {rc_bus_reg,cmp_node_data,final_cmp_result,final_flag,final_count,final_clear};

// Compose Lower Bus
// Description: Compose the output lower_bus
// Input
// Output: lower_bus


assign lower_ins_type = 
    (rc_bus_ins_type == `OP_POPROOT)?((final_flag && rc_node_lchild_valid)?`OP_POPLEAF:
                                    (!final_flag && rc_node_rchild_valid)?`OP_POPROOT:`OP_NOP):
    (rc_bus_ins_type == `OP_POPLEAF)?((final_flag && rc_node_lchild_valid)?`OP_POPLEAF:
                                    (!final_flag && rc_node_rchild_valid)?`OP_POPLEAF:`OP_NOP):
    (rc_bus_ins_type == `OP_PUSHROOT)?((final_flag && (cmp_node_lvalue == `INF))?`OP_NOP:
                                     (!final_flag && (cmp_node_rvalue == `INF))?`OP_NOP:
                                     (final_flag)?`OP_PUSHLEAF:`OP_PUSHROOT):
    (rc_bus_ins_type == `OP_PUSHLEAF)?((final_flag && (cmp_node_lvalue == `INF))?`OP_NOP:
                                     (!final_flag && (cmp_node_rvalue == `INF))?`OP_NOP:
                                     (final_flag)?`OP_PUSHLEAF:`OP_PUSHLEAF):
    `OP_NOP;
assign lower_ins_r1 = final_flag?rc_node_lchild:rc_node_rchild;
assign lower_ins_r2 = (rc_bus_ins_type == `OP_POPROOT || rc_bus_ins_type == `OP_POPLEAF)? rc_bus_r1:
                      (rc_bus_ins_type == `OP_PUSHROOT || rc_bus_ins_type == `OP_PUSHLEAF)? push_push_result:0;
assign lower_bus = {lower_ins_type,lower_ins_r1,lower_ins_r2};

//Compose To Bus
//Description: Compose the output to_bus
//Input:
//Output: to_bus


assign to_bus_ins_type = rc_bus_is_in? `OP_NOP: rc_bus_ins_type;
assign to_bus_ins_r1 = rc_bus_r2[`ADDR_W-1:0];
assign to_bus_ins_r2 = final_cmp_result;
assign to_bus_clear = final_clear;
assign to_bus = {to_bus_ins_type,to_bus_ins_r1,to_bus_ins_r2,to_bus_clear};

//Compose Out_bus
//Description: Compose the output out_bus
//Input:
//Output: out_bus

assign out_bus={rc_bus_is_in,rc_bus_ins_type,rc_bus_r1,final_cmp_result};

endmodule