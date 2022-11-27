`default_nettype none

module sram(
    input wire clk,         
    input wire rst,       

    input wire[31:0] if_addr,
    input wire if_ce,
    input wire[31:0] mem_addr,
    input wire mem_ce,
    input wire we,
    input wire be,
    input wire mem_use_uart,
    input wire[31:0] mem_data_in,
    output reg[31:0] data_out,

    inout wire[31:0] base_ram_data,  
    output wire[19:0] base_ram_addr, 
    output wire[3:0] base_ram_be_n,  
    output wire base_ram_ce_n,      
    output wire base_ram_oe_n,       
    output wire base_ram_we_n,       

    inout wire[31:0] ext_ram_data,  
    output wire[19:0] ext_ram_addr, 
    output wire[3:0] ext_ram_be_n,  
    output wire ext_ram_ce_n,       
    output wire ext_ram_oe_n,      
    output wire ext_ram_we_n,

    output wire uart_rdn,        
    output wire uart_wrn,        
    input wire uart_dataready,   
    input wire uart_tbre,         
    input wire uart_tsre     
);

    wire[31:0] addr;
    assign addr = mem_ce ? mem_addr : (if_ce ? if_addr : 32'b0);
    assign base_ram_addr = addr[21:2];
    assign ext_ram_addr = addr[21:2];

    wire use_uart;
    assign use_uart = mem_use_uart;

    wire use_uart_state;
    assign use_uart_state = (addr[31:0] === 32'h10000005);


    wire use_sram;
    assign use_sram = (addr[31:23] === 9'b100000000);
    wire use_ext;
    assign use_ext = addr[22];


    reg[31:0] raw_data;
    assign base_ram_data = we? raw_data: 32'bz;
    assign ext_ram_data = we? raw_data: 32'bz;
    reg[3:0] be_n;
    assign base_ram_be_n = be_n;
    assign ext_ram_be_n = be_n;
    
    always @(*) begin
        if(use_uart) begin
            raw_data <= {24'b0, mem_data_in[7:0]};
            be_n <= 4'b1111;
        end else if(be) begin
            case (addr[1:0])
                2'b00: begin
                    raw_data <= {24'b0, mem_data_in[7:0]};
                    be_n <= 4'b1110;
                end
                2'b01: begin
                    raw_data <= {16'b0, mem_data_in[7:0], 8'b0};
                    be_n <= 4'b1101;
                end
                2'b10: begin
                    raw_data <= {8'b0, mem_data_in[7:0], 16'b0};
                    be_n <= 4'b1011;
                end
                2'b11: begin
                    raw_data <= {mem_data_in[7:0], 24'b0};
                    be_n <= 4'b0111;
                end
                default: begin
                    // 理论不出现 防止latch
                    raw_data <= 32'b0;
                    be_n <= 4'b1111;
                end
            endcase
        end else begin
            raw_data <= mem_data_in;
            be_n <= 4'b0000;
        end
    end


    assign {base_ram_ce_n, ext_ram_ce_n} = ((if_ce || mem_ce) && use_sram && ~clk)? (use_ext? 2'b10: 2'b01): 2'b11;

    assign {base_ram_oe_n, ext_ram_oe_n} = (use_sram && ~we)? 2'b00: 2'b11;

    assign base_ram_we_n = ~we;
    assign ext_ram_we_n = ~we;

    assign uart_rdn = ~use_uart || we || clk;  // = ~(use_uart && ~we)
    assign uart_wrn = ~(use_uart && we);


    always @(*) begin
        if(use_uart_state)begin
            data_out <= {26'b0, uart_tbre & uart_tsre, 4'b0, uart_dataready};
        end else if(use_uart)begin
            data_out <= {24'b0, base_ram_data[7:0]};
        end else if(use_sram)begin
            if(be) begin
                case (addr[1:0])
                    2'b00: begin
                        data_out <= {24'b0, (use_ext? ext_ram_data[7:0]: base_ram_data[7:0])};
                    end
                    2'b01: begin
                        data_out <= {24'b0, (use_ext? ext_ram_data[15:8]: base_ram_data[15:8])};
                    end
                    2'b10: begin
                        data_out <= {24'b0, (use_ext? ext_ram_data[23:16]: base_ram_data[23:16])};
                    end
                    2'b11: begin
                        data_out <= {24'b0, (use_ext? ext_ram_data[31:24]: base_ram_data[31:24])};
                    end
                    default: begin
                        data_out <= 32'b0;
                    end
                endcase
            end else begin
                data_out <= use_ext? ext_ram_data: base_ram_data;
            end
        end else begin
            data_out <= 32'b0;
        end
    end








endmodule