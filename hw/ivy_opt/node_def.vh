`ifndef NODE_DEFS_VH
`define NODE_DEFS_VH
`include "ipu_def.vh"
`define TREE_NUM 88
`define TREE_LAYER 11
`define RANK_WIDTH 16
`define METADATA_WIDTH $clog2(`TREE_NUM)
`define COUNT_WIDTH 12
`define NODE_WIDTH 1+`RANK_WIDTH *2 +`METADATA_WIDTH *2 + 2 + `ADDR_W +`COUNT_WIDTH
// node: 
// [142:142] is_root
// [141:126] lnode_value
// [125:94] lnode_metadata
// [93:78] rnode_value
// [77:46] rnode_metadata
// [45:45] lchild_valid
// [44:29] lchild_addr
// [28:28] rchild_valid
// rchild addr is default laddr+1 so eliminate
// [11:0]  count

// `define IS_ROOT_POS 1+`RANK_WIDTH *2 +`METADATA_WIDTH *2 + 2 + `ADDR_W *2 +`COUNT_WIDTH-1

// `define LNODE_VALUE_POS `RANK_WIDTH +`METADATA_WIDTH *2 + 2 + `ADDR_W *2+ `COUNT_WIDTH

// `define LNODE_METADATA_POS `RANK_WIDTH +`METADATA_WIDTH + 2 + `ADDR_W *2+ `COUNT_WIDTH

// `define RNODE_VALUE_POS `METADATA_WIDTH + 2 + `ADDR_W *2+ `COUNT_WIDTH

// `define RNODE_METADATA_POS 2 + `ADDR_W *2+ `COUNT_WIDTH

// `define LCHILD_VALID_POS 1+`ADDR_W*2 + `COUNT_WIDTH

// `define LCHILD_ADDR_POS 1 + `ADDR_W + `COUNT_WIDTH

// `define RCHILD_VALID_POS `ADDR_W + `COUNT_WIDTH

// `define RCHILD_ADDR_POS `COUNT_WIDTH

// `define COUNT_POS 0

`define INF {`RANK_WIDTH{1'b1}}

`endif