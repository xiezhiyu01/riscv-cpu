`default_nettype none
`include "defines.vh"


module ex_mem(
    input wire            clk,
    input wire            rst,
    input wire[4:0]       stall,

    input wire[`OpBus]    ex_op,
    input wire[31:0]      ex_reg_t_val,
    input wire[31:0]      ex_result,
    input wire[3:0]       ex_flags,
    input wire[`RegBus]   ex_reg_d,
    input wire            ex_write_back,
    input wire            ex_we,
    input wire            ex_oe,
    input wire            ex_be,
    input wire            ex_use_uart,


    output reg[`OpBus]    mem_op,
    output reg[31:0]      mem_reg_t_val,
    output reg[31:0]      mem_result,
    output reg[3:0]       mem_flags,
    output reg[`RegBus]   mem_reg_d,
    output reg            mem_write_back,
    output reg            mem_we,
    output reg            mem_oe,
    output reg            mem_be,
    output reg            mem_use_uart


);

    always @(posedge clk or posedge rst) begin
        if (rst || stall[3] == `Stop) begin
            mem_op <= `OP_INVALID;
            mem_reg_t_val <= `ZeroWord;
            mem_result <= `ZeroWord;
            mem_flags <= 4'b0000;
            mem_reg_d <= 5'b0;
            mem_write_back <= 0;
            mem_we <= 0;
            mem_oe <= 0;
            mem_be <= 0; 
            mem_use_uart <= 0;
        end else begin
            mem_op <= ex_op;
            mem_reg_t_val <= ex_reg_t_val;
            mem_result <= ex_result;
            mem_flags <= ex_flags;
            mem_reg_d <= ex_reg_d;
            mem_write_back <= ex_write_back;
            mem_we <= ex_we;
            mem_oe <= ex_oe;
            mem_be <= ex_be;
            mem_use_uart <= ex_use_uart;
        end     
    end

endmodule