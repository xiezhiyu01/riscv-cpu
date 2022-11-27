`default_nettype none
`include "defines.vh"

module if_id(
    input wire            clk,
    input wire            rst,
    input wire[4:0]       stall,
    input wire            branch_flag,

    input wire[31:0]      if_pc,
    input wire[31:0]      if_inst,
    input wire            if_prediction_flag,
    input wire[31:0]      if_prediction_pc,    
    
    output reg[31:0]      id_pc,
    output reg[31:0]      id_inst,
    output reg            id_prediction_flag,
    output reg[31:0]      id_prediction_pc
);


    always @(posedge clk or posedge rst) begin
        if (rst || stall[1] == `Stop) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            id_prediction_flag<=1'b0;
            id_prediction_pc <= `ZeroWord;
        end else begin
            if(branch_flag) begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
                id_prediction_flag<=1'b0;
                id_prediction_pc <= `ZeroWord;
            end else begin
                id_pc <= if_pc;
                id_inst <= if_inst;
                id_prediction_flag <= if_prediction_flag;
                id_prediction_pc <= if_prediction_pc; 
            end
  
        end     
    end

endmodule