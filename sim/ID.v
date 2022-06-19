`include "./include/_74x138.v"
`include "./util/_add32.v"
`include "./util/_bus32.v"
`include "./util/_dec32.v"
`include "./util/_mux32.v"

module ID (
    input           clk,
    input   [31:0]  pc,
    input   [31:0]  inst,
    input   [32:0]  alu_data,
    input   [31:0]  reg_data,
    output          brh,
    output  [31:0]  brh_addr,
    output  [ 3:0]  alu_op,
    output          alu_src_1,
    output          alu_src_2,
    output  [ 5:0]  mem_op,
    output          reg_we
);

    wire [31:0] inst_enable;

    _dec32 u_dec32 (
        inst[6:2],
        inst_enable
    );

    wire [7:0] funct_enable;

    _74x138 u_74x138 (
        inst[14:12],
        1'b1,
        1'b0,
        1'b0,
        funct_enable
    );

    wire lui = inst_enable[13];
    wire auipc = inst_enable[5];
    wire jal = inst_enable[27];
    wire jalr = inst_enable[25];
    wire branch = inst_enable[24];
    wire load = inst_enable[0];
    wire store = inst_enable[8];
    wire immediate = inst_enable[4];
    wire register = inst_enable[12];

    wire [31:0] u_type_imm = {inst[31:12], 12'b0};
    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] s_type_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

    reg [3:0] alu_op_rom [5:0];
    reg [5:0] mem_op_rom [3:0];

    initial begin
        
    end

    // todo
    assign alu_op = alu_op_rom[inst[14:12]];
    assign mem_op = mem_op_rom[inst[14:12]];

    wire [31:0] imm;

    _bus32 _bus32_0 (
        {lui|auipc,     jal,            jalr|load|immediate,    branch,         store},
        {u_type_imm,    j_type_imm,     i_type_imm,             b_type_imm,     s_type_imm},
        imm
    );

    assign brh = jal | jalr |
                 funct_enable[0] & !(|alu_data[31:0]) | // beq
                 funct_enable[1] &  (|alu_data[31:0]) | // bne
                 funct_enable[2] &    alu_data[32]    | // blt
                 funct_enable[3] &   !alu_data[32]    | // bge
                 funct_enable[4] &    alu_data[32]    | // bltu
                 funct_enable[5] &   !alu_data[32];     // bgeu

    wire [31:0] brh_base;
    wire [31:0] brh_temp;

    _mux32 u_mux32_0 (
        pc,
        reg_data,
        jalr,
        brh_base
    );

    _add32 u_add32 (
        brh_base,
        imm,
        brh_temp
    );

    assign brh_addr = {brh_temp[31:1], 1'b0};
    
endmodule