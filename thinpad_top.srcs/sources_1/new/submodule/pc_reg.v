`default_nettype none
`include "defines.vh"

module pc_reg(
    input wire            clk,
    input wire            rst,
    input wire[4:0]       stall,
    input wire            branch_flag,
    input wire[31:0]      branch_pc,
    input wire            prediction_flag,
    input wire[31:0]      prediction_pc,

    output reg[31:0]      pc,
    output reg            ce

);

    // 这一部分时序很容易混乱，如果没出错请勿深入思考
    // 主要原因是我们的取指使用组合逻辑在一个周期内完成
    // 先执行pc+4还是取指基本由组合逻辑延时决定（一般来说读内存更慢，所以会先+4）
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ce <= `Disable;
            pc <= `StartInstAddr - 4;
        end else if(branch_flag)begin
            pc <= branch_pc;
        end else if(stall[0] == `Stop)begin
            ce <= `Enable; 
            //相当于pass
            //如果设成disable也要下个周期才能给到，反而造成时序错误
            //在mem读写的周期内 pc已经指向了下一条指令 mem读写实际上是让下一个周期pc不要+4
        end else begin
            ce <= `Enable;
            pc <= prediction_flag ? prediction_pc : pc + 4;
        end     
    end

endmodule