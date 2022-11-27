`default_nettype none
`include "defines.vh"
// 此文件暂时没用
module mem(
        input wire          rst,
        input wire[`OpBus]  mem_op,
        input wire[31:0]    mem_result,
        input wire[31:0]    mem_reg_t_val,

        output reg[31:0]    mem_addr,
        output reg          mem_ce,
        output reg          mem_we,
        output reg[31:0]    mem_data
    );
    

    assign mem_we = (mem_op == `OP_SW || mem_op == `OP_SB);
    wire mem_oe;
    assign mem_oe = (mem_op == `OP_LW || mem_op == `OP_LB);
    assign mem_ce = (mem_oe || mem_we);
    assign mem_data = mem_reg_t_val;

endmodule


