`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 17:03:13
// Design Name: 
// Module Name: ipu
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

`timescale 1ns/1ps
`include "bus_def.vh"
`include "ipu_def.vh"
`include "node_def.vh"
`include "stage.vh"
module ipu #(
    parameter CTRL_W = 8,
    parameter MEM_INIT_FILE = "mem_init.mem"
)(
    input  wire                 clk,
    input  wire                 rst_n,      // active low reset


    input  wire [`INTER_BUS_W-1:0]     in_bus,
    output wire                        in_bus_valid,
    input  wire [`INTER_BUS_W-1:0]     upper_bus,
    output  wire [`INTER_BUS_W-1:0]     lower_bus,
    input  wire [`FORWARD_BUS_W-1:0]     from_bus,
    output wire  [`FORWARD_BUS_W-1:0]     to_bus,
    input [`COUNT_WIDTH-1:0]    config_length,
    output wire [`OUTBUS_W-1:0] out_bus
    /* Maybe signals for BRAM initialization*/
);

    //
    // -----------------------------
    // pipeline stage internal buses
    // -----------------------------
    // read -> compare
    wire [`RC_BUS_W-1:0] rc_bus;
    // compare -> prepare
    wire [`CP_BUS_W-1:0] cp_bus;
    // prepare -> write (????????? compare)
    wire [`PW_BUS_W-1:0] pw_bus;
    // write bus
    wire [`WRITE_BUS_W-1:0] write_bus;

    // pipeline registers (stage outputs latched)
    reg  [`RC_BUS_W-1:0] read_stage_reg;     // read stage ????????
    reg  [`CP_BUS_W-1:0] compare_stage_reg;  // compare stage ????????
    reg  [`PW_BUS_W-1:0] prepare_stage_reg;  // prepare stage ????????


    reg  [CTRL_W-1:0] read_ctrl_reg;
    reg  [CTRL_W-1:0] compare_ctrl_reg;
    reg  [CTRL_W-1:0] prepare_ctrl_reg;
    reg  [CTRL_W-1:0] write_ctrl_reg;


    wire [`PW_BUS_W-1:0] pw_bus_forward;
    assign pw_bus_forward = prepare_stage_reg; // ??????? prepare stage ????????????????????????? pw_bus??

    //signals for BRAM
    wire wea;
    wire [`ADDR_W-1:0] addra;
    wire [`NODE_WIDTH-1:0] dina;
    wire enb;
    wire [`ADDR_W-1:0] addrb;
    wire [`NODE_WIDTH-1:0] doutb;
    
    // -----------------------------
    // STAGE: READ
    // -----------------------------


    read_stage read_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .in_bus     (in_bus),
        .upper_bus  (upper_bus),
        .rc_bus     (rc_bus),
        .in_bus_valid (in_bus_valid),
        .enb        (enb),
        .addrb      (addrb)
    );

    // -----------------------------
    // STAGE: COMPARE
    // -----------------------------
    // compare stage ?? rc_bus (???? read) ?? pw_bus_forward (???? prepare ???) ????????
    // input: clk, rst_n, rc_bus, pw_bus_forward
    // output: cp_bus, lower_bus, to_bus

    //PW_BUS_FORWARD = PW_BUS
    compare_stage compare_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .rc_bus     (rc_bus),
        .pw_bus_forward (pw_bus),
        .write_bus_forward (write_bus),
        .cp_bus     (cp_bus),
        .lower_bus  (lower_bus),
        .to_bus     (to_bus),
        .doutb      (doutb),
        .config_length (config_length),
        .out_bus     (out_bus)
    );

    // -----------------------------
    // STAGE: PREPARE
    // -----------------------------
    // prepare stage ?? cp_bus ???? pw_bus??????????? write??
    // input: clk, rst_n, cp_bus, from_bus
    // output: pw_bus
    
    prepare_stage prepare_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .cp_bus     (cp_bus),
        .from_bus   (from_bus),
        .pw_bus     (pw_bus)
    );

    // -----------------------------
    // STAGE: WRITE
    // -----------------------------
    // write stage ?? pw_bus ????????
    // input: clk, rst_n, pw_bus
    // output: write_stage_reg
    write_stage write_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .pw_bus     (pw_bus),
        .write_bus (write_bus)
    );

    assign {wea, addra, dina}=write_bus;
    // -----------------------------
    // BLOCKRAM
    // -----------------------------

    // Extract signal from write_stage_reg and read_stage

    // blk_mem_gen_0 #()
    // bram_inst(
    //     .clka(clk),
    //     .ena(1'b1),
    //     .wea(wea),
    //     .addra(addra),
    //     .dina(dina),
    //     .clkb(clk),
    //     .enb(enb),
    //     .addrb(addrb),
    //     .doutb(doutb)
    // );

    INFER_SDPRAM #(
        .DATA_WIDTH(`NODE_WIDTH),
        .ADDR_WIDTH(`ADDR_W),
        .ARCH(0),
        .RDW_MODE(1),
        .INIT_VALUE('d0)
    ) bram_inst (
        .i_clk(clk),
        .i_arst_n(rst_n),
        .i_we(wea),
        .i_waddr(addra),
        .i_wdata(dina),
        .i_re(enb),
        .i_raddr(addrb),
        .o_rdata(doutb)
    );

endmodule

