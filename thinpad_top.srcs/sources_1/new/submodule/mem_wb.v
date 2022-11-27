`default_nettype none
`include "defines.vh"


module mem_wb(
    input wire            clk,
    input wire            rst,
    input wire[4:0]       stall,

    input wire[`OpBus]    mem_op,
    input wire[31:0]      mem_data,
    input wire[`RegBus]   mem_reg_d,  
    input wire            mem_write_back,
    input wire[31:0]      mem_result,
    input wire            mem_oe,

    output reg[`OpBus]    wb_op,
    output reg[31:0]      wb_data,
    output reg[`RegBus]   wb_reg_d,
    output reg            wb_write_back,
    output reg[31:0]      wb_result,
    output reg            wb_oe

);

    always @(posedge clk or posedge rst) begin
        if (rst || stall[4] == `Stop) begin
            wb_op <= `OP_INVALID;
            wb_data <= `ZeroWord;
            wb_reg_d <= 5'b0;
            wb_write_back <= 0;
            wb_result <= `ZeroWord;
            wb_oe <= 0;

        end else begin
            wb_op <= mem_op;
            wb_data <= mem_data;
            wb_reg_d <= mem_reg_d;
            wb_write_back <= mem_write_back;
            wb_result <= mem_result;
            wb_oe <= mem_oe;
        end     
    end

endmodule