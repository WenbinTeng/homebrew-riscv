module alu (
    input [31:0] operand_a,
    input [31:0] operand_b,
    input [3:0] op,
    output [32:0] res
);

    wire [15:0] op_enable;

    _4dec16 u_4dec_16 (
        {1'b0, op[2:0]},
        op_enable
    );

    wire [31:0] res_computed;
    wire [2:0] sel;
    wire [7:0] p_negative;
    wire [7:0] g_negative;
    wire [1:0] p_ahead;
    wire [1:0] g_ahead;
    wire [8:0] carry;
    wire [31:0] dontcare;

    assign carry[0] = 1'b0;

    _mux4fromN #(8) u_mux4fromN (
        op_enable,
        {
            4'b0110,            // AND
            4'b0101,            // OR
            4'b0000,            // SRL SRA
            4'b0100,            // XOR
            4'b0010,            // SLTU
            4'b0010,            // SLT
            4'b0000,            // SLL
            {3'b001, ~op[3]}    // ADD SUB
        },
        {dontcare[0], sel}
    );

    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            _74x381 u_74x381 (
                operand_a[i*4+3:i*4],
                operand_b[i*4+3:i*4],
                sel[2:0],
                carry[i],
                g_negative[i],
                p_negative[i],
                res_computed[i*4+3:i*4]
            );
        end
        for (i = 0; i < 3; i = i + 1) begin
            if (i < 2) begin
                _74x182 u_74x182 (
                    g_negative[i*4+3:i*4],
                    p_negative[i*4+3:i*4],
                    carry[i*4],
                    carry[i*4+1],
                    carry[i*4+2],
                    carry[i*4+3],
                    g_ahead[i],
                    p_ahead[i]
                );
            end
            else begin
                _74x182 u_74x182 (
                    {2'b0, g_ahead},
                    {2'b0, p_ahead},
                    carry[0],
                    carry[4],
                    carry[8],
                    dontcare[1],
                    dontcare[2],
                    dontcare[3]
                );
            end
        end
    endgenerate
    
    wire [31:0] res_shifted;
    wire [31:0] res_shifted_reverted;
    wire [31:0] operand_shift;
    wire [31:0] operand_shift_reverted;
    wire [31:0] shift_input [4:0];
    wire [31:0] shift_right [4:0];

    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign res_shifted_reverted[i] = res_shifted[31-i];
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign operand_shift_reverted[i] = operand_shift[31-i];
        end
    endgenerate

    assign operand_shift = operand_a;
    assign shift_input[0] = !op_enable[1] ? operand_shift_reverted : operand_shift;
    assign shift_right[0] = {{16{op[3]&shift_input[0][31]}}, shift_input[0][31:16]};
    assign shift_right[1] = {{8{op[3]&shift_input[1][31]}}, shift_input[1][31:8]};
    assign shift_right[2] = {{4{op[3]&shift_input[2][31]}}, shift_input[2][31:4]};
    assign shift_right[3] = {{2{op[3]&shift_input[3][31]}}, shift_input[3][31:2]};
    assign shift_right[4] = {{1{op[3]&shift_input[0][31]}}, shift_input[4][31:1]};

    generate
        for (i = 0; i < 5; i = i + 1) begin
            if (i == 4) begin
                for (j = 0; j < 8; j = j + 1) begin
                    _74x157 u_74x157 (
                        operand_b[4-i],
                        1'b0,
                        shift_input[i][j*4+3:j*4],
                        shift_right[i][j*4+3:j*4],
                        res_shifted[j*4+3:j*4]
                    );
                end
            end
            else begin
                for (j = 0; j < 8; j = j + 1) begin
                    _74x157 u_74x157 (
                        operand_b[4-i],
                        1'b0,
                        shift_input[i][j*4+3:j*4],
                        shift_right[i][j*4+3:j*4],
                        shift_input[i+1][j*4+3:j*4]
                    );
                end
            end

        end
    endgenerate

    _mux32fromN #(8) u_mux32fromN (
        op_enable,
        {
            res_computed,           // AND
            res_computed,           // OR
            res_shifted,            // SRL SRA
            res_computed,           // XOR
            {31'b0, carry[8]},      // SLTU
            {31'b0, carry[7]},      // SLT
            res_shifted_reverted,   // SLL
            res_computed            // ADD SUB
        },
        res[31:0]
    );

    assign res[32] = carry[8];

endmodule