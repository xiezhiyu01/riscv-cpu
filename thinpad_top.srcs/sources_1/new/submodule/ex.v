`default_nettype none
`include "defines.vh"

module ex(
        input wire              rst,
        input wire[`OpBus]      ex_op,
        input wire[31:0]        ex_imm,
        input wire              ex_imm_select,
        input wire[31:0]        ex_reg_s_val,
        input wire[31:0]        ex_reg_t_val,
        input wire[31:0]        ex_pc,

        //data forward
        input wire[`RegBus]     ex_reg_s,
        input wire[`RegBus]     ex_reg_t,
        input wire[`RegBus]     mem_reg_d,
        input wire[`RegBus]     wb_reg_d, 
        input wire              mem_write_back,  
        input wire[31:0]        mem_data,
        input wire              wb_write_back,  
        input wire[31:0]        wb_data,

        output wire[31:0]       ex_reg_t_val_forward,
        output wire[31:0]       ex_result,
        output wire[3:0]        ex_flags
    );
    
    reg[3:0]    alu_op;
    reg[31:0]   a;
    reg[31:0]   b;
    reg[31:0]   reg_t_val_forward;
    assign ex_reg_t_val_forward = reg_t_val_forward;

    alu alu0(
        .op             (alu_op),
        .a              (a),
        .b              (b),
        .r              (ex_result),
        .flags          (ex_flags)
    );

    always @(*) begin
        case(ex_op)
            `OP_LW, `OP_SW, `OP_ADD, `OP_LB, `OP_SB, `OP_AUIPC, `OP_JAL, `OP_JALR:begin
                alu_op <= `ADD;
            end
            `OP_OR: begin
                alu_op <= `OR;
            end
            `OP_AND: begin
                alu_op <= `AND;
            end
            `OP_XOR: begin
                alu_op <= `XOR;
            end
            `OP_SLL: begin
                alu_op <= `SLL;
            end
            `OP_SRL: begin
                alu_op <= `SRL;
            end
            `OP_LUI: begin
                alu_op <= `RETB;
            end
            `OP_BEQ, `OP_BNE:begin
                alu_op <= `ZERO;
            end
            `OP_CTZ:begin
                alu_op <= `CTZ;
            end
            `OP_MINU:begin
                alu_op <= `MINU;
            end
            `OP_ANDN:begin
                alu_op <= `ANDN;
            end
            default: begin
                alu_op <= `ZERO;
            end
        endcase
    end

    always @(*) begin
        if(ex_op == `OP_AUIPC || ex_op == `OP_JAL || ex_op == `OP_JALR) begin
            a <= ex_pc;
        end else if(ex_reg_s == 5'b00000)begin
            a <= 0;
        end else if(mem_write_back && ex_reg_s == mem_reg_d) begin
            a <= mem_data;
        end else if(wb_write_back && ex_reg_s == wb_reg_d) begin
            a <= wb_data;
        end else begin
            a <= ex_reg_s_val;
        end
    end
    
    
    always @(*) begin
        if(ex_reg_t == 5'b00000)begin
            reg_t_val_forward <= 0;
        end else if(mem_write_back && ex_reg_t == mem_reg_d) begin
            reg_t_val_forward <= mem_data;
        end else if(wb_write_back && ex_reg_t == wb_reg_d) begin
            reg_t_val_forward <= wb_data;
        end else begin
            reg_t_val_forward <= ex_reg_t_val;
        end
    end

    always @(*) begin
        if(ex_op == `OP_JAL || ex_op == `OP_JALR) begin
            b <= 32'h4;
        end else if(ex_imm_select) begin
            b <= ex_imm;
        end else begin
            b <= reg_t_val_forward;
        end
    end

endmodule


