`ifndef STAGE_VH
`define STAGE_VH

`include "bus_def.vh"
`include "node_def.vh"

`define RC_BUS_W `INTER_BUS_W + `VALID_W
`define RC_INS_TYPE_POS `ADDR_W+ `INS_R2_W
`define RC_R1_POS `INS_R2_W
`define RC_R2_POS

`define CMP_RESULT_W `RANK_WIDTH + `METADATA_WIDTH
`define FLAG_W 1
`define SVC_W `COUNT_WIDTH
`define VALID_W 1
`define CP_BUS_W `INTER_BUS_W + `NODE_WIDTH + `CMP_RESULT_W + `FLAG_W + `SVC_W + `VALID_W
`define FORWARDV_W `CMP_RESULT_W
`define PW_BUS_W `INTER_BUS_W + `NODE_WIDTH + `CMP_RESULT_W + `FLAG_W + `SVC_W + `VALID_W + `FORWARDV_W + `CLEAR_W
`define WRITE_BUS_W `VALID_W + `ADDR_W + `NODE_WIDTH
`endif