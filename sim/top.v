`include "./IF.v"
`include "./ID.v"
`include "./register.v"
`include "./shifter.v"
`include "./backend.v"

module top (
    input           aclk,
    input           clk,
    input           rst
);
    
    wire    [31:0]  pc;
    wire    [31:0]  inst;
    wire            brh;
    wire    [31:0]  brh_addr;
    wire    [31:0]  qa;
    wire    [31:0]  qb;
    wire            is_lt;
    wire            is_ltu;
    wire            is_zero;
    wire            alu_src_1;
    wire            alu_src_2;
    wire    [31:0]  alu_imm_1;
    wire    [31:0]  alu_imm_2;
    wire    [ 7:0]  alu_op;
    wire    [ 7:0]  mem_op;
    wire            reg_we;
    wire    [31:0]  reg_di;
    wire            load;
    wire            store;

    IF u_IF (clk, rst, 32'h0, brh, brh_addr, pc, inst);

    ID u_ID (clk, rst, pc, inst, qa, is_lt, is_ltu, is_zero, brh, brh_addr, alu_src_1, alu_src_2, alu_imm_1, alu_imm_2, alu_op, mem_op, reg_we, load, store);

    register u_register (aclk, clk, reg_we, inst[19:15], inst[24:20], inst[11:7], reg_di, qa, qb);

    backend u_backend (clk, alu_op, mem_op, load, store, qa, qb, alu_imm_1, alu_imm_2, alu_src_1, alu_src_2, reg_di, is_lt, is_ltu, is_zero);

endmodule