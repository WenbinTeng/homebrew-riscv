// `include "./util/_add32.v"
// `include "./util/_bus32.v"
// `include "./util/_dec32.v"
// `include "./util/_reg32.v"
// `include "./include/_74x138.v"
// `include "./include/_at28c256.v"

module IF (
    input           clk,        // Clock signal
    input           rst_flag,   // Reset signal
    input   [31:0]  rst_addr,   // Reset address
    input           int_flag,   // Interupt signal
    input   [31:0]  int_addr,   // Interupt address
    input   [31:0]  gpr_qa,     // GPR output port a
    input           is_lt,      // Is a less than b. Active LOW
    input           is_ltu,     // Is unsigned a less than unsigned b. Active LOW
    input           is_zero,    // Is zero (a equals to b). Active LOW
    output  [31:0]  pc,         // Program counter
    output  [31:0]  inst,       // Instruciton
    output  [31:0]  inst_en     // Instruction operation code decode result. Active **LOW**
);

    /* Define program counter in different calculate stages */
    wire [31:0] curr_pc;
    wire [31:0] plus_pc;
    wire [31:0] next_pc;
    wire [31:0] buff_pc;
    
    /* Assignment of program counter output */
    assign pc = curr_pc;

    /* Decode instruction operation code */
    _dec32 u_dec32 (
        inst[6:2],
        inst_en
    );

    /* Designate if it is jump or branch instruciton */
    wire        jal     = inst_en[27];
    wire        jalr    = inst_en[25];
    wire        brh     = inst_en[24];
    wire [7:0]  brh_en;

    /* Decode branch instruction, then output one-hot (active LOW) operation code. */
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
        {jalr,  ~jalr},
        {gpr_qa,    pc   },
        pc_base
    );

    /* Concatenate immediate number from instrcution for jump or branch offset */
    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};

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
    
endmodule