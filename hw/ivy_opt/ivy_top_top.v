`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/20 15:56:13
// Design Name: 
// Module Name: ivy_top
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
module ivy_top_top#
(parameter NUM_IPU = 11
)(
    input wire    clk, 
    input wire    rst_n,
    input wire [(`INTER_BUS_W)*NUM_IPU-1:0] in_bus_all ,
    input wire [`COUNT_WIDTH-1:0] config_length,
    output wire [NUM_IPU-1:0] out_bus_fin
);
wire [(`OUTBUS_W)*NUM_IPU-1:0] out_bus_all;
assign out_bus_fin=out_bus_all[NUM_IPU-1:0];

ivy_top #(.NUM_IPU(11)) u_ivy_top (
    .clk(clk),
    .rst_n(rst_n),
    .in_bus_all(in_bus_all),
    .config_length(config_length),
    .out_bus_all(out_bus_all)
);


endmodule