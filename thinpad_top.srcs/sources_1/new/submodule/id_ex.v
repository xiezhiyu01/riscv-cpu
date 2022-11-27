`default_nettype none
`include "defines.vh"


module id_ex(
    input wire            clk,
    input wire            rst,
    input wire[4:0]       stall,

    input wire[31:0]      id_reg_s_val,
    input wire[31:0]      id_reg_t_val,
    input wire[`RegBus]   id_reg_s,
    input wire[`RegBus]   id_reg_d,
    input wire[`RegBus]   id_reg_t,
    input wire[`OpBus]    id_op,
    input wire            id_we,
    input wire            id_oe,
    input wire            id_be,
    input wire[31:0]      id_imm,
    input wire            id_imm_select,
    input wire            id_write_back,
    input wire[31:0]      id_pc,

    output reg[31:0]      ex_reg_s_val,
    output reg[31:0]      ex_reg_t_val,
    output reg[`RegBus]   ex_reg_s,
    output reg[`RegBus]   ex_reg_d,
    output reg[`RegBus]   ex_reg_t,
    output reg[`OpBus]    ex_op,
    output reg            ex_we,
    output reg            ex_oe,
    output reg            ex_be,
    output reg[31:0]      ex_imm,
    output reg            ex_imm_select,
    output reg            ex_write_back,
    output reg[31:0]      ex_pc
);

    always @(posedge clk or posedge rst) begin
        if (rst || stall[2] == `Stop) begin
            ex_reg_s_val <= `ZeroWord;
            ex_reg_t_val <= `ZeroWord;
            ex_reg_s <= 5'b0;
            ex_reg_t <= 5'b0;
            ex_reg_d <= 5'b0;
            ex_op <= `OP_INVALID;
            ex_imm <= `ZeroWord;
            ex_imm_select <= 0;
            ex_write_back <= 0;
            ex_we <= 0;
            ex_oe <= 0;
            ex_be <= 0;
            ex_pc <= `ZeroWord;
        end else begin
            ex_reg_s_val <= id_reg_s_val;
            ex_reg_t_val <= id_reg_t_val;
            ex_reg_d <= id_reg_d;
            ex_reg_s <= id_reg_s;
            ex_reg_t <= id_reg_t;
            ex_op <= id_op;
            ex_imm <= id_imm;
            ex_imm_select <= id_imm_select;
            ex_write_back <= id_write_back;
            ex_we <= id_we;
            ex_oe <= id_oe;
            ex_be <= id_be;
            ex_pc <= id_pc;
        end     
    end

endmodule