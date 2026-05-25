`timescale 1ns / 1ps
`include "for_vscode/bus_def.vh"
`include "for_vscode/ipu_def.vh"
`include "for_vscode/node_def.vh"
`include "for_vscode/stage.vh"
// `include "bus_def.vh"
// `include "ipu_def.vh"
// `include "node_def.vh"
// `include "stage.vh"

module ins_gen #(
    parameter NUM_IPU = 4,
    parameter NUM_INS = 4,
    parameter CONFIG_LENGTH=8
)(
input wire clk,
input wire rst_n,
output wire [(`INTER_BUS_W)*NUM_IPU-1:0] in_bus_all,
output wire [`COUNT_WIDTH-1:0] config_length
    );

wire [`INTER_BUS_W-1:0] in_bus [NUM_IPU-1:0];

genvar i;
generate
    for (i=0;i<NUM_IPU;i=i+1) begin : PACK
        assign in_bus_all[(`INTER_BUS_W)*(i+1) -1:(`INTER_BUS_W) * i] = in_bus[i];
    end
endgenerate

reg [`INTER_BUS_W-1:0] ins_reg [NUM_INS-1:0];

reg [`INTER_BUS_W-1:0] ins_0;
reg [$clog2(NUM_INS):0] count;

always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        count <= 0;
        ins_0 <= 0;
    end else begin
        if (count == NUM_INS-1) begin
            count <= 0;
            ins_0 <= ins_reg[count];
        end else begin
            count <= count + 1;
            ins_0 <= ins_reg[count];
        end
    end
end

assign in_bus[0] = ins_0;
genvar j;
generate
    for (j=1;j<NUM_IPU;j=j+1) begin : INS_GEN
        assign in_bus[j] = 0;
    end
endgenerate

assign config_length = CONFIG_LENGTH;
endmodule
