`timescale 1ns / 1ps
// `include "bus_def.vh"
// `include "ipu_def.vh"
// `include "node_def.vh"
// `include "stage.vh"

`include "for_vscode/bus_def.vh"
`include "for_vscode/ipu_def.vh"
`include "for_vscode/node_def.vh"
`include "for_vscode/stage.vh"

module test_input_bram(
    );

reg clk;
reg ena, enb;
reg [0:0] wea;
reg [15:0] addra, addrb;
reg [142:0] dina;
wire [142:0] doutb;

integer i;

blk_mem_gen_0 bram_inst(
    .clka(clk),
    .ena(ena),
    .wea(wea),
    .addra(addra),
    .dina(dina),
    .clkb(clk),
    .enb(enb),
    .addrb(addrb),
    .doutb(doutb)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
end

initial begin
    ena = 0; enb = 0;
    wea = 0;
    addra = 0; addrb = 0;
    dina = 0;

    #20;

    $display("Loading memory from mem_ipu0.mem ...");
    $readmemh("D:/vhs/ivy/ivy.srcs/sim_1/new/mem_ipu0.mem", bram_inst.inst.native_mem_module.blk_mem_gen_v8_4_7_inst.memory);
    $display("Memory loaded.");

    enb = 1;

    for (i = 0; i < 256; i = i + 1) begin
        addrb = i;
        #10;
        $display("BRAM[%0d] = %h", i, doutb);
    end

    $stop;
end
endmodule
