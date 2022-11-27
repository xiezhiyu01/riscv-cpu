`default_nettype none
`include "defines.vh"

module id(
    input wire              rst,
    input wire[31:0]        inst,

    output wire[4:0]        reg_s,
    output wire[4:0]        reg_t,
    output wire[4:0]        reg_d,

    output reg[`OpBus]      op,
    output reg[31:0]        imm,
    output reg              imm_select,
    output reg              write_back,
    output reg              oe,
    output reg              we,
    output reg              be,
    output reg              stall_from_id
    );
    
    wire sign;
    wire[19:0] sign_ext;
    wire[11:0] sign_ext_12;
    assign sign = inst[31];
    assign sign_ext = {20{sign}};
    assign sign_ext_12 = {12{sign}};
    assign reg_d = inst[11:7];
    assign reg_s = inst[19:15];
    assign reg_t = inst[24:20];
    
    always @(*) begin
        if(rst) begin
            // TODO
        end else begin
            op = `OP_INVALID;
            imm = 32'h0;
            imm_select = 1'b0;
            write_back = 1'b0;
            oe = 1'b0;
            we = 1'b0;
            be = 1'b0;
            stall_from_id = 1'b0;

            case(inst[6:0])
                7'b0000011: begin //L
                    imm = {sign_ext, inst[31:20]};
                    imm_select = 1'b1;
                    write_back = 1'b1;
                    oe = 1;
                    stall_from_id = 1'b1;
                    case(inst[14:12])
                        3'b010: op = `OP_LW;
                        3'b000: begin
                            op = `OP_LB;
                            be = 1;
                        end 
                    endcase
                end
                
                7'b0100011: begin //S
                    imm = {sign_ext, inst[31:25], inst[11:7]};
                    imm_select = 1'b1;
                    write_back = 1'b0;
                    we = 1;
                    case(inst[14:12])
                        3'b010: op = `OP_SW;
                        3'b000: begin
                            op = `OP_SB;
                            be = 1;
                        end
                    endcase
                end
                
                7'b0010011: begin //I
                    imm = {sign_ext, inst[31:20]};
                    imm_select = 1'b1;
                    write_back = 1'b1;
                    case(inst[14:12])
                        3'b110: op = `OP_OR;
                        3'b000: op = `OP_ADD;
                        3'b111: op = `OP_AND;
                        3'b101: op = `OP_SRL;
                        3'b001:
                            case(inst[31:25])
                                7'b0000000: op = `OP_SLL;
                                7'b0110000: op = `OP_CTZ; //这个是不需要imm的 但是传过去也没事
                            endcase
                        
                    endcase
                end
                
                7'b0110011: begin //R
                    write_back = 1'b1;
                    case({inst[31:25], inst[14:12]})
                        10'b0000000_110: op = `OP_OR;
                        10'b0000000_000: op = `OP_ADD;
                        10'b0000000_111: op = `OP_AND;
                        10'b0000000_100: op = `OP_XOR;
                        10'b0000101_110: op = `OP_MINU;
                        10'b0100000_111: op = `OP_ANDN;
                    endcase
                end

                
                7'b1100011: begin //B
                    imm = {
                        sign_ext,
                        inst[7],inst[30:25],inst[11:8],1'b0
                    };
                    imm_select = 1'b1;
                    case(inst[14:12])
                        3'b000: op = `OP_BEQ;
                        3'b001: op = `OP_BNE;
                    endcase
                end

                7'b0110111: begin //LUI
                    write_back = 1'b1;
                    imm = {
                        inst[31:12],12'b0
                    };
                    imm_select = 1'b1;
                    op = `OP_LUI;
                end

                7'b0010111: begin //AUIPC
                    write_back = 1'b1;
                    imm = {
                        inst[31:12],12'b0
                    };
                    imm_select = 1'b1;
                    op = `OP_AUIPC;
                end

                7'b1101111: begin //JAL
                    write_back = 1'b1;
                    imm = { //check it?
                        sign_ext_12,
                        inst[19:12], inst[20], inst[30:21], 1'b0
                    };
                    // imm_select = 1'b0; ALU计算pc+4 不需要imm
                    op = `OP_JAL;
                end

                7'b1100111: begin //JALR
                    write_back = 1'b1;
                    imm = {sign_ext, inst[31:20]};
                    // imm_select = 1'b0; ALU计算pc+4 不需要imm
                    op = `OP_JALR;
                end

            endcase 
        end

    end
endmodule


