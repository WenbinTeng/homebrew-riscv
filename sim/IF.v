`include "./util/_add32.v"
`include "./util/_bus32.v"
`include "./util/_dec32.v"
`include "./util/_reg32.v"
`include "./include/_74x138.v"
`include "./include/_at28c256.v"

module IF (
    input           clk,
    input           rst_flag,
    input   [31:0]  rst_addr,
    input           int_flag,
    input   [31:0]  int_addr,
    input   [31:0]  qa,
    input           is_lt,      // ACTIVE LOW
    input           is_ltu,     // ACTIVE LOW
    input           is_zero,    // ACTIVE LOW
    output  [31:0]  pc,
    output  [31:0]  inst,
    output  [31:0]  inst_enable // ACTIVE **LOW**
);

    wire [31:0] curr_pc;
    wire [31:0] plus_pc;
    wire [31:0] next_pc;
    wire [31:0] buff_pc;

    assign pc = curr_pc;

    wire [31:0] pc_base;
    wire [31:0] pc_offs;

    _dec32 u_dec32 (
        inst[6:2],
        inst_enable
    );

    wire jal    = inst_enable[27];
    wire jalr   = inst_enable[25];
    wire branch = inst_enable[24];
    wire [7:0] branch_enable;

    wire [31:0] j_type_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    wire [31:0] b_type_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [31:0] i_type_imm = {{20{inst[31]}}, inst[31:20]};

    _74x138 u_74x138 (
        inst[14:12],
        1'b1,
        branch,
        branch,
        branch_enable
    );

    wire brh_flag = (branch_enable[0] |  is_zero) &  // beq
                    (branch_enable[1] | ~is_zero) &  // bne
                    (branch_enable[4] |  is_lt)   &  // blt
                    (branch_enable[5] | ~is_lt)   &  // bge
                    (branch_enable[6] |  is_ltu)  &  // bltu
                    (branch_enable[7] | ~is_ltu)  &  // bgeu
                    1;

    _bus32 #(2) u_bus32_0 (
        {jalr,  ~jalr},
        {qa,    pc   },
        pc_base
    );

    _bus32 #(4) u_bus32_1 (
        {jal,           jalr,           brh_flag,       ~(jal&jalr&brh_flag)},
        {j_type_imm,    i_type_imm,     b_type_imm,     32'h4               },
        pc_offs
    );

    _add32 u_add32 (
        pc_base,
        pc_offs,
        plus_pc
    );

    _bus32 #(3) u_bus32_2 (
        {rst_flag,  int_flag|~rst_flag, 1'b0|~int_flag|~rst_flag},
        {rst_addr,  int_addr,           plus_pc                 },
        next_pc
    );

    _reg32 u_reg32_0 (
        1'b0,
        ~clk,
        next_pc,
        buff_pc
    );

    _reg32 u_reg32_1 (
        1'b0,
        clk,
        buff_pc,
        curr_pc
    );

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