`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 16:36:13
// Design Name: 
// Module Name: read_stage
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
module read_stage (
    input  wire                 clk,
    input  wire                 rst_n,      // active low reset
    input  wire [`INTER_BUS_W-1:0]     in_bus,
    input  wire [`INTER_BUS_W-1:0]     upper_bus,
    output wire [`RC_BUS_W-1:0] rc_bus,
    output wire in_bus_valid, //signal to indicate this time choose in_bus or upper_bus
    //ADD: Signal to BRAM
    output wire enb,
    output wire [`ADDR_W-1:0] addrb
);

// Variables
// reg for input
reg [`INTER_BUS_W-1:0] in_bus_reg;
// reg [`INTER_BUS_W-1:0] upper_bus_reg;

// Extracted signal from in_bus and upper_bus
wire [`INS_TYPE_W-1:0] in_bus_ins_type;
wire [`INS_R1_W-1:0] in_bus_r1;
wire [`INS_R2_W-1:0] in_bus_r2;

wire [`INS_TYPE_W-1:0] upper_bus_ins_type;
wire [`INS_R1_W-1:0] upper_bus_r1;
wire [`INS_R2_W-1:0] upper_bus_r2;

// Signal for RC bus
wire [`INS_TYPE_W-1:0] rc_bus_ins_type;
wire [`INS_R1_W-1:0] rc_bus_r1;
wire [`INS_R2_W-1:0] rc_bus_r2;
wire rc_is_in;


// MicroModules:
// Synchronize
// Description: Register the input buses
// Input: in_bus
// Output: in_bus_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_bus_reg <= {`INTER_BUS_W{1'b0}};
    end else begin
        in_bus_reg <= in_bus;
    end
end

/* Extracting signals */
// Description: Extract necessary fields from in_bus and upper_bus
// Input: in_bus_reg, upper_bus_reg
// Output: in_bus_ins_type, in_bus_r1, in_bus_r2, upper_bus_ins_type, upper_bus_r1, upper_bus_r2

assign in_bus_ins_type = in_bus_reg[`INTER_BUS_W-1:`INTER_INS_TYPE_POS];
assign in_bus_r1 = in_bus_reg[`INTER_INS_TYPE_POS-1:`INTER_R1_POS];
assign in_bus_r2 = in_bus_reg[`INTER_R1_POS-1:`INTER_R2_POS];

assign upper_bus_ins_type = upper_bus[`INTER_BUS_W-1:`INTER_INS_TYPE_POS];
assign upper_bus_r1 = upper_bus[`INTER_INS_TYPE_POS-1:`INTER_R1_POS];
assign upper_bus_r2 = upper_bus[`INTER_R1_POS-1:`INTER_R2_POS];

// judging which bus to use
// Description: If Upper_bus_ins_type is NOT NOP, use upper_bus; else use in_bus
// Input: in_bus_ins_type, upper_bus_ins_type
// Output: in_bus_valid, rc_bus_ins_type, rc_bus_r1, rc_bus_r2,rc_bus

assign in_bus_valid = (upper_bus_ins_type == `OP_NOP) ? 1'b1 : 1'b0;
assign rc_bus_ins_type = (upper_bus_ins_type == `OP_NOP) ? in_bus_ins_type : upper_bus_ins_type;
assign rc_bus_r1 = (upper_bus_ins_type == `OP_NOP) ? in_bus_r1 : upper_bus_r1;
assign rc_bus_r2 = (upper_bus_ins_type == `OP_NOP) ? in_bus_r2 : upper_bus_r2;
assign rc_is_in = in_bus_valid;
assign rc_bus = {rc_is_in, rc_bus_ins_type, rc_bus_r1, rc_bus_r2};
// Sendout BRAM read signal
// Description: Send out BRAM read signal, enb: when not NOP is 1; addrb: r1
// Input: rc_bus_ins_type, rc_bus_r1
// Output: enb, addrb
assign enb = (rc_bus_ins_type != `OP_NOP) ? 1'b1 : 1'b0;
assign addrb = rc_bus_r1;


endmodule