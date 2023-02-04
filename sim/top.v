`include "util/_add32.v"
`include "util/_bus32.v"
`include "util/_dec32.v"
`include "util/_mux32.v"
`include "util/_reg32.v"
`include "frontend.v"
`include "backend.v"

module top (
    input           aclk,
    input           clk,
    input           rst,
    input           ei,
    input           ti
);
    
    wire    [ 7:0]  alu_op;
    wire    [ 7:0]  mem_op;
    wire            load;
    wire            store;
    wire    [31:0]  alu_opr_1;
    wire    [31:0]  alu_opr_2;
    wire            is_lt;
    wire            is_ltu;
    wire            is_zero;
    wire    [31:0]  mem_di;
    wire    [31:0]  gpr_di;

    frontend u_frontend (aclk, clk, ei, ti, rst, 32'h0, alu_op, mem_op, load, store, alu_opr_1, alu_opr_2, mem_di, gpr_di, is_lt, is_ltu, is_zero);
    
    backend u_backend (clk, alu_op, mem_op, load, store, alu_opr_1, alu_opr_2, mem_di, gpr_di, is_lt, is_ltu, is_zero);

endmodule