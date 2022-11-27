// Constants
`define Enable 1'b1
`define Disable 1'b0
`define ZeroWord 32'h00000000
`define InstValid 1'b1
`define InstInvalid 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define True_v 1'b1
`define False_v 1'b0
`define StartInstAddr 32'h80000000
`define RegBus 4:0 

// 译码结果，送给后面的阶段
`define OpBus 4:0 

`define OP_INVALID 5'h0
`define OP_LW 5'h1
`define OP_SW 5'h2
`define OP_OR 5'h3
`define OP_ADD 5'h4
`define OP_BEQ 5'h5
`define OP_LUI 5'h6
`define OP_LB 5'h7
`define OP_SB 5'h8
`define OP_AND 5'h9
`define OP_MINU 5'ha
`define OP_ANDN 5'hb
`define OP_CTZ 5'hc

`define OP_BNE 5'h10
`define OP_XOR 5'h11
`define OP_SLL 5'h12
`define OP_SRL 5'h13
`define OP_AUIPC 5'h14
`define OP_JAL 5'h15
`define OP_JALR 5'h16


// ALU采取的运算
`define ZERO    4'b0000 
`define ADD     4'b0001
`define SUB     4'b0010
`define AND     4'b0011
`define OR      4'b0100
`define XOR     4'b0101
`define NOT     4'b0110
`define SLL     4'b0111
`define SRL     4'b1000
`define SRA     4'b1001
`define ROL     4'b1010
`define RETB    4'b1011 //for lui, result = b
`define MINU    4'b1100 
`define ANDN    4'b1101 
`define CTZ     4'b1110