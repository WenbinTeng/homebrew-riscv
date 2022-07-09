// `include "./include/_74x138.v"
// `include "./include/_74x157.v"
// `include "./include/_74x182.v"
// `include "./include/_74x381.v"
// `include "./include/_cy7c1021.v"
// `include "./util/_bus32.v"
// `include "./util/_mux32.v"
// `include "./shifter.v"

module backend (
    input           clk,
    input           rst,
    input   [ 7:0]  alu_op,
    input   [ 7:0]  mem_op,
    input           load,
    input           store,
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
    wire [31:0] operand_a;
    wire [31:0] operand_b;

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
    wire [8:0] c;
    wire [2:0] c_dontcare;

    assign c[0] = 0;

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
        c_dontcare[0],
        c_dontcare[1],
        c_dontcare[2]
    );

    shifter u_shifter (
        operand_a,
        operand_b,
        alu_op[5:3],
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

    wire lb  = mem_op[7];
    wire lh  = mem_op[6];
    wire lw  = mem_op[5];
    wire lbu = mem_op[4];
    wire lhu = mem_op[3];
    wire sb  = mem_op[2];
    wire sh  = mem_op[1];
    wire sw  = mem_op[0];
    wire [31:0] mem_load;

    wire [3:0] byte_cs;
    wire [3:0] byte_cs_dontcare;
    wire [1:0] half_cs;
    wire [5:0] half_cs_dontcare;
    wire       word_cs = lw | sw;

    _74x138 u_74x138_0 (
        {1'b0, alu_data[1:0]},
        lb | lbh | sb,
        1'b0,
        1'b0,
        {byte_cs_dontcare, byte_cs}
    );

    _74x138 u_74x138_1 (
        {2'b0, alu_data[1]},
        lh | lhu | sh,
        1'b0,
        1'b0,
        {half_cs_dontcare, half_cs}
    );

    wire [3:0] byte_enable;
    assign byte_enable[0] = byte_cs[0] | half_cs[0] | word_cs;
    assign byte_enable[1] = byte_cs[1] | half_cs[0] | word_cs;
    assign byte_enable[2] = byte_cs[2] | half_cs[1] | word_cs;
    assign byte_enable[3] = byte_cs[3] | half_cs[1] | word_cs;

    wire dmem_oe = rst ? debug_dmem_oe : load;
    wire dmem_we = rst ? debug_dmem_we : store;
    wire [ 3:0] dmem_byte_enable = rst ? 'b0 : byte_enable;
    wire [31:0] dmem_addr = rst ? debug_dmem_addr : alu_data[17:2];
    wire [31:0] dmem_data = rst ? debug_dmem_data : store ? qb : 32'bz;

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

    // data bus using 74x244
    wire [ 7:0] load_byte = byte_cs[0] ? dmem_data[7:0] : byte_cs[1] ? dmem_data[15:8] : byte_cs[2] ? dmem_data[23:16] : byte_cs[3] ? dmem_data[31:24] : 8'bz;
    wire [15:0] load_half = half_cs[0] ? dmem_data[15:0] : half_cs[1] ? dmem_data[31:16] : 16'bz;

    _bus32 u_bus32_1 (
        {lb|lbu,                                lh|lhu,                                         lw             },
        {{{24{lb & load_byte[7]}}, load_byte},  {{16{lh & load_half[15]}}, load_half[15:0]},    dmem_data[31:0]},
        mem_load
    );

    _mux32 u_mux32_2 (
        alu_data,
        mem_load,
        load,
        reg_di
    );
    
endmodule