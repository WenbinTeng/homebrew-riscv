module decoder(
    input clk,
    input [31:0] addr,
    input [31:0] inst,
    input [31:0] alu_data,
    input [31:0] mem_data,
    output [2:0] funct3,
    output [6:0] funct7,
    output jal,
    output [31:0] jal_offset,
    output jalr,
    output [31:0] jalr_offset,
    output branch,
    output [31:0] branch_offset,
    output load,
    output store,
    output [4:0] alu_op,
    output [31:0] operand_a,
    output [31:0] operand_b,
    output [31:0] qa,
    output [31:0] qb
);

    wire [31:0] inst_enable;

    _5dec32 u_5dec32 (
        inst[6:2],
        inst_enable
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
    wire [31:0] j_type_imm = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21]};
    wire [31:0] b_type_imm = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8]};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] s_type_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    assign alu_op =
        branch ? 4'b1000 :
        immediate | register ? {inst[30], inst[14:12]} :
        4'b0000; // lui auipc jal jalr load store

    _mux32fromN #(9) u_mux32fromN_0 (
        {lui, auipc, jal, jalr, branch, load, store, immediate, register},
        {32'h0, addr, addr, addr, qa, qa, qa, qa, qa},
        operand_a
    );

    _mux32fromN #(9) u_mux32fromN_1 (
        {lui, auipc, jal, jalr, branch, load, store, immediate, register},
        {u_type_imm, u_type_imm, 32'h4, 32'h4, qb, i_type_imm, s_type_imm, i_type_imm, qb},
        operand_b
    );

    wire we = lui | auipc | jal | jalr | load | immediate | register;
    wire [31:0] di;

    _mux32 u_mux32 (
        alu_data,
        mem_data,
        load,
        di
    );

    regfile u_regfile (
        clk,
        inst[19:15],
        inst[24:20],
        we,
        inst[11:7],
        di,
        qa,
        qb
    );

endmodule