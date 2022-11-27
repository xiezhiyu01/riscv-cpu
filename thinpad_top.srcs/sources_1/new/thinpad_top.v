`default_nettype none
`define CLOCK clk_11M0592
`define RESET reset_btn
`include "./submodule/defines.vh"
// 为了读写内存能在一个周期内完成，clk频率不能过高

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);


    wire[4:0]       stall;
    wire            stall_from_id;
    wire            stall_from_mem;

    wire[31:0]      if_pc;
    wire[31:0]      id_pc;
    wire[31:0]      ex_pc;

    wire            if_ce;
    wire[31:0]      sram_data_out;

    wire            branch_flag;
    wire[31:0]      branch_pc;

    wire            if_prediction_flag;
    wire[31:0]      if_prediction_pc;

    wire            is_prediction_not_right;
    wire            bpu_set;    //为1则此条指令存储进btb中
    

    pc_reg pc_reg0(
        .clk(`CLOCK),
        .rst(`RESET),
        .stall(stall),
        .branch_flag(is_prediction_not_right),
        .branch_pc(branch_pc),
        .prediction_flag(if_prediction_flag),
        .prediction_pc(if_prediction_pc),

        .pc(if_pc),
        .ce(if_ce)
    );

    //动态预测 branch prodictor unit
    bpu bpu0(
        .clk(`CLOCK),
        .rst(`RESET),
        .pc_i(if_pc),
        .set_i(bpu_set),
        .set_pc_i(id_pc),
        .set_taken_i(branch_flag),
        .set_target_i(branch_pc),
        .pre_taken_o(if_prediction_flag),
        .pre_target_o(if_prediction_pc)
    );

    wire[31:0]      id_inst;
    wire            id_prediction_flag;
    wire[31:0]      id_prediction_pc;

    if_id if_id0(
        .clk(`CLOCK),
        .rst(`RESET),
        .stall(stall),
        .branch_flag(is_prediction_not_right),

        .if_pc(if_pc),
        .if_inst(sram_data_out),
        .if_prediction_flag(if_prediction_flag),
        .if_prediction_pc(if_prediction_pc),

        .id_pc(id_pc),
        .id_inst(id_inst),
        .id_prediction_flag(id_prediction_flag),
        .id_prediction_pc(id_prediction_pc)
    );


    //生成的信号，根据需要向后传递
    wire[`RegBus]   id_reg_s;
    wire[`RegBus]   ex_reg_s;

    wire[`RegBus]   id_reg_t;
    wire[`RegBus]   ex_reg_t;

    wire[`RegBus]   id_reg_d;
    wire[`RegBus]   ex_reg_d;
    wire[`RegBus]   mem_reg_d;
    wire[`RegBus]   wb_reg_d;

    wire[`OpBus]    id_op;
    wire[`OpBus]    ex_op;
    wire[`OpBus]    mem_op;
    wire[`OpBus]    wb_op;

    wire[31:0]      id_imm;
    wire[31:0]      ex_imm;

    wire            id_imm_select;
    wire            ex_imm_select;

    //是否需要wb阶段写回寄存器
    wire            id_write_back;
    wire            ex_write_back;
    wire            mem_write_back;
    wire            wb_write_back;

    wire[31:0]      id_reg_s_val;
    wire[31:0]      ex_reg_s_val;

    wire[31:0]      id_reg_t_val;
    wire[31:0]      ex_reg_t_val;
    wire[31:0]      ex_reg_t_val_forward;
    wire[31:0]      mem_reg_t_val;


    //ALU运算得到的结果
    wire[31:0]      ex_result;
    wire[31:0]      mem_result;
    wire[31:0]      wb_result;     

    //ALU flags 没用
    wire[3:0]       ex_flags;
    wire[3:0]       mem_flags;
     

    //是否要内存读写
    wire            id_we;
    wire            ex_we;
    wire            mem_we;

    wire            id_oe;
    wire            ex_oe;
    wire            mem_oe;
    wire            wb_oe;

    wire            id_be;
    wire            ex_be;
    wire            mem_be;
    wire            wb_be;

    wire mem_ce;
    assign mem_ce = (mem_oe || mem_we);
    assign stall_from_mem = mem_ce;

    wire ex_use_uart;
    assign ex_use_uart = (ex_result == 32'h10000000) && (ex_oe || ex_we);
    wire mem_use_uart;



    //要写回寄存器的数据
    wire[31:0]      mem_data;
    assign mem_data = mem_oe? sram_data_out: mem_result;  
    wire[31:0]      wb_data;   

    id id0(
        .rst(`RESET),
        .inst(id_inst),

        .reg_s(id_reg_s),
        .reg_t(id_reg_t),
        .reg_d(id_reg_d),
        .op(id_op),
        .imm(id_imm),
        .imm_select(id_imm_select),
        .write_back(id_write_back),
        .oe(id_oe),
        .we(id_we),
        .be(id_be),
        .stall_from_id(stall_from_id)
    );

    regfile regfile0(
        .clk(`CLOCK),
        .rst(`RESET),
        .we(wb_write_back),
        .waddr(wb_reg_d),
        .wdata(wb_data),

        .raddr1(id_reg_s),
        .rdata1(id_reg_s_val),
        .raddr2(id_reg_t),
        .rdata2(id_reg_t_val)
    );


    // 静态分支预测：默认不跳转（pc+4），如果要跳转，需要在下一个时钟周期内改变pc并且清除id_if寄存器内容
    branch branch0(
        .rst(`RESET),
        .op(id_op),
        .pc(id_pc),
        .offset(id_imm),
        .id_reg_s_val(id_reg_s_val),
        .id_reg_t_val(id_reg_t_val),

        .id_reg_s(id_reg_s),
        .id_reg_t(id_reg_t),
        .ex_reg_d(ex_reg_d),
        .mem_reg_d(mem_reg_d),
        .wb_reg_d(wb_reg_d),
        .ex_write_back(ex_write_back),
        .mem_write_back(mem_write_back),
        .wb_write_back(wb_write_back),
        .ex_data(ex_result), //由于在L指令后插入了气泡，因此如果此时要前传ex阶段的结果，一定是ALU的结果
        .mem_data(mem_data),
        .wb_data(wb_data),
        .id_prediction_flag(id_prediction_flag),
        .id_prediction_pc(id_prediction_pc),

        .branch_flag(branch_flag),
        .branch_pc(branch_pc),
        .bpu_set(bpu_set),
        .is_prediction_not_right(is_prediction_not_right)
    );

    id_ex id_ex0(
        .clk(`CLOCK),
        .rst(`RESET),
        .stall(stall),

        .id_reg_s_val(id_reg_s_val),
        .id_reg_t_val(id_reg_t_val),
        .id_reg_d(id_reg_d),
        .id_reg_s(id_reg_s),
        .id_reg_t(id_reg_t),
        .id_op(id_op),
        .id_imm(id_imm),
        .id_imm_select(id_imm_select),
        .id_write_back(id_write_back),
        .id_we(id_we),
        .id_oe(id_oe),
        .id_be(id_be),
        .id_pc(id_pc),
        
        .ex_reg_s_val(ex_reg_s_val),
        .ex_reg_t_val(ex_reg_t_val),
        .ex_reg_d(ex_reg_d),
        .ex_reg_s(ex_reg_s),
        .ex_reg_t(ex_reg_t),
        .ex_op(ex_op),
        .ex_imm(ex_imm),
        .ex_imm_select(ex_imm_select),
        .ex_write_back(ex_write_back),
        .ex_we(ex_we),
        .ex_oe(ex_oe),
        .ex_be(ex_be),
        .ex_pc(ex_pc)
    );

    ex ex0(
        .rst(`RESET),
        .ex_op(ex_op),
        .ex_imm(ex_imm),
        .ex_imm_select(ex_imm_select),
        .ex_reg_s_val(ex_reg_s_val),
        .ex_reg_t_val(ex_reg_t_val),
        .ex_pc(ex_pc),

        .ex_reg_s(ex_reg_s),
        .ex_reg_t(ex_reg_t),
        .mem_reg_d(mem_reg_d),
        .wb_reg_d(wb_reg_d),   
        .mem_write_back(mem_write_back),
        .mem_data(mem_data),
        .wb_write_back(wb_write_back),
        .wb_data(wb_data),

        .ex_result(ex_result),
        .ex_flags(ex_flags),
        .ex_reg_t_val_forward(ex_reg_t_val_forward)
    );

    ex_mem ex_mem0(
        .clk(`CLOCK),
        .rst(`RESET),
        .stall(stall),

        .ex_op(ex_op),
        .ex_reg_t_val(ex_reg_t_val_forward),
        .ex_result(ex_result),
        .ex_flags(ex_flags),
        .ex_reg_d(ex_reg_d),
        .ex_write_back(ex_write_back),
        .ex_oe(ex_oe),
        .ex_we(ex_we),
        .ex_be(ex_be),
        .ex_use_uart(ex_use_uart),

        .mem_op(mem_op),
        .mem_reg_t_val(mem_reg_t_val),
        .mem_result(mem_result),
        .mem_flags(mem_flags),
        .mem_reg_d(mem_reg_d),
        .mem_write_back(mem_write_back),
        .mem_oe(mem_oe),
        .mem_we(mem_we),
        .mem_be(mem_be),
        .mem_use_uart(mem_use_uart)
    );

    mem_wb mem_wb0(
        .clk(`CLOCK),
        .rst(`RESET),
        .stall(stall),

        .mem_op(mem_op),
        .mem_data(mem_data),
        .mem_reg_d(mem_reg_d),
        .mem_write_back(mem_write_back),
        .mem_result(mem_result),
        .mem_oe(mem_oe),

        .wb_op(wb_op),
        .wb_data(wb_data),
        .wb_reg_d(wb_reg_d),
        .wb_write_back(wb_write_back),
        .wb_result(wb_result),
        .wb_oe(wb_oe)
    );

    ctrl ctrl0(
        .clk(`CLOCK),
        .rst(`RESET),

        .stall_from_id(stall_from_id),
        .stall_from_mem(stall_from_mem), // 如果mem阶段需要读写sram，前面取指部分需要暂停
        
        .stall(stall)
    );

    sram sram0(
        .clk(`CLOCK),
        .rst(`RESET),
        
        .if_addr(if_pc),
        .if_ce(if_ce),

        .mem_addr(mem_result),
        .mem_ce(mem_ce),
        .we(mem_we),
        .be(mem_be),
        .mem_use_uart(mem_use_uart),
        .mem_data_in(mem_reg_t_val),
        .data_out(sram_data_out),
        
        .base_ram_data(base_ram_data),
        .base_ram_addr(base_ram_addr),
        .base_ram_be_n(base_ram_be_n),
        .base_ram_ce_n(base_ram_ce_n),
        .base_ram_oe_n(base_ram_oe_n),
        .base_ram_we_n(base_ram_we_n),

        .ext_ram_data(ext_ram_data),
        .ext_ram_addr(ext_ram_addr),
        .ext_ram_be_n(ext_ram_be_n),
        .ext_ram_ce_n(ext_ram_ce_n),
        .ext_ram_oe_n(ext_ram_oe_n),
        .ext_ram_we_n(ext_ram_we_n),
        
        .uart_rdn(uart_rdn),
        .uart_wrn(uart_wrn),
        .uart_dataready(uart_dataready),
        .uart_tbre(uart_tbre),
        .uart_tsre(uart_tsre)
    );


    // for debug:
    assign leds={sram_data_out[7:0], mem_result[7:0]}; //16bit
    SEG7_LUT segL(.oSEG1(dpy0), .iDIG(if_pc[3:0])); //dpy0是低位数码管
    SEG7_LUT segH(.oSEG1(dpy1), .iDIG(if_pc[7:4])); //dpy1是高位数码管

endmodule
