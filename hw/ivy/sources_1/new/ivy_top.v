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
module ivy_top #(
    parameter NUM_IPU = 10,
    parameter MEM_INIT_FILE="mem_init.mem"
)(  input wire    clk, 
    input wire    rst_n,
    input wire [(`INTER_BUS_W)*NUM_IPU-1:0] in_bus_all ,
    input wire [`COUNT_WIDTH-1:0] config_length,
    output wire [(`OUTBUS_W)*NUM_IPU-1:0] out_bus_all
);

wire [`INTER_BUS_W-1:0] upper_bus [0:NUM_IPU-1];
wire [`INTER_BUS_W-1:0] lower_bus [0:NUM_IPU-1];
wire [`FORWARD_BUS_W-1:0] to_bus [0:NUM_IPU-1];
wire [`FORWARD_BUS_W-1:0] from_bus [0:NUM_IPU-1];

wire [`INTER_BUS_W-1:0] in_bus [0:NUM_IPU-1];
wire [`OUTBUS_W-1:0] out_bus [0:NUM_IPU-1];
genvar k;
generate
    for (k=0;k<NUM_IPU; k = k + 1) begin: UNPACK
        assign in_bus[k] = in_bus_all[(`INTER_BUS_W)*(k+1) -1:(`INTER_BUS_W) * k];
        assign out_bus_all[(`OUTBUS_W)*(k+1) -1:(`OUTBUS_W) * k] = out_bus[k];
    end
endgenerate
wire input_valid [0:NUM_IPU-1];
genvar i;
generate
    for (i=0;i<NUM_IPU; i = i + 1) begin: IPU_RING
    
    wire [`INTER_BUS_W-1:0] in_bus_k;
    wire [`INTER_BUS_W-1:0] upper_bus_k;
    wire [`FORWARD_BUS_W-1:0] from_bus_k;
    wire [`INTER_BUS_W-1:0] lower_bus_k;
    wire [`FORWARD_BUS_W-1:0] to_bus_k;
    wire [`OUTBUS_W-1:0] out_bus_k;
    assign in_bus_k = in_bus[i];
    assign upper_bus_k = upper_bus[i];
    assign from_bus_k = to_bus[(i+1) % NUM_IPU];
    assign upper_bus[(i+1) % NUM_IPU]=lower_bus_k;
    assign to_bus[i]=to_bus_k; 
    assign out_bus[i] = out_bus_k;
    ipu #(
    ) u_ipu (
        .clk(clk),
        .rst_n(rst_n),
        .in_bus(in_bus_k),
        .in_bus_valid(input_valid[i]),
        .upper_bus(upper_bus_k),
        .lower_bus(lower_bus_k),
        .from_bus(from_bus_k),
        .to_bus(to_bus_k),
        .config_length(config_length),
        .out_bus(out_bus_k)
    );
    end
endgenerate

endmodule