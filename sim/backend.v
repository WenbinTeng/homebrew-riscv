// `include "./include/_74x138.v"
// `include "./include/_74x157.v"
// `include "./include/_74x182.v"
// `include "./include/_74x381.v"
// `include "./include/_is61c256.v"
// `include "./util/_bus32.v"
// `include "./util/_mux32.v"
// `include "./shifter.v"

module backend (
    input           clk,
    input   [ 7:0]  alu_op,     // op: slt, sltu, sll, srl, sra, 74x381's op. ACTIVE LOW
    input   [ 7:0]  mem_op,     // op: lb, lh, lw, lbu, lhu, sb, sh, sw. ACTIVE LOW
    input           load,       // ACTIVE LOW
    input           store,      // ACTIVE LOW
    input   [31:0]  qa,
    input   [31:0]  qb,
    output  [31:0]  gpr_di,
    input   [31:0]  alu_imm_1,
    input   [31:0]  alu_imm_2,
    input           alu_src_1,  // qa or imm1. ACTIVE LOW
    input           alu_src_2,  // qb or imm2. ACTIVE LOW
    output          is_lt,      // ACTIVE LOW
    output          is_ltu,     // ACTIVE LOW
    output          is_zero     // ACTIVE LOW
);
    wire [31:0] operand_a;
    wire [31:0] operand_b;

    _mux32 u_mux32_0 (
        qa,
        alu_imm_1,
        alu_src_1,
        operand_a
    );
    _mux32 u_mux32_1 (
        qb,
        alu_imm_2,
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
        {2'b11, ga},
        {2'b11, pa},
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

    assign is_lt   = ~((operand_a[31] & ~operand_b[31]) | (~operand_a[31] & ~operand_b[31] & f[31]) | (operand_a[31] & operand_b[31] & f[31]));
    assign is_ltu  = ~c[8];
    assign is_zero = |f;

    wire slt  = alu_op[7];
    wire sltu = alu_op[6];
    wire sll  = alu_op[5];
    wire srl  = alu_op[4];
    wire sra  = alu_op[3];
    wire [2:0] al = alu_op[2:0];
    wire [31:0] alu_temp;
    wire [31:0] alu_data;

    _mux32 u_mux32_2 (
        h,
        f,
        sll&srl&sra,
        alu_temp
    );
    _mux32 u_mux32_3 (
        {31'b0, (~slt&~is_lt)|(~sltu&~is_ltu)},
        alu_temp,
        slt&sltu,
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
    wire       word_cs = lw&sw;

    _74x138 u_74x138_0 (
        {1'b0, alu_data[1:0]},
        1'b1,
        lb & lbu & sb,
        lb & lbu & sb,
        {byte_cs_dontcare, byte_cs}
    );
    _74x138 u_74x138_1 (
        {2'b0, alu_data[1]},
        1'b1,
        lh & lhu & sh,
        lh & lhu & sh,
        {half_cs_dontcare, half_cs}
    );

    wire [3:0] byte_enable;
    assign byte_enable[0] = byte_cs[0] & half_cs[0] & word_cs;
    assign byte_enable[1] = byte_cs[1] & half_cs[0] & word_cs;
    assign byte_enable[2] = byte_cs[2] & half_cs[1] & word_cs;
    assign byte_enable[3] = byte_cs[3] & half_cs[1] & word_cs;

    wire [31:0] store_byte = {qb[7:0], qb[7:0], qb[7:0], qb[7:0]};
    wire [31:0] store_half = {qb[15:8], qb[7:0], qb[15:8], qb[7:0]};
    wire [31:0] store_word = qb;
    wire [31:0] store_data;

    _bus32 #(3) u_bus32_1 (
        {sb,            sh,             sw        },
        {store_byte,    store_half,     store_word},
        store_data
    );

    wire [31:0] dmem_data = store ? 32'bz : store_data;

    generate
        for (i = 0; i < 4; i = i + 1) begin
            _is61c256 u_is61c256 (
                ~clk,
                load&store,
                load|byte_enable[i],
                store|byte_enable[i],
                alu_data[16:2],
                dmem_data[i*8+7:i*8]
            );
        end
    endgenerate

    // data bus using 74x245
    wire [ 7:0] load_byte = ~byte_cs[0] ? dmem_data[7:0] : ~byte_cs[1] ? dmem_data[15:8] : ~byte_cs[2] ? dmem_data[23:16] : ~byte_cs[3] ? dmem_data[31:24] : 8'bz;
    wire [15:0] load_half = ~half_cs[0] ? {dmem_data[15:8], dmem_data[7:0]} : ~half_cs[1] ? {dmem_data[31:24], dmem_data[23:16]} : 16'bz;
    wire [31:0] load_word = ~word_cs ? dmem_data : 32'bz;

    _bus32 #(3) u_bus32_2 (
        {lb&lbu,                                lh&lhu,                                         lw             },
        {{{24{~lb & load_byte[7]}}, load_byte}, {{16{~lh & load_half[15]}}, load_half[15:0]},   load_word[31:0]},
        mem_load
    );

    _bus32 #(2) u_bus32_3 (
        {~(|alu_op[2:0]),   load    },
        {alu_data,          mem_load},
        gpr_di
    );
    
endmodule