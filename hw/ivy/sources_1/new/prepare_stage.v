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

//Set pw_bus
//Description: generate pw_bus by cp_bus_reg and from_bus
//Input: cp_bus_reg, from_bus
//OUTPUT: pw_bus

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