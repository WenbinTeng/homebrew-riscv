`include "./IF.v"
`include "./ID.v"
`include "./register.v"
`include "./shifter.v"
`include "./backend.v"

module top (
    input           clk,
    input           rst,
    input   [31:0]  rst_addr,
    input           debug_imem_oe,
    input           debug_imem_we,
    input   [31:0]  debug_imem_addr,
    input   [31:0]  debug_imem_data,
    input           debug_dmem_oe,
    input           debug_dmem_we,
    input   [31:0]  debug_dmem_addr,
    input   [31:0]  debug_dmem_data,
    input           debug_reg_oe,
    input           debug_reg_we,
    input   [ 4:0]  debug_reg_ra,
    input   [ 4:0]  debug_reg_rb,
    input   [31:0]  debug_reg_data
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
    wire    [ 9:0]  mem_op;
    wire            reg_we;
    wire    [31:0]  reg_di;

    IF u_IF (clk, rst, rst_addr, brh, brh_addr, debug_imem_oe, debug_imem_we, debug_imem_addr, debug_imem_data, pc, inst);

    ID u_ID (clk, rst, pc, inst, qb, is_lt, is_ltu, is_zero, brh, brh_addr, alu_src_1, alu_src_2, alu_imm_1, alu_imm_2, alu_op, mem_op, reg_we);

    register u_register (clk, rst, reg_we, inst[19:15], inst[24:20], inst[11:7], qa, qb, debug_reg_oe, debug_reg_we, debug_reg_ra, debug_reg_rb, debug_reg_data);

    backend u_backend (clk, alu_op, mem_op, qa, qb, alu_imm_1, alu_imm_2, reg_di, is_lt, is_ltu, is_zero, debug_dmem_oe, debug_dmem_we, debug_dmem_addr, debug_dmem_data);

endmodule