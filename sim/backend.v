`include "./include/_74x157.v"
`include "./include/_74x182.v"
`include "./include/_74x381.v"
`include "./include/_cy7c1021.v"
`include "./util/_bus32.v"
`include "./util/_mux32.v"
`include "./shifter.v"

module backend (
    input           clk,
    input   [ 7:0]  alu_op,
    input   [ 9:0]  mem_op,
    input   [31:0]  qa,
    input   [31:0]  qb,
    input   [31:0]  alu_imm_1,
    input   [31:0]  alu_imm_2,
    output  [31:0]  reg_di,
    output          is_lt,
    output          is_ltu,
    output          is_zero,
    input           debug_dmem_oe,
    input           debug_dmem_we,
    input   [31:0]  debug_dmem_addr,
    input   [31:0]  debug_dmem_data
);

    _mux32 u_mux32_0 (
        alu_imm_1,
        qa,
        alu_src_1,
        operand_a
    );
    _mux32 u_mux32_1 (
        alu_imm_2,
        qb,
        alu_src_2,
        operand_b
    );

    wire [31:0] f;
    wire [31:0] h;

    wire [7:0] pn;
    wire [7:0] gn;
    wire [1:0] pa;
    wire [1:0] ga;
    wire [8:0] c = 'b0;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            _74x381 u_74x381 (
                operand_a[i*4+3:i*4],
                operand_b[i*4+3:i*4],
                alu_op[2:0],
                c[i],
                gn[i],
                pn[i],
                f[i*4+3:i*4]
            );
        end
    endgenerate

    _74x182 u_74x182_0 (
        gn[3:0],
        pn[3:0],
        c[0],
        c[1],
        c[2],
        c[3],
        ga[0],
        pa[0]
    );
    _74x182 u_74x182_1 (
        gn[7:4],
        pn[7:4],
        c[4],
        c[5],
        c[6],
        c[7],
        ga[1],
        pa[1]
    );
    _74x182 u_74x182_2 (
        {2'b0, ga},
        {2'b0, pa},
        c[0],
        c[4],
        c[8],
        x,
        x,
        x
    );

    shifter u_shifter (
        operand_a,
        operand_b,
        alu_op,
        h
    );

    assign is_lt   = (operand_a[31] & ~operand_b[31]) | (~operand_a[31] & ~operand_b[31] & f[31]) | (operand_a[31] & operand_b[31] & f[31]);
    assign is_ltu  = c[8];
    assign is_zero = ~(|f);

    wire slt  = alu_op[7];
    wire sltu = alu_op[6];
    wire sll  = alu_op[5];
    wire srl  = alu_op[4];
    wire sra  = alu_op[3];
    wire [2:0] al = alu_op[2:0];
    wire [31:0] alu_data;

    _bus32 u_bus32_0 (
        {slt|sltu,                          sll|srl|sra,   |al},
        {{31'b0, slt&is_lt|sltu&is_ltu},    h,             f  },
        alu_data
    );

    wire sign = mem_op[9];
    wire byte = mem_op[8];
    wire half = mem_op[7];
    wire word = mem_op[6];
    wire oe   = mem_op[5];
    wire we   = mem_op[4];
    wire [3:0] byte_enable = mem_op[3:0];
    wire [31:0] mem_load;

    wire dmem_oe = rst ? debug_dmem_oe : oe;
    wire dmem_we = rst ? debug_dmem_we : we;
    wire [ 3:0] dmem_byte_enable = rst ? 'b0 : byte_enable;
    wire [31:0] dmem_addr = rst ? debug_dmem_addr : currPc[17:2];
    wire [31:0] dmem_data = rst ? debug_dmem_data : we ? qb : 32'bz;

    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021 (
                clk,
                1'b0,
                dmem_oe,
                dmem_we,
                dmem_byte_enable[i*2],
                dmem_byte_enable[i*2+1],
                dmem_addr[15:0],
                dmem_data[16*i+15:16*i]
            );
        end
    endgenerate

    _bus32 u_bus32_1 (
        {byte,                                          half,                                           word           },
        {{{24{sign & dmem_data[7]}}, dmem_data[7:0]},   {{16{sign & dmem_data[15]}}, dmem_data[15:0]},  dmem_data[31:0]},
        mem_load
    );

    _mux32 u_mux32_2 (
        alu_data,
        mem_load,
        oe,
        reg_di
    );
    
endmodule