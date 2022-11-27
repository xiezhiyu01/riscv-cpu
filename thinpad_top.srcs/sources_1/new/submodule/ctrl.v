`default_nettype none
`include "defines.vh"

module ctrl(
        input wire clk,
        input wire rst,

        input wire stall_from_id,
        input wire stall_from_mem,

        output reg[4:0] stall
    );

    // stall 0~4 分别表示 
    // 0:  pc_reg 是否 +4
    // 1:  if_id  
    // 2:  id_ex
    // 3:  ex_mem
    // 4:  mem_wb

    always @(*) begin
        if(stall_from_mem == `Stop || stall_from_id == `Stop)begin
            // mem阶段需要读写，没有取出指令
            // id阶段如果读出LB或LW，也需要紧跟着插一个气泡，否则碰到LW + Branch时，读出数据时Branch已经到ex阶段了
            stall <= 5'b00011; // 相当于直接给id一个nop
        end else begin
            stall <= 5'b00000;
        end
    end
    

    

endmodule


