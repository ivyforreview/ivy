`timescale 1ns / 1ps
`include "for_vscode/bus_def.vh"
`include "for_vscode/ipu_def.vh"
`include "for_vscode/node_def.vh"
`include "for_vscode/stage.vh"
`include "for_vscode/ins_type.vh"
// `include "bus_def.vh"
// `include "ipu_def.vh"
// `include "node_def.vh"
// `include "stage.vh"
// `include "ins_type.vh"
module test_ivy_top #(
    parameter NUM_IPU = 4
)
(

    );

    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end

    initial begin
        $display("Loading memory from ins.mem ...");
        $readmemh("D:/vhs/ins_mem/ins.mem", ins_gen_inst.ins_reg); 
        $display("Memory loaded.");
    end

    initial begin
        #1;
        $display("Loading memory from mem_pool ...");
        $readmemh("D:/vhs/mem_pool/mem_ipu_0.mem", ivy_top_inst.IPU_RING[0].u_ipu.bram_inst.inst.native_mem_module.blk_mem_gen_v8_4_7_inst.memory);
        $readmemh("D:/vhs/mem_pool/mem_ipu_1.mem", ivy_top_inst.IPU_RING[1].u_ipu.bram_inst.inst.native_mem_module.blk_mem_gen_v8_4_7_inst.memory);
        $readmemh("D:/vhs/mem_pool/mem_ipu_2.mem", ivy_top_inst.IPU_RING[2].u_ipu.bram_inst.inst.native_mem_module.blk_mem_gen_v8_4_7_inst.memory);
        $readmemh("D:/vhs/mem_pool/mem_ipu_3.mem", ivy_top_inst.IPU_RING[0].u_ipu.bram_inst.inst.native_mem_module.blk_mem_gen_v8_4_7_inst.memory); 
    
    end
    

    wire [(`INTER_BUS_W)*NUM_IPU-1:0] in_bus_all;
    wire [`COUNT_WIDTH-1:0] config_length;
    wire [(`OUTBUS_W)*NUM_IPU-1:0] out_bus_all;

    wire [`OUTBUS_W-1:0] out_bus [0:NUM_IPU-1];

    genvar i;
    generate
        for (i = 0; i < NUM_IPU; i = i + 1) begin
            assign out_bus[i] = out_bus_all[(`OUTBUS_W)*(i+1)-1:(`OUTBUS_W) * i];
        end
    endgenerate

    ins_gen ins_gen_inst(
        .clk(clk),
        .rst_n(rst_n),
        .in_bus_all(in_bus_all),
        .config_length(config_length)
    );
    
    ivy_top ivy_top_inst(
        .clk(clk),
        .rst_n(rst_n),
        .in_bus_all(in_bus_all),
        .config_length(config_length),
        .out_bus_all(out_bus_all)
    );

    always @(posedge clk) begin
        if ((out_bus[0][`OUTBUS_W-1]==1'b1) && 
        (out_bus[0][`OUTBUS_W-2:`ADDR_W+`INS_R2_W]==`OP_POPROOT ||
        out_bus[0][`OUTBUS_W-2:`ADDR_W+`INS_R2_W]==`OP_POPLEAF))
        begin
            $display("outbus! [%0t] %s", $time, out_bus[0]);
        end
    end
    

endmodule
