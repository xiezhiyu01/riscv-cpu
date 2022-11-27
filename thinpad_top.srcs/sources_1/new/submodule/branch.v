`default_nettype none
`include "defines.vh"

module branch(
        input wire              rst,
        input wire[`OpBus]      op,
        input wire[31:0]        pc,
        input wire[31:0]        offset,
        input wire[31:0]        id_reg_s_val,
        input wire[31:0]        id_reg_t_val,

        //data forward
        input wire[`RegBus]     id_reg_s,
        input wire[`RegBus]     id_reg_t,
        input wire[`RegBus]     ex_reg_d,
        input wire[`RegBus]     mem_reg_d,
        input wire[`RegBus]     wb_reg_d,   
        input wire              ex_write_back,  
        input wire              mem_write_back,  
        input wire              wb_write_back,  
        input wire[31:0]        ex_data,
        input wire[31:0]        mem_data,
        input wire[31:0]        wb_data,
        input wire              id_prediction_flag,
        input wire[31:0]        id_prediction_pc,

        output wire              branch_flag,
        output wire[31:0]        branch_pc,
        output wire             bpu_set,
        output wire             is_prediction_not_right           
    );

    reg[31:0] s_val;
    reg[31:0] t_val;
    
    wire equal;
    assign equal = (s_val == t_val);
  

    always @(*) begin
        if(id_reg_s == 5'b0)begin
            s_val <= 0;
        end else if(ex_write_back && id_reg_s == ex_reg_d) begin
            s_val <= ex_data;
        end else if(mem_write_back && id_reg_s == mem_reg_d) begin
            s_val <= mem_data;
        end else if(wb_write_back && id_reg_s == wb_reg_d) begin
            s_val <= wb_data;
        end else begin
            s_val <= id_reg_s_val;
        end
    end

    always @(*) begin
        if(id_reg_t == 5'b0)begin
            t_val <= 0;
        end else if(ex_write_back && id_reg_t == ex_reg_d) begin
            t_val <= ex_data;
        end else if(mem_write_back && id_reg_t == mem_reg_d) begin
            t_val <= mem_data;
        end else if(wb_write_back && id_reg_t == wb_reg_d) begin
            t_val <= wb_data;
        end else begin
            t_val <= id_reg_t_val;
        end
    end
    
    assign bpu_set = (op == `OP_BEQ) || (op == `OP_BNE) || (op == `OP_JAL) || (op == `OP_JALR);

    assign is_prediction_not_right = !(((branch_flag == 1'b0) && (id_prediction_flag == 1'b0)) 
            || ((branch_flag == 1'b1) && (id_prediction_flag == 1'b1) && (branch_pc == id_prediction_pc)));

    assign branch_flag = (equal && (op == `OP_BEQ)) || ((~equal) && (op == `OP_BNE)) 
            || (op == `OP_JAL) || (op == `OP_JALR);

    assign branch_pc = branch_flag ? ((op == `OP_JALR) ? (s_val + offset) & (~(32'b1)):pc + offset) : pc + 4;
endmodule


