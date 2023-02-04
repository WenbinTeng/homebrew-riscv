`include "include/_74x138.v"
`include "include/_74x245.v"
`include "include/_at28c256.v"
`include "include/_cy7c1021.v"
`include "util/_add32.v"
`include "util/_bus32.v"
`include "util/_dec32.v"
`include "util/_mux32.v"

module frontend (
    input           aclk,       // Simulate async write clock signal
    input           clk,        // Clock signal
    input           ei,         // External interrupt, ACTIVE LOW
    input           ti,         // Timer interrupt, ACTIVE LOW
    input           rst_flag,   // Reset signal
    input   [31:0]  rst_addr,   // Reset address
    output  [ 7:0]  alu_op,     // op: slt, sltu, sll, srl, sra, 74x381's op. ACTIVE LOW
    output  [ 7:0]  mem_op,     // op: lb, lh, lw, lbu, lhu, sb, sh, sw. ACTIVE LOW
    output          load,       // Is load instruction. Active LOW
    output          store,      // Is store instruction. Active LOW
    output  [31:0]  alu_opr_1,  // ALU operand a
    output  [31:0]  alu_opr_2,  // ALU operand a
    output  [31:0]  mem_di,     // Output data from GPR port b
    input   [31:0]  gpr_di,     // Input data for GPR
    input           is_lt,      // Is a less than b. Active LOW
    input           is_ltu,     // Is unsigned a less than unsigned b. Active LOW
    input           is_zero     // Is zero (a equals to b). Active LOW
);

    /* Interupt signal and address */
    wire        int_flag;
    wire [31:0] int_addr;

    /* GPR data port */
    wire [31:0] gpr_qa;
    wire [31:0] gpr_qb;
    
    /* CSR data port */
    wire [31:0] csr_di;
    wire [31:0] csr_do;

    /*
    * --------------------------------------------------
    * Part I: Instruction fetcher.
    * --------------------------------------------------
    */

    /* Define program counter in different calculate stages */
    wire [31:0] curr_pc;
    wire [31:0] plus_pc;
    wire [31:0] next_pc;
    wire [31:0] buff_pc;

    /* Decode instruction operation code */
    wire [31:0] inst;
    wire [31:0] inst_en;
    _dec32 u_dec32 (
        inst[6:2],
        inst_en
    );

    /* Designate which type of instruction is */
    wire    lui         = inst_en[13];
    wire    auipc       = inst_en[ 5];
    wire    jal         = inst_en[27];
    wire    jalr        = inst_en[25];
    wire    branch      = inst_en[24];
    wire    immediate   = inst_en[ 4];
    wire    register    = inst_en[12];
    wire    csr         = inst_en[28];
    assign  load        = inst_en[ 0];
    assign  store       = inst_en[ 8];

    /* Decode branch instruction, then output one-hot (active LOW) operation code. */
    wire [7:0]  brh_en;
    _74x138 u_74x138 (
        inst[14:12],
        1'b1,
        brh,
        brh,
        brh_en
    );

    /* Calculate whether the branch will take or not */
    wire brh_flag = (brh_en[0] |  is_zero) &  // beq
                    (brh_en[1] | ~is_zero) &  // bne
                    (brh_en[4] |  is_lt  ) &  // blt
                    (brh_en[5] | ~is_lt  ) &  // bge
                    (brh_en[6] |  is_ltu ) &  // bltu
                    (brh_en[7] | ~is_ltu ) &  // bgeu
                    1;

    /* Use GPR output port a as base address in addition for program counter if it is JALR instruction */
    wire [31:0] pc_base;
    _bus32 #(2) u_bus32_0 (
        {jalr,      ~jalr  },
        {gpr_qa,    curr_pc},
        pc_base
    );

    /* Concatenate immediate number from instrcution */
    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};
    wire [31:0] u_type_imm = {inst[31:12], 12'b0};
    wire [31:0] s_type_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

    /* Select offset address in addition for next program counter */
    wire [31:0] pc_offs;
    _bus32 #(4) u_bus32_1 (
        {jal,           jalr,           brh_flag,       ~(jal&jalr&brh_flag)},
        {j_type_imm,    i_type_imm,     b_type_imm,     32'h4               },
        pc_offs
    );

    /* Add base address and offset address */
    _add32 u_add32 (
        pc_base,
        pc_offs,
        plus_pc
    );

    /* If reset or interupt occurs, respond it. Else, execute what instruction defines. */
    _bus32 #(3) u_bus32_2 (
        {rst_flag,  int_flag|~rst_flag, 1'b0|~int_flag|~rst_flag},
        {rst_addr,  int_addr,           plus_pc                 },
        next_pc
    );

    /* Buffer pc in the negative edge of clock signal (gpr_qa would change then) */
    _reg32 u_reg32_0 (
        1'b0,
        ~clk,
        next_pc,
        buff_pc
    );

    /* Update program counter value at positive edge of clock signal */
    _reg32 u_reg32_1 (
        1'b0,
        clk,
        buff_pc,
        curr_pc
    );

    /* Instantiate 4 ROMs for instruciton storage */
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _at28c256 u_at28c256 (
                1'b0,
                1'b0,
                {curr_pc[14:2], i[1:0]},
                inst[i*8+7:i*8]
            );
        end
    endgenerate

    /*
    * --------------------------------------------------
    * Part II: Instruction decoder.
    * --------------------------------------------------
    */

    /* Use a ROM to decode instruction and generate operaion code */
    reg [7:0] alu_op_rom [255:0];
    /* op: slt, sltu, sll, srl, sra, 74x381's op. ACTIVE LOW */
    assign alu_op = alu_op_rom[{lui&auipc&jal&jalr&load&store, branch, immediate, register, inst[30], inst[14:12]}];

    /* Decode load and store instruction, then output one-hot (active LOW) operation code. */
    wire [7:0] load_enable;
    wire [7:0] store_enable;
    _74x138 u_74x138_0 (
        inst[14:12],
        1'b1,
        load,
        load,
        load_enable
    );
    _74x138 u_74x138_1 (
        inst[14:12],
        1'b1,
        store,
        store,
        store_enable
    );
    /* op: lb, lh, lw, lbu, lhu, sb, sh, sw. ACTIVE LOW */
    assign mem_op = {load_enable[0], load_enable[1], load_enable[2], load_enable[4], load_enable[5], store_enable[0], store_enable[1], store_enable[2]};

    /* Decode csr and privileged instruciton, then output one-hot (active LOW) operation code. */
    wire [7:0] csr_enable;
    wire [7:0] csr_funct;
    _74x138 u_74x138_2 (
        inst[14:12],
        1'b1,
        csr,
        csr,
        csr_enable
    );
    _74x138 u_74x138_3 (
        inst[22:20],
        1'b1,
        csr,
        csr_enable[0],
        csr_funct
    );
    /* op: ecall, ebreak, mret, csrrw, csrrs, csrrc, is_imm. ACTIVE LOW */
    wire [7:0] csr_op = {1'b0, csr_funct[0], csr_funct[1], csr_funct[2], csr_enable[1]&csr_enable[5], csr_enable[2]&csr_enable[6], csr_enable[3]&csr_enable[7], ~inst[14]};

    /* Choose immediate number based on different instructions */
    wire [31:0] imm;
    _bus32 #(3) u_bus32_3 (
        {lui&auipc,     load&immediate,     store     },
        {u_type_imm,    i_type_imm,         s_type_imm},
        imm
    );

    /* Select operands for 2 ports of ALU */
    _bus32 #(3) u_bus32_4 (
        {auipc&jal&jalr,    lui,    load&store&immediate&register&branch},
        {curr_pc,           32'h0,  gpr_qa                              },
        alu_opr_1
    );
    _bus32 #(3) u_bus32_5 (
        {jal&jalr,  lui&auipc&load&store&immediate,     register&branch},
        {32'h4,     imm,                                gpr_qb         },
        alu_opr_2
    );

    /* Calculate whether GPR will be writen or not */
    assign gpr_we = lui&auipc&jal&jalr&load&immediate&register&(&csr_op[3:1])|(~|inst[11:7]);

    /*
    * --------------------------------------------------
    * Part III: General Perpose Register (GPR).
    * --------------------------------------------------
    */

    /* GPR access address */
    wire [ 4:0] gpr_ra = inst[19:15];
    wire [ 4:0] gpr_rb = inst[24:20];
    wire [ 4:0] gpr_rd = inst[11: 7];

    /* Select the GPR input data, combine two inputs from ALU/MEM and CSR through bus */
    wire [31:0] _gpr_di;
    _bus32 #(2) u_bus32_6 (
        {1'b0,      1'b0  },
        {gpr_di,    csr_do},
        _gpr_di
    );

    /* Select the GPR access address, activate gpr_ra and gpr_rb at high voltage of clock signal, and gpr_rd otherwise. */
    wire [4:0] _gpr_ra;
    wire [2:0] _gpr_ra_dontcare;
    wire [4:0] _gpr_rb;
    wire [2:0] _gpr_rb_dontcare;
    _74x245 u_74x245_a0 (
        ~clk,
        {3'b0, gpr_ra},
        {_gpr_ra_dontcare, _gpr_ra}
    );
    _74x245 u_74x245_a1 (
        clk,
        {3'b0, gpr_rd},
        {_gpr_ra_dontcare, _gpr_ra}
    );
    _74x245 u_74x245_b0 (
        ~clk,
        {3'b0, gpr_rb},
        {_gpr_rb_dontcare, _gpr_rb}
    );
    _74x245 u_74x245_b1 (
        clk,
        {3'b0, gpr_rd},
        {_gpr_rb_dontcare, _gpr_rb}
    );

    /* Buffer write enable signal at negative edge, and use it at low voltage. */
    wire [31:0] buffer_we;
    _reg32 u_reg32_2 (
        clk,
        ~clk,
        {31'b0, gpr_we},
        buffer_we
    );

    /* Buffer write data at negative edge, and use it at low voltage. */
    wire [31:0] buffer_di;
    _reg32 u_reg32_3 (
        clk,
        ~clk,
        _gpr_di,
        buffer_di
    );

    /* Tri-state wire statement for RAM */
    wire [31:0] gpr_apin = buffer_di;
    wire [31:0] gpr_bpin = buffer_di;

    /* 
        Instantiate 2 RAMs instead of using a stack of registers. Usually, single
        RAM chip have only one read port, we use two RAM to offer two read port,
        which have to maintain the same content with each other. So, the write 
        enable signal and data are valid for each RAM chip.
    */
    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021_a (
                aclk,
                1'b0,
                ~clk,
                buffer_we[0]|clk,
                1'b0,
                1'b0,
                {11'b0, _gpr_ra[4:0]},
                gpr_apin[i*16+15:i*16]
            );
            _cy7c1021 u_cy7c1021_b (
                aclk,
                1'b0,
                ~clk,
                buffer_we[0]|clk,
                1'b0,
                1'b0,
                {11'b0, _gpr_rb[4:0]},
                gpr_bpin[i*16+15:i*16]
            );
        end
    endgenerate

    /* Get output, assign 0 while read address is 0. */
    assign gpr_qa = _gpr_ra == 5'b0 ? 32'b0 : gpr_apin;
    assign gpr_qb = _gpr_rb == 5'b0 ? 32'b0 : gpr_bpin;
    /* Data from port b as memory input */
    assign mem_di = gpr_qb;

    /*
    * --------------------------------------------------
    * Part IV: Control and Status Register (CSR).
    * --------------------------------------------------
    */

    /* CSR access address */ 
    wire [ 4:0] csr_zimm = inst[19:15];
    wire [11:0] csr_addr = inst[31:20];

    /* CSR registers' signal */
    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire [31:0] mcause;
    wire [31:0] mie;
    wire [31:0] mip;
    wire [31:0] mstatus;

    /* CSR operation one-hot (active LOW) code */
    wire ecall  = csr_op[6];
    wire ebreak = csr_op[5];
    wire mret   = csr_op[4];
    wire csrrw  = csr_op[3];
    wire csrrs  = csr_op[2];
    wire csrrc  = csr_op[1];
    wire is_imm = csr_op[0];

    /*
        Only if a trap instruction or external interrupt is encountered and
        the corresponding flag (in Mie register) is valid and global interrupt
        is enable (for the machine level, in Mstatus), the interrupt occurs.
        Active LOW.
    */
    wire csr_en = csrrw&csrrs&csrrc;
    wire ecall_en = ~(~ecall&mie[3]&mstatus[3]);
    wire ebreak_en = ~(~ebreak&mie[3]&mstatus[3]);
    wire ei_en = ~(mip[11]&mie[11]);
    wire ti_en = ~(mip[7]&mie[7]);

    /* interrupt handling state. Active LOW */
    wire        _int_handle = ecall_en&ebreak_en&ei_en&ti_en;
    wire        _int_flag = _int_handle&mret;
    wire [30:0] _int_flag_dontcare;
    wire [31:0] _int_addr;
    /*
        When an interrupt occurs, take the Mtvec as the program entrance.
        When the interrupt returns, take the Mepc as the return address.
    */
    _mux32 u_mux32_1 (
        mepc,
        mtvec,
        mret,
        _int_addr
    );

    /* Buffer interrupt signal and address in negative edge to avoid gpr_qa changes */
    _reg32 u_reg32_4 (
        1'b0,
        ~aclk,
        {31'b0, _int_flag},
        {_int_flag_dontcare, int_flag}
    );
    _reg32 u_reg32_5 (
        1'b0,
        ~aclk,
        _int_addr,
        int_addr
    );

    /* Select operand */
    _mux32 u_mux32_0 (
        {27'b0, csr_zimm},
        gpr_qa,
        is_imm,
        csr_di
    );

    /* Write/Set/Clear the flag(s) in CSRs */
    wire [31:0] _csr_di;
    _bus32 #(3) u_bus32_7 (
        {csrrw,     csrrs,          csrrc       },
        {wdata,     dout|wdata,     dout&wdata  },
        _csr_di
    );

    /* CSR operations, for more infornmations, please refer to Risc-V Manual. */
    _reg32 mtvec_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h305),
        _csr_di,
        mtvec
    );
    _reg32 mepc_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h341|~_int_handle),
        ~_int_handle ? {curr_pc[31:2], 2'b0} : {_csr_di[31:2], 2'b0},
        mepc
    );
    _reg32 mcause_reg (
        1'b0,
        ~aclk&~_int_handle,
        ~ecall_en ? 32'hb : ~ebreak_en ? 32'h3 : ~ti_en ? 32'h80000007 : ~ei_en ? 32'h8000000b : 32'ha,
        mcause
    );
    _reg32 mie_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h304),
        {20'b0, _csr_di[11], 3'b0, _csr_di[7], 3'b0, _csr_di[3], 3'b0},
        mie
    );
    _reg32 mip_reg (
        1'b0,
        ~aclk,
        {20'b0, ~ei, 3'b0, ~ti, 3'b0, 1'b0, 3'b0},
        mip
    );
    _reg32 mstatus_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h300|~_int_flag),
        ~_int_handle ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b0, 3'b0} : ~mret ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0} : {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, _csr_di[3], 3'b0},
        mstatus
    );

    /* Select output data based on the read address */
    _bus32 #(6) u_bus32_8 (
        {
            ~(~csr_en&csr_addr==12'h305),
            ~(~csr_en&csr_addr==12'h341),
            ~(~csr_en&csr_addr==12'h342),
            ~(~csr_en&csr_addr==12'h304),
            ~(~csr_en&csr_addr==12'h344),
            ~(~csr_en&csr_addr==12'h300)
        },
        {
            mtvec,
            mepc,
            mcause,
            mie,
            mip,
            mstatus
        },
        csr_do
    );

    /*
    * --------------------------------------------------
    * Part V: Initialize ROM.
    * --------------------------------------------------
    */

    initial begin
        alu_op_rom[0] = 8'b11111011;
        alu_op_rom[1] = 8'b11111011;
        alu_op_rom[2] = 8'b11111011;
        alu_op_rom[3] = 8'b11111011;
        alu_op_rom[4] = 8'b11111011;
        alu_op_rom[5] = 8'b11111011;
        alu_op_rom[6] = 8'b11111011;
        alu_op_rom[7] = 8'b11111011;
        alu_op_rom[8] = 8'b11111011;
        alu_op_rom[9] = 8'b11111011;
        alu_op_rom[10] = 8'b11111011;
        alu_op_rom[11] = 8'b11111011;
        alu_op_rom[12] = 8'b11111011;
        alu_op_rom[13] = 8'b11111011;
        alu_op_rom[14] = 8'b11111011;
        alu_op_rom[15] = 8'b11111011;
        alu_op_rom[16] = 8'b11111011;
        alu_op_rom[17] = 8'b11111011;
        alu_op_rom[18] = 8'b11111011;
        alu_op_rom[19] = 8'b11111011;
        alu_op_rom[20] = 8'b11111011;
        alu_op_rom[21] = 8'b11111011;
        alu_op_rom[22] = 8'b11111011;
        alu_op_rom[23] = 8'b11111011;
        alu_op_rom[24] = 8'b11111011;
        alu_op_rom[25] = 8'b11111011;
        alu_op_rom[26] = 8'b11111011;
        alu_op_rom[27] = 8'b11111011;
        alu_op_rom[28] = 8'b11111011;
        alu_op_rom[29] = 8'b11111011;
        alu_op_rom[30] = 8'b11111011;
        alu_op_rom[31] = 8'b11111011;
        alu_op_rom[32] = 8'b11111011;
        alu_op_rom[33] = 8'b11111011;
        alu_op_rom[34] = 8'b11111011;
        alu_op_rom[35] = 8'b11111011;
        alu_op_rom[36] = 8'b11111011;
        alu_op_rom[37] = 8'b11111011;
        alu_op_rom[38] = 8'b11111011;
        alu_op_rom[39] = 8'b11111011;
        alu_op_rom[40] = 8'b11111011;
        alu_op_rom[41] = 8'b11111011;
        alu_op_rom[42] = 8'b11111011;
        alu_op_rom[43] = 8'b11111011;
        alu_op_rom[44] = 8'b11111011;
        alu_op_rom[45] = 8'b11111011;
        alu_op_rom[46] = 8'b11111011;
        alu_op_rom[47] = 8'b11111011;
        alu_op_rom[48] = 8'b11111011;
        alu_op_rom[49] = 8'b11111011;
        alu_op_rom[50] = 8'b11111011;
        alu_op_rom[51] = 8'b11111011;
        alu_op_rom[52] = 8'b11111011;
        alu_op_rom[53] = 8'b11111011;
        alu_op_rom[54] = 8'b11111011;
        alu_op_rom[55] = 8'b11111011;
        alu_op_rom[56] = 8'b11111011;
        alu_op_rom[57] = 8'b11111011;
        alu_op_rom[58] = 8'b11111011;
        alu_op_rom[59] = 8'b11111011;
        alu_op_rom[60] = 8'b11111011;
        alu_op_rom[61] = 8'b11111011;
        alu_op_rom[62] = 8'b11111011;
        alu_op_rom[63] = 8'b11111011;
        alu_op_rom[64] = 8'b11111011;
        alu_op_rom[65] = 8'b11111011;
        alu_op_rom[66] = 8'b11111011;
        alu_op_rom[67] = 8'b11111011;
        alu_op_rom[68] = 8'b11111011;
        alu_op_rom[69] = 8'b11111011;
        alu_op_rom[70] = 8'b11111011;
        alu_op_rom[71] = 8'b11111011;
        alu_op_rom[72] = 8'b11111011;
        alu_op_rom[73] = 8'b11111011;
        alu_op_rom[74] = 8'b11111011;
        alu_op_rom[75] = 8'b11111011;
        alu_op_rom[76] = 8'b11111011;
        alu_op_rom[77] = 8'b11111011;
        alu_op_rom[78] = 8'b11111011;
        alu_op_rom[79] = 8'b11111011;
        alu_op_rom[80] = 8'b11111011;
        alu_op_rom[81] = 8'b11111011;
        alu_op_rom[82] = 8'b11111011;
        alu_op_rom[83] = 8'b11111011;
        alu_op_rom[84] = 8'b11111011;
        alu_op_rom[85] = 8'b11111011;
        alu_op_rom[86] = 8'b11111011;
        alu_op_rom[87] = 8'b11111011;
        alu_op_rom[88] = 8'b11111011;
        alu_op_rom[89] = 8'b11111011;
        alu_op_rom[90] = 8'b11111011;
        alu_op_rom[91] = 8'b11111011;
        alu_op_rom[92] = 8'b11111011;
        alu_op_rom[93] = 8'b11111011;
        alu_op_rom[94] = 8'b11111011;
        alu_op_rom[95] = 8'b11111011;
        alu_op_rom[96] = 8'b11111011;
        alu_op_rom[97] = 8'b11111011;
        alu_op_rom[98] = 8'b11111011;
        alu_op_rom[99] = 8'b11111011;
        alu_op_rom[100] = 8'b11111011;
        alu_op_rom[101] = 8'b11111011;
        alu_op_rom[102] = 8'b11111011;
        alu_op_rom[103] = 8'b11111011;
        alu_op_rom[104] = 8'b11111011;
        alu_op_rom[105] = 8'b11111011;
        alu_op_rom[106] = 8'b11111011;
        alu_op_rom[107] = 8'b11111011;
        alu_op_rom[108] = 8'b11111011;
        alu_op_rom[109] = 8'b11111011;
        alu_op_rom[110] = 8'b11111011;
        alu_op_rom[111] = 8'b11111011;
        alu_op_rom[112] = 8'b11111011;
        alu_op_rom[113] = 8'b11111011;
        alu_op_rom[114] = 8'b11111011;
        alu_op_rom[115] = 8'b11111011;
        alu_op_rom[116] = 8'b11111011;
        alu_op_rom[117] = 8'b11111011;
        alu_op_rom[118] = 8'b11111011;
        alu_op_rom[119] = 8'b11111011;
        alu_op_rom[120] = 8'b11111011;
        alu_op_rom[121] = 8'b11111011;
        alu_op_rom[122] = 8'b11111011;
        alu_op_rom[123] = 8'b11111011;
        alu_op_rom[124] = 8'b11111011;
        alu_op_rom[125] = 8'b11111011;
        alu_op_rom[126] = 8'b11111011;
        alu_op_rom[127] = 8'b11111011;
        alu_op_rom[128] = 8'b11111010;
        alu_op_rom[129] = 8'b11111010;
        alu_op_rom[130] = 8'b11111010;
        alu_op_rom[131] = 8'b11111010;
        alu_op_rom[132] = 8'b11111010;
        alu_op_rom[133] = 8'b11111010;
        alu_op_rom[134] = 8'b11111010;
        alu_op_rom[135] = 8'b11111010;
        alu_op_rom[136] = 8'b11111010;
        alu_op_rom[137] = 8'b11111010;
        alu_op_rom[138] = 8'b11111010;
        alu_op_rom[139] = 8'b11111010;
        alu_op_rom[140] = 8'b11111010;
        alu_op_rom[141] = 8'b11111010;
        alu_op_rom[142] = 8'b11111010;
        alu_op_rom[143] = 8'b11111010;
        alu_op_rom[144] = 8'b11111010;
        alu_op_rom[145] = 8'b11111010;
        alu_op_rom[146] = 8'b11111010;
        alu_op_rom[147] = 8'b11111010;
        alu_op_rom[148] = 8'b11111010;
        alu_op_rom[149] = 8'b11111010;
        alu_op_rom[150] = 8'b11111010;
        alu_op_rom[151] = 8'b11111010;
        alu_op_rom[152] = 8'b11111010;
        alu_op_rom[153] = 8'b11111010;
        alu_op_rom[154] = 8'b11111010;
        alu_op_rom[155] = 8'b11111010;
        alu_op_rom[156] = 8'b11111010;
        alu_op_rom[157] = 8'b11111010;
        alu_op_rom[158] = 8'b11111010;
        alu_op_rom[159] = 8'b11111010;
        alu_op_rom[160] = 8'b11111010;
        alu_op_rom[161] = 8'b11111010;
        alu_op_rom[162] = 8'b11111010;
        alu_op_rom[163] = 8'b11111010;
        alu_op_rom[164] = 8'b11111010;
        alu_op_rom[165] = 8'b11111010;
        alu_op_rom[166] = 8'b11111010;
        alu_op_rom[167] = 8'b11111010;
        alu_op_rom[168] = 8'b11111010;
        alu_op_rom[169] = 8'b11111010;
        alu_op_rom[170] = 8'b11111010;
        alu_op_rom[171] = 8'b11111010;
        alu_op_rom[172] = 8'b11111010;
        alu_op_rom[173] = 8'b11111010;
        alu_op_rom[174] = 8'b11111010;
        alu_op_rom[175] = 8'b11111010;
        alu_op_rom[176] = 8'b11111010;
        alu_op_rom[177] = 8'b11111010;
        alu_op_rom[178] = 8'b11111010;
        alu_op_rom[179] = 8'b11111010;
        alu_op_rom[180] = 8'b11111010;
        alu_op_rom[181] = 8'b11111010;
        alu_op_rom[182] = 8'b11111010;
        alu_op_rom[183] = 8'b11111010;
        alu_op_rom[184] = 8'b11111010;
        alu_op_rom[185] = 8'b11111010;
        alu_op_rom[186] = 8'b11111010;
        alu_op_rom[187] = 8'b11111010;
        alu_op_rom[188] = 8'b11111010;
        alu_op_rom[189] = 8'b11111010;
        alu_op_rom[190] = 8'b11111010;
        alu_op_rom[191] = 8'b11111010;
        alu_op_rom[192] = 8'b11111011;
        alu_op_rom[193] = 8'b11011000;
        alu_op_rom[194] = 8'b01111010;
        alu_op_rom[195] = 8'b10111010;
        alu_op_rom[196] = 8'b11111100;
        alu_op_rom[197] = 8'b11101000;
        alu_op_rom[198] = 8'b11111101;
        alu_op_rom[199] = 8'b11111110;
        alu_op_rom[200] = 8'b11111011;
        alu_op_rom[201] = 8'b11011000;
        alu_op_rom[202] = 8'b01111010;
        alu_op_rom[203] = 8'b10111010;
        alu_op_rom[204] = 8'b11111100;
        alu_op_rom[205] = 8'b11110000;
        alu_op_rom[206] = 8'b11111101;
        alu_op_rom[207] = 8'b11111110;
        alu_op_rom[208] = 8'b11111011;
        alu_op_rom[209] = 8'b11011000;
        alu_op_rom[210] = 8'b01111010;
        alu_op_rom[211] = 8'b10111010;
        alu_op_rom[212] = 8'b11111100;
        alu_op_rom[213] = 8'b11101000;
        alu_op_rom[214] = 8'b11111101;
        alu_op_rom[215] = 8'b11111110;
        alu_op_rom[216] = 8'b11111011;
        alu_op_rom[217] = 8'b11011000;
        alu_op_rom[218] = 8'b01111010;
        alu_op_rom[219] = 8'b10111010;
        alu_op_rom[220] = 8'b11111100;
        alu_op_rom[221] = 8'b11110000;
        alu_op_rom[222] = 8'b11111101;
        alu_op_rom[223] = 8'b11111110;
        alu_op_rom[224] = 8'b11111011;
        alu_op_rom[225] = 8'b11011000;
        alu_op_rom[226] = 8'b01111010;
        alu_op_rom[227] = 8'b10111010;
        alu_op_rom[228] = 8'b11111100;
        alu_op_rom[229] = 8'b11101000;
        alu_op_rom[230] = 8'b11111101;
        alu_op_rom[231] = 8'b11111110;
        alu_op_rom[232] = 8'b11111010;
        alu_op_rom[233] = 8'b11011000;
        alu_op_rom[234] = 8'b01111010;
        alu_op_rom[235] = 8'b10111010;
        alu_op_rom[236] = 8'b11111100;
        alu_op_rom[237] = 8'b11110000;
        alu_op_rom[238] = 8'b11111101;
        alu_op_rom[239] = 8'b11111110;
        alu_op_rom[240] = 8'b11111000;
        alu_op_rom[241] = 8'b11111000;
        alu_op_rom[242] = 8'b11111000;
        alu_op_rom[243] = 8'b11111000;
        alu_op_rom[244] = 8'b11111000;
        alu_op_rom[245] = 8'b11111000;
        alu_op_rom[246] = 8'b11111000;
        alu_op_rom[247] = 8'b11111000;
        alu_op_rom[248] = 8'b11111000;
        alu_op_rom[249] = 8'b11111000;
        alu_op_rom[250] = 8'b11111000;
        alu_op_rom[251] = 8'b11111000;
        alu_op_rom[252] = 8'b11111000;
        alu_op_rom[253] = 8'b11111000;
        alu_op_rom[254] = 8'b11111000;
        alu_op_rom[255] = 8'b11111000;
    end

endmodule