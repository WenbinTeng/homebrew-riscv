// `include "./include/_74x138.v"
// `include "./util/_add32.v"
// `include "./util/_bus32.v"
// `include "./util/_dec32.v"
// `include "./util/_mux32.v"

module ID (
    input           clk,
    input           rst,
    input   [31:0]  pc,
    input   [31:0]  inst,
    input   [31:0]  qa,
    input           is_lt,
    input           is_ltu,
    input           is_zero,
    output          brh,        // branch flag
    output  [31:0]  brh_addr,   // branch addr
    output          alu_src_1,  // qa or imm1
    output          alu_src_2,  // qb or imm2
    output  [31:0]  alu_imm_1,  // imm1
    output  [31:0]  alu_imm_2,  // imm2
    output  [ 7:0]  alu_op,     // op: slt, sltu, sll, srl, sra, 74x381's op
    output  [ 7:0]  mem_op,     // op: lb, lh, lw, lbu, lhu, sb, sh, sw
    output          reg_we,
    output          load,
    output          store
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
    wire immediate = inst_enable[4];
    wire register = inst_enable[12];
    assign load = inst_enable[0];
    assign store = inst_enable[8];

    wire [31:0] u_type_imm = {inst[31:12], 12'b0};
    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] s_type_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

    reg [4:0] alu_op_rom [7:0];
    reg [9:0] mem_op_rom [4:0];

    wire [15:0] dontcare;
    wire [ 7:0] _alu_op = alu_op_rom[{lui|auipc|jal|jalr|load|store, branch, immediate, register, inst[14:12], inst[30]}];
    wire [ 7:0] _mem_op = mem_op_rom[{load, store, inst[14:12]}];

    _bus32 u_bus32 (
        ~rst,
        {16'b0, _alu_op, _mem_op},
        {dontcare, alu_op, mem_op}
    );

    wire [31:0] imm;

    _bus32 _bus32_0 (
        {lui|auipc,     jal,            jalr|load|immediate,    branch,         store},
        {u_type_imm,    j_type_imm,     i_type_imm,             b_type_imm,     s_type_imm},
        imm
    );

    assign alu_src_1 = load | store | immediate | register | branch;
    assign alu_src_2 = register | branch;
    _mux32 u_mux32_0 (
        32'h0,
        pc,
        auipc | jal | jalr,
        alu_imm_1
    );
    _mux32 u_mux32_1 (
        imm,
        32'h4,
        jal | jalr,
        alu_imm_2
    );

    assign reg_we = lui | auipc | jal | jalr | load | immediate | register;

    assign brh = jal | jalr |
                 branch & funct_enable[0] &  is_zero |  // beq
                 branch & funct_enable[1] & !is_zero |  // bne
                 branch & funct_enable[2] &  is_lt   |  // blt
                 branch & funct_enable[3] & !is_lt   |  // bge
                 branch & funct_enable[4] &  is_ltu  |  // bltu
                 branch & funct_enable[5] & !is_ltu  |  // bgeu
                 0;

    wire [31:0] brh_base;
    wire [31:0] brh_temp;

    _mux32 u_mux32_2 (
        pc,
        qa,
        jalr,
        brh_base
    );

    _add32 u_add32 (
        brh_base,
        imm,
        brh_temp
    );

    assign brh_addr = {brh_temp[31:1], 1'b0};

    integer i;
    initial begin
        alu_op_rom[0] = 8'b00000000;
        alu_op_rom[1] = 8'b00000000;
        alu_op_rom[2] = 8'b00000000;
        alu_op_rom[3] = 8'b00000000;
        alu_op_rom[4] = 8'b00000000;
        alu_op_rom[5] = 8'b00000000;
        alu_op_rom[6] = 8'b00000000;
        alu_op_rom[7] = 8'b00000000;
        alu_op_rom[8] = 8'b00000000;
        alu_op_rom[9] = 8'b00000000;
        alu_op_rom[10] = 8'b00000000;
        alu_op_rom[11] = 8'b00000000;
        alu_op_rom[12] = 8'b00000000;
        alu_op_rom[13] = 8'b00000000;
        alu_op_rom[14] = 8'b00000000;
        alu_op_rom[15] = 8'b00000000;
        alu_op_rom[16] = 8'b00000011;
        alu_op_rom[17] = 8'b00000010;
        alu_op_rom[18] = 8'b00100000;
        alu_op_rom[19] = 8'b00100000;
        alu_op_rom[20] = 8'b10000000;
        alu_op_rom[21] = 8'b10000000;
        alu_op_rom[22] = 8'b01000000;
        alu_op_rom[23] = 8'b01000000;
        alu_op_rom[24] = 8'b00000100;
        alu_op_rom[25] = 8'b00000100;
        alu_op_rom[26] = 8'b00010000;
        alu_op_rom[27] = 8'b00001000;
        alu_op_rom[28] = 8'b00000101;
        alu_op_rom[29] = 8'b00000101;
        alu_op_rom[30] = 8'b00000110;
        alu_op_rom[31] = 8'b00000110;
        alu_op_rom[32] = 8'b00000011;
        alu_op_rom[33] = 8'b00000011;
        alu_op_rom[34] = 8'b00100000;
        alu_op_rom[35] = 8'b00100000;
        alu_op_rom[36] = 8'b10000000;
        alu_op_rom[37] = 8'b10000000;
        alu_op_rom[38] = 8'b01000000;
        alu_op_rom[39] = 8'b01000000;
        alu_op_rom[40] = 8'b00000100;
        alu_op_rom[41] = 8'b00000100;
        alu_op_rom[42] = 8'b00010000;
        alu_op_rom[43] = 8'b00001000;
        alu_op_rom[44] = 8'b00000101;
        alu_op_rom[45] = 8'b00000101;
        alu_op_rom[46] = 8'b00000110;
        alu_op_rom[47] = 8'b00000110;
        alu_op_rom[48] = 8'b00000011;
        alu_op_rom[49] = 8'b00000011;
        alu_op_rom[50] = 8'b00100000;
        alu_op_rom[51] = 8'b00100000;
        alu_op_rom[52] = 8'b10000000;
        alu_op_rom[53] = 8'b10000000;
        alu_op_rom[54] = 8'b01000000;
        alu_op_rom[55] = 8'b01000000;
        alu_op_rom[56] = 8'b00000100;
        alu_op_rom[57] = 8'b00000100;
        alu_op_rom[58] = 8'b00010000;
        alu_op_rom[59] = 8'b00001000;
        alu_op_rom[60] = 8'b00000101;
        alu_op_rom[61] = 8'b00000101;
        alu_op_rom[62] = 8'b00000110;
        alu_op_rom[63] = 8'b00000110;
        alu_op_rom[64] = 8'b00000010;
        alu_op_rom[65] = 8'b00000010;
        alu_op_rom[66] = 8'b00000010;
        alu_op_rom[67] = 8'b00000010;
        alu_op_rom[68] = 8'b00000010;
        alu_op_rom[69] = 8'b00000010;
        alu_op_rom[70] = 8'b00000010;
        alu_op_rom[71] = 8'b00000010;
        alu_op_rom[72] = 8'b00000010;
        alu_op_rom[73] = 8'b00000010;
        alu_op_rom[74] = 8'b00000010;
        alu_op_rom[75] = 8'b00000010;
        alu_op_rom[76] = 8'b00000010;
        alu_op_rom[77] = 8'b00000010;
        alu_op_rom[78] = 8'b00000010;
        alu_op_rom[79] = 8'b00000010;
        alu_op_rom[80] = 8'b00000010;
        alu_op_rom[81] = 8'b00000010;
        alu_op_rom[82] = 8'b00000010;
        alu_op_rom[83] = 8'b00000010;
        alu_op_rom[84] = 8'b00000010;
        alu_op_rom[85] = 8'b00000010;
        alu_op_rom[86] = 8'b00000010;
        alu_op_rom[87] = 8'b00000010;
        alu_op_rom[88] = 8'b00000010;
        alu_op_rom[89] = 8'b00000010;
        alu_op_rom[90] = 8'b00000010;
        alu_op_rom[91] = 8'b00000010;
        alu_op_rom[92] = 8'b00000010;
        alu_op_rom[93] = 8'b00000010;
        alu_op_rom[94] = 8'b00000010;
        alu_op_rom[95] = 8'b00000010;
        alu_op_rom[96] = 8'b00000010;
        alu_op_rom[97] = 8'b00000010;
        alu_op_rom[98] = 8'b00000010;
        alu_op_rom[99] = 8'b00000010;
        alu_op_rom[100] = 8'b00000010;
        alu_op_rom[101] = 8'b00000010;
        alu_op_rom[102] = 8'b00000010;
        alu_op_rom[103] = 8'b00000010;
        alu_op_rom[104] = 8'b00000010;
        alu_op_rom[105] = 8'b00000010;
        alu_op_rom[106] = 8'b00000010;
        alu_op_rom[107] = 8'b00000010;
        alu_op_rom[108] = 8'b00000010;
        alu_op_rom[109] = 8'b00000010;
        alu_op_rom[110] = 8'b00000010;
        alu_op_rom[111] = 8'b00000010;
        alu_op_rom[112] = 8'b00000010;
        alu_op_rom[113] = 8'b00000010;
        alu_op_rom[114] = 8'b00000010;
        alu_op_rom[115] = 8'b00000010;
        alu_op_rom[116] = 8'b00000010;
        alu_op_rom[117] = 8'b00000010;
        alu_op_rom[118] = 8'b00000010;
        alu_op_rom[119] = 8'b00000010;
        alu_op_rom[120] = 8'b00000010;
        alu_op_rom[121] = 8'b00000010;
        alu_op_rom[122] = 8'b00000010;
        alu_op_rom[123] = 8'b00000010;
        alu_op_rom[124] = 8'b00000010;
        alu_op_rom[125] = 8'b00000010;
        alu_op_rom[126] = 8'b00000010;
        alu_op_rom[127] = 8'b00000010;
        alu_op_rom[128] = 8'b00000011;
        alu_op_rom[129] = 8'b00000011;
        alu_op_rom[130] = 8'b00000011;
        alu_op_rom[131] = 8'b00000011;
        alu_op_rom[132] = 8'b00000011;
        alu_op_rom[133] = 8'b00000011;
        alu_op_rom[134] = 8'b00000011;
        alu_op_rom[135] = 8'b00000011;
        alu_op_rom[136] = 8'b00000011;
        alu_op_rom[137] = 8'b00000011;
        alu_op_rom[138] = 8'b00000011;
        alu_op_rom[139] = 8'b00000011;
        alu_op_rom[140] = 8'b00000011;
        alu_op_rom[141] = 8'b00000011;
        alu_op_rom[142] = 8'b00000011;
        alu_op_rom[143] = 8'b00000011;
        alu_op_rom[144] = 8'b00000011;
        alu_op_rom[145] = 8'b00000011;
        alu_op_rom[146] = 8'b00000011;
        alu_op_rom[147] = 8'b00000011;
        alu_op_rom[148] = 8'b00000011;
        alu_op_rom[149] = 8'b00000011;
        alu_op_rom[150] = 8'b00000011;
        alu_op_rom[151] = 8'b00000011;
        alu_op_rom[152] = 8'b00000011;
        alu_op_rom[153] = 8'b00000011;
        alu_op_rom[154] = 8'b00000011;
        alu_op_rom[155] = 8'b00000011;
        alu_op_rom[156] = 8'b00000011;
        alu_op_rom[157] = 8'b00000011;
        alu_op_rom[158] = 8'b00000011;
        alu_op_rom[159] = 8'b00000011;
        alu_op_rom[160] = 8'b00000011;
        alu_op_rom[161] = 8'b00000011;
        alu_op_rom[162] = 8'b00000011;
        alu_op_rom[163] = 8'b00000011;
        alu_op_rom[164] = 8'b00000011;
        alu_op_rom[165] = 8'b00000011;
        alu_op_rom[166] = 8'b00000011;
        alu_op_rom[167] = 8'b00000011;
        alu_op_rom[168] = 8'b00000011;
        alu_op_rom[169] = 8'b00000011;
        alu_op_rom[170] = 8'b00000011;
        alu_op_rom[171] = 8'b00000011;
        alu_op_rom[172] = 8'b00000011;
        alu_op_rom[173] = 8'b00000011;
        alu_op_rom[174] = 8'b00000011;
        alu_op_rom[175] = 8'b00000011;
        alu_op_rom[176] = 8'b00000011;
        alu_op_rom[177] = 8'b00000011;
        alu_op_rom[178] = 8'b00000011;
        alu_op_rom[179] = 8'b00000011;
        alu_op_rom[180] = 8'b00000011;
        alu_op_rom[181] = 8'b00000011;
        alu_op_rom[182] = 8'b00000011;
        alu_op_rom[183] = 8'b00000011;
        alu_op_rom[184] = 8'b00000011;
        alu_op_rom[185] = 8'b00000011;
        alu_op_rom[186] = 8'b00000011;
        alu_op_rom[187] = 8'b00000011;
        alu_op_rom[188] = 8'b00000011;
        alu_op_rom[189] = 8'b00000011;
        alu_op_rom[190] = 8'b00000011;
        alu_op_rom[191] = 8'b00000011;
        alu_op_rom[192] = 8'b00000011;
        alu_op_rom[193] = 8'b00000011;
        alu_op_rom[194] = 8'b00000011;
        alu_op_rom[195] = 8'b00000011;
        alu_op_rom[196] = 8'b00000011;
        alu_op_rom[197] = 8'b00000011;
        alu_op_rom[198] = 8'b00000011;
        alu_op_rom[199] = 8'b00000011;
        alu_op_rom[200] = 8'b00000011;
        alu_op_rom[201] = 8'b00000011;
        alu_op_rom[202] = 8'b00000011;
        alu_op_rom[203] = 8'b00000011;
        alu_op_rom[204] = 8'b00000011;
        alu_op_rom[205] = 8'b00000011;
        alu_op_rom[206] = 8'b00000011;
        alu_op_rom[207] = 8'b00000011;
        alu_op_rom[208] = 8'b00000011;
        alu_op_rom[209] = 8'b00000011;
        alu_op_rom[210] = 8'b00000011;
        alu_op_rom[211] = 8'b00000011;
        alu_op_rom[212] = 8'b00000011;
        alu_op_rom[213] = 8'b00000011;
        alu_op_rom[214] = 8'b00000011;
        alu_op_rom[215] = 8'b00000011;
        alu_op_rom[216] = 8'b00000011;
        alu_op_rom[217] = 8'b00000011;
        alu_op_rom[218] = 8'b00000011;
        alu_op_rom[219] = 8'b00000011;
        alu_op_rom[220] = 8'b00000011;
        alu_op_rom[221] = 8'b00000011;
        alu_op_rom[222] = 8'b00000011;
        alu_op_rom[223] = 8'b00000011;
        alu_op_rom[224] = 8'b00000011;
        alu_op_rom[225] = 8'b00000011;
        alu_op_rom[226] = 8'b00000011;
        alu_op_rom[227] = 8'b00000011;
        alu_op_rom[228] = 8'b00000011;
        alu_op_rom[229] = 8'b00000011;
        alu_op_rom[230] = 8'b00000011;
        alu_op_rom[231] = 8'b00000011;
        alu_op_rom[232] = 8'b00000011;
        alu_op_rom[233] = 8'b00000011;
        alu_op_rom[234] = 8'b00000011;
        alu_op_rom[235] = 8'b00000011;
        alu_op_rom[236] = 8'b00000011;
        alu_op_rom[237] = 8'b00000011;
        alu_op_rom[238] = 8'b00000011;
        alu_op_rom[239] = 8'b00000011;
        alu_op_rom[240] = 8'b00000011;
        alu_op_rom[241] = 8'b00000011;
        alu_op_rom[242] = 8'b00000011;
        alu_op_rom[243] = 8'b00000011;
        alu_op_rom[244] = 8'b00000011;
        alu_op_rom[245] = 8'b00000011;
        alu_op_rom[246] = 8'b00000011;
        alu_op_rom[247] = 8'b00000011;
        alu_op_rom[248] = 8'b00000011;
        alu_op_rom[249] = 8'b00000011;
        alu_op_rom[250] = 8'b00000011;
        alu_op_rom[251] = 8'b00000011;
        alu_op_rom[252] = 8'b00000011;
        alu_op_rom[253] = 8'b00000011;
        alu_op_rom[254] = 8'b00000011;
        alu_op_rom[255] = 8'b00000011;

        mem_op_rom[0] = 8'b00000000;
        mem_op_rom[1] = 8'b00000000;
        mem_op_rom[2] = 8'b00000000;
        mem_op_rom[3] = 8'b00000000;
        mem_op_rom[4] = 8'b00000000;
        mem_op_rom[5] = 8'b00000000;
        mem_op_rom[6] = 8'b00000000;
        mem_op_rom[7] = 8'b00000000;
        mem_op_rom[8] = 8'b00000100;
        mem_op_rom[9] = 8'b00000010;
        mem_op_rom[10] = 8'b00000001;
        mem_op_rom[11] = 8'b00000000;
        mem_op_rom[12] = 8'b00000000;
        mem_op_rom[13] = 8'b00000000;
        mem_op_rom[14] = 8'b00000000;
        mem_op_rom[15] = 8'b00000000;
        mem_op_rom[16] = 8'b10000000;
        mem_op_rom[17] = 8'b01000000;
        mem_op_rom[18] = 8'b00100000;
        mem_op_rom[19] = 8'b00000000;
        mem_op_rom[20] = 8'b00010000;
        mem_op_rom[21] = 8'b00001000;
        mem_op_rom[22] = 8'b00000000;
        mem_op_rom[23] = 8'b00000000;
        mem_op_rom[24] = 8'b10000000;
        mem_op_rom[25] = 8'b01000000;
        mem_op_rom[26] = 8'b00100000;
        mem_op_rom[27] = 8'b00000000;
        mem_op_rom[28] = 8'b00010000;
        mem_op_rom[29] = 8'b00001000;
        mem_op_rom[30] = 8'b00000000;
        mem_op_rom[31] = 8'b00000000;
    end
    
endmodule