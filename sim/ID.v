`include "./util/_dec32.v"

module ID (
    input           clk,
    input   [31:0]  inst,
    output          brh,
    output  [31:0]  brh_addr,
    output  [ 3:0]  alu_op,
    output  [ 2:0]  mem_op
);

    reg [3:0] alu_op_rom [5:0];
    reg [2:0] mem_op_rom [3:0];

    initial begin
        
    end

    wire [31:0] inst_enable;

    _dec32 u_dec32 (
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
    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] s_type_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    
endmodule