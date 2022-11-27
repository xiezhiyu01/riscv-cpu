module bpu(
    input wire          clk,
    input wire          rst,
    input wire[31:0]    pc_i, // PC of current branch instruction
    input wire          set_i,
    input wire[31:0]    set_pc_i, // set pc
    input wire          set_taken_i,
    input wire[31:0]    set_target_i, // target
    output reg          pre_taken_o,  //预测是否跳转
    output reg[31:0]    pre_target_o //跳转目标
);
    localparam SCS_STRONGLY_TAKEN = 2'b11;
    localparam SCS_WEAKLY_TAKEN = 2'b10;
    localparam SCS_WEAKLY_NOT_TAKEN = 2'b01;
    localparam SCS_STRONGLY_NOT_TAKEN = 2'b00;
    localparam BTBW = 6; // The width of btb address
    
    wire [BTBW-1:0] tb_entry;
    wire [BTBW-1:0] set_tb_entry;

    // PC Address hash mapping 取5-1位
    assign tb_entry = pc_i[BTBW:1];
    assign set_tb_entry = set_pc_i[BTBW:1];


    // Saturating counters 两位动态预测
    reg [1:0]   counter[(1<<BTBW)-1:0];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter[0]<=2'b00;	counter[1]<=2'b00;	counter[2]<=2'b00;	counter[3]<=2'b00;
            counter[4]<=2'b00;	counter[5]<=2'b00;	counter[6]<=2'b00;	counter[7]<=2'b00;
            counter[8]<=2'b00;	counter[9]<=2'b00;	counter[10]<=2'b00;	counter[11]<=2'b00;
            counter[12]<=2'b00;	counter[13]<=2'b00;	counter[14]<=2'b00;	counter[15]<=2'b00;
            counter[16]<=2'b00;	counter[17]<=2'b00;	counter[18]<=2'b00;	counter[19]<=2'b00;
            counter[20]<=2'b00;	counter[21]<=2'b00;	counter[22]<=2'b00;	counter[23]<=2'b00;
            counter[24]<=2'b00;	counter[25]<=2'b00;	counter[26]<=2'b00;	counter[27]<=2'b00;
            counter[28]<=2'b00;	counter[29]<=2'b00;	counter[30]<=2'b00;	counter[31]<=2'b00;
            counter[32]<=2'b00;	counter[33]<=2'b00;	counter[34]<=2'b00;	counter[35]<=2'b00;
            counter[36]<=2'b00;	counter[37]<=2'b00;	counter[38]<=2'b00;	counter[39]<=2'b00;
            counter[40]<=2'b00;	counter[41]<=2'b00;	counter[42]<=2'b00;	counter[43]<=2'b00;
            counter[44]<=2'b00;	counter[45]<=2'b00;	counter[46]<=2'b00;	counter[47]<=2'b00;
            counter[48]<=2'b00;	counter[49]<=2'b00;	counter[50]<=2'b00;	counter[51]<=2'b00;
            counter[52]<=2'b00;	counter[53]<=2'b00;	counter[54]<=2'b00;	counter[55]<=2'b00;
            counter[56]<=2'b00;	counter[57]<=2'b00;	counter[58]<=2'b00;	counter[59]<=2'b00;
            counter[60]<=2'b00;	counter[61]<=2'b00;	counter[62]<=2'b00;	counter[63]<=2'b00;
        end
        else if(set_i && set_taken_i && (counter[set_tb_entry] != SCS_STRONGLY_TAKEN)) begin
                counter[set_tb_entry] <= counter[set_tb_entry] + 2'b01;
        end
        else if(set_i && (!set_taken_i) && (counter[set_tb_entry] != SCS_STRONGLY_NOT_TAKEN)) begin
                counter[set_tb_entry] <= counter[set_tb_entry] - 2'b01;
        end
    end

    //branch target buffer 分支目标缓存
    reg [31:0] btb[(1<<BTBW)-1:0];
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            btb[0]<=32'b0;	btb[1]<=32'b0;	btb[2]<=32'b0;	btb[3]<=32'b0;
            btb[4]<=32'b0;	btb[5]<=32'b0;	btb[6]<=32'b0;	btb[7]<=32'b0;
            btb[8]<=32'b0;	btb[9]<=32'b0;	btb[10]<=32'b0;	btb[11]<=32'b0;
            btb[12]<=32'b0;	btb[13]<=32'b0;	btb[14]<=32'b0;	btb[15]<=32'b0;
            btb[16]<=32'b0;	btb[17]<=32'b0;	btb[18]<=32'b0;	btb[19]<=32'b0;
            btb[20]<=32'b0;	btb[21]<=32'b0;	btb[22]<=32'b0;	btb[23]<=32'b0;
            btb[24]<=32'b0;	btb[25]<=32'b0;	btb[26]<=32'b0;	btb[27]<=32'b0;
            btb[28]<=32'b0;	btb[29]<=32'b0;	btb[30]<=32'b0;	btb[31]<=32'b0;
            btb[32]<=32'b0;	btb[33]<=32'b0;	btb[34]<=32'b0;	btb[35]<=32'b0;
            btb[36]<=32'b0;	btb[37]<=32'b0;	btb[38]<=32'b0;	btb[39]<=32'b0;
            btb[40]<=32'b0;	btb[41]<=32'b0;	btb[42]<=32'b0;	btb[43]<=32'b0;
            btb[44]<=32'b0;	btb[45]<=32'b0;	btb[46]<=32'b0;	btb[47]<=32'b0;
            btb[48]<=32'b0;	btb[49]<=32'b0;	btb[50]<=32'b0;	btb[51]<=32'b0;
            btb[52]<=32'b0;	btb[53]<=32'b0;	btb[54]<=32'b0;	btb[55]<=32'b0;
            btb[56]<=32'b0;	btb[57]<=32'b0;	btb[58]<=32'b0;	btb[59]<=32'b0;
            btb[60]<=32'b0;	btb[61]<=32'b0;	btb[62]<=32'b0;	btb[63]<=32'b0;
        end
        else if(set_i)begin
            btb[set_tb_entry] <= set_target_i;
        end
    end

    always @(*) begin
        pre_target_o <= btb[tb_entry];
        pre_taken_o <= counter[tb_entry][1];
    end
endmodule