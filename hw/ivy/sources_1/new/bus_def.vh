

`ifndef BUS_DEFS_VH
`define BUS_DEFS_VH
`include "ipu_def.vh"
`include "node_def.vh"
`define INS_TYPE_W 3
`define INS_R1_W  `ADDR_W
`define INS_R2_W  `RANK_WIDTH+`METADATA_WIDTH
`define VALID_W   1
`define CLEAR_W   1


`define INTER_BUS_W      `INS_TYPE_W + `INS_R1_W + `INS_R2_W
`define FORWARD_BUS_W    `INS_TYPE_W + `INS_R1_W + `INS_R2_W + `CLEAR_W

// [47:0] r2
// [63:48] r1
// [66:64] ins_type

`define INTER_INS_TYPE_POS `ADDR_W + `INS_R2_W
`define INTER_R1_POS `INS_R2_W
`define INTER_R2_POS 0


// [47:0] r2
// [63:48] r1
// [66:64] ins_type
// [67]     valid
// [68]     clear
//48+16+3+1
`define FORWARD_CLEAR_POS `ADDR_W + `INS_R2_W + `INS_TYPE_W + `VALID_W
`define FORWARD_VALID_POS `ADDR_W + `INS_R2_W + `INS_TYPE_W
`define FORWARD_INS_TYPE_POS `ADDR_W + `INS_R2_W
`define FORWARD_R1_POS `INS_R2_W
`define FORWARD_R2_POS 0


`define OUTBUS_W `VALID_W + `INTER_BUS_W


// `define DATA_W     128
`define STAGE_NUM  4

`endif
