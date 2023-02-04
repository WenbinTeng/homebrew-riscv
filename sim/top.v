`include "ifetcher.v"
`include "idecoder.v"
`include "csr.v"
`include "gpr.v"
`include "backend.v"

module top (
    input           aclk,
    input           clk,
    input           rst,
    input           ei,
    input           ti
);
    
    wire    [31:0]  pc;
    wire    [31:0]  inst;
    wire    [31:0]  inst_enable;
    wire            brh_flag;
    wire    [31:0]  brh_addr;
    wire            int_flag;
    wire    [31:0]  int_addr;
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
    wire    [ 7:0]  csr_op;
    wire            gpr_we;
    wire    [31:0]  gpr_di;
    wire            load;
    wire            store;
    wire    [31:0]  csr_rdata;

    ifetcher u_ifetcher (clk, rst, 32'h0, int_flag, int_addr, qa, is_lt, is_ltu, is_zero, pc, inst, inst_enable);

    idecoder u_idecoder (rst, pc, inst, inst_enable, alu_src_1, alu_src_2, alu_imm_1, alu_imm_2, alu_op, mem_op, csr_op, gpr_we, load, store);

    csr u_csr (aclk, clk, pc, qa, ei, ti, csr_op, inst[19:15], inst[31:20], csr_rdata, int_flag, int_addr);

    gpr u_gpr (aclk, clk, gpr_we, inst[19:15], inst[24:20], inst[11:7], gpr_di, csr_rdata, qa, qb);
    
    backend u_backend (clk, alu_op, mem_op, load, store, qa, qb, gpr_di, alu_imm_1, alu_imm_2, alu_src_1, alu_src_2, is_lt, is_ltu, is_zero);

endmodule